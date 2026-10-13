classdef EnginesDialogTest < KsptotTestCase
    %EnginesDialogTest Full round-trip UI tests for the engines set editor
    %(Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditEnginesGUI_App.mlapp
    %   ('Edit Engines'; single-arg ctor (lvdData), no output arg -- Add /
    %   Remove write straight into lvdData.launchVehicle and Close just
    %   closes).  Add opens the single-engine editor (lvd_EditEngineGUI_App)
    %   for a new engine and only keeps it on Save & Close.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The nested single-engine
    %   editor is stubbed with whenShown handlers and the fixture error log
    %   is asserted empty.
    %
    % COVERED
    %   Open lists the stored engines and disables Remove for the last one;
    %   Add with a nested Save appends the engine (and enables Remove) while
    %   Add with a nested Cancel adds nothing; Remove drops the selected
    %   engine; Close and window-X preserve the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredEnginesAndDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            engine = lvdData.launchVehicle.stages(1).engines(1);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.enginesListBox.Items(:), {'First Stage Engine'}, ...
                'The list must mirror the vehicle''s engines.');
            testCase.verifyEqual(numel(app.enginesListBox.ItemsData), 1);
            testCase.verifyTrue(app.enginesListBox.ItemsData(1) == engine);
            testCase.verifyTrue(testCase.isOff(app.removeEngineButton), ...
                'The last engine cannot be removed.');
        end

        function addEngineViaSaveAppendsEngine(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Engine', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.addEngineButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Engine'), 'Add must open the single-engine editor.');
            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
            testCase.verifyEqual(numel(engines), 2, 'A nested Save must keep the new engine.');
            testCase.verifyEqual(app.enginesListBox.Items(:), {'First Stage Engine'; 'Untitled Engine'});
            testCase.verifyFalse(testCase.isOff(app.removeEngineButton), ...
                'Remove must enable once two engines exist.');
        end

        function addEngineViaCancelAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Engine', @(fig) recordAndPush(fig, seen, 'Cancel'));
            testCase.pushButton(app.addEngineButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Engine'));
            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
            testCase.verifyEqual(numel(engines), 1, 'A nested Cancel must drop the new engine.');
            testCase.verifyEqual(app.enginesListBox.Items(:), {'First Stage Engine'});
            testCase.verifyTrue(testCase.isOff(app.removeEngineButton));
        end

        function removeAddedEngine(testCase)
            [lvdData, engine2] = testCase.twoEngineFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.enginesListBox.Value = engine2;
            testCase.pushButton(app.removeEngineButton);

            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
            testCase.verifyEqual(numel(engines), 1, 'Remove must drop the selected engine.');
            testCase.verifyEqual(app.enginesListBox.Items(:), {'First Stage Engine'});
            testCase.verifyTrue(testCase.isOff(app.removeEngineButton), ...
                'Remove must disable again at one engine.');
            testCase.verifyTrue(isvalid(handles.lvd_EditEnginesGUI), ...
                'Removing must leave the editor open.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEnginesGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
            testCase.verifyEqual(numel(engines), 1, 'Close must leave the model alone.');
        end

        function windowXClosePreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEnginesGUI;

            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
            testCase.verifyEqual(numel(engines), 1);
        end
    end

    methods(Access=private)
        function [lvdData, engine2] = twoEngineFixture(testCase)
            %A second engine built exactly the way the Add button builds
            %one (engine plus its engine state), so removal is exercised on
            %a fully wired object.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            engine2 = LaunchVehicleEngine(stg);
            engine2.name = 'Second Engine';
            stg.addEngine(engine2);

            stageState = lvdData.initStateModel.stageStates(1);
            engineState = LaunchVehicleEngineState(stageState);
            engineState.engine = engine2;
            stageState.addEngineState(engineState);
        end

        function app = openDialog(testCase, lvdData)
            %The engines editor takes only lvdData (no output arg).
            app = lvd_EditEnginesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EnginesDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Engines')
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
