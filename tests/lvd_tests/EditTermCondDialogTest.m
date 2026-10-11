classdef EditTermCondDialogTest < KsptotTestCase
    %EditTermCondDialogTest Full round-trip UI tests for the termination
    %condition editor (Phase 5: event editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/event/lvd_editEvtTermCond_App.mlapp
    %   Callers: the event editor (lvd_editEventGUI_App) add/edit-term-cond
    %   buttons via editSelectedTermCond, which swaps the selected condition
    %   into event.termCond for the duration of this dialog.
    %
    % CTOR (verified against the dialog OpeningFcn: event = varargin{1};
    % the lvdData is derived from event.script.lvdData.  Unlike most LVD
    % editors this dialog takes NO AppDesignerGUIOutput: saving replaces
    % event.termCond in place and closes, cancelling just closes):
    %   app = lvd_editEvtTermCond_App(event)
    %
    % VALIDATION (verified against validateInputs: the parameter and its
    % lower/upper bounds must each be numeric, and the upper bound must not
    % sit below the lower bound.  Plain negative values are NOT rejected by
    % validateNumber with lb = -Inf, so the rejection tests below pin blank
    % and inverted-bounds input, which is what production refuses):
    %   blank/inverted-bounds input is rejected, Cancel preserves.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The nested runs (add /
    %   edit buttons) register a whenShown('Edit Termination Condition', ...)
    %   handler that reaches the nested controls through guidata(fig) and
    %   presses Save & Close through UiwaitInterceptorFixture.pushButton.
    %   Never runs the optimizer or a propagation.
    %
    % COVERED
    %   Direct open shows the stored duration/altitude value and type; Save
    %   & Close writes a new duration and a new altitude back onto
    %   event.termCond; blank values and inverted bounds are rejected and
    %   leave the condition alone; Cancel preserves the condition (its
    %   callback is a plain close, so window-X behaves identically); the
    %   event editor's add button appends a condition and drives this
    %   dialog for it, and its edit button edits the selected condition
    %   in place.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredDurationValue(testCase)
            evt = testCase.durationFixture();
            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.termCondTypeCombo, 'Value'), ...
                TerminationConditionEnum.getIndOfListboxStrsForTermCond(evt.termCond), ...
                'The duration type must be selected.');
            testCase.verifyEqual(get(handles.numParamLabel, 'String'), 'Event Duration');
            testCase.verifyEqual(str2double(get(handles.numParamText, 'String')), 100, ...
                'AbsTol', 1e-9, 'The stored duration must be shown.');
        end

        function saveAndCloseWritesNewDurationValue(testCase)
            evt = testCase.durationFixture();
            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editEvtTermCond;

            set(handles.numParamText, 'String', '250');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyClass(evt.termCond, 'EventDurationTermCondition');
            testCase.verifyEqual(evt.termCond.getTermCondUiStruct().value, 250, 'AbsTol', 1e-9, ...
                'The edited duration must be written back onto the event.');
        end

        function saveAndCloseWritesNewAltitudeValue(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = AltitudeTermCondition(70);

            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editEvtTermCond;

            testCase.verifyEqual(str2double(get(handles.numParamText, 'String')), 70, ...
                'AbsTol', 1e-9, 'The stored altitude must be shown first.');
            set(handles.numParamText, 'String', '12.5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyClass(evt.termCond, 'AltitudeTermCondition');
            testCase.verifyEqual(evt.termCond.getTermCondUiStruct().value, 12.5, 'AbsTol', 1e-9, ...
                'The edited altitude must be written back onto the event.');
        end

        function blankParamValueIsRejected(testCase)
            evt = testCase.durationFixture();
            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editEvtTermCond;

            set(handles.numParamText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(isvalid(fig), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(evt.termCond.getTermCondUiStruct().value, 100, ...
                'Rejected input must leave the condition alone.');
            testCase.closeAlerts();
        end

        function invertedBoundsAreRejected(testCase)
            evt = testCase.durationFixture();
            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editEvtTermCond;

            set(handles.numParamText, 'String', '100');
            set(handles.paramLbText, 'String', '10');
            set(handles.paramUbText, 'String', '5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(isvalid(fig), ...
                'An upper bound below the lower bound must leave the dialog open.');
            testCase.verifyEqual(evt.termCond.getTermCondUiStruct().value, 100, ...
                'Rejected input must leave the condition alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesCondition(testCase)
            evt = testCase.durationFixture();
            app = testCase.openDialog(evt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editEvtTermCond;

            set(handles.numParamText, 'String', '999');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(evt.termCond.getTermCondUiStruct().value, 100, ...
                'Cancel must leave the condition alone.');
        end

        function addButtonOpensEditorAndSavesNewCondition(testCase)
            evt = testCase.durationFixture();
            n0 = evt.getNumTermConds();
            editor = testCase.openEventEditor(evt);

            testCase.fixture.whenShown('Edit Termination Condition', ...
                @(fig) EditTermCondDialogTest.setParamAndSave(fig, '321'));
            testCase.pushButton(editor.addTermCondButton);

            testCase.verifyEmpty(testCase.fixture.errors(), ...
                strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEqual(evt.getNumTermConds(), n0 + 1, ...
                'Add must append a condition.');
            conds = evt.getAllTermConds();
            testCase.verifyClass(conds(end), 'EventDurationTermCondition');
            testCase.verifyEqual(conds(end).getTermCondUiStruct().value, 321, 'AbsTol', 1e-9, ...
                'The value saved in the nested dialog must land on the new condition.');
            testCase.verifyEqual(numel(editor.termCondListbox.Items), n0 + 1, ...
                'The editor list must show the new condition.');
        end

        function editButtonEditsSelectedCondition(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);
            evt.addTermCond(AltitudeTermCondition(70), EventTermCondDirectionEnum.NoDir);
            editor = testCase.openEventEditor(evt);

            editor.termCondListbox.Value = 2;
            testCase.fixture.whenShown('Edit Termination Condition', ...
                @(fig) EditTermCondDialogTest.setParamAndSave(fig, '55'));
            testCase.pushButton(editor.editTermCondParamsButton);

            testCase.verifyEmpty(testCase.fixture.errors(), ...
                strjoin(testCase.fixture.errors(), newline));
            conds = evt.getAllTermConds();
            testCase.verifyEqual(numel(conds), 2, 'Editing must not add or remove conditions.');
            testCase.verifyClass(conds(1), 'EventDurationTermCondition');
            testCase.verifyEqual(conds(1).getTermCondUiStruct().value, 100, 'AbsTol', 1e-9, ...
                'The unselected condition must be untouched.');
            testCase.verifyClass(conds(2), 'AltitudeTermCondition');
            testCase.verifyEqual(conds(2).getTermCondUiStruct().value, 55, 'AbsTol', 1e-9, ...
                'The value saved in the nested dialog must land on the selected condition.');
        end
    end

    methods(Access=private)
        function evt = durationFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);
        end

        function app = openDialog(testCase, evt)
            app = lvd_editEvtTermCond_App(evt);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EditTermCondDialogTest.deleteIfValid(app));
        end

        function editor = openEventEditor(testCase, evt)
            out = AppDesignerGUIOutput({false});
            editor = lvd_editEventGUI_App(evt, false, out);
            drawnow;
            testCase.assertTrue(~isempty(editor), 'The event editor constructor returned nothing.');
            testCase.addTeardown(@() EditTermCondDialogTest.deleteIfValid(editor));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            %closeAlerts Dismisses msgbox/uialert figures while sparing the
            %termination condition dialog and any event editor under test.
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if ~isvalid(figs(i))
                    continue;
                end
                nm = figs(i).Name;
                if strcmp(nm, 'Edit Termination Condition') || startsWith(nm, 'Edit Event')
                    continue;
                end
                try %#ok<TRYNC>
                    close(figs(i));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Termination Condition')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function setParamAndSave(fig, valueStr)
            %setParamAndSave whenShown player for the nested termination
            %condition dialog: types the parameter and presses Save & Close.
            %The dialog stores its GUIDE handles with guidata (see its
            %OpeningFcn), with a Tag lookup as fallback.
            h = guidata(fig);
            if isstruct(h) && isfield(h, 'numParamText')
                set(h.numParamText, 'String', valueStr);
            else
                set(findall(fig, 'Tag', 'numParamText'), 'String', valueStr);
            end
            UiwaitInterceptorFixture.pushButton(fig, 'Save & Close');
            drawnow;
        end
    end
end
