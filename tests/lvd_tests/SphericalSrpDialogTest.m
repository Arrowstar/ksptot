classdef SphericalSrpDialogTest < KsptotTestCase
    %SphericalSrpDialogTest Full round-trip UI tests for the spherical
    %solar radiation pressure editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/srp/lvd_EditSphericalSolarRadPressModel_App.mlapp
    %   ('Edit Solar Radiation Pressure Properties'; programmatic,
    %   ctor (srpModel, output) -- note: no lvdData argument)
    %   backing class: SphericalSolarRadiationPressureModel
    %   production caller: SphericalSolarRadiationPressureModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/solar_radiation_pressure/@SphericalSolarRadiationPressureModel/SphericalSolarRadiationPressureModel.m:77-85).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The model is the default
    %   mission's spherical SRP slot so the fixture matches production.
    %
    % COVERED
    %   Open shows every stored field; Save & Close writes every field
    %   back; a blank flux or a negative area is rejected and leaves the
    %   model alone; Cancel and window-X preserve the model.
    %
    % NOTE
    %   Validation caps nothing above, but the model caps cR at 2 (see bug
    %   list); the rejection tests below pin the lower-bound paths, which
    %   are validated correctly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [model, ~] = testCase.fixture();
            model.refSolarFlux = 1400;
            model.solarFluxRefDist = 14000000;
            model.cR = 1.5;
            model.area = 2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            testCase.verifyEqual(app.EditSolarRadiationPressurePropertiesUIFigure.Name, ...
                'Edit Solar Radiation Pressure Properties');
            testCase.verifyEqual(str2double(app.RefSolarFluxEdit.Value), 1400, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(app.SolarFluxReFDistEdit.Value), 14000000, 'AbsTol', 1e-6);
            testCase.verifyEqual(str2double(app.CoeffReflectEdit.Value), 1.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(app.AreaEdit.Value), 2.5, 'AbsTol', 1e-12);
        end

        function saveAndCloseWritesEveryField(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            fig = app.EditSolarRadiationPressurePropertiesUIFigure;

            app.RefSolarFluxEdit.Value = '1400';
            app.SolarFluxReFDistEdit.Value = '14000000';
            app.CoeffReflectEdit.Value = '1.5';
            app.AreaEdit.Value = '2.5';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.refSolarFlux, 1400, 'AbsTol', 1e-9);
            testCase.verifyEqual(model.solarFluxRefDist, 14000000, 'AbsTol', 1e-6);
            testCase.verifyEqual(model.cR, 1.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.area, 2.5, 'AbsTol', 1e-12);
        end

        function blankFluxIsRejected(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            app.RefSolarFluxEdit.Value = '';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank flux must not save.');
            testCase.verifyTrue(isvalid(app.EditSolarRadiationPressurePropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.refSolarFlux, 1367, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeAreaIsRejected(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            app.AreaEdit.Value = '-2';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative area must not save.');
            testCase.verifyTrue(isvalid(app.EditSolarRadiationPressurePropertiesUIFigure));
            testCase.verifyEqual(model.area, 1, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            fig = app.EditSolarRadiationPressurePropertiesUIFigure;

            app.RefSolarFluxEdit.Value = '9999';
            app.AreaEdit.Value = '99';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.refSolarFlux, 1367, 'Cancel must leave the model alone.');
            testCase.verifyEqual(model.area, 1, 'AbsTol', 1e-12);
        end

        function windowXPreservesModel(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            fig = app.EditSolarRadiationPressurePropertiesUIFigure;

            app.RefSolarFluxEdit.Value = '9999';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(model.refSolarFlux, 1367, 'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.srp.srpSphericalModel;
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSphericalSolarRadPressModel_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SphericalSrpDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Solar Radiation Pressure Properties')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Solar Radiation Pressure Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
