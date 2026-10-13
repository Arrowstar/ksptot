classdef MissionNotesDialogTest < KsptotTestCase
    %MissionNotesDialogTest Full round-trip UI tests for the mission notes
    %dialog (Phase 5: root/misc UIs; upgrades the main-GUI smoke press to
    %a value-level suite).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/lvd_MissionNotesGUI_App.mlapp
    %   (GUIDE-migrated; ctor is lvd_MissionNotesGUI_App(lvdData))
    %   main-GUI caller: editMissionNotesMenu_Callback (Edit menu) wraps it
    %   in an undo state; the dialog writes lvdData.notes on Save & Close.
    %
    % PATTERN
    %   The dialog does not block in uiwait, so no fixture is strictly
    %   needed; UiwaitInterceptorFixture is applied for uniformity.  The
    %   GUIDE-migrated callbacks read event.Source, so buttons are fired
    %   through ButtonPushedFcn with a minimal event struct and text is
    %   driven through the handles adapters from
    %   convertToGUIDECallbackArguments (the TankConstraintDialogTest
    %   pattern).  There is no Cancel button: window-X is the cancel path.
    %
    % COVERED
    %   Open shows the stored notes; Save & Close writes edited (and empty)
    %   notes back to the mission; a save round-trips through a reopen;
    %   window-X preserves the notes; the expected controls exist.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredNotes(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = sprintf('First line.\nSecond line.');
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            shown = strjoin(cellstr(get(handles.missionNotesText, 'String')), newline);
            testCase.verifyTrue(contains(shown, 'First line.'), 'Stored notes must be shown.');
            testCase.verifyTrue(contains(shown, 'Second line.'));
        end

        function saveAndCloseWritesNotes(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = 'Original notes.';
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = app.lvd_MissionNotesGUI;

            set(handles.missionNotesText, 'String', 'Edited mission note.');
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            saved = strjoin(cellstr(lvdData.notes), newline);
            testCase.verifyTrue(contains(saved, 'Edited mission note.'), ...
                'Save & Close must write the notes to the mission.');
        end

        function saveEmptyNotesClearsMission(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = 'Something to clear.';
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.missionNotesText, 'String', '');
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(isempty(strjoin(cellstr(lvdData.notes), newline)), ...
                'Saving empty notes must clear the mission notes.');
        end

        function savedNotesRoundTripThroughReopen(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            set(handles.missionNotesText, 'String', 'Round trip note.');
            testCase.pushButton(app.saveCloseButton);

            app2 = testCase.openDialog(lvdData);
            [~, ~, handles2] = convertToGUIDECallbackArguments(app2);
            shown = strjoin(cellstr(get(handles2.missionNotesText, 'String')), newline);

            testCase.verifyTrue(contains(shown, 'Round trip note.'), ...
                'A reopen must show the saved notes.');
        end

        function windowXPreservesNotes(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.notes = 'Keep me.';
            app = testCase.openDialog(lvdData);
            fig = app.lvd_MissionNotesGUI;

            app.missionNotesText.Value = {'Changed without saving.'};
            close(fig);
            drawnow;

            testCase.verifyEqual(lvdData.notes, 'Keep me.', 'Window X must leave the notes alone.');
        end

        function dialogExposesExpectedControls(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.lvd_MissionNotesGUI.Name, 'Mission Notes');
            testCase.verifyEqual(app.MissionNotesPanel.Title, 'Mission Notes');
            testCase.verifyEqual(app.saveCloseButton.Text, 'Save & Close');
            testCase.verifyEqual(app.lvd_MissionNotesGUI.WindowStyle, 'modal');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, lvdData)
            app = lvd_MissionNotesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.lvd_MissionNotesGUI), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() MissionNotesDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Mission Notes')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
