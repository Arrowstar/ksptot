classdef ViewSettingsDialogTest < KsptotTestCase
    %ViewSettingsDialogTest Full round-trip UI tests for the view settings
    %dialog (Phase 5: root/misc UIs; upgrades the main-GUI smoke press and
    %the LvdColorPickerBulkTest picker coverage to a profile-level suite).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/view/lvd_viewSettingsGUI_App.mlapp
    %   (GUIDE-migrated; ctor is lvd_viewSettingsGUI_App(viewSettings))
    %   main-GUI caller: editViewSettingsMenu_Callback (Edit menu) wraps it
    %   in an undo state.  Profile access mirrors
    %   ViewProfilePlottingOptionsTest (lvdData.viewSettings.selViewProfile,
    %   getProfilesArray).  Checkbox callbacks write live to the selected
    %   profile; Save & Close only closes the figure.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The GUIDE-migrated callbacks read
    %   event.Source, so checkboxes/listboxes are set and then fired through
    %   their ValueChangedFcn and buttons through ButtonPushedFcn with
    %   minimal event structs (the TankConstraintDialogTest pattern).  The
    %   frame-picker button is never pressed (it opens a blocking editor).
    %   There is no Cancel button: window-X is the cancel path.
    %
    % COVERED
    %   Open shows the stored profile; SoI and sun-lighting toggles write
    %   live; selecting another profile retargets the edits; add/remove
    %   round-trips the profile set; Save & Close keeps the edits and
    %   closes; window-X preserves the profile.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredProfile(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.viewSettings.selViewProfile.name = 'Default Profile';
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.lvd_viewSettingsGUI.Name, 'View Settings');
            testCase.verifyTrue(any(contains(string(app.viewProfilesListbox.Items), 'Default Profile')), ...
                'The stored profile must be listed.');
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyTrue(contains(string(get(handles.nameText, 'String')), 'Default Profile'), ...
                'The name field must show the selected profile.');
        end

        function toggleSoIWritesLiveToProfile(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            profile = lvdData.viewSettings.selViewProfile;
            testCase.assertFalse(profile.showSoIRadius, 'Fixture: SoI starts hidden.');
            app = testCase.openDialog(lvdData);

            app.showSoICheckbox.Value = true;
            testCase.fireValueChanged(app.showSoICheckbox);

            testCase.verifyTrue(profile.showSoIRadius, 'The SoI toggle must write live to the profile.');
        end

        function toggleSunLightingWritesLiveToProfile(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            profile = lvdData.viewSettings.selViewProfile;
            app = testCase.openDialog(lvdData);

            app.showSunLightingCheckbox.Value = ~profile.showLighting;
            testCase.fireValueChanged(app.showSunLightingCheckbox);

            testCase.verifyEqual(profile.showLighting, app.showSunLightingCheckbox.Value, ...
                'The lighting toggle must write live to the profile.');
        end

        function selectingAnotherProfileSwitchesEditedTarget(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            testCase.pushButton(app.addViewProfileButton);
            profiles = lvdData.viewSettings.getProfilesArray();
            testCase.assertEqual(numel(profiles), 2, 'Fixture: a second profile must be added.');
            testCase.assertFalse(profiles(2).showSoIRadius);

            testCase.selectProfileByIndex(app, 2);
            app.showSoICheckbox.Value = true;
            testCase.fireValueChanged(app.showSoICheckbox);

            testCase.verifyTrue(profiles(2).showSoIRadius, 'The selected profile must take the edit.');
            testCase.verifyFalse(profiles(1).showSoIRadius, 'The other profile must be untouched.');
        end

        function addAndRemoveProfileRoundTrip(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.pushButton(app.addViewProfileButton);
            testCase.verifyEqual(numel(lvdData.viewSettings.getProfilesArray()), 2, ...
                'Add must append a view profile.');
            testCase.verifyEqual(numel(app.viewProfilesListbox.Items), 2, 'The list must refresh.');

            testCase.selectProfileByIndex(app, 2);
            testCase.pushButton(app.removeViewProfileButton);

            testCase.verifyEqual(numel(lvdData.viewSettings.getProfilesArray()), 1, ...
                'Remove must drop the selected profile.');
            testCase.verifyEqual(numel(app.viewProfilesListbox.Items), 1);
            testCase.verifyTrue(isvalid(app.lvd_viewSettingsGUI));
        end

        function saveAndCloseKeepsEdits(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            profile = lvdData.viewSettings.selViewProfile;
            app = testCase.openDialog(lvdData);
            fig = app.lvd_viewSettingsGUI;

            app.showSoICheckbox.Value = true;
            testCase.fireValueChanged(app.showSoICheckbox);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(profile.showSoIRadius, 'Save & Close must keep the live edits.');
        end

        function windowXPreservesProfile(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            profile = lvdData.viewSettings.selViewProfile;
            app = testCase.openDialog(lvdData);
            fig = app.lvd_viewSettingsGUI;

            app.showSoICheckbox.Value = true;
            close(fig);
            drawnow;

            testCase.verifyFalse(profile.showSoIRadius, 'Window X must leave the profile alone.');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, lvdData)
            app = lvd_viewSettingsGUI_App(lvdData.viewSettings);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.lvd_viewSettingsGUI), ...
                'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ViewSettingsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireValueChanged(~, ctrl)
            %The redirect strategy reads event.Value (checkboxes and
            %listboxes alike); include it plus a PreviousValue.
            if islogical(ctrl.Value)
                prev = ~ctrl.Value;
            else
                prev = [];
            end
            evt = struct('Source', ctrl, 'Value', ctrl.Value, ...
                'PreviousValue', prev, 'EventName', 'ValueChanged');
            ctrl.ValueChangedFcn(ctrl, evt);
            drawnow;
        end

        function selectProfileByIndex(testCase, app, ind)
            %Single-select string listbox: assign the item, not the index.
            items = cellstr(app.viewProfilesListbox.Items);
            app.viewProfilesListbox.Value = items{ind};
            testCase.fireValueChanged(app.viewProfilesListbox);
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'View Settings')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
