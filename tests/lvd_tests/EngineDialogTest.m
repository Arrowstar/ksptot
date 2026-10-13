classdef EngineDialogTest < KsptotTestCase
    %EngineDialogTest Full round-trip UI tests for the single-engine editor
    %(Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditEngineGUI_App.mlapp
    %   ('Edit Engine'; two-arg ctor (engine, output) -- no lvdData.  Backing
    %   class: LaunchVehicleEngine.)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The thrust/Isp/throttle
    %   profile buttons open nested editors stubbed with whenShown handlers.
    %
    % COVERED
    %   Open shows the stored name/stage/throttle limits/alternator and
    %   electric-charge settings; Save & Close writes every field and moves
    %   the engine (keeping its tank connections); a blank throttle, a
    %   maximum below the minimum and a negative alternator rate are
    %   rejected and leave the model alone; Cancel preserves the model; the
    %   profile buttons open the nested curve editors.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredEngineValues(testCase)
            [engine, ~] = testCase.engineFixture();
            engine.name = 'Sustainer';
            engine.minThrottle = 0.2;
            engine.maxThrottle = 0.9;
            engine.hasAlternator = true;
            engine.altPwrRate = 5;
            engine.reqsElecCharge = true;
            engine.pwrUsageRate = -3;

            app = testCase.openDialog(engine);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.engineNameText, 'String'), 'Sustainer');
            testCase.verifyEqual(str2double(get(handles.minThrottleText, 'String')), 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxThrottleText, 'String')), 90, 'AbsTol', 1e-9);
            testCase.verifyEqual(handles.stageCombo.Value, 1);
            testCase.verifyTrue(logical(handles.hasAlternatorCheckbox.Value));
            testCase.verifyEqual(str2double(get(handles.altChargeRateText, 'String')), 5, 'AbsTol', 1e-12);
            testCase.verifyTrue(logical(handles.reqsElecChargeCheckbox.Value));
            testCase.verifyEqual(str2double(get(handles.elecEnginePwrConsumptionText, 'String')), 3, ...
                'AbsTol', 1e-12, 'The discharge rate is shown positive (stored negated).');
        end

        function saveAndCloseWritesEveryField(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineGUI;

            set(handles.engineNameText, 'String', 'Orbital Engine');
            set(handles.minThrottleText, 'String', '10');
            set(handles.maxThrottleText, 'String', '80');
            set(handles.hasAlternatorCheckbox, 'Value', 1);
            set(handles.altChargeRateText, 'String', '2.5');
            set(handles.reqsElecChargeCheckbox, 'Value', 1);
            set(handles.elecEnginePwrConsumptionText, 'String', '1.25');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(engine.name, 'Orbital Engine');
            testCase.verifyEqual(engine.minThrottle, 0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(engine.maxThrottle, 0.8, 'AbsTol', 1e-12);
            testCase.verifyTrue(engine.hasAlternator);
            testCase.verifyEqual(engine.altPwrRate, 2.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(engine.reqsElecCharge);
            testCase.verifyEqual(engine.pwrUsageRate, -1.25, 'AbsTol', 1e-12, ...
                'The discharge rate is stored negated.');
        end

        function saveAndCloseMovesEngineAndKeepsConnections(testCase)
            [engine, lvdData] = testCase.engineFixture();
            lv = lvdData.launchVehicle;
            stgB = LaunchVehicleStage(lv);
            stgB.name = 'Upper Stage';
            lv.addStage(stgB);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.stageCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(engine.stage == stgB, 'Save must move the engine to the selected stage.');
            testCase.verifyTrue(any([stgB.engines] == engine));
            testCase.verifyEmpty(lv.stages(1).engines, 'The old stage must let the engine go.');
            testCase.verifyEqual(numel(lv.getEngineToTankConnsForEngine(engine)), 1, ...
                'The engine''s tank connections must survive the move.');
        end

        function blankThrottleIsRejected(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.minThrottleText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank throttle must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditEngineGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(engine.minThrottle, 0, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function maxBelowMinIsRejected(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.minThrottleText, 'String', '70');
            set(handles.maxThrottleText, 'String', '60');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A maximum below the minimum must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditEngineGUI));
            testCase.verifyEqual(engine.maxThrottle, 1, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeAlternatorRateIsRejected(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.altChargeRateText, 'String', '-2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative alternator rate must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditEngineGUI));
            testCase.verifyEqual(engine.altPwrRate, 0, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineGUI;

            set(handles.engineNameText, 'String', 'Scratch Engine');
            set(handles.minThrottleText, 'String', '50');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(engine.name, 'First Stage Engine', 'Cancel must leave the model alone.');
            testCase.verifyEqual(engine.minThrottle, 0);
        end

        function profileButtonsOpenNestedEditors(testCase)
            [engine, ~] = testCase.engineFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(engine, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Throttle Modifier Profile', @(fig) countAndPush(fig, seen), false);
            testCase.pushButton(app.editThrustProfileButton);
            testCase.pushButton(app.editIspProfileButton);
            testCase.pushButton(app.editThrottleModifierProfileButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('n') && seen('n') == 3, ...
                'All three profile buttons must open the curve editor.');
            testCase.verifyTrue(isvalid(handles.lvd_EditEngineGUI), ...
                'Dismissing the nested editors must leave the engine editor open.');
        end
    end

    methods(Access=private)
        function [engine, lvdData] = engineFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            engine = lvdData.launchVehicle.stages(1).engines(1);
        end

        function app = openDialog(testCase, engine, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditEngineGUI_App(engine, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EngineDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Engine')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Engine')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function countAndPush(fig, seen)
    if seen.isKey('n')
        seen('n') = seen('n') + 1; %#ok<NASGU>
    else
        seen('n') = 1; %#ok<NASGU>
    end
    UiwaitInterceptorFixture.pushButton(fig, 'Save & Close');
end
