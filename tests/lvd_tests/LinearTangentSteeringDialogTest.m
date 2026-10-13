classdef LinearTangentSteeringDialogTest < KsptotTestCase
    %LinearTangentSteeringDialogTest Full round-trip UI tests for the
    %linear-tangent steering-math editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditLinearTangentModelGUI_App.mlapp
    %   backing class: LinearTangentSelectableModel (the dialog reads the
    %   var*/bounds properties that only the selectable wrapper has; a bare
    %   LinearTangentModel crashes populateGUI, bug log 2.11).
    %   production caller: none under helper_methods/ (.mlapp only; opened
    %   from the selectable/linear-tangent steering editors).  The dialog
    %   is therefore driven directly as
    %   lvd_EditLinearTangentModelGUI_App(model, out).
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
    %   Open shows stored a/a-dot/b/b-dot; Save & Close writes every field
    %   back; blank and non-numeric fields are rejected and leave the
    %   model alone; closing without saving preserves the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            model = testCase.fixture();
            model.a = 0.02;
            model.a_dot = 0.0005;
            model.b = 0.5;
            model.b_dot = -0.001;

            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.aText, 'String')), 0.02, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.aDotText, 'String')), 0.0005, 'AbsTol', 1e-15);
            testCase.verifyEqual(str2double(get(handles.bText, 'String')), 0.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.bDotText, 'String')), -0.001, 'AbsTol', 1e-15);
        end

        function controlCallbacksWriteThroughLive(testCase)
            %The dialog writes through its control callbacks (raw units);
            %Save & Close only reports success (verified in the .mlapp:
            %saveAndClose is {true}+close with no validation of its own).
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditLinearTangentModelGUI;

            testCase.editControl(app, handles.aText, app.aText, '0.03');
            testCase.editControl(app, handles.aDotText, app.aDotText, '0.001');
            testCase.editControl(app, handles.bText, app.bText, '0.6');
            testCase.editControl(app, handles.bDotText, app.bDotText, '-0.002');
            testCase.verifyEqual(model.a, 0.03, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.a_dot, 0.001, 'AbsTol', 1e-15);
            testCase.verifyEqual(model.b, 0.6, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.b_dot, -0.002, 'AbsTol', 1e-15);

            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
        end

        function blankFieldIsRejectedAtControl(testCase)
            model = testCase.fixture();
            model.a = 0.02;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.aText, 'String', '');
            app.aText.ValueChangedFcn(app.aText, testCase.vcEvent(app.aText, ''));
            drawnow;

            testCase.verifyEqual(model.a, 0.02, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.verifyTrue(isvalid(handles.lvd_EditLinearTangentModelGUI), ...
                'The dialog must stay open.');
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditLinearTangentModelGUI);
        end

        function nonNumericFieldIsRejectedAtControl(testCase)
            model = testCase.fixture();
            model.b = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.bText, 'String', 'xyz');
            app.bText.ValueChangedFcn(app.bText, testCase.vcEvent(app.bText, 'xyz'));
            drawnow;

            testCase.verifyEqual(model.b, 0.5, 'AbsTol', 1e-15);
            testCase.verifyTrue(isvalid(handles.lvd_EditLinearTangentModelGUI));
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditLinearTangentModelGUI);
        end

        function boundsRoundTrip(testCase)
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditLinearTangentModelGUI;

            testCase.editControl(app, handles.aLbText, app.aLbText, '-1');
            testCase.editControl(app, handles.aUbText, app.aUbText, '1');
            testCase.verifyEqual(model.aLb, -1, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.aUb, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.getValueAtTime(model.t0), atan(model.a * 0 + model.b), 'AbsTol', 1e-12, ...
                'The linear-tangent law must still evaluate its closed form.');

            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
        end

        function closeWithoutSavingPreservesModel(testCase)
            model = testCase.fixture();
            model.a = 0.02;
            model.b = 0.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditLinearTangentModelGUI;

            set(handles.aText, 'String', '9.9');
            set(handles.bText, 'String', '8.8');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyEqual(model.a, 0.02, 'AbsTol', 1e-15, 'Closing without saving must leave a alone.');
            testCase.verifyEqual(model.b, 0.5, 'AbsTol', 1e-15, 'Closing without saving must leave b alone.');
        end
    end

    methods(Access=private)
        function model = fixture(~)
            model = LinearTangentSelectableModel(0, 0.02, 0.0005, 0.5, -0.001);
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditLinearTangentModelGUI_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() LinearTangentSteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function editControl(testCase, app, legacyCtrl, ctrl, str)
            %editControl Sets an EditField's text through its legacy
            %GUIDE handle (the only route accepting 'String') and fires
            %its ValueChanged callback on the app component.
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
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Linear Tangent Model'))
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Linear Tangent Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
