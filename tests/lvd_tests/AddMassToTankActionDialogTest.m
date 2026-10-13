classdef AddMassToTankActionDialogTest < KsptotTestCase
    %AddMassToTankActionDialogTest Full round-trip UI tests for the
    %add-mass-to-tank action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_AddMassToTankActionGUI_App.mlapp
    %   backing class: AddMassToTankAction
    %   (opens via AddMassToTankAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditActionUI); the fixture adds a second
    %   tank so tank reselection is exercisable (default LVD data ships
    %   one tank).
    %
    % COVERED
    %   Open shows stored tank/mass-to-add/opt flag/bounds; Save & Close
    %   writes mass, tank selection, opt flag and bounds back (the
    %   backing AddMassToTankActionOptimVar assigns itself to
    %   action.optVar on construction, so the write is observable on the
    %   action); a blank mass and inverted bounds are rejected and leave
    %   the model alone; Cancel preserves the model; the tank dropdown
    %   mirrors the vehicle's tanks.

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

            testCase.verifyEqual(handles.tankCombo.Value, 1);
            testCase.verifyEqual(str2double(get(handles.massToAddText, 'String')), 1.5, 'AbsTol', 1e-12);
            testCase.verifyFalse(logical(handles.optCheckbox.Value), ...
                'A fresh action optimizes nothing by default.');
            testCase.verifyEqual(str2double(get(handles.lbText, 'String')), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.ubText, 'String')), 0, 'AbsTol', 1e-12);
        end

        function tankComboOffersEveryTank(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(tanks), 2);
            testCase.verifyEqual(numel(cellstr(handles.tankCombo.String)), numel(tanks), ...
                'Every vehicle tank must be offered.');
        end

        function saveAndCloseWritesMassAndTank(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_AddMassToTankActionGUI;

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            set(handles.massToAddText, 'String', '2.5');
            handles.tankCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(action.massToAdd, 2.5, 'AbsTol', 1e-12);
            testCase.verifyTrue(action.tank == tanks(2), ...
                'The selected tank must be written back.');
        end

        function saveAndCloseWritesOptFlagAndBounds(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.optCheckbox, 'Value', 1);
            set(handles.lbText, 'String', '1');
            set(handles.ubText, 'String', '9');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isempty(action.optVar), ...
                'Save must attach the backing optimization variable to the action.');
            testCase.verifyTrue(action.optVar.getUseTfForVariable(), ...
                'The opt checkbox must be written through.');
            [lb, ub] = action.optVar.getAllBndsForVariable();
            testCase.verifyEqual(lb, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(ub, 9, 'AbsTol', 1e-12);
        end

        function blankMassToAddIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.massToAddText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank mass must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_AddMassToTankActionGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.massToAdd, 1.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function invertedBoundsAreRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.lbText, 'String', '10');
            set(handles.ubText, 'String', '2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Inverted bounds must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_AddMassToTankActionGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.massToAdd, 1.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_AddMassToTankActionGUI;

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            set(handles.massToAddText, 'String', '99');
            handles.tankCombo.Value = 2;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(action.massToAdd, 1.5, 'Cancel must leave the model alone.');
            testCase.verifyTrue(action.tank == tanks(1), 'Cancel must leave the tank alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            tank2.capacity = 9;
            stg.addTank(tank2);

            action = AddMassToTankAction(tank1, 1.5);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_AddMassToTankActionGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() AddMassToTankActionDialogTest.deleteIfValid(app));
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
