classdef ConditionalAction < AbstractEventAction
    %ConditionalAction An if / elseif / else container of other event actions.
    %
    %   The first branch whose conditional evaluates true has its actions
    %   executed in order; if none do, the else actions run.  Like every other
    %   simple event action, executeAction mutates the incoming state log
    %   entry in place and returns that same handle (see
    %   LaunchVehicleEvent.cleanupEvent for why the log is built that way).

    properties
        ifCondition(1,1) AbstractActionConditional = AlwaysTrueActionCondition();
        ifActions(1,:) AbstractEventAction

        elseifConditions(1,:) AbstractActionConditional
        elseifActions(1,1) dictionary

        elseActions(1,:) AbstractEventAction
    end

    methods
        function obj = ConditionalAction()
            if(nargin > 0)

            end

            obj.elseifActions = dictionary(AbstractActionConditional.empty(1,0), {AbstractEventAction.empty(1,0)});

            obj.id = rand();
        end

        function addIfAction(obj, action)
            obj.ifActions(end+1) = action;
        end

        function removeIfAction(obj, action, lvdData)
            if(nargin < 3)
                lvdData = obj.resolveLvdData();
            end

            obj.removeActionVariables(action, lvdData);
            obj.ifActions(obj.ifActions == action) = [];
        end

        function addElseIfConditional(obj, cond)
            obj.elseifConditions(end+1) = cond;
            obj.elseifActions{cond} = AbstractEventAction.empty(1,0);
        end

        function removeElseIfConditional(obj, cond)
            obj.elseifConditions(obj.elseifConditions == cond) = [];
            obj.elseifActions{cond} = [];
        end

        function substituteElseIfConditional(obj, oldCond, newCond)
            ind = find(obj.elseifConditions == oldCond);
            obj.elseifConditions(ind) = newCond;

            obj.elseifActions(newCond) = obj.elseifActions(oldCond);
            obj.elseifActions(oldCond) = [];
        end

        function addElseIfAction(obj, elseIfCond, action)
            %Adding an action must never strip its optimization variables;
            %only the remove* methods do that.
            if(obj.elseifActions.isKey(elseIfCond))
                elseIfActions = obj.getElseIfActionsForCond(elseIfCond);

                if(iscell(action))
                    action = [action{:}];
                end

                if(not(isempty(action)))
                    elseIfActions(end+1) = action;
                end

                obj.elseifActions{elseIfCond} = elseIfActions;
            else
                error('Unknown key in else if action dictionary!');
            end
        end

        function removeElseIfAction(obj, elseIfCond, action, lvdData)
            if(nargin < 4)
                lvdData = obj.resolveLvdData();
            end

            if(obj.elseifActions.isKey(elseIfCond))
                obj.removeActionVariables(action, lvdData);

                elseIfActions = obj.getElseIfActionsForCond(elseIfCond);
                elseIfActions(elseIfActions == action) = [];
                obj.elseifActions{elseIfCond} = elseIfActions;
            else
                error('Unknown key in else if action dictionary!');
            end
        end

        function addElseAction(obj, action)
            obj.elseActions(end+1) = action;
        end

        function removeElseAction(obj, action, lvdData)
            if(nargin < 3)
                lvdData = obj.resolveLvdData();
            end

            obj.removeActionVariables(action, lvdData);
            obj.elseActions(obj.elseActions == action) = [];
        end

        function removeActionVariables(obj, action, lvdData)
            %removeActionVariables Removes the optimization variables owned by
            %a branch action from the mission's variable set.  lvdData may be
            %omitted, in which case it is resolved through the owning event;
            %if no lvdData can be found there is no variable set to clean and
            %the call is a no-op.
            if(nargin < 3)
                lvdData = obj.resolveLvdData();
            end

            if(isempty(lvdData) || isempty(lvdData.optimizer))
                return;
            end

            [~, vars] = action.hasActiveOptimVar();
            if(not(isempty(vars)))
                for(i=1:length(vars))
                    lvdData.optimizer.vars.removeVariable(vars(i));
                end
            end
        end

        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) ConditionalAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            %Consistent with every other simple action: operate on (and
            %return) the incoming handle rather than a deep copy.
            newStateLogEntry = stateLogEntry;

            %IF
            if(obj.ifCondition.evaluateConditional(newStateLogEntry))
                for(i=1:length(obj.ifActions))
                    newStateLogEntry = obj.ifActions(i).executeAction(newStateLogEntry);
                end

                return;
            end

            %ELSE IF
            for(i=1:length(obj.elseifConditions))
                elseIfCondition = obj.elseifConditions(i);
                if(elseIfCondition.evaluateConditional(newStateLogEntry))
                    theseElseIfActions = obj.getElseIfActionsForCond(elseIfCondition);

                    for(j=1:length(theseElseIfActions))
                        newStateLogEntry = theseElseIfActions(j).executeAction(newStateLogEntry);
                    end

                    return;
                end
            end

            %ELSE
            for(i=1:length(obj.elseActions))
                newStateLogEntry = obj.elseActions(i).executeAction(newStateLogEntry);
            end
        end

        function initAction(obj, initialStateLogEntry)
            event = initialStateLogEntry.event;

            allActions = obj.getAllBranchActions();
            for(i=1:length(allActions))
                allActions(i).event = event;
                allActions(i).initAction(initialStateLogEntry);
            end
        end

        function name = getName(obj)
            name = sprintf('Conditional Action');
        end

        function allActions = getAllBranchActions(obj)
            %getAllBranchActions Every action in every branch (if, each
            %elseif in order, else) as one flat array.
            allActions = AbstractEventAction.empty(1,0);

            allActions = horzcat(allActions, obj.ifActions(:)');

            for(i=1:numel(obj.elseifConditions))
                theseActions = obj.getElseIfActionsForCond(obj.elseifConditions(i));
                allActions = horzcat(allActions, theseActions(:)'); %#ok<AGROW>
            end

            allActions = horzcat(allActions, obj.elseActions(:)');
        end

        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);

            allActions = obj.getAllBranchActions();
            for(i=1:numel(allActions))
                [thisTf, theseVars] = allActions(i).hasActiveOptimVar();

                tf = tf || thisTf;
                vars = horzcat(vars, theseVars(:)'); %#ok<AGROW>
            end
        end

        %% Dependency tracking: a component referenced only inside a branch
        %  must still count as "in use", otherwise the GUI lets it be deleted.
        function tf = usesStage(obj, stage)
            tf = obj.anyBranchAction(@(a) a.usesStage(stage));
        end

        function tf = usesEngine(obj, engine)
            tf = obj.anyBranchAction(@(a) a.usesEngine(engine));
        end

        function tf = usesTank(obj, tank)
            tf = obj.anyBranchAction(@(a) a.usesTank(tank));
        end

        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.anyBranchAction(@(a) a.usesEngineToTankConn(engineToTank));
        end

        function tf = usesStopwatch(obj, stopwatch)
            tf = obj.anyBranchAction(@(a) a.usesStopwatch(stopwatch));
        end

        function tf = usesExtremum(obj, extremum)
            tf = obj.anyBranchAction(@(a) a.usesExtremum(extremum));
        end

        function tf = usesTankToTankConn(obj, tankToTank)
            tf = obj.anyBranchAction(@(a) a.usesTankToTankConn(tankToTank));
        end

        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = obj.anyBranchAction(@(a) a.usesCalculusCalc(calculusCalc));
        end

        function tf = usesEvent(obj, event)
            %The if/elseif conditions can reference an event too (quantity at
            %event comparisons), not just the branch actions.
            tf = obj.ifCondition.usesEvent(event);

            for(i=1:numel(obj.elseifConditions))
                tf = tf || obj.elseifConditions(i).usesEvent(event);
            end

            tf = tf || obj.anyBranchAction(@(a) a.usesEvent(event));
        end

        function tf = usesPwrSink(obj, powerSink)
            tf = obj.anyBranchAction(@(a) a.usesPwrSink(powerSink));
        end

        function tf = usesPwrSrc(obj, powerSrc)
            tf = obj.anyBranchAction(@(a) a.usesPwrSrc(powerSrc));
        end

        function tf = usesPwrStorage(obj, powerStorage)
            tf = obj.anyBranchAction(@(a) a.usesPwrStorage(powerStorage));
        end

        function tf = usesSensor(obj, sensor)
            tf = obj.anyBranchAction(@(a) a.usesSensor(sensor));
        end

        function tf = usesPluginVariable(obj, pluginVar)
            tf = obj.anyBranchAction(@(a) a.usesPluginVariable(pluginVar));
        end
    end

    methods(Access = private)
        function actions = getElseIfActionsForCond(obj, cond)
            actions = obj.elseifActions{cond};

            if(iscell(actions))
                if(isempty(actions))
                    actions = AbstractEventAction.empty(1,0);
                else
                    actions = [actions{:}];
                end
            end

            if(isempty(actions))
                actions = AbstractEventAction.empty(1,0);
            end
        end

        function tf = anyBranchAction(obj, predicate)
            tf = false;

            allActions = obj.getAllBranchActions();
            for(i=1:numel(allActions))
                if(predicate(allActions(i)))
                    tf = true;
                    return;
                end
            end
        end

        function lvdData = resolveLvdData(obj)
            lvdData = LvdData.empty(1,0);

            if(not(isempty(obj.event)))
                try
                    lvdData = obj.event.lvdData;
                catch
                    lvdData = LvdData.empty(1,0);
                end
            end
        end
    end

    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            arguments
                action(1,1) ConditionalAction
                lv(1,1) LaunchVehicle
            end

            output = AppDesignerGUIOutput({false});
            lvd_EditConditionalActionGUI_App(action, lv.lvdData, output);
            addActionTf = output.output{1};
        end
    end
end
