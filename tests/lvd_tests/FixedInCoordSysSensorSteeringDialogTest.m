classdef FixedInCoordSysSensorSteeringDialogTest < KsptotTestCase
    %FixedInCoordSysSensorSteeringDialogTest Full round-trip UI tests for the
    %fixed-in-coordinate-system sensor steering editor (Phase 4: sensors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/sensors/sensor_models/steering_models/lvd_EditFixedInCoordSysSensorSteeringModelGUI_App.mlapp
    %   ('Edit Sensor Pointing Model'; modern App Designer, uiwait).
    %   backing class: FixedInCoordSysSensorSteeringModel
    %   production caller: FixedInCoordSysSensorSteeringModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/Sensors/SensorModels/SensorSteeringModels/@FixedInCoordSysSensorSteeringModel/FixedInCoordSysSensorSteeringModel.m:59-63):
    %   lvd_EditFixedInCoordSysSensorSteeringModelGUI_App(obj, obj.lvdData, output).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   SensorSteeringModelActionDialogTest pattern). This modern dialog
    %   exposes its controls as app properties, so tests drive
    %   app.RightAscText / app.DeclinationText / app.RollText /
    %   app.CoordSysCombo directly and fire app.saveAndCloseButton.
    %
    % COVERED
    %   Open shows stored RA/dec/roll (deg) and the frame; the frame combo
    %   offers every scenario coordinate system; Save & Close writes every
    %   field back including the frame; a blank angle and an out-of-range
    %   declination are rejected and leave the model alone; Cancel and
    %   window-X preserve the model.
    %
    % NOTES
    %   Production offers no sub-dialog for the frame: it is a plain
    %   dropdown (document.xml has no callback on CoordSysCombo), so the
    %   frame selection is set through CoordSysCombo.Value directly and no
    %   stub is needed. Angles are validated with validateNumber
    %   (RA/roll in [-360, 360], dec in [-90, 90]); blanks are non-numeric
    %   and rejected. No propagation, no rendering.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredAnglesAndFrame(testCase)
            [model, lvdData, cs1] = testCase.fixture(); %#ok<ASGLU>
            app = testCase.openDialog(model, lvdData);

            testCase.verifyEqual(str2double(app.RightAscText.Value), 30, 'AbsTol', 1e-9, ...
                'Right ascension must show in degrees.');
            testCase.verifyEqual(str2double(app.DeclinationText.Value), 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(app.RollText.Value), 10, 'AbsTol', 1e-9);
            testCase.verifyTrue(app.CoordSysCombo.Value == cs1, ...
                'The frame dropdown must point at the stored coordinate system.');
        end

        function coordSysComboOffersEveryCoordSys(testCase)
            [model, lvdData, cs1, cs2] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);

            testCase.verifyNumElements(app.CoordSysCombo.Items, 2, ...
                'Every scenario coordinate system must be offered.');
            testCase.verifyTrue(any(app.CoordSysCombo.ItemsData == cs1));
            testCase.verifyTrue(any(app.CoordSysCombo.ItemsData == cs2));
        end

        function saveAndCloseWritesAnglesAndFrame(testCase)
            [model, lvdData, ~, cs2] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '45';
            app.DeclinationText.Value = '-15';
            app.RollText.Value = '90';
            app.CoordSysCombo.Value = cs2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(45), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.dec, deg2rad(-15), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.roll, deg2rad(90), 'AbsTol', 1e-12);
            testCase.verifyTrue(model.coordSys == cs2, 'Save must write the selected frame.');
        end

        function blankAngleIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank angle must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(30), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function outOfRangeDeclinationIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.DeclinationText.Value = '200';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Declination outside [-90, 90] must not save.');
            testCase.verifyTrue(isvalid(fig));
            testCase.verifyEqual(model.dec, deg2rad(20), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, lvdData, cs1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditSensorPointingModelUIFigure;

            app.RightAscText.Value = '99';
            app.CoordSysCombo.Value = app.CoordSysCombo.ItemsData(2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.rhtAsc, deg2rad(30), 'AbsTol', 1e-12, ...
                'Cancel must leave the model alone.');
            testCase.verifyTrue(model.coordSys == cs1, 'Cancel must leave the frame alone.');
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
        function [model, lvdData, cs1, cs2] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            cs1 = ParallelToFrameCoordSystem(testCase.kerbinFrame, 'cs1', lvdData);
            cs2 = ParallelToFrameCoordSystem(testCase.kerbinFrame, 'cs2', lvdData);
            lvdData.geometry.coordSyses.addCoordSys(cs1);
            lvdData.geometry.coordSyses.addCoordSys(cs2);
            model = FixedInCoordSysSensorSteeringModel(deg2rad(30), deg2rad(20), deg2rad(10), cs1, lvdData);
        end

        function app = openDialog(testCase, model, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditFixedInCoordSysSensorSteeringModelGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FixedInCoordSysSensorSteeringDialogTest.deleteIfValid(app));
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
