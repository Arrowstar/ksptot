classdef T2WThrottleModelDialogTest < KsptotTestCase
    %T2WThrottleModelDialogTest Full round-trip UI tests for the
    %thrust-to-weight throttle editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/throttleModels/lvd_EditT2WThrottleModelGUI_App.mlapp
    %   backing class: T2WThrottleModel
    %   production caller: T2WThrottleModel.openEditThrottleModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/throttle/@T2WThrottleModel/T2WThrottleModel.m:69-74).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored target T/W; Save & Close writes it back;
    %   blank and non-numeric ratios are rejected and leave the model
    %   alone; Cancel preserves the model; the continuity checkbox
    %   round-trips; the optimizer variable belongs to the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredRatio(testCase)
            [model, lvdData] = testCase.fixture();
            model.targetT2W = 1.25;

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.twRatioText, 'String')), 1.25, 'AbsTol', 1e-12);
        end

        function dialogShowsContinuityState(testCase)
            [model, lvdData] = testCase.fixture();
            model.throttleContinuity = true;

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(logical(handles.throttleContCheckbox.Value), ...
                'The continuity checkbox must reflect the model.');
        end

        function saveAndCloseWritesRatio(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditT2WThrottleModelGUI;

            set(handles.twRatioText, 'String', '1.75');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.targetT2W, 1.75, 'AbsTol', 1e-12);
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
                testCase.verifyFalse(model.throttleContinuity);
                testCase.closeAlerts();
                testCase.pushButton(app.cancelButton);
            end
        end

        function blankRatioIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.targetT2W = 1.25;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.twRatioText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank T/W ratio must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditT2WThrottleModelGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.targetT2W, 1.25, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function nonNumericRatioIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            model.targetT2W = 0.8;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.twRatioText, 'String', 'abc');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric T/W ratio must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditT2WThrottleModelGUI));
            testCase.verifyEqual(model.targetT2W, 0.8, 'AbsTol', 1e-15);
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function optVarBelongsToModel(testCase)
            [model, ~] = testCase.fixture();
            optVar = model.getNewOptVar();

            testCase.verifyClass(optVar, 'T2WThrottleModelOptimVar', ...
                'The T/W throttle variable must have the expected class.');
            testCase.verifySameHandle(model.getExistingOptVar(), optVar, ...
                'The model must link back to its variable.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.targetT2W = 1.25;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditT2WThrottleModelGUI;

            set(handles.twRatioText, 'String', '9.99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.targetT2W, 1.25, 'AbsTol', 1e-15, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            model = T2WThrottleModel.getDefaultThrottleModel();
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditT2WThrottleModelGUI_App(model, lv, true, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() T2WThrottleModelDialogTest.deleteIfValid(app));
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
