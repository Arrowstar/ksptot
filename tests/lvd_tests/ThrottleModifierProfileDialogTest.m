classdef ThrottleModifierProfileDialogTest < KsptotTestCase
    %ThrottleModifierProfileDialogTest Full round-trip UI tests for the
    %fuel throttle modifier profile table editor (Phase 3: throttle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/editThrottleModifierProfileGUI_App.mlapp
    %   backing classes: FuelThrottleCurve, FuelThrottleCurveElement
    %   production caller: lvd_EditEngineGUI_App editThrottleModifierProfileButton
    %   (kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditEngineGUI_App.mlapp);
    %   element editor caller: editThrottleModifierProfileGUI add/editElementButton_Callbacks.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern, InterpThrottleModelUITest table
    %   pattern for add/remove).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  Add/Edit open the nested
    %   element editor and are covered by existence plus model-level adds;
    %   Delete is safe (no nesting) except for the mandatory-endpoint guard.
    %
    % COVERED
    %   Open shows the default two rows; a model-level add appears on
    %   reopen; Delete removes a middle row; deleting a mandatory endpoint
    %   is rejected; Save reports success and closes; window-X preserves.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsDefaultRows(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(handles.elementsListbox.String), 2, ...
                'The default curve (0 % and 100 %) must show two rows.');
            testCase.verifyTrue(contains(handles.titleLabel.String, 'Fuel'), ...
                'The title must name the throttle curve.');
            testCase.verifyTrue(isvalid(handles.profileAxes), 'The profile axes must exist.');
            close(handles.editThrottleModifierProfileGUI);
            drawnow;
        end

        function addedRowAppearsOnReopen(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            curve.addElement(FuelThrottleCurveElement(50, 0.8));

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(handles.elementsListbox.String), 3, ...
                'A model-level add must appear as a third row.');
            testCase.verifyEqual(numel(curve.elems), 3);
            close(handles.editThrottleModifierProfileGUI);
            drawnow;
        end

        function deleteButtonRemovesMiddleRow(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            mid = FuelThrottleCurveElement(50, 0.8);
            curve.addElement(mid);
            testCase.assertEqual(numel(curve.elems), 3);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, elems] = curve.getListboxStr();
            midInd = find([elems.indepVar] == 50, 1);
            testCase.assertNotEmpty(midInd, 'The middle row must be selectable.');
            set(handles.elementsListbox, 'Value', midInd);
            testCase.pushButton(app.deleteElementButton);

            testCase.verifyEqual(numel(curve.elems), 2, 'Delete must remove one row.');
            testCase.verifyEqual(numel(handles.elementsListbox.String), 2, ...
                'The listbox must refresh after deletion.');
            close(handles.editThrottleModifierProfileGUI);
            drawnow;
        end

        function deleteEndpointIsRejected(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.elementsListbox, 'Value', 1);
            testCase.pushButton(app.deleteElementButton);

            testCase.verifyEqual(numel(curve.elems), 2, ...
                'Mandatory endpoints must not be deletable.');
            testCase.verifyEqual(numel(handles.elementsListbox.String), 2);
            testCase.closeAlerts();
            close(handles.editThrottleModifierProfileGUI);
            drawnow;
        end

        function addAndEditButtonsExist(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(isvalid(app.addElementButton), ...
                'The add button must exist (nested element editor not pressed).');
            testCase.verifyTrue(isvalid(app.editElementButton), ...
                'The edit button must exist (nested element editor not pressed).');
            close(handles.editThrottleModifierProfileGUI);
            drawnow;
        end

        function saveReportsSuccessAndCloses(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.editThrottleModifierProfileGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
        end

        function windowCloseDoesNotReportSuccess(testCase)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.editThrottleModifierProfileGUI;

            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyEqual(numel(curve.elems), 2, 'Window-X must leave the curve alone.');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, curve, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = editThrottleModifierProfileGUI_App(curve, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ThrottleModifierProfileDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Throttle Modifier Profile')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Throttle Modifier Profile')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
