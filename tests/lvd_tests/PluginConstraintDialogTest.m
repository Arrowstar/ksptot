classdef PluginConstraintDialogTest < KsptotTestCase
    %PluginConstraintDialogTest Full round-trip UI tests for the plugin
    %constraint editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/lvd_EditPluginConstraintGUI_App.mlapp
    %   backing class: PluginConstraint
    %   (opens via PluginConstraint.openEditConstraintUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditConstraintUI) so no errordlg guard can
    %   fire; the fixture always creates a plugin because DefaultLvdData
    %   ships none.
    %
    % COVERED
    %   Open shows stored lb/ub/scale/plugin/active; Save & Close writes
    %   every field back including the plugin selection; blank bounds and
    %   a non-positive scale factor are rejected and leave the model
    %   alone; a self-referencing state comparison is rejected; Cancel
    %   preserves the model; the plugin dropdown mirrors the set.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [con, lvdData] = testCase.fixture();
            con.lb = 5;
            con.ub = 50;
            con.setScaleFactor(2);

            app = testCase.openDialog(con, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.lbText, 'String')), 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.ubText, 'String')), 50, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.scaleFactorText, 'String')), 2, 'AbsTol', 1e-12);
            testCase.verifyEqual(handles.pluginCombo.Value, 1);
            testCase.verifyEqual(logical(handles.constActiveCheckbox.Value), con.active);
        end

        function pluginComboOffersEveryPlugin(testCase)
            [con, lvdData] = testCase.fixture();
            app = testCase.openDialog(con, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.pluginCombo.String)), ...
                lvdData.plugins.getNumPlugins(), ...
                'Every plugin must be offered.');
            testCase.verifyGreaterThanOrEqual(lvdData.plugins.getNumPlugins(), 1);
        end

        function saveAndCloseWritesEveryField(testCase)
            [con, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditPluginConstraintGUI;

            set(handles.lbText, 'String', '7.5');
            set(handles.ubText, 'String', '42');
            set(handles.scaleFactorText, 'String', '3');
            set(handles.constActiveCheckbox, 'Value', 0);

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(con.lb, 7.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(con.ub, 42, 'AbsTol', 1e-12);
            testCase.verifyEqual(con.getScaleFactor(), 3, 'AbsTol', 1e-12);
            testCase.verifyFalse(con.active);
        end

        function saveAndCloseWritesPluginSelection(testCase)
            [con, lvdData] = testCase.fixture();
            second = LvdPlugin();
            second.pluginName = 'Second Plugin';
            second.pluginCode = "value = 2;";
            lvdData.plugins.addPlugin(second);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.pluginCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyEqual(lvdData.plugins.getIndsForPlugins(con.plugin), 2, ...
                'The selected plugin must be written back.');
        end

        function blankBoundsAreRejected(testCase)
            [con, lvdData] = testCase.fixture();
            con.lb = 5;
            con.ub = 50;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.lbText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank lower bound must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditPluginConstraintGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(con.lb, 5, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function nonPositiveScaleFactorIsRejected(testCase)
            [con, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.scaleFactorText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero scale factor must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditPluginConstraintGUI));
            testCase.verifyEqual(con.getScaleFactor(), 1, 'AbsTol', 1e-12, ...
                'Rejected input must leave the scale factor alone.');
            testCase.closeAlerts();
        end

        function selfStateComparisonIsRejected(testCase)
            [con, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, enums] = ConstraintEvalTypeEnum.getListBoxStr();
            scInd = find(enums == ConstraintEvalTypeEnum.StateComparison, 1);
            testCase.assertNotEmpty(scInd);
            handles.constraintEvalTypeCombo.Value = scInd;
            % Force the illegal self-comparison: same event and same node.
            handles.compEventCombo.Value = handles.eventCombo.Value;
            handles.stateComparisonNodeCombo.Value = handles.eventNodeCombo.Value;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, ...
                'A state comparison against the same event/node must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditPluginConstraintGUI));
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [con, lvdData] = testCase.fixture();
            con.lb = 5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(con, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditPluginConstraintGUI;

            set(handles.lbText, 'String', '99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(con.lb, 5, 'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [con, lvdData, out] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            plugin = LvdPlugin();
            plugin.pluginName = 'Test Plugin';
            plugin.pluginCode = "value = 1;";
            lvdData.plugins.addPlugin(plugin);
            con = PluginConstraint.getDefaultConstraint([], []);
            con.event = lvdData.script.getEventForInd(1);
            con.plugin = lvdData.plugins.getPluginAtInd(1);
            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, con, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditPluginConstraintGUI_App(con, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PluginConstraintDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Constraint')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Constraint')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
