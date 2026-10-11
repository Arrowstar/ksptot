classdef CalculusObjsDialogTest < KsptotTestCase
    %CalculusObjsDialogTest Full round-trip UI tests for the calculus
    %calculation set editor (Phase 3: vehicle).  This promotes the
    %LvdMainGuiWidgetSmokeTest open/cancel smoke coverage to value-level
    %assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditCalculusObjsGUI_App.mlapp
    %   backing store: LaunchVehicle.calcObjs (dialog ctor is (lvdData))
    %   production caller: LVD main window (editCalculusObjectsMenu).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The Add button first
    %   opens the listdlgARH_App picker (figure 'Calculation Type') and then
    %   the single-calculation child dialog (figure 'Edit Calculus
    %   Calculation'); both are stubbed with UiwaitInterceptorFixture.whenShown
    %   (the CompositeObjectiveDialogTest pattern).
    %
    % COVERED
    %   The list mirrors the stored calculations; Add (stubbed picker plus
    %   stubbed child) appends one derivative calculation and refreshes the
    %   listbox; Remove drops the selection (and keeps the rest); Close ends
    %   the dialog and leaves the model alone.  The set dialog has no
    %   Save/Cancel/output: edits apply immediately.  No test propagates or
    %   optimizes.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function listShowsStoredCalcs(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeCalc(lvdData, 'Altitude');
            testCase.makeCalc(lvdData, 'Velocity');

            app = testCase.openDialog(lvdData);

            [calcStrs, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.verifyNumElements(app.calcObjListBox.ItemsData, 2, ...
                'The listbox must mirror the stored calculations.');
            testCase.verifyEqual(app.calcObjListBox.Items(:), calcStrs(:), ...
                'The listbox strings must mirror the vehicle strings.');
            testCase.verifyNumElements(calcObjs, 2);
        end

        function addCalcAppendsViaPickerAndChildDialog(testCase)
            [lvdData] = testCase.fixture();
            [~, before] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.assertEmpty(before, 'Fixture: the default mission must have no calculus objects.');

            stub = UiwaitInterceptorFixture();
            stub.whenShown('Calculation Type', @(fig) CalculusObjsDialogTest.pickDerivativeAndOk(fig));
            stub.whenShown('Edit Calculus Calculation', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));

            app = testCase.openDialog(lvdData);
            testCase.pushButton(app.addCalcObjButton);

            testCase.verifyEmpty(stub.errors(), strjoin(stub.errors(), newline));
            [~, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.verifyNumElements(calcObjs, 1, 'Accepting the pickers must append one calculation.');
            testCase.verifyClass(calcObjs(1), 'LaunchVehicleDerivativeCalc');
            testCase.verifyNumElements(app.calcObjListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
        end

        function removeCalcDropsSelected(testCase)
            [lvdData] = testCase.fixture();
            calcObj = testCase.makeCalc(lvdData, 'Altitude');

            app = testCase.openDialog(lvdData);
            app.calcObjListBox.Value = calcObj;
            drawnow;
            testCase.pushButton(app.removeCalcObjButton);

            [~, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.verifyEmpty(calcObjs, 'Remove must drop the selected calculation.');
            testCase.verifyEmpty(app.calcObjListBox.ItemsData, 'The listbox must refresh after a remove.');
        end

        function removeKeepsUnselectedCalcs(testCase)
            [lvdData] = testCase.fixture();
            calcA = testCase.makeCalc(lvdData, 'Altitude');
            calcB = testCase.makeCalc(lvdData, 'Velocity');

            app = testCase.openDialog(lvdData);
            app.calcObjListBox.Value = calcA;
            drawnow;
            testCase.pushButton(app.removeCalcObjButton);

            [~, calcObjs] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.verifyNumElements(calcObjs, 1, 'Only the selected calculation may go.');
            testCase.verifyEqual(calcObjs(1).quantStr, calcB.quantStr, ...
                'The surviving calculation must be the unselected one.');
        end

        function closeButtonClosesWithoutTouchingModel(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeCalc(lvdData, 'Altitude');
            [~, before] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();

            app = testCase.openDialog(lvdData);
            fig = app.lvd_EditCalculusObjsGUI;
            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, after] = lvdData.launchVehicle.getCalculusCalcObjListBoxStr();
            testCase.verifyNumElements(after, numel(before), 'Close must leave the model alone.');
        end

        function emptyVehicleShowsEmptyList(testCase)
            [lvdData] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.calcObjListBox.ItemsData, ...
                'The default mission ships with no calculus calculations.');
            testCase.verifyEqual(char(app.removeCalcObjButton.Enable), 'off', ...
                'With nothing listed there is nothing to remove.');
        end
    end

    methods(Access=private)
        function lvdData = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function calcObj = makeCalc(~, lvdData, quantStr)
            calcObj = LaunchVehicleDerivativeCalc(lvdData);
            calcObj.quantStr = quantStr;
            calcObj.frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
            lvdData.launchVehicle.addCalculusCalcObj(calcObj);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditCalculusObjsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() CalculusObjsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Calculus Calculations') || ...
                        strcmp(figs(i).Name, 'Edit Calculus Calculation') || ...
                        strcmp(figs(i).Name, 'Calculation Type'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function pickDerivativeAndOk(fig)
            %pickDerivativeAndOk listdlgARH handler: select the derivative
            %calculation type and press OK.  The registry lives in groot
            %appdata, so any interceptor instance can register this handler.
            lbs = findall(fig, 'Type', 'uilistbox');
            lb = lbs(1);
            idx = find(strcmp(lb.Items, 'Derivative'), 1);
            if isempty(idx)
                idx = 1;
            end
            lb.Value = lb.Items{idx};
            drawnow;
            UiwaitInterceptorFixture.pushButton(fig, 'OK');
        end
    end
end
