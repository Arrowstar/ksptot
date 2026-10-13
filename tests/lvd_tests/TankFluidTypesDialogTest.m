classdef TankFluidTypesDialogTest < KsptotTestCase
    %TankFluidTypesDialogTest Full round-trip UI tests for the tank fluid
    %type set editor (Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditTankFluidTypesGUI_App.mlapp
    %   ('Edit Tank Fluid Types'; single-arg ctor (lvdData), no output arg
    %   -- Add / Remove / Move Up / Move Down write straight into
    %   lvdData.launchVehicle.tankTypes and Close just closes).  Add prompts
    %   for the new name with inputdlg, which is stubbed.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %   NativeDialogInterceptorFixture stands in for inputdlg so the Add
    %   flow can be answered (or cancelled) without hanging under
    %   "matlab -batch".
    %
    % COVERED
    %   Open lists the three default fluid types and disables Remove; Add
    %   with an answered prompt appends the type (and enables Remove) while
    %   a cancelled prompt adds nothing; Remove drops the added type; a
    %   type in use on a tank cannot be removed; Move Up reorders the types
    %   and keeps the selection; Close preserves the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
        native NativeDialogInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowDialogs(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.native = testCase.applyFixture(NativeDialogInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsDefaultTypesAndDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.typesListbox.Items(:), ...
                {'Liquid Fuel/Ox'; 'Monopropellant'; 'Xenon'}, ...
                'The list must mirror the vehicle''s fluid types.');
            testCase.verifyEqual(numel(app.typesListbox.ItemsData), 3);
            testCase.verifyTrue(testCase.isOff(app.removeRemoveTypeButton), ...
                'The default three types cannot be removed.');
        end

        function addFluidTypeViaPromptAppendsType(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.native.setInputdlgResponse({'Test Fluid'});
            testCase.pushButton(app.addTypeButton);

            testCase.verifyGreaterThan(testCase.native.calls().inputdlg, 0, ...
                'Add must prompt for the new fluid name.');
            testCase.verifyEqual(numel(lvdData.launchVehicle.tankTypes.types), 4, ...
                'An answered prompt must keep the new type.');
            testCase.verifyEqual(app.typesListbox.Items(:), ...
                {'Liquid Fuel/Ox'; 'Monopropellant'; 'Xenon'; 'Test Fluid'});
            testCase.verifyTrue(app.typesListbox.Value == lvdData.launchVehicle.tankTypes.getTypeForInd(4), ...
                'The new type must be selected.');
            testCase.verifyFalse(testCase.isOff(app.removeRemoveTypeButton), ...
                'Remove must enable once four types exist.');
        end

        function addFluidTypeCancelledAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            %The stub default ({}) cancels the prompt.
            testCase.pushButton(app.addTypeButton);

            testCase.verifyGreaterThan(testCase.native.calls().inputdlg, 0);
            testCase.verifyEqual(numel(lvdData.launchVehicle.tankTypes.types), 3, ...
                'A cancelled prompt must add nothing.');
            testCase.verifyEqual(numel(app.typesListbox.Items), 3);
            testCase.verifyTrue(testCase.isOff(app.removeRemoveTypeButton));
        end

        function removeAddedFluidType(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            newType = TankFluidType('Test Fluid');
            lvdData.launchVehicle.tankTypes.addType(newType);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.typesListbox.Value = newType;
            testCase.pushButton(app.removeRemoveTypeButton);

            testCase.verifyEqual(numel(lvdData.launchVehicle.tankTypes.types), 3, ...
                'Remove must drop the selected type.');
            testCase.verifyEqual(app.typesListbox.Items(:), ...
                {'Liquid Fuel/Ox'; 'Monopropellant'; 'Xenon'});
            testCase.verifyTrue(testCase.isOff(app.removeRemoveTypeButton), ...
                'Remove must disable again at three types.');
            testCase.verifyTrue(isvalid(handles.lvd_EditTankFluidTypesGUI), ...
                'Removing must leave the editor open.');
        end

        function inUseFluidTypeCannotBeRemoved(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            inUse = lvdData.launchVehicle.tankTypes.getTypeForInd(1);
            app = testCase.openDialog(lvdData);

            app.typesListbox.Value = inUse;
            testCase.pushButton(app.removeRemoveTypeButton);

            testCase.verifyEqual(numel(lvdData.launchVehicle.tankTypes.types), 3, ...
                'A type in use on a tank must be kept.');
            testCase.verifyEqual(app.typesListbox.Items(:), ...
                {'Liquid Fuel/Ox'; 'Monopropellant'; 'Xenon'});
            testCase.closeAlerts();
        end

        function moveTypeUpReordersAndKeepsSelection(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            fourth = TankFluidType('Test Fluid');
            lvdData.launchVehicle.tankTypes.addType(fourth);
            app = testCase.openDialog(lvdData);

            app.typesListbox.Value = fourth;
            testCase.pushButton(app.moveTypeUpButton);

            types = lvdData.launchVehicle.tankTypes.types;
            testCase.verifyTrue(types(3) == fourth, 'Move Up must swap the type with its predecessor.');
            testCase.verifyEqual(app.typesListbox.Items(:), ...
                {'Liquid Fuel/Ox'; 'Monopropellant'; 'Test Fluid'; 'Xenon'});
            testCase.verifyTrue(app.typesListbox.Value == fourth, ...
                'The moved type must stay selected.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankFluidTypesGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(numel(lvdData.launchVehicle.tankTypes.types), 3, ...
                'Close must leave the model alone.');
        end
    end

    methods(Access=private)
        function app = openDialog(testCase, lvdData)
            %The fluid types editor takes only lvdData (no output arg).
            app = lvd_EditTankFluidTypesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankFluidTypesDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function tf = isOff(~, comp)
            tf = strcmpi(string(comp.Enable), 'off');
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Tank Fluid Types')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Tank Fluid Types')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
