classdef ConstDragDialogTest < KsptotTestCase
    %ConstDragDialogTest Full round-trip UI tests for the constant-drag
    %editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/drag/lvd_EditConstDragPropertiesGUI_App.mlapp
    %   ('Edit Drag Properties'; programmatic, ctor (dragCoeffModel, lvdData, out))
    %   backing class: ConstantDragCoeffModel
    %   production caller: ConstantDragCoeffModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/drag/constant/@ConstantDragCoeffModel/ConstantDragCoeffModel.m:46-50).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest throttle-set pattern).  The model is the
    %   default mission's constant-drag slot so the fixture matches
    %   production.
    %
    % COVERED
    %   Open shows the stored CdA; Save & Close writes it back; a blank or
    %   negative CdA is rejected and leaves the model alone; Cancel and
    %   window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredCdA(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdA = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyEqual(app.EditDragPropertiesUIFigure.Name, 'Edit Drag Properties');
            testCase.verifyEqual(str2double(app.DragCoeffText.Value), 2.5, 'AbsTol', 1e-12, ...
                'The stored CdA must be shown.');
        end

        function saveAndCloseWritesCdA(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.DragCoeffText.Value = '4.25';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.CdA, 4.25, 'AbsTol', 1e-12);
        end

        function blankCdAIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdA = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.DragCoeffText.Value = '';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank CdA must not save.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.CdA, 2.5, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeCdAIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdA = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.DragCoeffText.Value = '-3';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative CdA must not save.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure));
            testCase.verifyEqual(model.CdA, 2.5, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdA = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.DragCoeffText.Value = '99';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.CdA, 2.5, 'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.CdA = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.DragCoeffText.Value = '99';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(model.CdA, 2.5, 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.dragCoeffModel.constDragModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditConstDragPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ConstDragDialogTest.deleteIfValid(app));
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
