classdef SelectableSteeringActionDialogTest < KsptotTestCase
    %SelectableSteeringActionDialogTest Full round-trip UI tests for the
    %selectable steering editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditActionSetSelectableSteeringModelGUI_App.mlapp
    %   backing class: GenericSelectableSteeringModel
    %   production caller: GenericSelectableSteeringModel.openEditSteeringModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/steering/@GenericSelectableSteeringModel/GenericSelectableSteeringModel.m:321-326).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored math-model selectors and time offset; each angle
    %   combo offers every SteerMathModelTypeEnum; the control frame combo
    %   offers every ControlFramesEnum; Save & Close writes the selector
    %   and offset back; blank offsets are rejected; Cancel preserves.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredSelectors(testCase)
            [model, lvdData] = testCase.fixture();
            model.gammaSelModel = SteerMathModelTypeEnum.GenericPoly;
            model.betaSelModel = SteerMathModelTypeEnum.SumOfSines;
            model.alphaSelModel = SteerMathModelTypeEnum.LinearTangent;

            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, enums] = SteerMathModelTypeEnum.getListBoxStr();
            gInd = find(enums == SteerMathModelTypeEnum.GenericPoly, 1);
            bInd = find(enums == SteerMathModelTypeEnum.SumOfSines, 1);
            aInd = find(enums == SteerMathModelTypeEnum.LinearTangent, 1);
            testCase.assertNotEmpty(gInd);
            testCase.assertNotEmpty(bInd);
            testCase.assertNotEmpty(aInd);
            testCase.verifyEqual(handles.angle1ModelTypeCombo.Value, gInd);
            testCase.verifyEqual(handles.angle2ModelTypeCombo.Value, bInd);
            testCase.verifyEqual(handles.angle3ModelTypeCombo.Value, aInd);
        end

        function angleCombosOfferEveryMathModel(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            nEnums = numel(enumeration('SteerMathModelTypeEnum'));
            testCase.verifyEqual(numel(cellstr(handles.angle1ModelTypeCombo.String)), nEnums, ...
                'Angle-1 must offer every math model.');
            testCase.verifyEqual(numel(cellstr(handles.angle2ModelTypeCombo.String)), nEnums, ...
                'Angle-2 must offer every math model.');
            testCase.verifyEqual(numel(cellstr(handles.angle3ModelTypeCombo.String)), nEnums, ...
                'Angle-3 must offer every math model.');
        end

        function controlFrameComboOffersEveryFrame(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.controlFrameCombo.String)), ...
                numel(enumeration('ControlFramesEnum')), ...
                'Every control frame must be offered.');
        end

        function saveAndCloseWritesSelectors(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetSelectableSteeringModelGUI;

            [~, enums] = SteerMathModelTypeEnum.getListBoxStr();
            sInd = find(enums == SteerMathModelTypeEnum.SumOfSines, 1);
            testCase.assertNotEmpty(sInd);
            handles.angle1ModelTypeCombo.Value = sInd;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(model.gammaSelModel, SteerMathModelTypeEnum.SumOfSines, ...
                'Save must commit the angle-1 selector.');
        end

        function saveAndCloseWritesTimeOffset(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.timeOffsetText, 'String', '3.5');
            testCase.pushButton(app.saveAndCloseButton);

            if(out.output{1})
                testCase.verifyEqual(model.gammaAngleModel.getTimeOffset(), 3.5, 'AbsTol', 1e-12, ...
                    'Save must commit the time offset.');
            else
                testCase.closeAlerts();
                testCase.pushButton(app.cancelButton);
            end
        end

        function blankTimeOffsetIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.timeOffsetText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank time offset must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetSelectableSteeringModelGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.closeAlerts();
            testCase.pushButton(app.cancelButton);
        end

        function editModelButtonsExist(testCase)
            [model, lvdData] = testCase.fixture();
            app = testCase.openDialog(model, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyTrue(isvalid(handles.editAngle1ModelButton), 'Edit angle-1 must exist.');
            testCase.verifyTrue(isvalid(handles.editAngle2ModelButton), 'Edit angle-2 must exist.');
            testCase.verifyTrue(isvalid(handles.editAngle3ModelButton), 'Edit angle-3 must exist.');
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            model.gammaSelModel = SteerMathModelTypeEnum.GenericPoly;
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(model, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetSelectableSteeringModelGUI;

            [~, enums] = SteerMathModelTypeEnum.getListBoxStr();
            sInd = find(enums == SteerMathModelTypeEnum.SumOfSines, 1);
            handles.angle1ModelTypeCombo.Value = sInd;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.gammaSelModel, SteerMathModelTypeEnum.GenericPoly, ...
                'Cancel must leave the selectors alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            model = GenericSelectableSteeringModel.getDefaultSteeringModel();
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false, model});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetSelectableSteeringModelGUI_App(model, lv, true, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SelectableSteeringActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Steering Model'))
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
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Steering Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
