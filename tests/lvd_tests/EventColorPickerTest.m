classdef EventColorPickerTest < matlab.uitest.TestCase
    %EventColorPickerTest Free RGB colors for LVD segments/events.
    %
    % Covers the event-only pilot slice: EventColorLineSpec stores a 1x3
    % RGB double (legacy ColorSpecEnum values migrate via loadobj), all
    % renderers read through lvd_colorSpecToRGB, and lvd_editEventGUI_App
    % (the only UI changed in this slice) offers a "Choose..." button +
    % swatch backed by uisetcolor instead of the fixed-list dropdown.
    %
    % The modal uisetcolor dialog cannot be clicked in automation, so the
    % dialog seam-injects its picker through the eventColorPickerFcn
    % appdata (default @uisetcolor); tests stub it with a function handle
    % returning a known RGB, 0 (cancel), or garbage. Buttons are driven
    % with App Testing Framework gestures (press); the dialog blocks in
    % uiwait, so UiwaitInterceptorFixture stands in for uiwait.

    properties(Access = private)
        celBodyData
        fixture UiwaitInterceptorFixture
        figuresBefore
    end

    methods(TestClassSetup)
        function loadBodies(testCase)
            testCase.celBodyData = ksptotTestBodyData();
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)
        %% ------------------------------------------------ model + helpers

        function newEventColorDefaultsToRedRGB(testCase)
            spec = EventColorLineSpec();
            testCase.verifyEqual(spec.color, [1, 0, 0], 'AbsTol', 1e-12);
        end

        function palettePreservesLegacyOrder(testCase)
            p = lvd_defaultEventPalette();
            testCase.verifySize(p, [15, 3]);
            testCase.verifyTrue(all(p(:) >= 0 & p(:) <= 1));
            testCase.verifyEqual(p(1,:), [1, 0, 0], 'AbsTol', 1e-12, 'Row 1 stays Red.');
            testCase.verifyEqual(p(7,:), [0, 0, 1], 'AbsTol', 1e-12, 'Row 7 stays Blue.');
        end

        function converterAcceptsDoubleEnumAndStruct(testCase)
            testCase.verifyEqual(lvd_colorSpecToRGB([0.1, 0.5, 0.9]), [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
            testCase.verifyEqual(lvd_colorSpecToRGB(ColorSpecEnum.Blue), [0, 0, 1], 'AbsTol', 1e-12, ...
                'Legacy enum members unwrap to their RGB.');
            testCase.verifyEqual(lvd_colorSpecToRGB(struct('color', [0, 1, 0])), [0, 1, 0], 'AbsTol', 1e-12, ...
                'Struct-wrapped colors from old .mat files unwrap.');
            testCase.verifyError(@() lvd_colorSpecToRGB([2, 0, 0]), 'lvd_colorSpecToRGB:invalid');
            testCase.verifyError(@() lvd_colorSpecToRGB('red'), 'lvd_colorSpecToRGB:invalid');
        end

        function legacyStructMigratesThroughLoadobj(testCase)
            s = struct('color', ColorSpecEnum.Red, 'lineWidth', 2.0);
            obj = EventColorLineSpec.loadobj(s);
            testCase.verifyEqual(obj.color, [1, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.lineWidth, 2.0, 'Untouched fields survive migration.');
        end

        function newFormatSurvivesMatRoundTrip(testCase)
            spec = EventColorLineSpec();
            spec.color = [0.2, 0.4, 0.6];
            f = [tempname(), '.mat'];
            save(f, 'spec');
            clear('spec');
            loaded = load(f);
            delete(f);
            testCase.verifyEqual(loaded.spec.color, [0.2, 0.4, 0.6], 'AbsTol', 1e-12);
        end

        function arbitraryColorAppearsInHtmlListbox(testCase)
            evt = testCase.buildEvent();
            evt.colorLineSpec.color = [0.1, 0.5, 0.9];
            html = evt.getHtmlListboxStr();
            testCase.verifyTrue(contains(html, 'rgb(25.500,127.500,229.500)'), ...
                'The script list must show the picked color, not a palette name.');
        end

        function trajectoryDataStoresRgbRows(testCase)
            data = LaunchVehicleViewProfileTrajectoryData();
            data.addData([0; 1], [0, 0, 0; 1, 1, 1], [0.1, 0.5, 0.9]);
            testCase.verifyEqual(data.evtColors, [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
            data.addData([0; 1], [0, 0, 0; 1, 1, 1], ColorSpecEnum.Green);
            testCase.verifyEqual(data.evtColors(2,:), [76, 220, 0]/255, 'AbsTol', 1e-12, ...
                'Legacy enum inputs still convert on the way in.');
        end

        function groundTrackDataStoresRgbRows(testCase)
            data = LaunchVehicleViewProfileVehicleGrdTrkData();
            data.addData([0; 1], [0; 1], [0; 1], [100; 101], [0.1, 0.5, 0.9]);
            testCase.verifyEqual(data.evtColors, [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
        end

        %% ------------------------------------------------- the updated UI

        function dialogReplacesDropdownWithButtonAndSwatch(testCase)
            [app, evt] = testCase.openFor(testCase.buildEvent());
            fig = app.lvd_editEventGUI;

            btn = getappdata(fig, 'eventColorButton');
            sw = getappdata(fig, 'eventColorSwatch');
            testCase.verifyTrue(isa(btn, 'matlab.ui.control.Button') && all(isvalid(btn)), ...
                'A color button must be created at run time.');
            testCase.verifyEqual(btn.Text, 'Choose...');
            testCase.verifyEqual(sw.BackgroundColor, evt.colorLineSpec.color, 'AbsTol', 1e-12, ...
                'The swatch must preview the event''s stored color.');
            testCase.verifyFalse(isvalid(app.colorSpecCombo), ...
                'The fixed-list dropdown must be retired.');
        end

        function swatchShowsArbitraryEventColorOnOpen(testCase)
            evt = testCase.buildEvent();
            evt.colorLineSpec.color = [0.1, 0.5, 0.9];
            [app, ~] = testCase.openFor(evt);

            sw = getappdata(app.lvd_editEventGUI, 'eventColorSwatch');
            testCase.verifyEqual(sw.BackgroundColor, [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
            testCase.verifyEqual(getappdata(app.lvd_editEventGUI, 'eventColorRGB'), [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
        end

        function pickingColorUpdatesSwatchAndPendingState(testCase)
            [app, ~] = testCase.openFor(testCase.buildEvent());
            fig = app.lvd_editEventGUI;
            setappdata(fig, 'eventColorPickerFcn', @(cur, title) [0, 0, 1]);

            btn = getappdata(fig, 'eventColorButton');
            testCase.press(btn);

            testCase.verifyEqual(getappdata(fig, 'eventColorRGB'), [0, 0, 1], 'AbsTol', 1e-12);
            sw = getappdata(fig, 'eventColorSwatch');
            testCase.verifyEqual(sw.BackgroundColor, [0, 0, 1], 'AbsTol', 1e-12);
        end

        function saveAndCloseWritesPickedColor(testCase)
            [app, evt, out] = testCase.openFor(testCase.buildEvent());
            fig = app.lvd_editEventGUI;
            setappdata(fig, 'eventColorPickerFcn', @(cur, title) [0.2, 0.4, 0.6]);

            testCase.press(getappdata(fig, 'eventColorButton'));
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report a change.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the window.');
            testCase.verifyEqual(evt.colorLineSpec.color, [0.2, 0.4, 0.6], 'AbsTol', 1e-12);
        end

        function cancelledPickerKeepsOldColor(testCase)
            evt = testCase.buildEvent();
            evt.colorLineSpec.color = [0.1, 0.5, 0.9];
            [app, evt] = testCase.openFor(evt);
            fig = app.lvd_editEventGUI;
            setappdata(fig, 'eventColorPickerFcn', @(cur, title) 0);

            testCase.press(getappdata(fig, 'eventColorButton'));

            testCase.verifyEqual(getappdata(fig, 'eventColorRGB'), [0.1, 0.5, 0.9], 'AbsTol', 1e-12, ...
                'Cancelling uisetcolor (returns 0) must not touch the pending color.');
            testCase.press(app.saveAndCloseButton);
            testCase.verifyEqual(evt.colorLineSpec.color, [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
        end

        function invalidPickerOutputIsIgnored(testCase)
            [app, ~] = testCase.openFor(testCase.buildEvent());
            fig = app.lvd_editEventGUI;
            before = getappdata(fig, 'eventColorRGB');
            setappdata(fig, 'eventColorPickerFcn', @(cur, title) [2, 2, 2]);

            testCase.press(getappdata(fig, 'eventColorButton'));

            testCase.verifyEqual(getappdata(fig, 'eventColorRGB'), before, 'AbsTol', 1e-12, ...
                'Out-of-range picker output must be rejected.');
        end

        function pickerIsDisabledForNonSequentialEvents(testCase)
            [~, nonSeqEvt] = testCase.buildNonSeqEvent();
            app = testCase.openNonSeq(nonSeqEvt);

            btn = getappdata(app.lvd_editEventGUI, 'eventColorButton');
            testCase.verifyEqual(btn.Enable, matlab.lang.OnOffSwitchState.off, ...
                'Non-sequential events do not plot, so the picker stays off like the other style controls.');
        end

        function navigatingEventsKeepsASinglePicker(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(10);
            lvdData.script.addEvent(evt2);

            [app, ~, ~] = testCase.openFor(evt1);
            fig = app.lvd_editEventGUI;
            setappdata(fig, 'eventColorPickerFcn', @(cur, title) [0, 1, 0]);
            testCase.press(getappdata(fig, 'eventColorButton'));

            testCase.press(app.nextEventButton);

            testCase.verifyEqual(evt1.colorLineSpec.color, [0, 1, 0], 'AbsTol', 1e-12, ...
                'Moving to the next event must save the picked color first.');
            testCase.verifyTrue(isvalid(fig), 'Navigation must keep the dialog open.');
            testCase.verifyEqual(numel(findobj(fig, 'Tag', 'eventColorButton')), 1, ...
                'Repopulating the dialog must not duplicate the button.');
        end
    end

    methods(Access = private)
        function evt = buildEvent(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);
        end

        function [lvdData, nonSeqEvt] = buildNonSeqEvent(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            innerEvt = LaunchVehicleEvent(script);
            innerEvt.name = 'Non-seq';
            innerEvt.termCond = EventDurationTermCondition(300);

            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            script.nonSeqEvts.addEvent(nonSeqEvt);
        end

        function [app, evt, out] = openFor(testCase, evt)
            out = AppDesignerGUIOutput({false});
            app = lvd_editEventGUI_App(evt, false, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
        end

        function app = openNonSeq(testCase, nonSeqEvt)
            out = AppDesignerGUIOutput({false});
            app = lvd_editEventGUI_App(nonSeqEvt.evt, true, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
        end

        function closeNewFigures(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            delete(figs(isvalid(figs)));
        end
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        delete(h);
    end
end
