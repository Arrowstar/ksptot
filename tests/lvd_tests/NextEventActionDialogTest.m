classdef NextEventActionDialogTest < matlab.uitest.TestCase
    %NextEventActionDialogTest Full round-trip UI tests for the
    %set-next-event action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetNextEventActionGUI_App.mlapp
    %   backing class: SetNextEventAction
    %   (opens via SetNextEventAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.  This is a pure
    %   App Designer dialog (app.* properties, Items/ItemsData
    %   dropdown).  The dialog is opened directly (not via
    %   openEditActionUI); a second event is added in-test wherever
    %   reselection is exercisable (default LVD data ships one event).
    %
    % COVERED
    %   Open shows the stored next event; Save & Close writes the
    %   reselected event back; Cancel preserves the model; the event
    %   dropdown mirrors the script's events; an action with no next
    %   event yet defaults to the first event.  The dialog has no
    %   validateInputs, so no validation-rejection test applies.

    properties(Access=private)
        celBodyData
    end

    methods(TestClassSetup)
        function addPaths(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();
        end
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNextEvent(testCase)
            [action, lvdData, evt1] = testCase.fixture(); %#ok<ASGLU>
            app = testCase.openDialog(action, lvdData);

            testCase.verifyTrue(app.NextEventCombo.Value == evt1, ...
                'The stored next event must be selected.');
        end

        function nextEventComboOffersEveryEvent(testCase)
            [action, lvdData, ~] = testCase.fixture();
            testCase.addSecondEvent(lvdData);
            app = testCase.openDialog(action, lvdData);

            [~, events] = lvdData.script.getListboxStr();
            testCase.verifyEqual(numel(events), 2);
            testCase.verifyEqual(numel(app.NextEventCombo.Items), numel(events), ...
                'Every script event must be offered.');
        end

        function saveAndCloseWritesNextEvent(testCase)
            [action, lvdData, ~] = testCase.fixture();
            evt2 = testCase.addSecondEvent(lvdData);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            %Programmatic .Value assignment does not stick on this migrated
            %object dropdown (it silently keeps the old value), so drive
            %the selection with a real choose gesture like a user would.
            testCase.choose(app.NextEventCombo, 2);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.nextEvent == evt2, ...
                'The selected event must be written back.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, evt1] = testCase.fixture();
            evt2 = testCase.addSecondEvent(lvdData);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            testCase.choose(app.NextEventCombo, 2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.nextEvent == evt1, 'Cancel must leave the model alone.');
        end

        function emptyActionDefaultsToFirstEvent(testCase)
            [~, lvdData, evt1] = testCase.fixture();
            action = SetNextEventAction();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyTrue(app.NextEventCombo.Value == evt1, ...
                'With no stored event the dialog must point at the first event.');
        end
    end

    methods(Access=private)
        function [action, lvdData, evt1] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            action = SetNextEventAction(evt1);
        end

        function evt2 = addSecondEvent(~, lvdData)
            script = lvdData.script;
            evt2 = LaunchVehicleEvent.getDefaultEvent(script);
            script.addEvent(evt2);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetNextEventActionGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() NextEventActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Action')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Action')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
