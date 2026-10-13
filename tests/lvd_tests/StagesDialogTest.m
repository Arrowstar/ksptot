classdef StagesDialogTest < KsptotTestCase
    %StagesDialogTest Full round-trip UI tests for the stages set editor
    %(Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditStagesGUI_App.mlapp
    %   ('Edit Stages'; single-arg ctor (lvdData), no output arg -- Add /
    %   Remove / Move Up / Move Down write straight into
    %   lvdData.launchVehicle and Close just closes).  Add opens the
    %   single-stage editor (lvd_EditStageGUI_App) for a new stage and only
    %   keeps it on Save & Close.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The nested single-stage
    %   editor is stubbed with whenShown handlers and the fixture error log
    %   is asserted empty.
    %
    % COVERED
    %   Open lists the stored stages and disables Remove for the last one;
    %   Add with a nested Save appends the stage (and enables Remove) while
    %   Add with a nested Cancel adds nothing; Remove drops the selected
    %   stage; Move Up / Move Down reorder the stages and keep the
    %   selection; Close preserves the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredStagesAndDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stage = lvdData.launchVehicle.stages(1);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.stagesListbox.Items(:), {'First Stage'}, ...
                'The list must mirror the vehicle''s stages.');
            testCase.verifyEqual(numel(app.stagesListbox.ItemsData), 1);
            testCase.verifyTrue(app.stagesListbox.ItemsData(1) == stage);
            testCase.verifyTrue(testCase.isOff(app.removeStageButton), ...
                'The last stage cannot be removed.');
        end

        function addStageViaSaveAppendsStage(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Stage', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.addStageButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Stage'), 'Add must open the single-stage editor.');
            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(stages), 2, 'A nested Save must keep the new stage.');
            testCase.verifyEqual(app.stagesListbox.Items(:), {'First Stage'; 'Untitled Stage'});
            testCase.verifyEqual(numel(lvdData.initStateModel.stageStates), 2, ...
                'Add must wire a stage state for the new stage.');
            testCase.verifyFalse(testCase.isOff(app.removeStageButton), ...
                'Remove must enable once two stages exist.');
        end

        function addStageViaCancelAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Stage', @(fig) recordAndPush(fig, seen, 'Cancel'));
            testCase.pushButton(app.addStageButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Stage'));
            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(stages), 1, 'A nested Cancel must drop the new stage.');
            testCase.verifyEqual(app.stagesListbox.Items(:), {'First Stage'});
            testCase.verifyTrue(testCase.isOff(app.removeStageButton));
        end

        function removeAddedStage(testCase)
            [lvdData, second] = testCase.twoStageFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.stagesListbox.Value = second;
            testCase.pushButton(app.removeStageButton);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(stages), 1, 'Remove must drop the selected stage.');
            testCase.verifyEqual(app.stagesListbox.Items(:), {'First Stage'});
            testCase.verifyEqual(numel(lvdData.initStateModel.stageStates), 1, ...
                'Remove must drop the removed stage''s state.');
            testCase.verifyTrue(testCase.isOff(app.removeStageButton), ...
                'Remove must disable again at one stage.');
            testCase.verifyTrue(isvalid(handles.lvd_EditStagesGUI), ...
                'Removing must leave the editor open.');
        end

        function moveStageUpReordersAndKeepsSelection(testCase)
            [lvdData, second] = testCase.twoStageFixture();
            app = testCase.openDialog(lvdData);

            app.stagesListbox.Value = second;
            testCase.pushButton(app.moveStageUpButton);

            testCase.verifyEqual({lvdData.launchVehicle.stages.name}, {'Second Stage', 'First Stage'}, ...
                'Move Up must swap the stage with its predecessor.');
            testCase.verifyEqual(app.stagesListbox.Items(:), {'Second Stage'; 'First Stage'});
            testCase.verifyTrue(app.stagesListbox.Value == second, ...
                'The moved stage must stay selected.');
        end

        function moveStageDownReordersAndKeepsSelection(testCase)
            [lvdData, ~] = testCase.twoStageFixture();
            first = lvdData.launchVehicle.stages(1);
            app = testCase.openDialog(lvdData);

            app.stagesListbox.Value = first;
            testCase.pushButton(app.moveStageDownButton);

            testCase.verifyEqual({lvdData.launchVehicle.stages.name}, {'Second Stage', 'First Stage'}, ...
                'Move Down must swap the stage with its successor.');
            testCase.verifyEqual(app.stagesListbox.Items(:), {'Second Stage'; 'First Stage'});
            testCase.verifyTrue(app.stagesListbox.Value == first, ...
                'The moved stage must stay selected.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStagesGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(stages), 1, 'Close must leave the model alone.');
        end
    end

    methods(Access=private)
        function [lvdData, second] = twoStageFixture(testCase)
            %A second stage built exactly the way the Add button builds one
            %(stage plus its stage state), so removal and reordering are
            %exercised on a fully wired object.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            second = LaunchVehicleStage(lvdData.launchVehicle);
            second.name = 'Second Stage';
            lvdData.launchVehicle.addStage(second);
            lvdData.initStateModel.addStageState(LaunchVehicleStageState(second));
        end

        function app = openDialog(testCase, lvdData)
            %The stages editor takes only lvdData (no output arg).
            app = lvd_EditStagesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StagesDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Stages')
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
