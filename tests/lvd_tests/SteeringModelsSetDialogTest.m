classdef SteeringModelsSetDialogTest < KsptotTestCase
    %SteeringModelsSetDialogTest Full round-trip UI tests for the steering
    %model set editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditSteeringModelsSet_App.mlapp
    %   backing class: SteeringModelsSet
    %   production caller: SteeringModelsSet.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/steering/@SteeringModelsSet/SteeringModelsSet.m:56-60).
    %
    % PATTERN
    %   Programmatic App Designer dialog; UiwaitInterceptorFixture stands in
    %   for uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest throttle-set pattern:
    %   lvd_EditThrottleModelsSet_App).  The combo selects the model, Save
    %   writes the selection back, Cancel preserves it.
    %
    % COVERED
    %   The combo offers every SteerModelTypeEnum set member; switching the
    %   combo and saving moves the selection and keeps the slot handle;
    %   cancel and window-X preserve the selection; the edit button exists.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogOffersEverySteeringType(testCase)
            [models, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);

            testCase.verifyTrue(any(app.SteeringModelCombo.ItemsData == SteerModelTypeEnum.PolyAngles), ...
                'The polynomial steering type must be offered.');
            testCase.verifyTrue(any(app.SteeringModelCombo.ItemsData == SteerModelTypeEnum.QuaterionInterp), ...
                'The quaternion-interp steering type must be offered.');
            testCase.verifyTrue(any(app.SteeringModelCombo.ItemsData == SteerModelTypeEnum.SelectableModelAngles), ...
                'The selectable steering type must be offered.');
            testCase.verifyTrue(any(app.SteeringModelCombo.ItemsData == SteerModelTypeEnum.TabularQuaterionInterp), ...
                'The tabular steering type must be offered.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogShowsCurrentSelection(testCase)
            [models, lvdData] = testCase.fixture();
            models.selectedModel = models.quatInterp;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);

            testCase.verifyEqual(app.SteeringModelCombo.Value, SteerModelTypeEnum.QuaterionInterp, ...
                'The combo must reflect the current selection.');
            testCase.pushButton(app.cancelButton);
        end

        function saveMovesSelectionToQuatInterp(testCase)
            [models, lvdData] = testCase.fixture();
            models.selectedModel = models.polySteering;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);
            fig = app.EditSteeringModelsUIFigure;

            app.SteeringModelCombo.Value = SteerModelTypeEnum.QuaterionInterp;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifyClass(models.selectedModel, 'GenericQuatInterpSteeringModel');
            testCase.verifySameHandle(models.selectedModel, models.quatInterp, ...
                'The selection must be the set-owned quat-interp handle.');
        end

        function saveMovesSelectionToSelectable(testCase)
            [models, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);

            app.SteeringModelCombo.Value = SteerModelTypeEnum.SelectableModelAngles;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyClass(models.selectedModel, 'GenericSelectableSteeringModel');
            testCase.verifySameHandle(models.selectedModel, models.genericSelectableModels);
        end

        function saveMovesSelectionToTabular(testCase)
            [models, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);

            app.SteeringModelCombo.Value = SteerModelTypeEnum.TabularQuaterionInterp;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyClass(models.selectedModel, 'GenericTabularQuatInterpSteeringModel');
            testCase.verifySameHandle(models.selectedModel, models.tabularQuatInterp);
        end

        function editButtonExists(testCase)
            [models, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);

            testCase.verifyTrue(isvalid(app.EditSteeringModelButton), 'The edit-model button must exist.');
            testCase.pushButton(app.cancelButton);
        end

        function cancelPreservesSelection(testCase)
            [models, lvdData] = testCase.fixture();
            models.selectedModel = models.polySteering;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(models, lvdData, out);
            fig = app.EditSteeringModelsUIFigure;

            app.SteeringModelCombo.Value = SteerModelTypeEnum.QuaterionInterp;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifySameHandle(models.selectedModel, models.polySteering, ...
                'Cancel must leave the selection alone.');
        end
    end

    methods(Access=private)
        function [models, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            models = SteeringModelsSet();
        end

        function app = openDialog(testCase, models, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSteeringModelsSet_App(models, lvdData, out, true);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SteeringModelsSetDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Set Steering Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
