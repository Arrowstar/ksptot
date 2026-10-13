classdef PwrStorageStateActionDialogTest < KsptotTestCase
    %PwrStorageStateActionDialogTest Full round-trip UI tests for the
    %power-storage state action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetPwrStorageStateGUI_App.mlapp
    %   backing class: SetPowerStorageActiveStateAction
    %   (opens via SetPowerStorageActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored storage/state; Save & Close writes the selected
    %   storage and state back; saving without changes round-trips; Cancel
    %   and window-X preserve the model; the storage dropdown mirrors the
    %   vehicle's power storages.  The dialog performs no validation, so
    %   there is no rejection case.
    %
    % FIXTURE
    %   The default LvdData carries no power storages (openEditActionUI
    %   guards that case with a warndlg), so two batteries are seeded onto
    %   stage 1, mirroring EventActionTest.buildEntryWithBattery.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.verifyEqual(get(handles.refPwrCompCombo, 'Value'), find(storages == action.storage, 1), ...
                'The storage dropdown must point at the stored storage.');
            testCase.verifyEqual(get(handles.stateCombo, 'Value'), 2, ...
                'The fixture stores Inactive, which must be shown.');
            strs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(strs{get(handles.stateCombo, 'Value')}, 'Inactive');
        end

        function refComboOffersEveryStorage(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refPwrCompCombo, 'String'))), numel(storages), ...
                'Every vehicle power storage must be offered.');
        end

        function saveAndCloseWritesRefAndState(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrStorageStateGUI;

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            otherInd = mod(find(storages == action.storage, 1), numel(storages)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.storage == storages(otherInd), 'Save must write the selected storage.');
            testCase.verifyTrue(action.activeStateToSet, 'Save must write the selected state.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData] = testCase.fixture();
            storageBefore = action.storage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrStorageStateGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.storage == storageBefore, 'An unchanged save must keep the storage.');
            testCase.verifyFalse(action.activeStateToSet, 'An unchanged save must keep the state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            storageBefore = action.storage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrStorageStateGUI;

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            otherInd = mod(find(storages == action.storage, 1), numel(storages)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.storage == storageBefore, 'Cancel must leave the storage alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            storageBefore = action.storage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrStorageStateGUI;

            set(handles.stateCombo, 'Value', 1);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.storage == storageBefore, 'Window-X must leave the storage alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Window-X must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            bat1 = LaunchVehicleBasicElectricalBattery(stg);
            bat1.name = 'Test Battery 1';
            bat1.maxCapacity = 100;
            bat1.initialStateOfCharge = 37;
            stg.addPwrStorage(bat1);
            bat2 = LaunchVehicleBasicElectricalBattery(stg);
            bat2.name = 'Test Battery 2';
            bat2.maxCapacity = 100;
            bat2.initialStateOfCharge = 63;
            stg.addPwrStorage(bat2);

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.assertGreaterThanOrEqual(numel(storages), 2, 'Fixture must seed two power storages.');
            action = SetPowerStorageActiveStateAction(bat1, false);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetPwrStorageStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PwrStorageStateActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Action')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Action')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
