classdef ThreeDKwtDragDialogTest < KsptotTestCase
    %ThreeDKwtDragDialogTest Full round-trip UI tests for the 3-D Kerbal
    %Wind Tunnel drag editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/drag/lvd_Edit3DKerbalWindTunnelDragPropertiesGUI_App.mlapp
    %   ('Edit Drag Properties'; programmatic, ctor (dragCoeffModel, lvdData, out))
    %   backing class: ThreeDimKspWindTunnelDragCoeffModel
    %   production caller: ThreeDimKspWindTunnelDragCoeffModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/drag/three_dim_kerbal_wind_tunnel/@ThreeDimKspWindTunnelDragCoeffModel/ThreeDimKspWindTunnelDragCoeffModel.m:162-166).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The dialog edits a private
    %   deep-copy (dummyModel) and only copies it back on a clean Save, so
    %   Cancel and rejected Saves preserve the model.  The model is the
    %   default mission's 3-D wind-tunnel slot (two default AoA slices).
    %
    % COVERED
    %   Open lists the stored AoA slices; Save & Close installs the slices
    %   and builds the 3-D interpolant; an out-of-range slice AoA is
    %   rejected; duplicate AoAs block Save; Add/Remove round-trips the
    %   slice list; Cancel preserves the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredSlices(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyEqual(app.EditDragPropertiesUIFigure.Name, 'Edit Drag Properties');
            testCase.verifyEqual(numel(app.SlicesListBox.Items), 2, ...
                'The default model carries two AoA slices.');
            firstSlice = app.SlicesListBox.Value;
            testCase.verifyEqual(str2double(app.AoAText.Value), rad2deg(firstSlice.aoa), 'AbsTol', 1e-9, ...
                'The AoA field must show the selected slice.');
            testCase.verifyFalse(isempty(app.WarningsAlertsTable.Data), ...
                'The warnings table must be populated at open.');
        end

        function saveAndCloseWritesSlices(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(numel(model.slices), 2, ...
                'Save must install the edited slices.');
            testCase.verifyFalse(isempty(model.gi), ...
                'Save must build the 3-D interpolant from the slices.');
        end

        function outOfRangeAoAIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            aoaBefore = app.SlicesListBox.Value.aoa;
            app.AoAText.Value = '200';
            testCase.fireEdit(app.AoAText);

            testCase.verifyEqual(app.SlicesListBox.Value.aoa, aoaBefore, 'AbsTol', 0, ...
                'A rejected AoA must leave the slice alone.');
            testCase.verifyEqual(str2double(app.AoAText.Value), rad2deg(aoaBefore), 'AbsTol', 1e-9, ...
                'The field must revert to the stored AoA.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.closeAlerts();
        end

        function duplicateAoABlocksSave(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.pushButton(app.addAoASliceButton);
            testCase.assertEqual(numel(app.SlicesListBox.Items), 3);
            newSlice = app.SlicesListBox.Value;
            app.AoAText.Value = '0';
            testCase.fireEdit(app.AoAText);
            testCase.verifyEqual(newSlice.aoa, 0, 'AbsTol', 0);

            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'Duplicate AoA slices must not save.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'The dialog must stay open until the slices are fixed.');
            testCase.verifyEqual(numel(model.slices), 2, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function addAndRemoveSliceRoundTrip(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.pushButton(app.addAoASliceButton);
            testCase.verifyEqual(numel(app.SlicesListBox.Items), 3, ...
                'Add must append an AoA slice.');

            testCase.pushButton(app.removeAoASliceButton);
            testCase.verifyEqual(numel(app.SlicesListBox.Items), 2, ...
                'Remove must drop the selected slice.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'Add/Remove must leave the editor open.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            testCase.pushButton(app.addAoASliceButton);
            testCase.assertEqual(numel(app.SlicesListBox.Items), 3);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(numel(model.slices), 2, ...
                'Cancel must drop the dummy-model edits.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.dragCoeffModel.threeDimWindTunnelDragModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_Edit3DKerbalWindTunnelDragPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ThreeDKwtDragDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireEdit(~, comp)
            comp.ValueChangedFcn(comp, []);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Drag Properties')
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
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Drag Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
