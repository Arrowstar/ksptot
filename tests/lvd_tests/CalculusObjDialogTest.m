classdef CalculusObjDialogTest < KsptotTestCase
    %CalculusObjDialogTest Full round-trip UI tests for the single calculus
    %calculation editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditCalculusObjGUI_App.mlapp
    %   backing classes: LaunchVehicleDerivativeCalc, LaunchVehicleIntegralCalc
    %   (dialog ctor is (calcObj, lvdData, output))
    %   production caller: lvd_EditCalculusObjsGUI_App (add/edit paths).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored quantity and frame; the quantity combo offers the
    %   graphical-analysis tasks; Save & Close writes the quantity back and
    %   keeps the frame; Cancel and window-X preserve the model.  The dialog
    %   performs no quantity validation (there is no bad-expression check in
    %   the .mlapp): Save always succeeds.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredQuantityAndFrame(testCase)
            [calcObj, lvdData] = testCase.fixture();
            app = testCase.openDialog(calcObj, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.calcObjQuantCombo.Value, 1, ...
                'An empty quantity must fall back to the first task.');
            testCase.verifyEqual(string(handles.refFrameNameLabel.String), ...
                string(calcObj.frame.getNameStr()), ...
                'The frame label must name the current frame.');
        end

        function quantComboOffersTasks(testCase)
            [calcObj, lvdData] = testCase.fixture();
            app = testCase.openDialog(calcObj, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyFalse(isempty(cellstr(handles.calcObjQuantCombo.String)), ...
                'The quantity combo must offer graphical-analysis tasks.');
        end

        function saveAndCloseWritesQuantity(testCase)
            [calcObj, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(calcObj, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCalculusObjGUI;

            taskList = cellstr(handles.calcObjQuantCombo.String);
            val = min(2, numel(taskList));
            handles.calcObjQuantCombo.Value = val;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(calcObj.quantStr, strtrim(taskList{val}));
        end

        function saveKeepsFrame(testCase)
            [calcObj, lvdData] = testCase.fixture();
            frameName = calcObj.frame.getNameStr();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(calcObj, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.calcObjQuantCombo.Value = numel(cellstr(handles.calcObjQuantCombo.String));
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(string(calcObj.frame.getNameStr()), string(frameName), ...
                'Saving a new quantity must keep the frame.');
        end

        function cancelPreservesModel(testCase)
            [calcObj, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(calcObj, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCalculusObjGUI;

            handles.calcObjQuantCombo.Value = numel(cellstr(handles.calcObjQuantCombo.String));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(calcObj.quantStr, '', 'Cancel must leave the model alone.');
        end

        function windowClosePreservesModel(testCase)
            [calcObj, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(calcObj, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditCalculusObjGUI;

            handles.calcObjQuantCombo.Value = numel(cellstr(handles.calcObjQuantCombo.String));
            close(fig);

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(calcObj.quantStr, '', 'Window-X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [calcObj, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            calcObj = LaunchVehicleDerivativeCalc(lvdData);
            calcObj.frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
        end

        function app = openDialog(testCase, calcObj, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditCalculusObjGUI_App(calcObj, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() CalculusObjDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Calculus Calculation')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
