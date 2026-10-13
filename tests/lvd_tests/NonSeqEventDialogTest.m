classdef NonSeqEventDialogTest < KsptotTestCase
    %NonSeqEventDialogTest Full round-trip UI tests for the non-sequential
    %event editor (Phase 5: event editors).  This upgrades the
    %LvdMainGuiWidgetSmokeTest.mainNonSeqInsertChooseDelete open+cancel
    %smoke to value-level coverage.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/event/lvd_editNonSeqEventGUI_App.mlapp
    %   backing class: LaunchVehicleNonSeqEvent
    %
    % CTOR (verified against the dialog OpeningFcn: nonSeqEvt =
    % varargin{1}, lvdData = varargin{2}.  Like the termination condition
    % editor this dialog takes NO AppDesignerGUIOutput and has NO Cancel
    % button: saving writes the bounds/maximum in place and closes, while
    % dismissing without saving is done through window-X):
    %   app = lvd_editNonSeqEventGUI_App(nonSeqEvt, lvdData)
    %
    % Priority/enabled/log-executions live on the EVENT editor's
    % non-sequential panel (see EditEventDialogTest), not in this dialog:
    % the edit-event button path below proves the wrapped event opens there
    % and the label refreshes.  Never runs the optimizer or a propagation.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The wrapped event and
    %   the arming bounds are driven through the main-script
    %   script.nonSeqEvts container, mirroring the smoke test's
    %   insert/delete flow programmatically.
    %
    % COVERED
    %   Open shows the wrapped event name, the arming bounds and the
    %   maximum executions; Save & Close writes the bounds and the maximum
    %   (resetting executions remaining); zero/negative/fractional/blank
    %   maxima are rejected and leave the model alone; window-X preserves
    %   the model; the bound dropdowns offer every script event; the
    %   edit-event button opens the wrapped event editor; insert/delete
    %   round-trips through script.nonSeqEvts.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsWrappedEventNameBoundsAndMaxExecs(testCase)
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            nonSeqEvt.evt.name = 'Abort check';
            nonSeqEvt.maxNumExecs = 2;

            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.eventNameLabel, 'String'), 'Abort check', ...
                'The wrapped event name must be shown.');
            testCase.verifyEqual(str2double(get(handles.maxExecsText, 'String')), 2, ...
                'AbsTol', 1e-12, 'The stored maximum executions must be shown.');
            testCase.verifyEqual(get(handles.lwrBndEvtCombo, 'Value'), 1, ...
                'An empty lower bound must sit on the blank row.');
            testCase.verifyEqual(get(handles.uprBndEvtCombo, 'Value'), 1, ...
                'An empty upper bound must sit on the blank row.');
            n = lvdData.script.getTotalNumOfEvents();
            testCase.verifyEqual(numel(cellstr(get(handles.lwrBndEvtCombo, 'String'))), n + 1, ...
                'The leading blank row plus every script event must be offered.');
        end

        function boundCombosOfferEveryScriptEvent(testCase)
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            script = lvdData.script;
            evt2 = LaunchVehicleEvent.getDefaultEvent(script);
            evt2.name = 'Second burn';
            script.addEvent(evt2);

            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            n = script.getTotalNumOfEvents();
            testCase.verifyEqual(n, 2, 'The script must hold two sequential events.');
            testCase.verifyEqual(numel(cellstr(get(handles.lwrBndEvtCombo, 'String'))), n + 1);
            testCase.verifyEqual(numel(cellstr(get(handles.uprBndEvtCombo, 'String'))), n + 1);
        end

        function saveAndCloseWritesBoundsAndMaxExecs(testCase)
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            evt1 = lvdData.script.getEventForInd(1);

            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editNonSeqEventGUI;

            set(handles.lwrBndEvtCombo, 'Value', 2);
            set(handles.uprBndEvtCombo, 'Value', 2);
            set(handles.maxExecsText, 'String', '3');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(nonSeqEvt.lwrBndEvt == evt1, ...
                'The lower arming bound must be written back.');
            testCase.verifyTrue(nonSeqEvt.uprBndEvt == evt1, ...
                'The upper arming bound must be written back.');
            testCase.verifyEqual(nonSeqEvt.maxNumExecs, 3, ...
                'The maximum executions must be written back.');
            testCase.verifyEqual(nonSeqEvt.numExecsRemaining, 3, ...
                'Saving must reset the executions remaining.');
        end

        function invalidMaxExecsAreRejected(testCase)
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editNonSeqEventGUI;

            badMaxExecs = {'0', '2.5', '', '-1'};
            for k = 1:numel(badMaxExecs)
                set(handles.maxExecsText, 'String', badMaxExecs{k});
                testCase.pushButton(app.saveAndCloseButton);

                testCase.verifyTrue(isvalid(fig), ...
                    sprintf('A maximum of "%s" must leave the dialog open.', badMaxExecs{k}));
                testCase.verifyEqual(nonSeqEvt.maxNumExecs, 1, ...
                    'Rejected input must leave the model alone.');
            end
            testCase.closeAlerts();
        end

        function windowClosePreservesModel(testCase)
            %windowClosePreservesModel This dialog has no Cancel button, so
            %window-X is the only dismiss-without-saving path.
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editNonSeqEventGUI;

            set(handles.lwrBndEvtCombo, 'Value', 2);
            set(handles.maxExecsText, 'String', '5');
            close(fig);
            drawnow;

            testCase.verifyEqual(nonSeqEvt.maxNumExecs, 1, 'Window X must leave the model alone.');
            testCase.verifyEqual(nonSeqEvt.numExecsRemaining, 1, 'Window X must leave the model alone.');
            testCase.verifyEmpty(nonSeqEvt.lwrBndEvt, 'Window X must leave the model alone.');
            testCase.verifyEmpty(nonSeqEvt.uprBndEvt, 'Window X must leave the model alone.');
        end

        function editEventButtonOpensWrappedEventEditor(testCase)
            [nonSeqEvt, lvdData] = testCase.nonSeqFixture();
            nonSeqEvt.evt.name = 'Renamed inner';
            app = testCase.openDialog(nonSeqEvt, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Event*', ...
                @(fig) NonSeqEventDialogTest.recordAndClose(fig, seen));
            testCase.pushButton(app.editEventButton);

            testCase.verifyEmpty(testCase.fixture.errors(), ...
                strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('opened'), ...
                'Edit must open the wrapped event editor.');
            testCase.verifyTrue(isvalid(handles.lvd_editNonSeqEventGUI), ...
                'Dismissing the nested editor must leave this dialog open.');
            testCase.verifyEqual(get(handles.eventNameLabel, 'String'), 'Renamed inner', ...
                'Returning from the nested editor must refresh the event name.');
        end

        function insertAndDeleteRoundTripViaScript(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;
            n0 = script.nonSeqEvts.getTotalNumOfEvents();

            innerEvt = LaunchVehicleEvent(script);
            innerEvt.name = 'Staging watch';
            innerEvt.termCond = EventDurationTermCondition(10);
            wrapped = LaunchVehicleNonSeqEvent(innerEvt);
            script.nonSeqEvts.addEvent(wrapped);

            testCase.verifyEqual(script.nonSeqEvts.getTotalNumOfEvents(), n0 + 1, ...
                'Insert must add the non-sequential event.');

            script.nonSeqEvts.removeEvent(wrapped);

            testCase.verifyEqual(script.nonSeqEvts.getTotalNumOfEvents(), n0, ...
                'Delete must remove the non-sequential event again.');
        end
    end

    methods(Access=private)
        function [nonSeqEvt, lvdData] = nonSeqFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            innerEvt = LaunchVehicleEvent(script);
            innerEvt.name = 'Non-seq';
            innerEvt.termCond = EventDurationTermCondition(300);

            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            script.nonSeqEvts.addEvent(nonSeqEvt);
        end

        function app = openDialog(testCase, nonSeqEvt, lvdData)
            app = lvd_editNonSeqEventGUI_App(nonSeqEvt, lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() NonSeqEventDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Non-Sequential Event')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Non-Sequential Event')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function recordAndClose(fig, seen)
            %recordAndClose whenShown player for the nested event editor:
            %records that it opened and dismisses it without saving.
            seen('opened') = true; %#ok<NASGU> containers.Map is a handle
            close(fig);
            drawnow;
        end
    end
end
