classdef FitNetSteeringDialogTest < KsptotTestCase
    %FitNetSteeringDialogTest Full round-trip UI tests for the neural
    %network steering-math editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditFitNetModelGUI_App.mlapp
    %   backing class: FitNetModel
    %   production caller: none under helper_methods/ (.mlapp only; opened
    %   from the selectable-steering edit-angle buttons).  The dialog is
    %   therefore driven directly as lvd_EditFitNetModelGUI_App(model, out).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  This editor is
    %   save-only (no Cancel control in AREA_actionUIs.txt), so
    %   preservation is checked via failed validation and via closing
    %   without saving.
    %
    % COVERED
    %   Open shows stored const and WB bounds (degrees); the WB listbox
    %   mirrors getWbParams; control callbacks write through live (degrees
    %   in, radians stored) and Save & Close only reports success; blank
    %   const and non-numeric WB edits are rejected at the control (model
    %   untouched, field restored, message shown); closing without saving
    %   preserves the model.  There is no Cancel button and saveAndClose
    %   performs no validation of its own.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            model = testCase.fixture();
            model.const = 0.25;
            model.constLb = -0.5;
            model.constUb = 0.5;

            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            %Const terms display in degrees.
            testCase.verifyEqual(str2double(get(handles.constText, 'String')), rad2deg(0.25), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.constLbText, 'String')), rad2deg(-0.5), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.constUbText, 'String')), rad2deg(0.5), 'AbsTol', 1e-9);
        end

        function wbListboxMirrorsModel(testCase)
            model = testCase.fixture();
            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            nWb = numel(model.getWbParams());
            testCase.verifyEqual(numel(cellstr(handles.wbParamListbox.String)), nWb, ...
                'Every network weight/bias parameter must be listed.');
        end

        function controlCallbacksWriteThroughLive(testCase)
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFitNetModelGUI;

            %Degree entries store as radians as soon as the control
            %callback fires; Save & Close only reports success.
            %Legacy handles are used: set(..., 'String') is only accepted
            %through the GUIDE-migration mapping, not on app.* directly.
            testCase.editControl(app, handles.constText, app.constText, '0.4');
            testCase.editControl(app, handles.constLbText, app.constLbText, '-1');
            testCase.editControl(app, handles.constUbText, app.constUbText, '1');
            testCase.verifyEqual(model.const, deg2rad(0.4), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.constLb, deg2rad(-1), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.constUb, deg2rad(1), 'AbsTol', 1e-12);

            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
        end

        function blankConstIsRejectedAtControl(testCase)
            model = testCase.fixture();
            model.const = 0.25;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.constText, 'String', '');
            app.constText.ValueChangedFcn(app.constText, testCase.vcEvent(app.constText, ''));
            drawnow;

            testCase.verifyEqual(model.const, 0.25, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.verifyEqual(str2double(get(handles.constText, 'String')), rad2deg(0.25), 'AbsTol', 1e-9, ...
                'Rejected input must restore the field.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFitNetModelGUI), ...
                'The dialog must stay open.');
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditFitNetModelGUI);
        end

        function nonNumericWbIsRejectedAtControl(testCase)
            model = testCase.fixture();
            wb0 = model.getWbParamAtInd(1);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.wbParamText, 'String', 'not_a_number');
            app.wbParamText.ValueChangedFcn(app.wbParamText, testCase.vcEvent(app.wbParamText, 'not_a_number'));
            drawnow;

            testCase.verifyEqual(model.getWbParamAtInd(1), wb0, 'AbsTol', 1e-15, ...
                'Rejected input must leave the weights alone.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFitNetModelGUI));
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditFitNetModelGUI);
        end

        function closeWithoutSavingPreservesModel(testCase)
            model = testCase.fixture();
            model.const = 0.25;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFitNetModelGUI;

            set(handles.constText, 'String', '9.9');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyEqual(model.const, 0.25, 'AbsTol', 1e-15, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function model = fixture(~)
            model = FitNetModel(5);
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditFitNetModelGUI_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FitNetSteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function editControl(testCase, app, legacyCtrl, ctrl, str)
            %editControl Sets an EditField's text through its legacy
            %GUIDE handle (the only route accepting 'String') and fires
            %its ValueChanged callback on the app component (the redirect
            %strategy needs a Value-bearing event).
            %#ok<INUSL>
            set(legacyCtrl, 'String', str);
            ctrl.ValueChangedFcn(ctrl, testCase.vcEvent(ctrl, str));
            drawnow;
        end

        function evt = vcEvent(~, ctrl, str)
            evt = struct('Source', ctrl, 'Value', str, ...
                'PreviousValue', '', 'EventName', 'ValueChanged');
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Neural Network Model'))
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Neural Network Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
