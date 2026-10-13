classdef LvAndStagesStatesDialogTest < KsptotTestCase
    %LvAndStagesStatesDialogTest Full round-trip UI tests for the launch
    %vehicle & stage states editor (Phase 4: state/aero/SRP; upgrade of the
    %open+Cancel smoke test).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/lvd_EditLvAndStagesStatesGUI_App.mlapp
    %   ('Edit Launch Vehicle & Stage States'; GUIDE-migrated,
    %   ctor (lvdData, out))
    %   backing state: LvdData.initStateModel stage/engine/connection/power
    %   states plus lvState.holdDownEnabled.
    %   production caller: the initial-state editor's LV-and-stages button
    %   (lvd_EditInitialStateGUI_App: editLvAndStageStatesButton_Callback
    %   opens lvd_EditLvAndStagesStatesGUI_App(lvdData, output)).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Checkboxes are flipped by
    %   setting Value and firing ValueChangedFcn, the way a click would.
    %   Edits write LIVE into initStateModel (each checkbox callback sets
    %   its state at once); the dialog has no Cancel -- Close reports
    %   {true} and keeps the edits.  autoPropScript is off throughout so
    %   nothing propagates.
    %
    % COVERED
    %   Open lists the stored stages and reflects each active flag plus the
    %   hold-down clamps; flipping the stage, engine and hold-down
    %   checkboxes writes straight into initStateModel; Close reports true
    %   and keeps the edits; opening and closing untouched preserves the
    %   model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsPerStageStates(testCase)
            lvdData = testCase.newLvdData();
            stgStates = lvdData.initStateModel.stageStates;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.lvd_EditLvAndStagesStatesGUI.Name, 'Edit Launch Vehicle & Stage States');
            testCase.verifyEqual(numel(cellstr(get(handles.stageListbox, 'String'))), numel(lvdData.launchVehicle.stages), ...
                'The stage list must mirror the vehicle.');
            testCase.verifyGreaterThanOrEqual(numel(cellstr(get(handles.engineListbox, 'String'))), 1, ...
                'The default vehicle must list an engine.');
            testCase.verifyEqual(logical(handles.stageActiveCheckbox.Value), logical(stgStates(1).active), ...
                'The stage checkbox must reflect the stored state.');
            testCase.verifyEqual(logical(handles.holdDownClampsEnabledCheckbox.Value), ...
                logical(lvdData.initStateModel.lvState.holdDownEnabled), ...
                'The hold-down checkbox must reflect the stored state.');
        end

        function toggleStageActiveWritesLive(testCase)
            lvdData = testCase.newLvdData();
            stgStates = lvdData.initStateModel.stageStates;
            before = logical(stgStates(1).active);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.stageListbox.Value = 1;
            set(handles.stageActiveCheckbox, 'Value', double(~before));
            %Fire on the app component: legacy checkbox handles are
            %migration-converter objects with no ValueChangedFcn.
            testCase.fireCheckbox(app.stageActiveCheckbox);

            testCase.verifyEqual(logical(stgStates(1).active), ~before, ...
                'Flipping the stage checkbox must write the state at once.');
        end

        function toggleEngineActiveWritesLive(testCase)
            lvdData = testCase.newLvdData();
            engStates = lvdData.initStateModel.stageStates(1).engineStates;
            testCase.assertGreaterThan(numel(engStates), 0, 'The default stage must own an engine state.');
            before = logical(engStates(1).active);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            handles.engineListbox.Value = 1;
            set(handles.engineActiveCheckbox, 'Value', double(~before));
            testCase.fireCheckbox(app.engineActiveCheckbox);

            testCase.verifyEqual(logical(engStates(1).active), ~before, ...
                'Flipping the engine checkbox must write the state at once.');
        end

        function holdDownToggleWritesLive(testCase)
            lvdData = testCase.newLvdData();
            before = logical(lvdData.initStateModel.lvState.holdDownEnabled);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.holdDownClampsEnabledCheckbox, 'Value', double(~before));
            testCase.fireCheckbox(app.holdDownClampsEnabledCheckbox);

            testCase.verifyEqual(logical(lvdData.initStateModel.lvState.holdDownEnabled), ~before, ...
                'Flipping hold-down must write the state at once.');
        end

        function closeKeepsEditsAndReportsTrue(testCase)
            lvdData = testCase.newLvdData();
            stgStates = lvdData.initStateModel.stageStates;
            before = logical(stgStates(1).active);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditLvAndStagesStatesGUI;

            handles.stageListbox.Value = 1;
            set(handles.stageActiveCheckbox, 'Value', double(~before));
            testCase.fireCheckbox(app.stageActiveCheckbox);
            testCase.pushButton(app.closeButton);

            testCase.verifyTrue(out.output{1}, 'Close must report {true}.');
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(logical(stgStates(1).active), ~before, ...
                'Close must keep the live edits.');
        end

        function openCloseWithoutEditsPreserves(testCase)
            lvdData = testCase.newLvdData();
            stgStates = lvdData.initStateModel.stageStates;
            beforeActive = logical(stgStates(1).active);
            beforeHoldDown = logical(lvdData.initStateModel.lvState.holdDownEnabled);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditLvAndStagesStatesGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyEqual(logical(stgStates(1).active), beforeActive, ...
                'An untouched close must leave the stage state alone.');
            testCase.verifyEqual(logical(lvdData.initStateModel.lvState.holdDownEnabled), beforeHoldDown, ...
                'An untouched close must leave hold-down alone.');
        end
    end

    methods(Access=private)
        function lvdData = newLvdData(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.settings.autoPropScript = false;
        end

        function app = openDialog(testCase, lvdData, out)
            if(nargin < 3 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditLvAndStagesStatesGUI_App(lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() LvAndStagesStatesDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireCheckbox(~, comp)
            evt = struct('Source', comp, 'Value', comp.Value, ...
                'PreviousValue', comp.Value, 'EventName', 'ValueChanged');
            comp.ValueChangedFcn(comp, evt);
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Launch Vehicle & Stage States')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
