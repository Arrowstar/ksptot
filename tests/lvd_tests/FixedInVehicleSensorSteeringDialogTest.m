classdef FixedInVehicleSensorSteeringDialogTest < KsptotTestCase
    %FixedInVehicleSensorSteeringDialogTest Full round-trip UI tests for the
    %fixed-in-vehicle-frame sensor steering editor (Phase 4: sensors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/sensors/sensor_models/steering_models/lvd_EditFixedInVehicleBodyFrameSensorSteeringModelGUI_App.mlapp
    %   ('Edit Sensor Pointing Model'; modern App Designer, uiwait).
    %   backing class: FixedInVehicleFrameSensorSteeringModel
    %   production caller: FixedInVehicleFrameSensorSteeringModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/Sensors/SensorModels/SensorSteeringModels/@FixedInVehicleFrameSensorSteeringModel/FixedInVehicleFrameSensorSteeringModel.m:53-57):
    %   lvd_EditFixedInVehicleBodyFrameSensorSteeringModelGUI_App(obj, obj.lvdData, output).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   SensorSteeringModelActionDialogTest pattern). This modern dialog
    %   exposes its controls as app properties, so tests drive
    %   app.RightAscText / app.DeclinationText / app.RollText directly and
    %   fire app.saveAndCloseButton.
    %
    % COVERED
    %   Open shows stored RA/dec/roll (deg); Save & Close writes every field
    %   back; a blank angle and an out-of-range right ascension are rejected
    %   and leave the model alone; Cancel and window-X preserve the model.
    %
    % NOTES
    %   Unlike its coord-sys sibling this dialog has no frame control, so
    %   there is no frame-selection case. Angles are validated with
    %   validateNumber (RA/roll in [-360, 360], dec in [-90, 90]); blanks are
    %   non-numeric and rejected. No propagation, no rendering.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredAngles(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);

            testCase.verifyEqual(str2double(app.RightAscText.Value), 30, 'AbsTol', 1e-9, ...
                'Right ascension must show in degrees.');
            testCase.verifyEqual(str2double(app.DeclinationText.Value), 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(app.RollText.Value), 10, 'AbsTol', 1e-9);
        end

        function saveAndCloseWritesEveryField(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '45';
            app.DeclinationText.Value = '-15';
            app.RollText.Value = '90';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(45), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.dec, deg2rad(-15), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.roll, deg2rad(90), 'AbsTol', 1e-12);
        end

        function blankAngleIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.DeclinationText.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank angle must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.dec, deg2rad(20), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function outOfRangeRightAscensionIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '400';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Right ascension outside [-360, 360] must not save.');
            testCase.verifyTrue(isvalid(fig));
            testCase.verifyEqual(model.rhtAsc, deg2rad(30), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '99';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(30), 'AbsTol', 1e-12, ...
                'Cancel must leave the model alone.');
        end

        function windowXPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '99';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(30), 'AbsTol', 1e-12, ...
                'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = FixedInVehicleFrameSensorSteeringModel(deg2rad(30), deg2rad(20), deg2rad(10), lvdData);
        end

        function app = openDialog(testCase, model, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditFixedInVehicleBodyFrameSensorSteeringModelGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FixedInVehicleSensorSteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Sensor Pointing Model')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Sensor Pointing Model')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
