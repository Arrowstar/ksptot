classdef StopwatchDialogTest < KsptotTestCase
    %StopwatchDialogTest Full round-trip UI tests for the single stopwatch
    %editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditStopwatchGUI_App.mlapp
    %   backing class: LaunchVehicleStopwatch (dialog ctor is (stopwatch, output))
    %   production caller: lvd_EditStopwatchesGUI_App (add/edit paths).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored name/start value/start state; the state combo
    %   offers both running states; Save & Close writes every field back; a
    %   blank start value is rejected and leaves the model alone; Cancel and
    %   window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [sw] = testCase.fixture();
            app = testCase.openDialog(sw);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.stopwatchNameText, 'String'), 'Coast Timer');
            testCase.verifyEqual(str2double(get(handles.initialValueText, 'String')), 7.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(handles.startRunningCombo.Value, ...
                StopwatchRunningEnum.getIndOfListboxStrs(StopwatchRunningEnum.NotRunning));
        end

        function startRunningComboOffersBothStates(testCase)
            [sw] = testCase.fixture();
            app = testCase.openDialog(sw);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            items = cellstr(handles.startRunningCombo.String);
            testCase.verifyTrue(any(strcmp(items, 'Running')), 'The Running state must be offered.');
            testCase.verifyTrue(any(strcmp(items, 'Not Running')), 'The Not Running state must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [sw] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sw, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStopwatchGUI;

            set(handles.stopwatchNameText, 'String', 'Burn Timer');
            set(handles.initialValueText, 'String', '12.5');
            handles.startRunningCombo.Value = ...
                StopwatchRunningEnum.getIndOfListboxStrs(StopwatchRunningEnum.Running);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(sw.name, 'Burn Timer');
            testCase.verifyEqual(sw.startValue, 12.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(sw.startOn, StopwatchRunningEnum.Running);
        end

        function blankInitialValueIsRejected(testCase)
            [sw] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sw, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStopwatchGUI;

            set(handles.initialValueText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank start value must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(sw.startValue, 7.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts(fig);
        end

        function cancelPreservesModel(testCase)
            [sw] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sw, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStopwatchGUI;

            set(handles.stopwatchNameText, 'String', 'Scratch');
            set(handles.initialValueText, 'String', '99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(sw.name, 'Coast Timer', 'Cancel must leave the model alone.');
            testCase.verifyEqual(sw.startValue, 7.5, 'AbsTol', 1e-12);
        end

        function windowClosePreservesModel(testCase)
            [sw] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sw, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStopwatchGUI;

            set(handles.initialValueText, 'String', '99');
            close(fig);

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(sw.startValue, 7.5, 'AbsTol', 1e-12, 'Window-X must leave the model alone.');
        end
    end

    methods(Access=private)
        function sw = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw = LaunchVehicleStopwatch(lvdData);
            sw.name = 'Coast Timer';
            sw.startValue = 7.5;
            sw.startOn = StopwatchRunningEnum.NotRunning;
        end

        function app = openDialog(testCase, sw, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditStopwatchGUI_App(sw, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StopwatchDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~, keepFig)
            %Compare by captured figure number: .Number on a figure that
            %died mid-sweep returns [] and breaks &&-chained comparisons.
            keepNum = [];
            if ~isempty(keepFig) && isvalid(keepFig)
                keepNum = keepFig.Number;
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~isequal(figs(i).Number, keepNum)
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Stopwatch')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
