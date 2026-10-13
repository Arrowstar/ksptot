classdef PluginVariablesDialogTest < KsptotTestCase
    %PluginVariablesDialogTest Full round-trip UI tests for the plugin
    %variable editor (Phase 5: root/misc UIs; upgrades the main-GUI smoke
    %press to a value-level suite).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/plugins/lvd_EditPluginVariables_App.mlapp
    %   ctor: lvd_EditPluginVariables_App(lvdData)
    %   main-GUI caller: PluginVariablesMenuSelected (Plugins menu).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn and edit fields through their ValueChangedFcn with
    %   minimal event structs.  This is a pure App Designer dialog.
    %
    % COVERED
    %   Open lists the stored variables with values, bounds and the active
    %   flag; Add appends a variable plus its paired optimizer variable;
    %   rename, value, bound and Opt edits write live to the wrapper;
    %   invalid values are rejected and restored; Remove drops the wrapper
    %   and its optimizer variable; Close (the dialog has no Cancel; edits
    %   are live by design) keeps every edit.  Add/Remove manage the paired
    %   PluginOptimizationVariable programmatically, so no nested editor
    %   opens and nothing needs stubbing; no native dialogs are involved.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredVariables(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(numel(app.pluginVarListbox.Items), 1, ...
                'The stored variable must be listed.');
            testCase.verifyTrue(contains(app.pluginVarListbox.Items{1}, 'Seed Var'));
            testCase.verifyEqual(app.VariableNameText.Value, 'Seed Var');
            testCase.verifyEqual(str2double(app.valueText.Value), 0.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(app.optCheckbox.Value, 'The active flag must be shown.');
            testCase.verifyTrue(var1.isVariableActive());
        end

        function addVariableAppendsPairedOptimVar(testCase)
            [lvdData, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.pushButton(app.AddVariableButton);

            testCase.verifyEqual(lvdData.pluginVars.getNumPluginVars(), 2, ...
                'Add must append a plugin variable.');
            testCase.verifyEqual(numel(app.pluginVarListbox.Items), 2, ...
                'The listbox must refresh.');
            testCase.verifyEqual(char(app.RemoveVariableButton.Enable), 'on');
            testCase.verifyEqual(char(app.VariableNameText.Enable), 'on');
            newVar = lvdData.pluginVars.getPluginVarAtInd(2);
            testCase.verifyFalse(isempty(newVar.getExistingOptVar()), ...
                'Add must pair the wrapper with an optimizer variable.');
        end

        function renameVariableWritesLive(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            testCase.selectVar(app, var1);

            app.VariableNameText.Value = 'Renamed Var';
            app.VariableNameText.ValueChangingFcn(app.VariableNameText, ...
                struct('Source', app.VariableNameText, 'EventName', 'ValueChanging', ...
                       'Value', 'Renamed Var', 'PreviousValue', 'Seed Var'));

            testCase.verifyEqual(var1.name, 'Renamed Var', 'Renaming must write live.');
            testCase.verifyTrue(contains(app.pluginVarListbox.Items{1}, 'Renamed Var'), ...
                'The listbox must refresh.');
        end

        function editValueAndBoundsWriteLive(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            testCase.selectVar(app, var1);

            app.lbText.Value = '-10';
            testCase.fireValueChanged(app.lbText);
            app.ubText.Value = '10';
            testCase.fireValueChanged(app.ubText);
            [lb, ub] = var1.getBounds();
            testCase.verifyEqual([lb, ub], [-10, 10], 'Bounds edits must write live.');

            app.valueText.Value = '7.5';
            testCase.fireValueChanged(app.valueText);
            testCase.verifyEqual(var1.value, 7.5, 'AbsTol', 1e-12, 'Value edits must write live.');
        end

        function invalidValueIsRejectedAndRestored(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            testCase.selectVar(app, var1);

            app.valueText.Value = 'abc';
            testCase.fireValueChanged(app.valueText);

            testCase.verifyEqual(var1.value, 0.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the value alone.');
            testCase.verifyEqual(str2double(app.valueText.Value), 0.5, 'AbsTol', 1e-12, ...
                'Rejected input must restore the field.');
            testCase.verifyTrue(isvalid(app.EditPluginVariablesUIFigure));
            testCase.closeAlerts();
        end

        function removeVariableDropsPairedOptimVar(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            testCase.selectVar(app, var1);

            testCase.pushButton(app.RemoveVariableButton);

            testCase.verifyEqual(lvdData.pluginVars.getNumPluginVars(), 0, ...
                'Remove must drop the wrapper.');
            testCase.verifyEmpty(app.pluginVarListbox.Items, 'The listbox must refresh.');
            testCase.verifyEqual(char(app.VariableNameText.Enable), 'off', ...
                'With no variables the fields must disable.');
            testCase.verifyEqual(char(app.RemoveVariableButton.Enable), 'off');
        end

        function closeKeepsLiveEdits(testCase)
            [lvdData, var1] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            testCase.selectVar(app, var1);
            fig = app.EditPluginVariablesUIFigure;

            app.VariableNameText.Value = 'Kept Name';
            app.VariableNameText.ValueChangingFcn(app.VariableNameText, ...
                struct('Source', app.VariableNameText, 'EventName', 'ValueChanging', ...
                       'Value', 'Kept Name', 'PreviousValue', 'Seed Var'));
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(var1.name, 'Kept Name', ...
                'Close must keep the live edits (there is no Cancel by design).');
        end
    end

    methods(Access=private)
        function [lvdData, var1] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            var1 = LvdPluginOptimVarWrapper();
            var1.name = 'Seed Var';
            var1.value = 0.5;
            optVar = var1.getNewOptVar();
            var1.setIfVariableIsActive(true);
            lvdData.pluginVars.addPluginVar(var1);
            lvdData.optimizer.vars.addVariable(optVar);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditPluginVariables_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.EditPluginVariablesUIFigure), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PluginVariablesDialogTest.deleteIfValid(app));
        end

        function selectVar(testCase, app, wrap) %#ok<INUSL>
            app.pluginVarListbox.Value = wrap;
            evt = struct('Source', app.pluginVarListbox, 'EventName', 'ValueChanged');
            app.pluginVarListbox.ValueChangedFcn(app.pluginVarListbox, evt);
            drawnow;
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
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Plugin Variables')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Plugin Variables')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
