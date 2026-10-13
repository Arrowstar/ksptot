classdef TankDialogTest < KsptotTestCase
    %TankDialogTest Full round-trip UI tests for the single-tank editor
    %(Phase 3: vehicle editors).  This supersedes the capacity-only coverage
    %in PatchedMlappDialogsTest with every field the dialog edits.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditTankGUI_App.mlapp
    %   ('Edit Tank'; two-arg ctor (tank, output).  Backing class:
    %   LaunchVehicleTank, plus its StageTankInitMassOptimVar when the
    %   initial mass is optimized.)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name/stage/load/capacity/fluid type and
    %   optimization bounds; Save & Close writes every field (including the
    %   fluid type and the initial-mass optimization variable) and moves the
    %   tank; a blank capacity, a capacity below the initial load and a
    %   blank initial mass are rejected and leave the model alone; Cancel
    %   and window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [tank, lvdData] = testCase.fixture(); %#ok<ASGLU>
            app = testCase.openDialog(tank);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.tankNameText, 'String'), 'First Stage Tank');
            testCase.verifyEqual(str2double(get(handles.initPropMassText, 'String')), 4, 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(app.capacityText.Value), 4, 'AbsTol', 1e-9, ...
                'The stock tank is full: capacity equals the initial load.');
            testCase.verifyEqual(handles.stageCombo.Value, 1);
            testCase.verifyEqual(handles.fluidTypeCombo.Value, 1, ...
                'An untyped tank resolves to the first fluid type.');
            fluidItems = cellstr(handles.fluidTypeCombo.String);
            testCase.verifyEqual(fluidItems(:), {'Liquid Fuel/Ox'; 'Monopropellant'; 'Xenon'});
            testCase.verifyFalse(logical(handles.optCheckbox.Value), ...
                'The stock tank optimizes nothing.');
            testCase.verifyEqual(str2double(get(handles.lbText, 'String')), 0);
            testCase.verifyEqual(str2double(get(handles.ubText, 'String')), 0);
        end

        function saveAndCloseWritesEveryField(testCase)
            [tank, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankGUI;

            set(handles.tankNameText, 'String', 'Aft Tank');
            set(handles.initPropMassText, 'String', '5');
            app.capacityText.Value = '8';
            handles.fluidTypeCombo.Value = 2;
            set(handles.optCheckbox, 'Value', 1);
            set(handles.lbText, 'String', '2');
            set(handles.ubText, 'String', '6');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(tank.name, 'Aft Tank');
            testCase.verifyEqual(tank.initialMass, 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(tank.capacity, 8, 'AbsTol', 1e-12);
            testCase.verifyTrue(tank.tankType == lvdData.launchVehicle.tankTypes.getTypeForInd(2), ...
                'Save must write the fluid type.');
            optVar = tank.getExistingOptVar();
            testCase.verifyTrue(optVar.getUseTfForVariable(), 'Save must enable the mass variable.');
            [lb, ub] = optVar.getAllBndsForVariable();
            testCase.verifyEqual([lb, ub], [2, 6], 'Save must write the mass bounds.');
        end

        function saveAndCloseMovesTankAndKeepsConnections(testCase)
            [tank, lvdData] = testCase.fixture();
            lv = lvdData.launchVehicle;
            stgB = LaunchVehicleStage(lv);
            stgB.name = 'Upper Stage';
            lv.addStage(stgB);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.stageCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(tank.stage == stgB, 'Save must move the tank to the selected stage.');
            testCase.verifyTrue(any([stgB.tanks] == tank));
            testCase.verifyEmpty(lv.stages(1).tanks, 'The old stage must let the tank go.');
            testCase.verifyEqual(numel(lv.getEngineToTankConnsForTank(tank)), 1, ...
                'The tank''s engine connections must survive the move.');
        end

        function blankCapacityIsRejected(testCase)
            [tank, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.capacityText.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank capacity must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditTankGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(tank.capacity, 4, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function capacityBelowInitialMassIsRejected(testCase)
            [tank, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.capacityText.Value = '2';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A capacity below the initial mass must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditTankGUI));
            testCase.verifyEqual(tank.capacity, 4, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankInitialMassIsRejected(testCase)
            [tank, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.initPropMassText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank initial mass must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditTankGUI));
            testCase.verifyEqual(tank.initialMass, 4, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [tank, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankGUI;

            set(handles.tankNameText, 'String', 'Scratch Tank');
            set(handles.initPropMassText, 'String', '7');
            app.capacityText.Value = '9';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(tank.name, 'First Stage Tank', 'Cancel must leave the model alone.');
            testCase.verifyEqual(tank.initialMass, 4);
            testCase.verifyEqual(tank.capacity, 4);
        end

        function windowXPreservesModel(testCase)
            [tank, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(tank, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankGUI;

            app.capacityText.Value = '9';
            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(tank.capacity, 4);
        end
    end

    methods(Access=private)
        function [tank, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
        end

        function app = openDialog(testCase, tank, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditTankGUI_App(tank, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Tank')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Tank')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
