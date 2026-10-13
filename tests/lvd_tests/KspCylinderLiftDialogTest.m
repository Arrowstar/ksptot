classdef KspCylinderLiftDialogTest < KsptotTestCase
    %KspCylinderLiftDialogTest Full round-trip UI tests for the KSP
    %cylinder lift editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/lift/lvd_EditKSPCylinderLiftPropertiesGUI_App.mlapp
    %   ('Edit Lift Properties'; programmatic, ctor (liftCoeffModel, lvdData, out))
    %   backing class: CylindricalLiftModel
    %   production caller: CylindricalLiftModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/lift/@CylindricalLiftModel/CylindricalLiftModel.m:75-79).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The model is the default
    %   mission's cylinder-lift slot so the fixture matches production.
    %
    % COVERED
    %   Open shows the stored height and radius; Save & Close writes both
    %   back; a blank or negative height is rejected and leaves the model
    %   alone; Cancel and window-X preserve the model.
    %
    % NOTE
    %   The radius check re-reads the height field instead of the radius
    %   field (see bug list); the rejection tests below pin the height
    %   path, which is validated correctly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredDimensions(testCase)
            [model, lvdData] = testCase.fixture();
            model.cylinderLength = 2;
            model.cylinderRadius = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyEqual(app.EditLiftPropertiesUIFigure.Name, 'Edit Lift Properties');
            testCase.verifyEqual(str2double(app.CylinderHeightText.Value), 2, 'AbsTol', 1e-12, ...
                'The stored cylinder height must be shown.');
            testCase.verifyEqual(str2double(app.CylinderRadiusText.Value), 0.5, 'AbsTol', 1e-12, ...
                'The stored cylinder radius must be shown.');
        end

        function saveAndCloseWritesDimensions(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditLiftPropertiesUIFigure;

            app.CylinderHeightText.Value = '3';
            app.CylinderRadiusText.Value = '0.75';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.cylinderLength, 3, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.cylinderRadius, 0.75, 'AbsTol', 1e-12);
        end

        function blankHeightIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.cylinderLength = 2;
            model.cylinderRadius = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.CylinderHeightText.Value = '';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank height must not save.');
            testCase.verifyTrue(isvalid(app.EditLiftPropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.cylinderLength, 2, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeHeightIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.cylinderLength = 2;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.CylinderHeightText.Value = '-1';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative height must not save.');
            testCase.verifyTrue(isvalid(app.EditLiftPropertiesUIFigure));
            testCase.verifyEqual(model.cylinderLength, 2, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.cylinderLength = 2;
            model.cylinderRadius = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditLiftPropertiesUIFigure;

            app.CylinderHeightText.Value = '99';
            app.CylinderRadiusText.Value = '99';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.cylinderLength, 2, 'Cancel must leave the model alone.');
            testCase.verifyEqual(model.cylinderRadius, 0.5, 'AbsTol', 1e-12);
        end

        function windowXPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.cylinderLength = 2;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditLiftPropertiesUIFigure;

            app.CylinderHeightText.Value = '99';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(model.cylinderLength, 2, 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.liftCoeffModel.cylinderModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditKSPCylinderLiftPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() KspCylinderLiftDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Lift Properties')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Lift Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
