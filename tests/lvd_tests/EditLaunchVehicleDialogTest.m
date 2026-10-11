classdef EditLaunchVehicleDialogTest < KsptotTestCase
    %EditLaunchVehicleDialogTest Full round-trip UI tests for the top-level
    %vehicle configuration editor (Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_editLaunchVehicle_App.mlapp
    %   ('Edit Vehicle Configuration'; single-arg ctor (lvdData), no output
    %   arg -- the sub-editors write straight into lvdData.launchVehicle and
    %   the summary text is refreshed from lv.getLvSummaryStr() on return).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  Nested sub-editors are
    %   set-editors with Close (not Cancel) buttons; the whenShown handlers
    %   below use the dialogs' exact figure Names (which differ from some
    %   on-canvas labels, e.g. 'Edit Engine To Tank Connections') and press
    %   Close (or mutate the model and then Close), and the fixture error
    %   log is asserted empty.  The Import button is never pressed
    %   (uigetfile).  Every nested figure must be dismissed: MathWorks'
    %   convertToGUIDECallbackArguments resolves handles through the FIRST
    %   open figure, so a leaked figure poisons all later handles lookups.
    %
    % COVERED
    %   Open shows the stored stage/engine/tank names and mass totals; the
    %   stages/engines/tanks/connections/fluid-type buttons open their
    %   nested editors; edits made while a nested editor is open refresh the
    %   summary text; Close and window-X preserve the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredVehicleSummary(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            summ = testCase.summaryText(handles);
            testCase.verifyTrue(contains(summ, 'Launch Vehicle Configuration Summary'));
            testCase.verifyTrue(contains(summ, 'First Stage'));
            testCase.verifyTrue(contains(summ, 'First Stage Engine'));
            testCase.verifyTrue(contains(summ, 'First Stage Tank'));
            testCase.verifyTrue(contains(summ, 'Dry Mass = 2.000 mT, Prop Mass = 4.000 mT, Total = 6.000 mT'), ...
                'The stock vehicle is 2 mT dry plus 4 mT of propellant.');
        end

        function stagesEnginesAndTanksButtonsOpenNestedEditors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Stages', @(fig) recordAndPush(fig, seen, 'Close'));
            testCase.fixture.whenShown('Edit Engines', @(fig) recordAndPush(fig, seen, 'Close'));
            testCase.fixture.whenShown('Edit Tanks', @(fig) recordAndPush(fig, seen, 'Close'));

            testCase.pushButton(app.editStagesButton);
            testCase.pushButton(app.editEnginesButton);
            testCase.pushButton(app.editTanksButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Stages'), 'Stages button must open the stages editor.');
            testCase.verifyTrue(seen.isKey('Edit Engines'), 'Engines button must open the engines editor.');
            testCase.verifyTrue(seen.isKey('Edit Tanks'), 'Tanks button must open the tanks editor.');
            testCase.verifyTrue(isvalid(handles.lvd_editLaunchVehicle), ...
                'Dismissing nested editors must leave the vehicle editor open.');
        end

        function connsAndFluidTypesButtonsOpenNestedEditors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Engine To Tank Connections', @(fig) recordAndPush(fig, seen, 'Close'));
            testCase.fixture.whenShown('Edit Tank To Tank Connections', @(fig) recordAndPush(fig, seen, 'Close'));
            testCase.fixture.whenShown('Edit Tank Fluid Types', @(fig) recordAndPush(fig, seen, 'Close'));

            testCase.pushButton(app.editEngineToTankConnsButton);
            testCase.pushButton(app.editTankToTankConnsButton);
            testCase.pushButton(app.editTankFluidTypesButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Engine To Tank Connections'));
            testCase.verifyTrue(seen.isKey('Edit Tank To Tank Connections'));
            testCase.verifyTrue(seen.isKey('Edit Tank Fluid Types'));
            testCase.verifyTrue(isvalid(handles.lvd_editLaunchVehicle));
        end

        function nestedEditsRefreshTheSummary(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            %A nested edit that writes the model (here: a new stage) must be
            %visible in the summary once the sub-editor returns.
            testCase.fixture.whenShown('Edit Stages', @(fig) addStageAndCancel(fig, lvdData));
            testCase.pushButton(app.editStagesButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(contains(testCase.summaryText(handles), 'Extra Stage'), ...
                'The summary must refresh after a nested editor writes the model.');
        end

        function closeButtonClosesAndPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            before = lvdData.launchVehicle.getLvSummaryStr();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editLaunchVehicle;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(lvdData.launchVehicle.getLvSummaryStr(), before, ...
                'Close must leave the model alone.');
        end

        function windowXClosePreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editLaunchVehicle;

            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyEqual(numel(lvdData.launchVehicle.stages), 1);
            testCase.verifyEqual(numel(lvdData.launchVehicle.stages(1).engines), 1);
            testCase.verifyEqual(numel(lvdData.launchVehicle.stages(1).tanks), 1);
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, lvdData)
            %The vehicle editor takes only lvdData (no output arg).
            app = lvd_editLaunchVehicle_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EditLaunchVehicleDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function summ = summaryText(~, handles)
            summ = strjoin(cellstr(get(handles.lvSummaryText, 'String')), newline);
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Vehicle Configuration')
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

function addStageAndCancel(fig, lvdData)
    stg = LaunchVehicleStage(lvdData.launchVehicle);
    stg.name = 'Extra Stage';
    lvdData.launchVehicle.addStage(stg);
    UiwaitInterceptorFixture.pushButton(fig, 'Close');
end
