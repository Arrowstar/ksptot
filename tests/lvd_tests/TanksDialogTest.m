classdef TanksDialogTest < KsptotTestCase
    %TanksDialogTest Full round-trip UI tests for the tanks set editor
    %(Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditTanksGUI_App.mlapp
    %   ('Edit Tanks'; single-arg ctor (lvdData), no output arg -- Add /
    %   Remove write straight into lvdData.launchVehicle and Close just
    %   closes).  Add opens the single-tank editor (lvd_EditTankGUI_App) for
    %   a new tank and only keeps it on Save & Close.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The nested single-tank
    %   editor is stubbed with whenShown handlers and the fixture error log
    %   is asserted empty.
    %
    % COVERED
    %   Open lists the stored tanks and disables Remove for the last one;
    %   Add with a nested Save appends the tank (and enables Remove) while
    %   Add with a nested Cancel adds nothing; Remove drops the selected
    %   tank; Close and window-X preserve the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredTanksAndDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.tanksListBox.Items(:), {'First Stage Tank'}, ...
                'The list must mirror the vehicle''s tanks.');
            testCase.verifyEqual(numel(app.tanksListBox.ItemsData), 1);
            testCase.verifyTrue(app.tanksListBox.ItemsData(1) == tank);
            testCase.verifyTrue(testCase.isOff(app.removeTankButton), ...
                'The last tank cannot be removed.');
        end

        function addTankViaSaveAppendsTank(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Tank', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.addTankButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Tank'), 'Add must open the single-tank editor.');
            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 2, 'A nested Save must keep the new tank.');
            testCase.verifyEqual(app.tanksListBox.Items(:), {'First Stage Tank'; 'Untitled Tank'});
            testCase.verifyTrue(app.tanksListBox.Value == tanks(end), ...
                'The new tank must be selected.');
            testCase.verifyFalse(testCase.isOff(app.removeTankButton), ...
                'Remove must enable once two tanks exist.');
        end

        function addTankViaCancelAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Tank', @(fig) recordAndPush(fig, seen, 'Cancel'));
            testCase.pushButton(app.addTankButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Tank'));
            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 1, 'A nested Cancel must drop the new tank.');
            testCase.verifyEqual(app.tanksListBox.Items(:), {'First Stage Tank'});
            testCase.verifyTrue(testCase.isOff(app.removeTankButton));
        end

        function removeAddedTank(testCase)
            [lvdData, tank2] = testCase.twoTankFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.tanksListBox.Value = tank2;
            testCase.pushButton(app.removeTankButton);

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 1, 'Remove must drop the selected tank.');
            testCase.verifyEqual(app.tanksListBox.Items(:), {'First Stage Tank'});
            testCase.verifyTrue(testCase.isOff(app.removeTankButton), ...
                'Remove must disable again at one tank.');
            testCase.verifyTrue(isvalid(handles.lvd_EditTanksGUI), ...
                'Removing must leave the editor open.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTanksGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 1, 'Close must leave the model alone.');
        end

        function windowXClosePreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTanksGUI;

            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 1);
        end
    end

    methods(Access=private)
        function [lvdData, tank2] = twoTankFixture(testCase)
            %A second tank built exactly the way the Add button builds one
            %(tank plus its tank state), so removal is exercised on a fully
            %wired object.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 2;
            tank2.capacity = 2;
            stg.addTank(tank2);

            stageState = lvdData.initStateModel.stageStates(1);
            tankState = LaunchVehicleTankState(stageState);
            tankState.tank = tank2;
            tankState.tankMass = tank2.initialMass;
            stageState.addTankState(tankState);
        end

        function app = openDialog(testCase, lvdData)
            %The tanks editor takes only lvdData (no output arg).
            app = lvd_EditTanksGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TanksDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function tf = isOff(~, comp)
            tf = strcmpi(string(comp.Enable), 'off');
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Tanks')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function recordAndPush(fig, seen, buttonText)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, buttonText);
end
