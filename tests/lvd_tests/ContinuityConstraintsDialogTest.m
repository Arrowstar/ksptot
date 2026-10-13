classdef ContinuityConstraintsDialogTest < KsptotTestCase
    %ContinuityConstraintsDialogTest Full round-trip UI tests for the
    %create-continuity-constraints dialog (Phase 5: root/misc UIs).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/lvd_CreateContinuityConstraintsGUI_App.mlapp
    %   ctor: lvd_CreateContinuityConstraintsGUI_App(lvdData, selEvent, output)
    %   main-GUI caller: createContConstraintsWithSelEvtMenu_Callback opens
    %   it only when the script holds >= 2 events (otherwise warndlg), so
    %   the fixture below always carries two events.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.  This is a pure
    %   App Designer dialog (no GUIDE migration layer).  There is no Cancel
    %   button: window-X (the figure CloseRequestFcn) is the cancel path.
    %
    % COVERED
    %   Open shows the candidate constraint checkboxes/scales and both
    %   events with Event 1 preselected; unchecking a box disables its
    %   scale field; Save & Close writes time/position/velocity continuity
    %   constraints into the script; a custom scale factor lands on the new
    %   constraints; same-event and non-numeric-scale inputs are rejected
    %   and leave the model alone; window-X preserves the model.  State-log
    %   entries are synthesized (no propagation) so the constraint builder
    %   can resolve the reference frame.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsCandidateConstraintsAndEvents(testCase)
            [lvdData, evt1, evt2, out] = testCase.fixture();
            app = testCase.openDialog(lvdData, evt1, out);

            testCase.verifyTrue(app.TimeCheckBox.Value, 'Time must be on by default.');
            testCase.verifyTrue(app.PositionCheckbox.Value, 'Position must be on by default.');
            testCase.verifyTrue(app.VelocityCheckbox.Value, 'Velocity must be on by default.');
            testCase.verifyFalse(app.AttitudeCheckbox.Value, 'Attitude must be off by default.');
            testCase.verifyFalse(app.TankMassesCheckbox.Value, 'Tank masses must be off by default.');
            testCase.verifyEqual(app.TimeScaleFactorText.Value, '1.0');
            testCase.verifyEqual(app.PositionScaleFactorText.Value, '1.0');
            testCase.verifyEqual(app.VelocityScaleFactorText.Value, '1.0');

            testCase.verifyEqual(numel(app.Event1Combo.Items), 2, 'Both script events must be offered.');
            testCase.verifyEqual(numel(app.Event2Combo.Items), 2);
            testCase.verifyTrue(app.Event1Combo.Value == evt1, 'Event 1 must be preselected to the calling event.');
            testCase.verifyTrue(any(app.Event2Combo.ItemsData == evt2), 'Event 2 must offer the other event.');
        end

        function uncheckingTimeDisablesItsScaleField(testCase)
            [lvdData, evt1, ~, out] = testCase.fixture();
            app = testCase.openDialog(lvdData, evt1, out);

            app.TimeCheckBox.Value = false;
            testCase.fireValueChanged(app.TimeCheckBox);
            testCase.verifyEqual(char(app.TimeScaleFactorText.Enable), 'off');

            app.TimeCheckBox.Value = true;
            testCase.fireValueChanged(app.TimeCheckBox);
            testCase.verifyEqual(char(app.TimeScaleFactorText.Enable), 'on');
        end

        function saveAndCloseCreatesContinuityConstraints(testCase)
            [lvdData, evt1, evt2, out] = testCase.fixture();
            n0 = numel(lvdData.optimizer.constraints.consts);
            app = testCase.openDialog(lvdData, evt1, out);
            fig = app.CreateContinuityConstraintsUIFigure;

            app.Event2Combo.Value = evt2;
            testCase.pushButton(app.SaveAndCloseButton);

            consts = lvdData.optimizer.constraints.consts;
            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(numel(consts), n0 + 7, ...
                'Time (1) + position (3) + velocity (3) continuity constraints must be added.');
            for k = numel(consts)-6:numel(consts)
                testCase.verifyEqual(consts(k).evalType, ConstraintEvalTypeEnum.StateComparison, ...
                    'Continuity constraints compare states across events.');
            end
        end

        function customScaleFactorIsWrittenToNewConstraints(testCase)
            [lvdData, evt1, evt2, out] = testCase.fixture();
            n0 = numel(lvdData.optimizer.constraints.consts);
            app = testCase.openDialog(lvdData, evt1, out);

            app.PositionCheckbox.Value = false;
            app.VelocityCheckbox.Value = false;
            app.TimeScaleFactorText.Value = '2.5';
            app.Event2Combo.Value = evt2;
            testCase.pushButton(app.SaveAndCloseButton);

            consts = lvdData.optimizer.constraints.consts;
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(numel(consts), n0 + 1, 'Only the time constraint must be added.');
            testCase.verifyEqual(consts(end).getScaleFactor(), 2.5, 'AbsTol', 1e-12, ...
                'The entered scale factor must land on the new constraint.');
        end

        function sameEventSelectionIsRejected(testCase)
            [lvdData, evt1, ~, out] = testCase.fixture();
            n0 = numel(lvdData.optimizer.constraints.consts);
            app = testCase.openDialog(lvdData, evt1, out);
            fig = app.CreateContinuityConstraintsUIFigure;

            app.Event2Combo.Value = app.Event1Combo.Value;
            testCase.pushButton(app.SaveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Identical events must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(numel(lvdData.optimizer.constraints.consts), n0, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function invalidScaleFactorIsRejected(testCase)
            [lvdData, evt1, evt2, out] = testCase.fixture();
            n0 = numel(lvdData.optimizer.constraints.consts);
            app = testCase.openDialog(lvdData, evt1, out);
            fig = app.CreateContinuityConstraintsUIFigure;

            app.Event2Combo.Value = evt2;
            app.TimeScaleFactorText.Value = 'abc';
            testCase.pushButton(app.SaveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric scale factor must not save.');
            testCase.verifyTrue(isvalid(fig));
            testCase.verifyEqual(numel(lvdData.optimizer.constraints.consts), n0);
            testCase.closeAlerts();
        end

        function windowXPreservesConstraints(testCase)
            [lvdData, evt1, evt2, out] = testCase.fixture();
            n0 = numel(lvdData.optimizer.constraints.consts);
            app = testCase.openDialog(lvdData, evt1, out);
            fig = app.CreateContinuityConstraintsUIFigure;

            app.Event2Combo.Value = evt2;
            app.TimeScaleFactorText.Value = '9';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(numel(lvdData.optimizer.constraints.consts), n0, ...
                'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [lvdData, evt1, evt2, out] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            %Distinct names are load-bearing, not cosmetic: two
            %content-identical default events are isequal, and the event
            %dropdowns resolve programmatic object assignment by value, so
            %an unnamed second event can never be selected (bug log 2.8).
            evt2.name = 'Second Event';
            lvdData.script.addEvent(evt2);

            %Synthetic entries so createContinuityConstraints can resolve
            %the reference body's frame; nothing is propagated here.
            template = lvdData.initStateModel.getInitialStateLogEntry();
            e1 = template.deepCopy(); e1.event = evt1; e1.time = 0;
            e2 = template.deepCopy(); e2.event = evt1; e2.time = 10;
            e3 = template.deepCopy(); e3.event = evt2; e3.time = 20;
            lvdData.stateLog.appendStateLogEntries([e1, e2, e3]);

            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, lvdData, selEvent, out)
            app = lvd_CreateContinuityConstraintsGUI_App(lvdData, selEvent, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ContinuityConstraintsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireValueChanged(~, ctrl)
            evt = struct('Source', ctrl, 'EventName', 'ValueChanged');
            ctrl.ValueChangedFcn(ctrl, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Create Continuity Constraints')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Create Continuity Constraints')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
