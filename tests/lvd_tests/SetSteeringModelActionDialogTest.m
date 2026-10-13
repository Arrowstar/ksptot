classdef SetSteeringModelActionDialogTest < KsptotTestCase
    %SetSteeringModelActionDialogTest Full round-trip UI tests for the
    %polynomial steering editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditActionSetSteeringModelGUI_App.mlapp
    %   backing class: GenericPolySteeringModel (also serves
    %   RollPitchYawPolySteeringModel, AeroAnglesPolySteeringModel and
    %   InertialAeroAnglesPolySteeringModel)
    %   production caller: GenericPolySteeringModel.openEditSteeringModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/steering/@GenericPolySteeringModel/GenericPolySteeringModel.m:179-184).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored const/lin/accel terms; Save & Close writes every
    %   field back; blank and non-numeric input is rejected; Cancel
    %   preserves the model; the steering-type dropdown lists the poly
    %   family; the control frame dropdown offers every ControlFramesEnum.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [model, lvdData] = testCase.fixture();
            model.setConstTerms(0.05, 0.20, -0.11);
            model.setLinearTerms(0.0009, -0.0004, 0.0012);
            model.setAccelTerms(0.0001, 0.0002, -0.0003);

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            %Angle terms display in degrees (populateGUI applies rad2deg).
            testCase.verifyEqual(str2double(get(handles.angle1ConstTermText, 'String')), rad2deg(0.05), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle2ConstTermText, 'String')), rad2deg(0.20), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle3ConstTermText, 'String')), rad2deg(-0.11), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle1LinTermText, 'String')), rad2deg(0.0009), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle1AccelTermText, 'String')), rad2deg(0.0001), 'AbsTol', 1e-9);
        end

        function steeringTypeComboListsPolyFamily(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            names = SteeringModelEnum.getSteeringModelTypeNameStrs(true);
            testCase.verifyEqual(numel(cellstr(handles.steeringModelTypeCombo.String)), numel(names), ...
                'Every poly steering type must be offered.');
        end

        function controlFrameComboOffersEveryFrame(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.controlFrameCombo.String)), ...
                numel(enumeration('ControlFramesEnum')), ...
                'Every control frame must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetSteeringModelGUI;

            set(handles.angle1ConstTermText, 'String', '0.11');
            set(handles.angle1LinTermText, 'String', '0.002');
            set(handles.angle1AccelTermText, 'String', '0.0005');
            set(handles.timeOffsetText, 'String', '1.5');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            %Degree entries store as radians (saveAndClose applies deg2rad).
            testCase.verifyEqual(model.gammaAngleModel.constTerm, deg2rad(0.11), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.gammaAngleModel.linearTerm, deg2rad(0.002), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.gammaAngleModel.accelTerm, deg2rad(0.0005), 'AbsTol', 1e-12);
        end

        function blankConstIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.setConstTerms(0.05, 0, 0);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.angle1ConstTermText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank constant term must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetSteeringModelGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.gammaAngleModel.constTerm, 0.05, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function nonNumericTermIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.angle2LinTermText, 'String', 'xyz');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric linear term must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetSteeringModelGUI));
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.setConstTerms(0.05, 0, 0);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetSteeringModelGUI;

            set(handles.angle1ConstTermText, 'String', '9.9');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.gammaAngleModel.constTerm, 0.05, 'AbsTol', 1e-15, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            model = GenericPolySteeringModel.getDefaultSteeringModel();
            %The default model carries no reference frame, which crashes
            %populateGUI (bug log 2.10); configured models always have one.
            model.setRefFrame(lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame());
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false, model});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetSteeringModelGUI_App(model, lv, true, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SetSteeringModelActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Steering Model'))
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
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Steering Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
