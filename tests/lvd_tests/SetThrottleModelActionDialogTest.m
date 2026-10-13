classdef SetThrottleModelActionDialogTest < KsptotTestCase
    %SetThrottleModelActionDialogTest Full round-trip UI tests for the
    %polynomial throttle editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/throttleModels/lvd_EditActionSetThrottleModelGUI_App.mlapp
    %   backing class: ThrottlePolyModel
    %   production caller: ThrottlePolyModel.openEditThrottleModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/throttle/@ThrottlePolyModel/ThrottlePolyModel.m:67-72).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored const/lin/accel/time-offset terms; Save & Close
    %   writes every field back; blank and non-numeric terms are rejected
    %   and leave the model alone; Cancel and window-X preserve the model;
    %   the continuity checkbox round-trips; the optimizer variable belongs
    %   to the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [model, lvdData] = testCase.fixture();
            model.setPolyTerms(0.5, 0.02, -0.001);
            model.setTimeOffsets(1.5);

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            %Throttle terms display as percent (x100); the time offset is raw.
            testCase.verifyEqual(str2double(get(handles.throttleConstTermText, 'String')), 50, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.throttleLinTermText, 'String')), 2, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.throttleAccelTermText, 'String')), -0.1, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.timeOffsetText, 'String')), 1.5, 'AbsTol', 1e-12);
        end

        function dialogShowsContinuityState(testCase)
            [model, lvdData] = testCase.fixture();
            model.throttleContinuity = true;

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(logical(handles.throttleContCheckbox.Value), ...
                'The continuity checkbox must reflect the model.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThrottleModelGUI;

            set(handles.throttleConstTermText, 'String', '0.65');
            set(handles.throttleLinTermText, 'String', '0.03');
            set(handles.throttleAccelTermText, 'String', '-0.002');
            set(handles.timeOffsetText, 'String', '2.5');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            %Percent entries store as fractions (/100); the offset is raw.
            testCase.verifyEqual(model.throttleModel.constTerm, 0.0065, 'AbsTol', 1e-15);
            testCase.verifyEqual(model.throttleModel.linearTerm, 0.0003, 'AbsTol', 1e-15);
            testCase.verifyEqual(model.throttleModel.accelTerm, -0.00002, 'AbsTol', 1e-15);
            testCase.verifyEqual(model.throttleModel.tOffset, 2.5, 'AbsTol', 1e-12);
        end

        function saveAndCloseWritesContinuity(testCase)
            [model, lvdData] = testCase.fixture();
            model.throttleContinuity = false;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.throttleContCheckbox.Value = true;
            testCase.pushButton(app.saveAndCloseButton);

            if(out.output{1})
                testCase.verifyTrue(model.throttleContinuity, 'Save must commit the continuity checkbox.');
            else
                testCase.verifyFalse(model.throttleContinuity, 'Rejected save must leave continuity alone.');
                testCase.closeAlerts();
                testCase.pushButton(app.cancelButton);
            end
        end

        function blankConstIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.setPolyTerms(0.5, 0, 0);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.throttleConstTermText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank constant term must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetThrottleModelGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.throttleModel.constTerm, 0.5, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function nonNumericTermIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.throttleLinTermText, 'String', 'abc');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric linear term must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetThrottleModelGUI));
            testCase.verifyEqual(model.throttleModel.linearTerm, 0, 'AbsTol', 1e-15);
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function optVarBelongsToModel(testCase)
            [model, ~] = testCase.fixture();
            optVar = model.getNewOptVar();

            testCase.verifyClass(optVar, 'SetPolyThrottleModelActionOptimVar', ...
                'The poly throttle variable must have the expected class.');
            testCase.verifySameHandle(model.getExistingOptVar(), optVar, ...
                'The model must link back to its variable.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.setPolyTerms(0.5, 0.01, 0);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetThrottleModelGUI;

            set(handles.throttleConstTermText, 'String', '0.99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.throttleModel.constTerm, 0.5, 'AbsTol', 1e-15, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            model = ThrottlePolyModel.getDefaultThrottleModel();
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetThrottleModelGUI_App(model, lv, true, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SetThrottleModelActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Throttle Model'))
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Throttle Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
