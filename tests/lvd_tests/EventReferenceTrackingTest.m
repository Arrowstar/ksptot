classdef EventReferenceTrackingTest < KsptotTestCase
    %EventReferenceTrackingTest "Is this object still referenced?" bookkeeping.
    %
    % The usesX() predicates on events, non-sequential events, and actions
    % guard deletion in the GUI: a false negative lets the user delete an
    % event/stage/tank/... that another object still points at, leaving a
    % dangling handle in the mission file.  Each test here pins a hole that
    % existed in that bookkeeping:
    %
    %   * SetNextEventAction had no usesEvent override, so its branch target
    %     could be deleted.
    %   * LaunchVehicleNonSeqEvents had no usesEvent at all (bounding events
    %     and inner actions were invisible) and its usesCalculusCalc called
    %     usesExtremum (copy/paste).
    %   * ConditionalAction overrode none of the usesX predicates, so anything
    %     referenced only inside an if/elseif/else branch was invisible; its
    %     removeActionVariables read a non-existent property; and adding an
    %     elseif action stripped the action's optimization variables.
    %   * SetKinematicStateAction.usesEvent ignored the stage, engine, EPS
    %     sink, and EPS source inherit-from-event links.
    %   * The main GUI's delete-event check asked whether the event referenced
    %     ITSELF; LaunchVehicleScript.getEventUsageReport now does the real
    %     cross-check and the GUI calls it.
    %
    % Object identity checks use == because every class involved is a
    % handle (matlab.mixin.SetGet), which is also what production relies on.

    methods(Test)

        %% ---------------------------------------------- SetNextEventAction

        function setNextEventActionReportsItsTarget(testCase)
            [~, evt1, evt2, evt3] = testCase.buildThreeEventScript();

            action = SetNextEventAction(evt2);
            evt3.addAction(action);

            testCase.verifyTrue(action.usesEvent(evt2), ...
                'SetNextEventAction must report the event it jumps to.');
            testCase.verifyFalse(action.usesEvent(evt1), ...
                'SetNextEventAction must not report unrelated events.');
            testCase.verifyTrue(evt3.usesEvent(evt2), ...
                'The owning event must surface the SetNextEventAction target through usesEvent.');
            testCase.verifyFalse(evt3.usesEvent(evt1));

            emptyTarget = SetNextEventAction();
            testCase.verifyFalse(emptyTarget.usesEvent(evt1), ...
                'An unconfigured SetNextEventAction must report no references rather than erroring.');
        end

        %% ------------------------------------------ Non-sequential events

        function nonSeqEventsReportBoundAndActionReferences(testCase)
            [lvdData, evt1, evt2, evt3] = testCase.buildThreeEventScript();
            script = lvdData.script;
            nonSeqEvts = script.nonSeqEvts;

            testCase.verifyFalse(nonSeqEvts.usesEvent(evt1), ...
                'With no non-sequential events nothing can be referenced.');

            innerEvt = LaunchVehicleEvent.getDefaultEvent(script);
            nse = LaunchVehicleNonSeqEvent(innerEvt);
            nse.lwrBndEvt = evt1;
            nse.uprBndEvt = evt2;
            nonSeqEvts.addEvent(nse);

            testCase.verifyTrue(nonSeqEvts.usesEvent(evt1), 'Lower bounding event must count as a reference.');
            testCase.verifyTrue(nonSeqEvts.usesEvent(evt2), 'Upper bounding event must count as a reference.');
            testCase.verifyFalse(nonSeqEvts.usesEvent(evt3), 'An event that is neither a bound nor an action target must not be reported.');

            innerEvt.addAction(SetNextEventAction(evt3));
            testCase.verifyTrue(nonSeqEvts.usesEvent(evt3), ...
                'An action inside the non-sequential event must count as a reference.');
        end

        function nonSeqEventsDistinguishExtremaFromCalculusCalcs(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            ex = LaunchVehicleExtrema(lvdData);
            lvdData.launchVehicle.addExtremum(ex);

            innerEvt = LaunchVehicleEvent.getDefaultEvent(script);
            innerEvt.addAction(ResetExtremumValueAction(ex));
            script.nonSeqEvts.addEvent(LaunchVehicleNonSeqEvent(innerEvt));

            testCase.verifyTrue(script.nonSeqEvts.usesExtremum(ex), ...
                'The extremum reset action must be reported by usesExtremum.');
            testCase.verifyFalse(script.nonSeqEvts.usesCalculusCalc(ex), ...
                ['usesCalculusCalc used to delegate to usesExtremum, so an extremum passed in as a ' ...
                 '"calculus calc" was reported as in use.  It must consult usesCalculusCalc only.']);
        end

        %% ---------------------------------------------- ConditionalAction

        function conditionalActionExposesBranchReferences(testCase)
            [lvdData, evt1, evt2, ~] = testCase.buildThreeEventScript();
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);
            tank = stg.tanks(1);

            sw = LaunchVehicleStopwatch(lvdData);
            lv.addStopwatch(sw);
            ex = LaunchVehicleExtrema(lvdData);
            lv.addExtremum(ex);

            unusedSw = LaunchVehicleStopwatch(lvdData);
            lv.addStopwatch(unusedSw);

            cond = ConditionalAction();
            cond.ifCondition = AlwaysFalseActionCondition();
            cond.addIfAction(SetStageActiveStateAction(stg, false));

            elseIfCond = AlwaysFalseActionCondition();
            cond.addElseIfConditional(elseIfCond);
            cond.addElseIfAction(elseIfCond, SetEngineActiveStateAction(engine, true));
            cond.addElseIfAction(elseIfCond, SetStopwatchRunningStateAction(sw, StopwatchRunningEnum.Running));

            cond.addElseAction(AddMassToTankAction(tank, 0.1));
            cond.addElseAction(ResetExtremumValueAction(ex));
            cond.addElseAction(SetNextEventAction(evt2));

            testCase.verifyEqual(numel(cond.getAllBranchActions()), 6, ...
                'getAllBranchActions must flatten if + every elseif + else.');

            testCase.verifyTrue(cond.usesStage(stg),       'Stage referenced in the IF branch must be reported.');
            testCase.verifyTrue(cond.usesEngine(engine),   'Engine referenced in an ELSEIF branch must be reported.');
            testCase.verifyTrue(cond.usesStopwatch(sw),    'Stopwatch referenced in an ELSEIF branch must be reported.');
            testCase.verifyTrue(cond.usesTank(tank),       'Tank referenced in the ELSE branch must be reported.');
            testCase.verifyTrue(cond.usesExtremum(ex),     'Extremum referenced in the ELSE branch must be reported.');
            testCase.verifyTrue(cond.usesEvent(evt2),      'Event referenced in the ELSE branch must be reported.');

            testCase.verifyFalse(cond.usesStopwatch(unusedSw), 'An unreferenced stopwatch must not be reported.');
            testCase.verifyFalse(cond.usesEvent(evt1),         'An unreferenced event must not be reported.');
            testCase.verifyFalse(cond.usesCalculusCalc(ex),    'Nothing in the branches uses a calculus calc.');

            %The whole chain the GUI actually consults must see through the
            %conditional: action -> event -> script -> lvdData.
            evt1.addAction(cond);
            testCase.verifyTrue(evt1.usesStage(stg),               'Event.usesStage must see into conditional branches.');
            testCase.verifyTrue(lvdData.script.usesEngine(engine), 'Script.usesEngine must see into conditional branches.');
            testCase.verifyTrue(lvdData.usesTank(tank),            'LvdData.usesTank must see into conditional branches.');
            testCase.verifyTrue(lvdData.usesStopwatch(sw),         'LvdData.usesStopwatch must see into conditional branches.');
            testCase.verifyTrue(lvdData.usesExtremum(ex),          'LvdData.usesExtremum must see into conditional branches.');
            testCase.verifyTrue(evt1.usesEvent(evt2),              'Event.usesEvent must see a SetNextEventAction inside a conditional.');
        end

        function conditionalActionRemovesBranchActionVariables(testCase)
            [lvdData, evt1, ~, ~] = testCase.buildThreeEventScript();
            varSet = lvdData.optimizer.vars;
            numVars0 = numel(varSet.vars);

            %-- explicit lvdData (the path the conditional editor GUI uses)
            dvIf = AddDeltaVAction([0.1; 0; 0], DeltaVFrameEnum.Inertial, false);
            varSet.addVariable(AddDeltaVActionVariable(dvIf));
            testCase.assertEqual(numel(varSet.vars), numVars0 + 1, 'Fixture: the variable must be registered.');

            cond = ConditionalAction();
            cond.addIfAction(dvIf);
            cond.removeIfAction(dvIf, lvdData);

            testCase.verifyEqual(numel(varSet.vars), numVars0, ...
                'removeIfAction must strip the removed action''s optimization variable from the set.');
            testCase.verifyEmpty(cond.ifActions, 'removeIfAction must remove the action from the branch.');

            %-- implicit lvdData resolved through the owning event
            dvElse = AddDeltaVAction([0; 0.1; 0], DeltaVFrameEnum.Inertial, false);
            varSet.addVariable(AddDeltaVActionVariable(dvElse));
            cond.addElseAction(dvElse);
            evt1.addAction(cond);
            cond.event = evt1; %as the event editor does when it attaches an action

            cond.removeElseAction(dvElse); %used to error: "Unrecognized property lvdData"
            testCase.verifyEqual(numel(varSet.vars), numVars0, ...
                'removeElseAction must find lvdData through the owning event and strip the variable.');
            testCase.verifyEmpty(cond.elseActions);

            %-- adding an action must NOT strip its variables
            elseIfCond = AlwaysFalseActionCondition();
            dvElseIf = AddDeltaVAction([0; 0; 0.1], DeltaVFrameEnum.Inertial, false);
            varSet.addVariable(AddDeltaVActionVariable(dvElseIf));
            cond.addElseIfConditional(elseIfCond);
            cond.addElseIfAction(elseIfCond, dvElseIf); %used to error for actions with variables
            testCase.verifyEqual(numel(varSet.vars), numVars0 + 1, ...
                'addElseIfAction must leave the action''s optimization variable registered.');

            cond.removeElseIfAction(elseIfCond, dvElseIf, lvdData);
            testCase.verifyEqual(numel(varSet.vars), numVars0, ...
                'removeElseIfAction must strip the removed action''s optimization variable.');

            %-- a conditional that is attached to nothing still removes the
            %   action; there is simply no variable set to clean.
            orphan = ConditionalAction();
            dvOrphan = AddDeltaVAction([0.2; 0; 0], DeltaVFrameEnum.Inertial, false);
            AddDeltaVActionVariable(dvOrphan);
            orphan.addIfAction(dvOrphan);
            orphan.removeIfAction(dvOrphan);
            testCase.verifyEmpty(orphan.ifActions, ...
                'An unattached conditional must still remove the action instead of erroring.');
        end

        function conditionalActionMutatesEntryInPlaceLikeOtherActions(testCase)
            [lvdData, evt1, ~, ~] = testCase.buildThreeEventScript();
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.event = evt1;
            v0 = entry.velocity;

            dv1 = [0.1; 0; 0];
            dv2 = [0; 0.05; 0];

            cond = ConditionalAction();
            cond.ifCondition = AlwaysTrueActionCondition();
            cond.addIfAction(AddDeltaVAction(dv2, DeltaVFrameEnum.Inertial, false));

            evt1.addAction(AddDeltaVAction(dv1, DeltaVFrameEnum.Inertial, false));
            evt1.addAction(cond);

            entries = evt1.cleanupEvent(entry);

            testCase.verifyEqual(numel(entries), 2, 'cleanupEvent returns one entry per action.');
            testCase.verifySameHandle(entries(1), entry, 'A simple action returns the incoming handle.');
            testCase.verifySameHandle(entries(2), entry, ...
                ['ConditionalAction must return the incoming handle too; it used to be the only simple action ' ...
                 'that deep-copied, so per-action entries were aliases for every action except this one.']);
            testCase.verifyVectorEqual(entry.velocity, v0 + dv1 + dv2, 1e-12, ...
                'Both actions must have been applied to the one shared entry.');
        end

        %% ------------------------------------------- SetKinematicStateAction

        function setKinematicStateActionReportsEveryInheritLink(testCase)
            [lvdData, evt1, evt2, evt3] = testCase.buildThreeEventScript();
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);
            tank = stg.tanks(1);

            action = SetKinematicStateAction(lvdData.stateLog, KeplerianElementSet.getDefaultElements());
            testCase.verifyFalse(action.usesEvent(evt2), 'A fresh action inherits from the last state only.');

            %stage link (was ignored)
            stageState = SetKinematicStateStageState(stg);
            stageState.inheritStageStateFrom = InheritStateEnum.InheritFromSpecifiedEvent;
            stageState.inheritStageStateFromEvent = evt2;
            action.stageStates = stageState;
            testCase.verifyTrue(action.usesEvent(evt2),  'A stage state inheriting from an event must be reported.');
            testCase.verifyFalse(action.usesEvent(evt3), 'Other events must not be reported.');
            action.stageStates = SetKinematicStateStageState.empty(1,0);

            %engine link (was ignored)
            engineState = SetKinematicStateEngineState(engine);
            engineState.inheritEngineStateFrom = InheritStateEnum.InheritFromSpecifiedEvent;
            engineState.inheritEngineStateFromEvent = evt3;
            action.engineStates = engineState;
            testCase.verifyTrue(action.usesEvent(evt3),  'An engine state inheriting from an event must be reported.');
            testCase.verifyFalse(action.usesEvent(evt2));
            action.engineStates = SetKinematicStateEngineState.empty(1,0);

            %tank link (already worked; keep it that way)
            tankState = SetKinematicStateTankState(tank);
            tankState.inheritTankStateFrom = InheritStateEnum.InheritFromSpecifiedEvent;
            tankState.inheritTankStateFromEvent = evt1;
            action.tankStates = tankState;
            testCase.verifyTrue(action.usesEvent(evt1),  'A tank state inheriting from an event must be reported.');
            action.tankStates = SetKinematicStateTankState.empty(1,0);

            %a link that is configured but switched to "last state" is not a reference
            stageState.inheritStageStateFrom = InheritStateEnum.InheritFromLastState;
            action.stageStates = stageState;
            testCase.verifyFalse(action.usesEvent(evt2), ...
                'Inherit-from-last-state links must not report the (stale) event handle they still hold.');

            %time / pos-vel links still work
            action.stageStates = SetKinematicStateStageState.empty(1,0);
            action.inheritTime = true;
            action.inheritTimeFrom = InheritStateEnum.InheritFromSpecifiedEvent;
            action.inheritTimeFromEvent = evt3;
            testCase.verifyTrue(action.usesEvent(evt3), 'The time inherit link must still be reported.');
        end

        %% ------------------------------------ LaunchVehicleScript usage report

        function scriptUsageReportListsEveryReferrer(testCase)
            [lvdData, evt1, evt2, evt3] = testCase.buildThreeEventScript();
            script = lvdData.script;

            [tf, reasons] = script.getEventUsageReport(evt2);
            testCase.verifyFalse(tf, 'An unreferenced event must be deletable.');
            testCase.verifyEmpty(reasons);

            %another sequential event's action
            evt3.addAction(SetNextEventAction(evt2));
            [tf, reasons] = script.getEventUsageReport(evt2);
            testCase.verifyTrue(tf);
            testCase.verifyEqual(numel(reasons), 1);
            testCase.verifySubstring(reasons{1}, 'Event 3', ...
                'The report must name the referencing event.');

            %a self reference is not a reason to block deletion (the old GUI
            %check tested exactly and only this case)
            evt2.addAction(SetNextEventAction(evt2));
            [~, reasons] = script.getEventUsageReport(evt2);
            testCase.verifyEqual(numel(reasons), 1, ...
                'An event referencing itself must not be counted as an external reference.');

            %non-sequential event bound
            nse = LaunchVehicleNonSeqEvent(LaunchVehicleEvent.getDefaultEvent(script));
            nse.lwrBndEvt = evt2;
            script.nonSeqEvts.addEvent(nse);
            [~, reasons] = script.getEventUsageReport(evt2);
            testCase.verifyEqual(numel(reasons), 2);
            testCase.verifyTrue(any(contains(reasons, 'bounding event')), ...
                'The report must call out the non-sequential bounding-event reference.');

            %objective function
            noBody = KSPTOT_BodyInfo.empty(1,0);
            fcn = GenericMAConstraint('Altitude', evt2, 0, 0, [], [], noBody);
            genObjFcn = GenericObjectiveFcn(evt2, testCase.kerbinFrame, fcn, 1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.objFcns(end+1) = genObjFcn;
            [~, reasons] = script.getEventUsageReport(evt2);
            testCase.verifyEqual(numel(reasons), 3);
            testCase.verifyTrue(any(contains(reasons, 'objective function')), ...
                'The report must call out the objective-function reference.');

            %the other events remain free
            [tf, reasons] = script.getEventUsageReport(evt1);
            testCase.verifyFalse(tf);
            testCase.verifyEmpty(reasons);
        end
    end

    methods(Access=private)
        function [lvdData, evt1, evt2, evt3] = buildThreeEventScript(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            evt1 = script.getEventForInd(1);
            evt2 = LaunchVehicleEvent.getDefaultEvent(script);
            script.addEvent(evt2);
            evt3 = LaunchVehicleEvent.getDefaultEvent(script);
            script.addEvent(evt3);
        end
    end
end
