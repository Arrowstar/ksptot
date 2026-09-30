classdef EngineMixtureDialogTest < matlab.unittest.TestCase
    %EngineMixtureDialogTest Timer-driven coverage of the two programmatic
    %propulsion editors (lvd_EditE2TPriorityGUI_App,
    %lvd_EditEngineMixtureGUI_App).
    %
    % The dialogs block in uiwait during construction; each test arms a
    % single-shot timer that fills the fields and presses a button while
    % the dialog is waiting (timer callbacks run during uiwait).  A
    % watchdog timer bounds every test: if the dialog never closes, the
    % watchdog deletes it so uiwait returns instead of hanging the suite.
    % Tests assume away when no graphics device is available (headless CI).

    properties(Constant)
        DRIVE_DELAY_S = 1.5;
        WATCHDOG_DELAY_S = 25;
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            ksptotAddProjectPaths();
            testCase.assumeGraphicsAvailable();

            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end
        end
    end

    methods(TestMethodSetup)
        function snapshotFigures(testCase)
            testCase.addTeardown(@() testCase.closeTagFigures());
        end
    end

    methods(Test)
        function prioritySaveWritesValues(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            conn = lvdData.launchVehicle.engineTankConns(1);

            output = testCase.drivePriorityDialog(conn, @() testCase.pushPrioritySave('2', '0.5'));

            testCase.verifyTrue(output.output{1}, 'Save must report success');
            testCase.verifyEqual(conn.priority, 2, 'saved priority sticks');
            testCase.verifyEqual(conn.flowWeight, 0.5, 'saved weight sticks');
        end

        function priorityBlankWeightMeansEven(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            conn = lvdData.launchVehicle.engineTankConns(1);
            conn.flowWeight = 3;

            output = testCase.drivePriorityDialog(conn, @() testCase.pushPrioritySave('0', ''));

            testCase.verifyTrue(output.output{1}, 'Save must report success');
            testCase.verifyTrue(isnan(conn.flowWeight), 'blank weight saves as NaN (even)');
            testCase.verifyEqual(conn.getEffectiveWeight(), 1, 'blank resolves to 1');
        end

        function priorityInvalidWeightRejectsAndLeavesUntouched(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            conn = lvdData.launchVehicle.engineTankConns(1);

            output = testCase.drivePriorityDialog(conn, @() testCase.pushPrioritySaveThenCancel('1', '-4'));

            testCase.verifyFalse(output.output{1}, 'rejected save must report failure');
            testCase.verifyEqual(conn.priority, 0, 'rejected edit must not touch priority');
            testCase.verifyTrue(isnan(conn.flowWeight), 'rejected edit must not touch weight');
        end

        function priorityCancelLeavesUntouched(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            conn = lvdData.launchVehicle.engineTankConns(1);

            output = testCase.drivePriorityDialog(conn, @() testCase.pushPriorityCancel());

            testCase.verifyFalse(output.output{1}, 'Cancel must report failure');
            testCase.verifyEqual(conn.priority, 0, 'cancel must not touch priority');
        end

        function mixtureSaveWritesMixture(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            lv = lvdData.launchVehicle;
            engine = lv.stages(1).engines(1);
            t1 = lv.tankTypes.getTypeForInd(1);
            t2 = lv.tankTypes.getTypeForInd(2);

            output = testCase.driveMixtureDialog(engine, @() testCase.pushMixtureSave({t1.name, 0.25; t2.name, 0.75}));

            testCase.verifyTrue(output.output{1}, 'Save must report success');
            testCase.verifyTrue(engine.hasCustomMixture(), 'saved mixture sticks');
            testCase.verifyEqual(engine.mixtureFractions, [0.25, 0.75], 'AbsTol', 1e-15, 'saved fractions stick');
        end

        function mixtureInvalidSumRejectsAndLeavesUntouched(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            lv = lvdData.launchVehicle;
            engine = lv.stages(1).engines(1);
            t1 = lv.tankTypes.getTypeForInd(1);

            output = testCase.driveMixtureDialog(engine, @() testCase.pushMixtureSaveThenCancel({t1.name, 0.5}));

            testCase.verifyFalse(output.output{1}, 'bad-sum save must report failure');
            testCase.verifyFalse(engine.hasCustomMixture(), 'rejected edit must not create a mixture');
        end

        function mixtureLegacyButtonClears(testCase)
            lvdData = LvdData.getDefaultLvdData(ksptotTestBodyData());
            lv = lvdData.launchVehicle;
            engine = lv.stages(1).engines(1);
            t1 = lv.tankTypes.getTypeForInd(1);
            t2 = lv.tankTypes.getTypeForInd(2);
            engine.setMixture([t1, t2], [0.5, 0.5]);

            output = testCase.driveMixtureDialog(engine, @() testCase.pushMixtureLegacy());

            testCase.verifyTrue(output.output{1}, 'Legacy must report success');
            testCase.verifyFalse(engine.hasCustomMixture(), 'Legacy clears back to the single pool');
        end
    end

    methods(Access=private)
        function assumeGraphicsAvailable(testCase)
            ok = true;
            try
                f = uifigure('Visible', 'off');
                close(f);
            catch
                ok = false;
            end
            testCase.assumeTrue(ok, 'No graphics device: skipping programmatic dialog tests.');
        end

        function closeTagFigures(~)
            for(tag = {'lvd_EditE2TPriorityGUI', 'lvd_EditEngineMixtureGUI'})
                figs = findall(groot, 'Type', 'figure', 'Tag', tag{1});
                for(i=1:length(figs))
                    try
                        delete(figs(i));
                    catch
                    end
                end
            end
        end

        function output = drivePriorityDialog(testCase, conn, driveFcn)
            output = AppDesignerGUIOutput({false});
            watchdog = timer('StartDelay', testCase.WATCHDOG_DELAY_S, 'ExecutionMode', 'singleShot', ...
                'TimerFcn', @(~,~) testCase.closeTagFigures());
            driver = timer('StartDelay', testCase.DRIVE_DELAY_S, 'ExecutionMode', 'singleShot', ...
                'TimerFcn', @(~,~) driveFcn());
            start(watchdog);
            start(driver);
            cleanup = onCleanup(@() testCase.deleteTimers(watchdog, driver));
            lvd_EditE2TPriorityGUI_App(conn, output);
        end

        function output = driveMixtureDialog(testCase, engine, driveFcn)
            output = AppDesignerGUIOutput({false});
            watchdog = timer('StartDelay', testCase.WATCHDOG_DELAY_S, 'ExecutionMode', 'singleShot', ...
                'TimerFcn', @(~,~) testCase.closeTagFigures());
            driver = timer('StartDelay', testCase.DRIVE_DELAY_S, 'ExecutionMode', 'singleShot', ...
                'TimerFcn', @(~,~) driveFcn());
            start(watchdog);
            start(driver);
            cleanup = onCleanup(@() testCase.deleteTimers(watchdog, driver));
            lvd_EditEngineMixtureGUI_App(engine, output);
        end

        function deleteTimers(~, varargin)
            for(i=1:nargin-1)
                try
                    stop(varargin{i});
                catch
                end
                try
                    delete(varargin{i});
                catch
                end
            end
        end

        function app = findDialogApp(~, tag)
            figs = findall(groot, 'Type', 'figure', 'Tag', tag);
            assert(not(isempty(figs)), sprintf('dialog figure %s did not open', tag));
            app = getappdata(figs(1), 'LvdEditApp');
        end

        function pushPrioritySave(testCase, prioStr, wStr)
            app = testCase.findDialogApp('lvd_EditE2TPriorityGUI');
            app.PriorityText.Value = prioStr;
            app.WeightText.Value = wStr;
            app.SaveCloseButton.ButtonPushedFcn(app.SaveCloseButton, []);
        end

        function pushPrioritySaveThenCancel(testCase, prioStr, wStr)
            app = testCase.findDialogApp('lvd_EditE2TPriorityGUI');
            app.PriorityText.Value = prioStr;
            app.WeightText.Value = wStr;
            app.SaveCloseButton.ButtonPushedFcn(app.SaveCloseButton, []);
            testCase.closeAlertFigures();
            app.CancelButton.ButtonPushedFcn(app.CancelButton, []);
        end

        function pushPriorityCancel(testCase)
            app = testCase.findDialogApp('lvd_EditE2TPriorityGUI');
            app.CancelButton.ButtonPushedFcn(app.CancelButton, []);
        end

        function pushMixtureSave(testCase, rows)
            app = testCase.findDialogApp('lvd_EditEngineMixtureGUI');
            app.MixtureTable.Data = rows;
            app.SaveCloseButton.ButtonPushedFcn(app.SaveCloseButton, []);
        end

        function pushMixtureSaveThenCancel(testCase, rows)
            app = testCase.findDialogApp('lvd_EditEngineMixtureGUI');
            app.MixtureTable.Data = rows;
            app.SaveCloseButton.ButtonPushedFcn(app.SaveCloseButton, []);
            testCase.closeAlertFigures();
            app.CancelButton.ButtonPushedFcn(app.CancelButton, []);
        end

        function pushMixtureLegacy(testCase)
            app = testCase.findDialogApp('lvd_EditEngineMixtureGUI');
            app.ClearMixtureButton.ButtonPushedFcn(app.ClearMixtureButton, []);
        end

        function closeAlertFigures(~)
            drawnow;
            figs = findall(groot, 'Type', 'figure');
            for(i=1:length(figs))
                try
                    if(contains(figs(i).Name, 'Invalid'))
                        delete(figs(i));
                    end
                catch
                end
            end
            drawnow;
        end
    end
end
