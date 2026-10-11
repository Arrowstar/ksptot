classdef QuatInterpSteeringDialogTest < KsptotTestCase
    %QuatInterpSteeringDialogTest Full round-trip UI tests for the
    %quaternion-interpolation steering editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditActionSetQuatInterpSteeringModelGUI_App.mlapp
    %   backing class: GenericQuatInterpSteeringModel
    %   production caller: GenericQuatInterpSteeringModel.openEditSteeringModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/steering/@GenericQuatInterpSteeringModel/GenericQuatInterpSteeringModel.m:189-194).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored duration/init/final angles; Save & Close writes
    %   every field back; blank and non-numeric input is rejected and
    %   leaves the model alone; Cancel preserves the model; the control
    %   frame dropdown offers every ControlFramesEnum; the optimizer
    %   variable belongs to the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [model, lvdData] = testCase.fixture();
            model.setDuration(100);
            model.setInitAngles(0.1, 0.2, 0.3);
            model.setFinalAngles(0.4, 0.5, 0.6);

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            %Angles display in degrees (populateGUI applies rad2deg).
            testCase.verifyEqual(str2double(get(handles.tDurText, 'String')), 100, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.angle1InitText, 'String')), rad2deg(0.1), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle2InitText, 'String')), rad2deg(0.2), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle3InitText, 'String')), rad2deg(0.3), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle1FinalText, 'String')), rad2deg(0.4), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle2FinalText, 'String')), rad2deg(0.5), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.angle3FinalText, 'String')), rad2deg(0.6), 'AbsTol', 1e-9);
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
            fig = handles.lvd_EditActionSetQuatInterpSteeringModelGUI;

            set(handles.tDurText, 'String', '50');
            set(handles.angle1InitText, 'String', '0.15');
            set(handles.angle1FinalText, 'String', '0.45');
            set(handles.angle2InitText, 'String', '-0.1');
            set(handles.angle2FinalText, 'String', '0.2');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.getDuration(), 50, 'AbsTol', 1e-12);
            %Degree entries store as radians.
            [g0, b0, ~] = model.getInitAngles();
            testCase.verifyEqual(g0, deg2rad(0.15), 'AbsTol', 1e-12);
            testCase.verifyEqual(b0, deg2rad(-0.1), 'AbsTol', 1e-12);
            [g1, b1, ~] = model.getFinalAngles();
            testCase.verifyEqual(g1, deg2rad(0.45), 'AbsTol', 1e-12);
            testCase.verifyEqual(b1, deg2rad(0.2), 'AbsTol', 1e-12);
        end

        function blankDurationIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.setDuration(100);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.tDurText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank duration must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetQuatInterpSteeringModelGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.getDuration(), 100, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function nonNumericAngleIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.angle1InitText, 'String', 'abc');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric angle must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetQuatInterpSteeringModelGUI));
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function optVarBelongsToModel(testCase)
            [model, ~] = testCase.fixture();
            optVar = model.getNewOptVar();

            testCase.verifyClass(optVar, 'SetGenericQuatInterpSteeringModelActionOptimVar');
            testCase.verifySameHandle(model.getExistingOptVar(), optVar, ...
                'The model must link back to its variable.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.setDuration(100);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetQuatInterpSteeringModelGUI;

            set(handles.tDurText, 'String', '7');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.getDuration(), 100, 'AbsTol', 1e-15, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            model = GenericQuatInterpSteeringModel.getDefaultSteeringModel();
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false, model});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetQuatInterpSteeringModelGUI_App(model, lv, true, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() QuatInterpSteeringDialogTest.deleteIfValid(app));
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
