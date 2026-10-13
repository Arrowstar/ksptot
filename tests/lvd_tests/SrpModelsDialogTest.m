classdef SrpModelsDialogTest < KsptotTestCase
    %SrpModelsDialogTest Full round-trip UI tests for the solar radiation
    %pressure set editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/srp/lvd_EditSrpModels_App.mlapp
    %   ('Edit Solar Radiation Pressure Properties'; programmatic,
    %   ctor (srpModel, lvdData, out))
    %   backing class: LaunchVehicleSolarRadPressState
    %   production caller: LaunchVehicleSolarRadPressState.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/StateLog/@LaunchVehicleSolarRadPressState/LaunchVehicleSolarRadPressState.m:38-47).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   SteeringModelsSetDialogTest set-editor pattern: the combo selects
    %   the model, Save writes the selection back, Cancel preserves it).
    %   The model is the default mission's SRP state so the fixture matches
    %   production.  Validation is trivially empty, so there is no
    %   rejection test.
    %
    % COVERED
    %   Open shows the current model; the description follows the combo;
    %   Save moves the selection to the solar-sail model and back to the
    %   spherical model, keeping the set-owned handles; Cancel preserves
    %   the selection; the edit-model button exists.  (The per-model
    %   sub-editors are covered by their own dialog tests; the edit button
    %   is not pressed here.)

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsCurrentModel(testCase)
            [srp, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);

            testCase.verifyEqual(app.EditSrpPropertiesUIFigure.Name, 'Edit Solar Radiation Pressure Properties');
            testCase.verifyEqual(app.SrpModelCombo.Value, SolarRadPressModelEnum.Spherical, ...
                'The default SRP model must be selected.');
            testCase.verifyEqual(string(app.ModelDescLabel.Text), srp.srpModelObj.enum.desc, ...
                'The description must match the current model.');
        end

        function comboDescriptionFollowsSelection(testCase)
            [srp, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);

            app.SrpModelCombo.Value = SolarRadPressModelEnum.SolarSail;
            app.SrpModelCombo.ValueChangedFcn(app.SrpModelCombo, []);

            testCase.verifyEqual(string(app.ModelDescLabel.Text), SolarRadPressModelEnum.SolarSail.desc, ...
                'The description must follow the selection.');
        end

        function saveMovesSelectionToSolarSail(testCase)
            [srp, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);
            fig = app.EditSrpPropertiesUIFigure;

            app.SrpModelCombo.Value = SolarRadPressModelEnum.SolarSail;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifySameHandle(srp.srpModelObj, srp.srpSolarSailModel, ...
                'The selection must be the set-owned solar-sail handle.');
        end

        function saveMovesSelectionBackToSpherical(testCase)
            [srp, lvdData] = testCase.fixture();
            srp.srpModelObj = srp.srpSolarSailModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);
            fig = app.EditSrpPropertiesUIFigure;

            testCase.verifyEqual(app.SrpModelCombo.Value, SolarRadPressModelEnum.SolarSail, ...
                'The combo must reflect the current selection.');
            app.SrpModelCombo.Value = SolarRadPressModelEnum.Spherical;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifySameHandle(srp.srpModelObj, srp.srpSphericalModel, ...
                'The selection must be the set-owned spherical handle.');
        end

        function cancelPreservesSelection(testCase)
            [srp, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);
            fig = app.EditSrpPropertiesUIFigure;

            app.SrpModelCombo.Value = SolarRadPressModelEnum.SolarSail;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifySameHandle(srp.srpModelObj, srp.srpSphericalModel, ...
                'Cancel must leave the selection alone.');
        end

        function editButtonExists(testCase)
            [srp, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(srp, lvdData, out);

            testCase.verifyTrue(isvalid(app.EditSrpModelButton), ...
                'The edit-model button must exist.');
        end
    end

    methods(Access=private)
        function [srp, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            srp = lvdData.initStateModel.srp;
        end

        function app = openDialog(testCase, srp, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSrpModels_App(srp, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SrpModelsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
