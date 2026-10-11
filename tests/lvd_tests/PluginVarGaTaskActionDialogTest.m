classdef PluginVarGaTaskActionDialogTest < KsptotTestCase
    %PluginVarGaTaskActionDialogTest Full round-trip UI tests for the
    %set-plugin-variable-to-graphical-analysis-task action editor
    %(Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetPluginVarGaTaskValueGUI_App.mlapp
    %   backing class: SetLvdPluginVarGaTaskValueAction
    %   (opens via SetLvdPluginVarGaTaskValueAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.  This is a pure
    %   App Designer dialog (app.* properties, Items/ItemsData
    %   dropdowns plus a reference-frame selector component).  The dialog
    %   is opened directly (not via openEditActionUI); the fixture seeds
    %   two plugin variables (default LVD data ships none) and builds the
    %   action with the production defaults from openEditActionUI (first
    %   task in lvd_getGraphAnalysisTaskList, default body-centered
    %   inertial frame), so the task dropdown and frame selector
    %   populate exactly as in production.  No propagation is run: Save
    %   only rebuilds the GraphicalAnalysisTask object, it never
    %   executes it.
    %
    % COVERED
    %   Open shows the stored plugin variable, task string and frame;
    %   Save & Close writes the reselected plugin variable and task back
    %   and rebuilds the task object; Cancel preserves the model; the
    %   task dropdown mirrors lvd_getGraphAnalysisTaskList and the
    %   plugin-variable dropdown mirrors the plugin-variable set.  The
    %   dialog's validateInputs unconditionally returns empty, so no
    %   validation-rejection test applies by design.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData, frame, taskStr] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            [~, vars] = lvdData.pluginVars.getListboxStr();
            testCase.verifyTrue(app.PluginVarsCombo.Value == vars(1), ...
                'The stored plugin variable must be selected.');
            testCase.verifyEqual(app.TaskListDropdown.Value, taskStr, ...
                'The stored task string must be selected.');
            testCase.verifyTrue(app.referenceFrameSelectComp.getSelectedFrame() == frame, ...
                'The stored frame must be selected.');
        end

        function taskDropdownMirrorsTaskList(testCase)
            [action, lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            taskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
            testCase.verifyEqual(numel(app.TaskListDropdown.Items), numel(taskList), ...
                'Every graphical-analysis task must be offered.');
        end

        function pluginVarsComboOffersEveryPluginVar(testCase)
            [action, lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            [~, vars] = lvdData.pluginVars.getListboxStr();
            testCase.verifyEqual(numel(vars), 2);
            testCase.verifyEqual(numel(app.PluginVarsCombo.Items), numel(vars), ...
                'Every plugin variable must be offered.');
        end

        function saveAndCloseWritesTaskAndPluginVar(testCase)
            [action, lvdData, ~, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.lvd_EditActionSetPluginVarValueGUI;

            taskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
            [~, vars] = lvdData.pluginVars.getListboxStr();
            app.TaskListDropdown.Value = taskList{end};
            app.PluginVarsCombo.Value = vars(2);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(action.taskStr, taskList{end}, ...
                'The selected task string must be written back.');
            testCase.verifyTrue(action.pluginVar == vars(2), ...
                'The selected plugin variable must be written back.');
            testCase.verifyTrue(isa(action.task, 'GraphicalAnalysisTask'), ...
                'Save must rebuild the task object from the dialog selections.');
            testCase.verifyEqual(action.task.taskStr, taskList{end});
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, ~, taskStr] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.lvd_EditActionSetPluginVarValueGUI;

            taskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
            [~, vars] = lvdData.pluginVars.getListboxStr();
            app.TaskListDropdown.Value = taskList{end};
            app.PluginVarsCombo.Value = vars(2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(action.taskStr, taskStr, 'Cancel must leave the task alone.');
            testCase.verifyTrue(action.pluginVar == vars(1), 'Cancel must leave the selection alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData, frame, taskStr] = fixture(testCase)
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

            taskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
            taskStr = taskList{1};
            frame = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();

            action = SetLvdPluginVarGaTaskValueAction(var1, taskStr, frame);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetPluginVarGaTaskValueGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PluginVarGaTaskActionDialogTest.deleteIfValid(app));
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
