classdef ThrottleModifierProfileElementDialogTest < KsptotTestCase
    %ThrottleModifierProfileElementDialogTest Full round-trip UI tests for
    %the single throttle modifier profile element editor (Phase 3).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_editThrottleModifierProfileElementGUI_App.mlapp
    %   backing classes: FuelThrottleCurveElement, FuelThrottleCurve
    %   production caller: editThrottleModifierProfileGUI_App
    %   addElementButton_Callback / editElementButton_Callback
    %   (kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/editThrottleModifierProfileGUI_App.mlapp).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  Fuel is bounded to
    %   [0, 100] % and the modifier to [0, 1]; endpoints 0/100 are locked.
    %
    % COVERED
    %   Open shows stored fuel/modifier; Save & Close writes both back;
    %   blank, out-of-range and endpoint-duplicating inputs are rejected;
    %   Cancel and window-X preserve the element; locked endpoints disable
    %   the fuel field.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            app = testCase.openDialog(elem, true, curve);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.fuRemainPctText, 'String')), 50, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.throtModifierText, 'String')), 0.8, 'AbsTol', 1e-12);
            testCase.pushButton(app.cancelButton);
        end

        function saveAndCloseWritesBothFields(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editThrottleModifierProfileElementGUI;

            set(handles.fuRemainPctText, 'String', '60');
            set(handles.throtModifierText, 'String', '0.4');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(elem.indepVar, 60, 'AbsTol', 1e-12);
            testCase.verifyEqual(elem.depVar, 0.4, 'AbsTol', 1e-12);
        end

        function blankFuelIsRejected(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.fuRemainPctText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank fuel value must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editThrottleModifierProfileElementGUI));
            testCase.verifyEqual(elem.indepVar, 50, 'AbsTol', 1e-12);
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function outOfRangeModifierIsRejected(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.throtModifierText, 'String', '1.5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A modifier above 1 must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editThrottleModifierProfileElementGUI));
            testCase.verifyEqual(elem.depVar, 0.8, 'AbsTol', 1e-12);
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function endpointDuplicationIsRejected(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.fuRemainPctText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Moving a row onto 0 % must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editThrottleModifierProfileElementGUI));
            testCase.verifyEqual(elem.indepVar, 50, 'AbsTol', 1e-12);
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function lockedEndpointDisablesFuelField(testCase)
            [elem, curve] = testCase.fixture(0, 1);
            app = testCase.openDialog(elem, false, curve);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(strcmp(get(handles.fuRemainPctText, 'Enable'), 'off'), ...
                'Mandatory endpoints must lock the fuel field.');
            testCase.pushButton(app.cancelButton);
        end

        function cancelPreservesElement(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editThrottleModifierProfileElementGUI;

            set(handles.fuRemainPctText, 'String', '70');
            set(handles.throtModifierText, 'String', '0.2');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(elem.indepVar, 50, 'AbsTol', 1e-12);
            testCase.verifyEqual(elem.depVar, 0.8, 'AbsTol', 1e-12);
        end

        function windowClosePreservesElement(testCase)
            [elem, curve] = testCase.fixture(50, 0.8);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(elem, true, curve, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editThrottleModifierProfileElementGUI;

            set(handles.throtModifierText, 'String', '0.2');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(elem.depVar, 0.8, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function [elem, curve] = fixture(~, fuelPct, modifier)
            curve = FuelThrottleCurve.getDefaultFuelThrottleCurve();
            elem = FuelThrottleCurveElement(fuelPct, modifier);
        end

        function app = openDialog(testCase, elem, allowEdit, curve, out)
            if nargin < 5 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editThrottleModifierProfileElementGUI_App(elem, allowEdit, curve, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ThrottleModifierProfileElementDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Throttle Modifier Profile Element')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Throttle Modifier Profile Element')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
