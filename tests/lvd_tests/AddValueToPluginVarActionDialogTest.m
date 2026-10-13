classdef AddValueToPluginVarActionDialogTest < KsptotTestCase
    %AddValueToPluginVarActionDialogTest Full round-trip UI tests for the
    %add-value-to-plugin-variable action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionAddValueToLvdPluginVarValueGUI_App.mlapp
    %   backing class: AddValueToLvdPluginVarValueAction
    %   (opens via AddValueToLvdPluginVarValueAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.  This is a pure
    %   App Designer dialog (app.* properties, Items/ItemsData
    %   dropdowns); its figure closes on Save and is deleted with the
    %   app.  The dialog is opened directly (not via openEditActionUI);
    %   the fixture seeds two plugin variables (default LVD data ships
    %   none) and attaches the action to event 1, because populateGUI
    %   reads action.event.lvdData.
    %
    % COVERED
    %   Open shows the stored plugin variable and offset; Save & Close
    %   writes both back; a non-numeric offset is rejected and leaves
    %   the model alone; Cancel preserves the model; the plugin-variable
    %   dropdown mirrors the plugin-variable set.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action);

            [~, vars] = lvdData.pluginVars.getListboxStr();
            testCase.verifyEqual(str2double(app.offsetValueText.Value), 2.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(app.PluginVarsCombo.Value == vars(1), ...
                'The stored plugin variable must be selected.');
        end

        function pluginVarsComboOffersEveryPluginVar(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action);

            [~, vars] = lvdData.pluginVars.getListboxStr();
            testCase.verifyEqual(numel(vars), 2);
            testCase.verifyEqual(numel(app.PluginVarsCombo.Items), numel(vars), ...
                'Every plugin variable must be offered.');
        end

        function saveAndCloseWritesValueAndSelection(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, out);
            fig = app.lvd_EditActionSetPluginVarValueGUI;

            [~, vars] = lvdData.pluginVars.getListboxStr();
            app.offsetValueText.Value = '4.5';
            app.PluginVarsCombo.Value = vars(2);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(action.pluginValueOffset, 4.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(action.pluginVar == vars(2), ...
                'The selected plugin variable must be written back.');
        end

        function nonNumericOffsetIsRejected(testCase)
            [action, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, out);
            fig = app.lvd_EditActionSetPluginVarValueGUI;

            app.offsetValueText.Value = 'abc';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric offset must not save.');
            testCase.verifyTrue(isvalid(fig), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.pluginValueOffset, 2.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, out);
            fig = app.lvd_EditActionSetPluginVarValueGUI;

            [~, vars] = lvdData.pluginVars.getListboxStr();
            app.offsetValueText.Value = '99';
            app.PluginVarsCombo.Value = vars(2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(action.pluginValueOffset, 2.5, 'Cancel must leave the model alone.');
            testCase.verifyTrue(action.pluginVar == vars(1), 'Cancel must leave the selection alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            var1 = LvdPluginOptimVarWrapper();
            var1.name = 'Test Plugin Var';
            var1.value = 5;
            var1.getNewOptVar();
            lvdData.pluginVars.addPluginVar(var1);

            var2 = LvdPluginOptimVarWrapper();
            var2.name = 'Second Plugin Var';
            var2.value = -1;
            var2.getNewOptVar();
            lvdData.pluginVars.addPluginVar(var2);

            action = AddValueToLvdPluginVarValueAction(var1, 2.5);
            action.event = lvdData.script.getEventForInd(1);
        end

        function app = openDialog(testCase, action, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionAddValueToLvdPluginVarValueGUI_App(action, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() AddValueToPluginVarActionDialogTest.deleteIfValid(app));
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
