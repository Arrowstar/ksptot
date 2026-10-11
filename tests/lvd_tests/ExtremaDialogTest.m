classdef ExtremaDialogTest < KsptotTestCase
    %ExtremaDialogTest Full round-trip UI tests for the single extremum
    %editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditExtremaGUI_App.mlapp
    %   backing class: LaunchVehicleExtrema (dialog ctor is (extrema, lvdData, output))
    %   production caller: lvd_EditExtremasGUI_App (add/edit paths).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored quantity/type/recording state; the quantity combo
    %   offers the graphical-analysis tasks; Save & Close writes quantity,
    %   type and recording state back; the frame label names the current
    %   frame; Cancel and window-X preserve the model.  The dialog performs
    %   no validation: Save always succeeds.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredTypeAndRecording(testCase)
            [ex, lvdData] = testCase.fixture();
            app = testCase.openDialog(ex, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.typeCombo.Value, ...
                LaunchVehicleExtremaTypeEnum.getIndOfListboxStrs(LaunchVehicleExtremaTypeEnum.Minimum));
            testCase.verifyEqual(handles.startRecordingCombo.Value, ...
                LaunchVehicleExtremaRecordingEnum.getIndOfListboxStrs(LaunchVehicleExtremaRecordingEnum.NotRecording));
            testCase.verifyEqual(handles.extremaQuantCombo.Value, 1, ...
                'An empty quantity must fall back to the first task.');
        end

        function quantComboOffersTasks(testCase)
            [ex, lvdData] = testCase.fixture();
            app = testCase.openDialog(ex, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyFalse(isempty(cellstr(handles.extremaQuantCombo.String)), ...
                'The quantity combo must offer graphical-analysis tasks.');
        end

        function saveAndCloseWritesQuantityTypeAndState(testCase)
            [ex, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(ex, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditExtremaGUI;

            taskList = cellstr(handles.extremaQuantCombo.String);
            val = min(2, numel(taskList));
            handles.extremaQuantCombo.Value = val;
            handles.typeCombo.Value = ...
                LaunchVehicleExtremaTypeEnum.getIndOfListboxStrs(LaunchVehicleExtremaTypeEnum.Maximum);
            handles.startRecordingCombo.Value = ...
                LaunchVehicleExtremaRecordingEnum.getIndOfListboxStrs(LaunchVehicleExtremaRecordingEnum.Recording);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(ex.quantStr, strtrim(taskList{val}));
            testCase.verifyEqual(ex.type.nameStr, 'Maximum');
            testCase.verifyEqual(ex.startingState.nameStr, 'Recording');
        end

        function frameLabelShowsCurrentFrame(testCase)
            [ex, lvdData] = testCase.fixture();
            app = testCase.openDialog(ex, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(string(handles.refFrameNameLabel.String), string(ex.frame.getNameStr()), ...
                'The frame label must name the current frame.');
        end

        function cancelPreservesModel(testCase)
            [ex, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(ex, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditExtremaGUI;

            handles.typeCombo.Value = ...
                LaunchVehicleExtremaTypeEnum.getIndOfListboxStrs(LaunchVehicleExtremaTypeEnum.Maximum);
            handles.extremaQuantCombo.Value = numel(cellstr(handles.extremaQuantCombo.String));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(ex.type.nameStr, 'Minimum', 'Cancel must leave the model alone.');
            testCase.verifyEqual(ex.quantStr, '');
        end

        function windowClosePreservesModel(testCase)
            [ex, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(ex, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditExtremaGUI;

            handles.typeCombo.Value = ...
                LaunchVehicleExtremaTypeEnum.getIndOfListboxStrs(LaunchVehicleExtremaTypeEnum.Maximum);
            close(fig);

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(ex.type.nameStr, 'Minimum', 'Window-X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [ex, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            ex = LaunchVehicleExtrema(lvdData);
            ex.type = LaunchVehicleExtremaTypeEnum.Minimum;
            ex.startingState = LaunchVehicleExtremaRecordingEnum.NotRecording;
            ex.frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
        end

        function app = openDialog(testCase, ex, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditExtremaGUI_App(ex, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ExtremaDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Extrema')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
