classdef DragCoefficientModelsDialogTest < KsptotTestCase
    %DragCoefficientModelsDialogTest Full round-trip UI tests for the drag
    %coefficient set editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/drag/lvd_EditDragCoefficientModels_App.mlapp
    %   ('Edit Drag Properties'; programmatic, ctor (dragCoeffModel, lvdData, out))
    %   backing class: DragCoeffModel
    %   production caller: DragCoeffModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/drag/@DragCoeffModel/DragCoeffModel.m:56-60).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   SteeringModelsSetDialogTest set-editor pattern: the combo selects
    %   the model, Save writes the selection back, Cancel preserves it).
    %   The model is the default mission's drag set so the fixture matches
    %   production.
    %
    % COVERED
    %   Open shows the current model and global multiplier; the description
    %   follows the combo; Save moves the selection and writes the
    %   multiplier; a blank multiplier is rejected and leaves the model
    %   alone; Cancel preserves the selection; the edit-model button
    %   exists.  (The per-model sub-editors are covered by their own
    %   dialog tests; the edit button is not pressed here.)

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsCurrentModelAndMultiplier(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyEqual(app.EditDragPropertiesUIFigure.Name, 'Edit Drag Properties');
            testCase.verifyEqual(app.DragCoeffModelCombo.Value, DragCoefficientModelEnum.OneDim, ...
                'The default drag model must be selected.');
            testCase.verifyTrue(any(app.DragCoeffModelCombo.ItemsData == DragCoefficientModelEnum.Constant), ...
                'The constant drag model must be offered.');
            testCase.verifyEqual(str2double(app.GlobalDragCoeffText.Value), 0.8, 'AbsTol', 1e-12);
            testCase.verifyEqual(string(app.ModelDescLabel.Text), model.dragCoeffObj.enum.desc, ...
                'The description must match the current model.');
        end

        function comboDescriptionFollowsSelection(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.DragCoeffModelCombo.Value = DragCoefficientModelEnum.Constant;
            app.DragCoeffModelCombo.ValueChangedFcn(app.DragCoeffModelCombo, []);

            testCase.verifyEqual(string(app.ModelDescLabel.Text), DragCoefficientModelEnum.Constant.desc, ...
                'The description must follow the selection.');
        end

        function saveMovesSelectionToConstant(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.DragCoeffModelCombo.Value = DragCoefficientModelEnum.Constant;
            app.GlobalDragCoeffText.Value = '1.5';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifySameHandle(model.dragCoeffObj, model.constDragModel, ...
                'The selection must be the set-owned constant model.');
            testCase.verifyEqual(model.globalDragMultiplier, 1.5, 'AbsTol', 1e-12);
        end

        function blankMultiplierIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.DragCoeffModelCombo.Value = DragCoefficientModelEnum.Constant;
            app.GlobalDragCoeffText.Value = '';
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank multiplier must not save.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.globalDragMultiplier, 0.8, 'AbsTol', 1e-12, ...
                'Rejected input must leave the multiplier alone.');
            testCase.verifySameHandle(model.dragCoeffObj, model.oneDDragModel, ...
                'Rejected input must leave the selection alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesSelection(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.DragCoeffModelCombo.Value = DragCoefficientModelEnum.Constant;
            app.GlobalDragCoeffText.Value = '1.5';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifySameHandle(model.dragCoeffObj, model.oneDDragModel, ...
                'Cancel must leave the selection alone.');
            testCase.verifyEqual(model.globalDragMultiplier, 0.8, 'AbsTol', 1e-12);
        end

        function editButtonExists(testCase)
            [model, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyTrue(isvalid(app.EditDragCoefficientModelButton), ...
                'The edit-model button must exist.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.dragCoeffModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditDragCoefficientModels_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() DragCoefficientModelsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Drag Properties')
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
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Drag Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
