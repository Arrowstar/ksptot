classdef OneDDragDialogTest < KsptotTestCase
    %OneDDragDialogTest Full round-trip UI tests for the 1-D drag
    %coefficient editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/drag/lvd_Edit1DDragPropertiesGUI_App.mlapp
    %   ('Edit Drag Properties'; GUIDE-migrated, ctor (dragCoeffModel, lvdData, out))
    %   backing class: OneDimDragCoefficientModel
    %   production caller: OneDimDragCoefficientModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/drag/one_dim/@OneDimDragCoefficientModel/OneDimDragCoefficientModel.m:84-88).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The model is the default
    %   mission's 1-D drag slot so the fixture matches production.
    %
    % COVERED
    %   Open shows the stored area, independent variable, interp method and
    %   curve points; Save & Close writes the area, both enums and rebuilds
    %   the interpolant; a blank area is rejected and leaves the model
    %   alone; removing the selected curve point drops it from the model;
    %   Cancel and window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredAreaAndCombos(testCase)
            [model, lvdData] = testCase.fixture();
            model.area = 2.5;
            model.CdIndepVar = AeroIndepVar.MachNum;
            model.CdInterpMethod = GriddedInterpolantMethodEnum.PChip;

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.lvd_EditDragPropertiesGUI.Name, 'Edit Drag Properties');
            testCase.verifyEqual(str2double(get(handles.dragAreaText, 'String')), 2.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(handles.indepVarCombo.Value, AeroIndepVar.getIndForName(AeroIndepVar.MachNum.name), ...
                'The independent-variable combo must reflect the model.');
            testCase.verifyEqual(handles.interpMethodCombo.Value, GriddedInterpolantMethodEnum.getIndForName(GriddedInterpolantMethodEnum.PChip.name), ...
                'The interp-method combo must reflect the model.');
            testCase.verifyEqual(numel(cellstr(get(handles.ptsListbox, 'String'))), 2, ...
                'The default model carries two curve points.');
        end

        function saveAndCloseWritesAreaAndEnums(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditDragPropertiesGUI;

            set(handles.dragAreaText, 'String', '3.25');
            handles.indepVarCombo.Value = AeroIndepVar.getIndForName(AeroIndepVar.MachNum.name);
            handles.interpMethodCombo.Value = GriddedInterpolantMethodEnum.getIndForName(GriddedInterpolantMethodEnum.Nearest.name);
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.area, 3.25, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.CdIndepVar, AeroIndepVar.MachNum);
            testCase.verifyEqual(model.CdInterpMethod, GriddedInterpolantMethodEnum.Nearest);
            testCase.verifyEqual(model.CdInterp(0.5), 0.3, 'AbsTol', 1e-12, ...
                'Save must rebuild the interpolant from the curve points.');
        end

        function blankAreaIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.area = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.dragAreaText, 'String', '');
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank area must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditDragPropertiesGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.area, 2.5, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function removePointDropsSelectedPoint(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdInterpPts.addPoint(GriddedInterpolantPoint(2, 0.5));
            testCase.assertEqual(model.CdInterpPts.getNumPoints(), 3);

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.removePointFromCurveButton, 'Enable'), 'on', ...
                'Remove must enable once three points exist.');
            %Remove the MIDDLE point: removing the last index crashes the
            %listbox refresh (bug log 1.31), while a middle removal keeps
            %the selection valid and exercises the full path.
            handles.ptsListbox.Value = 2;
            testCase.pushButton(app.removePointFromCurveButton);

            testCase.verifyEqual(model.CdInterpPts.getNumPoints(), 2, ...
                'Remove must drop the selected point from the model.');
            testCase.verifyEqual(numel(cellstr(get(handles.ptsListbox, 'String'))), 2, ...
                'The listbox must mirror the model.');
            testCase.verifyEqual(get(handles.removePointFromCurveButton, 'Enable'), 'off', ...
                'Remove must disable again at two points.');
            testCase.verifyTrue(isvalid(handles.lvd_EditDragPropertiesGUI), ...
                'Removing must leave the editor open.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.area = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditDragPropertiesGUI;

            set(handles.dragAreaText, 'String', '99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.area, 2.5, 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.area = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditDragPropertiesGUI;

            set(handles.dragAreaText, 'String', '99');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(model.area, 2.5, 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.dragCoeffModel.oneDDragModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_Edit1DDragPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() OneDDragDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
