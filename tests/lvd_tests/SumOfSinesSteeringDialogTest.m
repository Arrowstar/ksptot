classdef SumOfSinesSteeringDialogTest < KsptotTestCase
    %SumOfSinesSteeringDialogTest Full round-trip UI tests for the
    %sum-of-sines math editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditSumOfSinesModelGUI_App.mlapp
    %   backing class: SumOfSinesModel (+ SineModel rows)
    %   production caller: none under helper_methods/ (.mlapp only; opened
    %   from the selectable-steering edit-sine buttons).  The dialog is
    %   therefore driven directly as lvd_EditSumOfSinesModelGUI_App(model, out).
    %
    % PATTERN
    %   GUIDE-migrated dialog; UiwaitInterceptorFixture stands in for uiwait
    %   (the PatchedMlappDialogsTest pattern).  The sineListbox mirrors the
    %   InterpThrottleModelUITest table: population, add/remove rows,
    %   validation of bad rows, save mutation and preservation without
    %   saving.  This editor is save-only (no Cancel in
    %   AREA_actionUIs.txt), so preservation is checked via failed
    %   validation and via closing without saving.
    %
    % COVERED
    %   Listbox population from sines (const/amp display in degrees,
    %   period/phase raw); add appends a sine; remove drops the selected
    %   sine (select by member object); removing the last sine empties the
    %   list (no last-sine guard); control callbacks write through live;
    %   non-numeric amp and zero period are rejected at the control; Save &
    %   Close only reports success; close without saving preserves.
    %
    % NOTE: reassigning the listbox Items while Value holds a removed sine
    %   trips the App Designer migration-layer ismember crash (bug log
    %   1.25-family); it surfaces as a listener warning, not a failure.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListboxMatchesModel(testCase)
            model = testCase.fixture();
            model.const = -0.4;
            model.sines(1).amp = 0.1;
            model.sines(1).period = 20;
            model.sines(1).phase = 0;
            model.addSine(SineModel(0, 0.05, 2*pi/60, 3));

            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.sineListbox.String)), 2, ...
                'Both sines must be listed.');
            testCase.verifyEqual(str2double(get(handles.constText, 'String')), rad2deg(-0.4), 'AbsTol', 1e-9, ...
                'Const displays in degrees.');
        end

        function dialogAddSineAppendsRow(testCase)
            model = testCase.fixture();
            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyEqual(model.getNumSines(), 1);

            testCase.pushButton(app.addSineButton);
            drawnow;

            testCase.verifyEqual(model.getNumSines(), 2, 'Add must append one sine.');
            testCase.verifyEqual(numel(cellstr(handles.sineListbox.String)), 2, ...
                'The listbox must show the new sine.');
        end

        function dialogRemoveSineDropsSelectedRow(testCase)
            model = testCase.fixture();
            model.sines(1).amp = 0.1;
            model.addSine(SineModel(0, 0.05, 2*pi/60, 3));
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyEqual(model.getNumSines(), 2);

            %Select by member object through the modern handle (the legacy
            %handle only accepts indices).
            app.sineListbox.Value = model.sines(1);
            testCase.pushButton(app.removeSineButton);

            testCase.verifyEqual(model.getNumSines(), 1, 'One of the two sines must remain.');
            testCase.verifyEqual(model.sines(1).amp, 0.05, 'AbsTol', 1e-12, ...
                'Removing sine 1 must keep sine 2.');
        end

        function dialogRemoveLastSineEmptiesList(testCase)
            %The dialog has no last-sine guard: removing the only sine
            %empties the model.
            model = testCase.fixture();
            app = testCase.openDialog(model);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.assertEqual(model.getNumSines(), 1);

            app.sineListbox.Value = model.sines(1);
            testCase.pushButton(app.removeSineButton);
            drawnow;

            testCase.verifyEqual(model.getNumSines(), 0, 'Removing the last sine empties the model.');
            testCase.closeAlerts();
        end

        function controlCallbacksWriteThroughLive(testCase)
            model = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSumOfSinesModelGUI;

            %Const/amp entries are degrees in, radians stored; period/phase
            %are raw.  Save & Close only reports success.
            testCase.editControl(app, handles.constText, app.constText, '0.2');
            testCase.editControl(app, handles.ampText, app.ampText, '0.15');
            testCase.editControl(app, handles.periodText, app.periodText, '40');
            testCase.editControl(app, handles.phaseText, app.phaseText, '2');
            testCase.verifyEqual(model.const, deg2rad(0.2), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.sines(1).amp, deg2rad(0.15), 'AbsTol', 1e-12);
            testCase.verifyEqual(model.sines(1).period, 40, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.sines(1).phase, 2, 'AbsTol', 1e-12);

            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
        end

        function zeroPeriodIsRejectedAtControl(testCase)
            model = testCase.fixture();
            p0 = model.sines(1).period;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.periodText, 'String', '0');
            app.periodText.ValueChangedFcn(app.periodText, testCase.vcEvent(app.periodText, '0'));
            drawnow;

            testCase.verifyEqual(model.sines(1).period, p0, 'AbsTol', 1e-15, ...
                'A zero period must leave the model alone.');
            testCase.verifyTrue(isvalid(handles.lvd_EditSumOfSinesModelGUI), ...
                'The dialog must stay open.');
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditSumOfSinesModelGUI);
        end

        function nonNumericAmpIsRejectedAtControl(testCase)
            model = testCase.fixture();
            model.sines(1).amp = 0.1;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.ampText, 'String', 'abc');
            app.ampText.ValueChangedFcn(app.ampText, testCase.vcEvent(app.ampText, 'abc'));
            drawnow;

            testCase.verifyEqual(model.sines(1).amp, 0.1, 'AbsTol', 1e-15, ...
                'Rejected input must leave the model alone.');
            testCase.verifyTrue(isvalid(handles.lvd_EditSumOfSinesModelGUI));
            testCase.verifyFalse(out.output{1}, 'Nothing saved yet.');
            testCase.closeAlerts();
            close(handles.lvd_EditSumOfSinesModelGUI);
        end

        function closeWithoutSavingPreservesModel(testCase)
            model = testCase.fixture();
            model.const = -0.4;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSumOfSinesModelGUI;

            set(handles.constText, 'String', '9.9');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(model.const, -0.4, 'AbsTol', 1e-15, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function model = fixture(~)
            model = SumOfSinesModel(0);
        end

        function app = openDialog(testCase, model, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSumOfSinesModelGUI_App(model, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SumOfSinesSteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function editControl(testCase, app, legacyCtrl, ctrl, str)
            %editControl Sets an EditField's text through its legacy
            %GUIDE handle and fires its ValueChanged callback on the app
            %component (the redirect strategy needs a Value-bearing event).
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
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Sum of Sines Model'))
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Sum of Sines Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
