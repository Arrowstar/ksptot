classdef SolarSailSrpDialogTest < KsptotTestCase
    %SolarSailSrpDialogTest Full round-trip UI tests for the solar-sail
    %solar radiation pressure editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/srp/lvd_EditSolarSailSolarRadPressModel_App.mlapp
    %   ('Edit Solar Radiation Pressure Properties'; programmatic,
    %   ctor (srpModel, output) -- note: no lvdData argument)
    %   backing class: SolarSailSolarRadiationPressureModel
    %   production caller: SolarSailSolarRadiationPressureModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/solar_radiation_pressure/@SolarSailSolarRadiationPressureModel/SolarSailSolarRadiationPressureModel.m:99-107).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The model is the default
    %   mission's solar-sail SRP slot so the fixture matches production.
    %
    % COVERED
    %   Open shows every stored field; Save & Close writes every field
    %   back; the sail normal is normalized on save; a coefficient set
    %   that does not sum to 1 and a blank area are rejected and leave the
    %   model alone; Cancel and window-X preserve the model.
    %
    % NOTE
    %   Validation allows a zero area but the model requires area > 0 (see
    %   bug list); the blank-area test below pins the empty-string path,
    %   which is validated correctly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            testCase.verifyEqual(app.EditSolarRadiationPressurePropertiesUIFigure.Name, ...
                'Edit Solar Radiation Pressure Properties');
            testCase.verifyEqual(str2double(app.RefSolarFluxEdit.Value), 1367, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(app.SolarFluxReFDistEdit.Value), 13599840.256, 'AbsTol', 1e-6);
            testCase.verifyEqual(str2double(app.CoeffAbsorbEdit.Value), 0.10, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(app.CoeffSpecularReflectEdit.Value), 0.85, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(app.CoeffDiffuseReflectEdit.Value), 0.05, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(app.AreaEdit.Value), 1, 'AbsTol', 1e-12);
            testCase.verifyEqual([str2double(app.XNormCompEdit.Value); str2double(app.YNormCompEdit.Value); str2double(app.ZNormCompEdit.Value)], ...
                [1; 0; 0], 'AbsTol', 1e-12, 'The stored sail normal must be shown.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            fig = app.EditSolarRadiationPressurePropertiesUIFigure;

            app.RefSolarFluxEdit.Value = '1400';
            app.SolarFluxReFDistEdit.Value = '14000000';
            app.CoeffAbsorbEdit.Value = '0.2';
            app.CoeffSpecularReflectEdit.Value = '0.7';
            app.CoeffDiffuseReflectEdit.Value = '0.1';
            app.AreaEdit.Value = '3';
            app.XNormCompEdit.Value = '0';
            app.YNormCompEdit.Value = '1';
            app.ZNormCompEdit.Value = '0';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.refSolarFlux, 1400, 'AbsTol', 1e-9);
            testCase.verifyEqual(model.solarFluxRefDist, 14000000, 'AbsTol', 1e-6);
            testCase.verifyEqual(model.cRa, 0.2, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.cRs, 0.7, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.cRd, 0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.area, 3, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.areaBodyFrameNormVector, [0; 1; 0], 'AbsTol', 1e-12);
        end

        function saveNormalizesNormalVector(testCase)
            %Each component validates to [-1, 1], so the unnormalized
            %input must itself be valid; save then normalizes it.
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            app.XNormCompEdit.Value = '0.5';
            app.YNormCompEdit.Value = '0.5';
            app.ZNormCompEdit.Value = '0';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(model.areaBodyFrameNormVector, [0.5; 0.5; 0]/norm([0.5; 0.5; 0]), 'AbsTol', 1e-12, ...
                'Save must normalize the sail normal vector.');
        end

        function coefficientSumIsRejected(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            app.CoeffAbsorbEdit.Value = '0.5';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'Coefficients that do not sum to 1 must not save.');
            testCase.verifyTrue(isvalid(app.EditSolarRadiationPressurePropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.cRa, 0.10, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankAreaIsRejected(testCase)
            [model, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);

            app.AreaEdit.Value = '';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank area must not save.');
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
            app.CoeffAbsorbEdit.Value = '0.2';
            app.CoeffSpecularReflectEdit.Value = '0.7';
            app.CoeffDiffuseReflectEdit.Value = '0.1';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.refSolarFlux, 1367, 'Cancel must leave the model alone.');
            testCase.verifyEqual(model.cRa, 0.10, 'AbsTol', 1e-12);
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
            model = lvdData.initStateModel.srp.srpSolarSailModel;
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSolarSailSolarRadPressModel_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SolarSailSrpDialogTest.deleteIfValid(app));
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
