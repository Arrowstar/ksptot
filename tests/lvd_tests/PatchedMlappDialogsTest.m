classdef PatchedMlappDialogsTest < KsptotTestCase
    %PatchedMlappDialogsTest The App Designer (.mlapp) dialogs that gained
    %controls for the LVD enhancements really open with those controls and
    %write the new fields back on Save & Close.
    %
    %   Covers lvd_AddDeltaVActionGUI_App (A9), lvd_EditActionConditionalGUI_App
    %   (A11), lvd_EditTankGUI_App (C1), lvd_EditThrottleModelsSet_App (B2)
    %   and lvd_editEventGUI_App (A1 condition-count hint).
    %
    %   These dialogs block in uiwait, which cannot be released from a timer
    %   under "matlab -batch".  UiwaitInterceptorFixture replaces uiwait for
    %   the duration of each test, so the dialog constructors return their
    %   live app object immediately; the test then inspects and drives the
    %   app through its public component properties and button callbacks
    %   before deleting it.  LvdMainGuiInteractionTest covers the same
    %   dialogs with App Testing Framework gestures.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            %With no handlers registered the fixture's stand-in uiwait simply
            %returns, so every dialog constructor hands back its live app.
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)

        %% ------------------------------------------------ A9: AddDeltaVAction

        function addDeltaVDialogExposesFramesAndParameterization(testCase)
            lvdData = testCase.lvdFixture();
            action = AddDeltaVAction([0.1; 0.2; 0.3], DeltaVFrameEnum.OrbitRsw, false);
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_AddDeltaVActionGUI_App(action, lvdData, out));
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(isa(app.paramTypeCombo, 'matlab.ui.control.DropDown') && isvalid(app.paramTypeCombo), ...
                'The parameterization dropdown must be created at run time.');
            testCase.verifyTrue(isa(app.userFrameCombo, 'matlab.ui.control.DropDown') && isvalid(app.userFrameCombo), ...
                'The user frame dropdown must be created at run time.');
            testCase.verifyEqual(numel(app.GridLayout3.RowHeight), 7, 'Two rows must have been added to the layout.');

            testCase.verifyEqual(numel(cellstr(handles.dvFrameCombo.String)), numel(enumeration('DeltaVFrameEnum')), ...
                'Every delta-v frame must be offered.');
            testCase.verifyEqual(app.paramTypeCombo.Value, action.paramType.nameStr);
            testCase.verifyEqual(handles.xCompLabel.String, 'Radial', 'RSW component labels must be shown for an RSW action.');
            testCase.verifyEqual(app.userFrameCombo.Enable, matlab.lang.OnOffSwitchState.off, ...
                'The user frame is only selectable for the user-defined frame.');

            %Save with nothing changed: the action must round-trip exactly.
            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(action.paramType, DeltaVParamTypeEnum.Cartesian);
            testCase.verifyEqual(action.frame, DeltaVFrameEnum.OrbitRsw);
            testCase.verifyEqual(action.deltaVVect, [0.1; 0.2; 0.3], 'AbsTol', 1e-12);
        end

        function addDeltaVDialogSavesAPolarDeltaV(testCase)
            lvdData = testCase.lvdFixture();
            action = AddDeltaVAction([0.1; 0; 0], DeltaVFrameEnum.Inertial, false);
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_AddDeltaVActionGUI_App(action, lvdData, out));
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.paramTypeCombo.Value = DeltaVParamTypeEnum.Polar.nameStr;
            app.paramTypeCombo.ValueChangedFcn(app.paramTypeCombo, []);
            testCase.verifyEqual(handles.xCompLabel.String, 'Magnitude', 'Polar labels must follow the parameterization.');
            testCase.verifyEqual(app.text6.Text, 'm/s');
            testCase.verifyEqual(app.text15.Text, 'deg');

            handles.dvXCompText.String = '500';
            handles.dvYCompText.String = '30';
            handles.dvZCompText.String = '-10';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(action.paramType, DeltaVParamTypeEnum.Polar);
            testCase.verifyEqual(action.deltaVVect, [0.5; deg2rad(30); deg2rad(-10)], 'AbsTol', 1e-12, ...
                'Polar values are stored as km/s and radians.');
            testCase.verifyEqual(action.getDeltaVFrameComponents(), 0.5*[cosd(-10)*cosd(30); cosd(-10)*sind(30); sind(-10)], 'AbsTol', 1e-12);
        end

        %% ----------------------------------------- A11: conditional actions

        function conditionalDialogExposesQuantityAtEventControls(testCase)
            lvdData = testCase.lvdFixture();
            conditional = LogicalAndActionConditional(AbstractActionConditional.empty(1,0));
            out = AppDesignerGUIOutput({conditional, false});

            app = testCase.openDialog(@() lvd_EditActionConditionalGUI_App(conditional, lvdData, out));

            testCase.verifyTrue(isa(app.CompareEventDropDown, 'matlab.ui.control.DropDown') && isvalid(app.CompareEventDropDown));
            testCase.verifyTrue(isa(app.CompareEventNodeDropDown, 'matlab.ui.control.DropDown') && isvalid(app.CompareEventNodeDropDown));
            testCase.verifyEqual(numel(app.GridLayout16.RowHeight), 4, 'Two rows must have been added to the comparison panel.');

            [evtStrs, ~] = lvdData.script.getListboxStr();
            testCase.verifyEqual(app.CompareEventDropDown.Items(:), evtStrs(:), 'The event list must mirror the script.');
            testCase.verifyEqual(numel(app.CompareEventNodeDropDown.Items), numel(enumeration('ConstraintStateComparisonNodeEnum')));

            testCase.verifyTrue(any(app.CompareAgainstDropDown.ItemsData == CompareAgainstEnum.EventQuantity), ...
                '"Quantity at Event" must be offered as a comparison target.');
        end

        %% ------------------------------------------------------- C1: tanks

        function tankDialogEditsCapacity(testCase)
            lvdData = testCase.lvdFixture();
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            tank.capacity = 12.5;

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditTankGUI_App(tank, out));

            testCase.verifyEqual(numel(app.GridLayout3.RowHeight), 5, 'One row must have been added for the capacity.');
            testCase.verifyEqual(str2double(app.capacityText.Value), 12.5, 'The stored capacity must be shown.');

            app.capacityText.Value = '20';
            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(tank.capacity, 20);

            %A capacity is always required: a blank field is rejected and the
            %stored value is left alone.
            out2 = AppDesignerGUIOutput({false});
            app2 = testCase.openDialog(@() lvd_EditTankGUI_App(tank, out2));
            testCase.verifyEqual(str2double(app2.capacityText.Value), 20);

            app2.capacityText.Value = '';
            testCase.pushButton(app2.saveAndCloseButton);
            testCase.verifyFalse(out2.output{1}, 'A blank capacity must not be saved.');
            testCase.verifyEqual(tank.capacity, 20);

            %So is a capacity below the initial propellant load.
            app2.capacityText.Value = fullAccNum2Str(0.5 * tank.initialMass);
            testCase.pushButton(app2.saveAndCloseButton);
            testCase.verifyFalse(out2.output{1}, 'A capacity below the initial mass must not be saved.');
            testCase.verifyEqual(tank.capacity, 20);
        end

        %% ---------------------------------------------- B2: throttle models

        function throttleModelsDialogOffersTheLimitedModel(testCase)
            lvdData = testCase.lvdFixture();
            throttleModels = ThrottleModelsSet();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditThrottleModelsSet_App(throttleModels, lvdData, out, true));

            testCase.verifyTrue(any(app.ThrottleModelCombo.ItemsData == ThrottleModelEnum.Limited), ...
                'The limited (q / accel) throttle model must be selectable.');

            app.ThrottleModelCombo.Value = ThrottleModelEnum.Limited;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(isa(throttleModels.selectedModel, 'LimitedThrottleModel'));
            testCase.verifyTrue(throttleModels.selectedModel == throttleModels.limitedThrottle);
        end

        %% ------------------------------------------- A1: event editor list

        function eventEditorListsEveryCondition(testCase)
            lvdData = testCase.lvdFixture();
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);
            evt.addTermCond(AltitudeTermCondition(70), EventTermCondDirectionEnum.Increasing);
            evt.addTermCond(AltitudeTermCondition(10), EventTermCondDirectionEnum.Decreasing);

            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_editEventGUI_App(evt, false, out));

            testCase.verifyEqual(numel(app.termCondListbox.Items), 3, ...
                'The editor must list every termination condition.');
            testCase.verifyTrue(contains(app.termCondListbox.Items{1}, evt.termCond.getName()));
            testCase.verifyEqual({app.EventTabGroup.Children.Title}, {'Event', 'Advanced'});
        end
    end

    methods(Access=private)
        function lvdData = lvdFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function app = openDialog(testCase, launchFcn)
            %openDialog Runs a dialog constructor (whose uiwait is a no-op
            %while this test class runs) and returns the live app.
            app = launchFcn();
            drawnow;

            testCase.assertTrue(not(isempty(app)), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PatchedMlappDialogsTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            %pushButton Fires a button's callback the way a click would.  The
            %GUIDE-migrated dialogs read event.Source, so a minimal event
            %structure is supplied.
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(not(isempty(app)) && isvalid(app))
                delete(app);
            end
        end
    end
end
