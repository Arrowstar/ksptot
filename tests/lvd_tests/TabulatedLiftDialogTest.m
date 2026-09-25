classdef TabulatedLiftDialogTest < KsptotTestCase
    %TabulatedLiftDialogTest D4 lift dialogs: the rewritten
    %lvd_EditLiftCoefficientModels_App selector (.mlapp -> programmatic .m)
    %and the new lvd_EditUserTabulatedLiftPropertiesGUI_App editor.
    %
    %   Uses the same headless harness as PatchedMlappDialogsTest:
    %   UiwaitInterceptorFixture releases the modal uiwait so each dialog
    %   constructor returns its live app, which the test then drives through
    %   public components and button callbacks.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function selectorRoundTripsCylinderByDefault(testCase)
            %Guards the .mlapp -> .m rewrite: default selection and save
            %behavior for the KSP cylinder model must be unchanged.
            liftModels = LiftCoeffModel();
            lvdData = testCase.lvdFixture();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditLiftCoefficientModels_App(liftModels, lvdData, out));

            testCase.verifyEqual(app.LiftCoeffModelCombo.Value, LiftCoefficientModelEnum.KSPCylinder, ...
                'The default lift model must be selected.');
            testCase.pushButton(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(liftModels.liftCoeffObj == liftModels.cylinderModel);
        end

        function selectorOffersAndSavesTabularModel(testCase)
            liftModels = LiftCoeffModel();
            lvdData = testCase.lvdFixture();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditLiftCoefficientModels_App(liftModels, lvdData, out));

            testCase.verifyTrue(any(app.LiftCoeffModelCombo.ItemsData == LiftCoefficientModelEnum.UserTabulated), ...
                'The user-tabulated lift model must be selectable.');

            app.LiftCoeffModelCombo.Value = LiftCoefficientModelEnum.UserTabulated;
            app.LiftCoeffModelCombo.ValueChangedFcn(app.LiftCoeffModelCombo, []);
            testCase.verifyTrue(contains(app.ModelDescLabel.Text, 'CSV', 'IgnoreCase', true), ...
                'The description must follow the selection.');

            testCase.pushButton(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(liftModels.liftCoeffObj == liftModels.tabularLiftModel);
        end

        function editorRejectsMissingFile(testCase)
            model = UserTabulatedLiftModel('');
            lvdData = testCase.lvdFixture();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditUserTabulatedLiftPropertiesGUI_App(model, lvdData, out));

            app.FileSelector.Value = fullfile(tempdir(), 'definitely-not-a-lift-table.csv');
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A missing CSV must not be saved.');
            testCase.verifyTrue(isempty(model.dataFile) || ~isfile(model.dataFile), ...
                'The model must keep its previous (empty) data file.');
        end

        function editorLoadsCsvOnSave(testCase)
            rows = [0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                    1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0];
            f = [tempname(), '.csv'];
            writematrix(rows, f);

            model = UserTabulatedLiftModel('');
            lvdData = testCase.lvdFixture();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditUserTabulatedLiftPropertiesGUI_App(model, lvdData, out));

            app.FileSelector.Value = f;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(model.dataFile, f);
            testCase.verifyEqual(model.machNum, [0;1], 'AbsTol', 0);
            testCase.verifyEqual(model.giClS(1, deg2rad(10), deg2rad(5)), 8.0, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function lvdData = lvdFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function app = openDialog(testCase, launchFcn)
            app = launchFcn();
            drawnow;

            testCase.assertTrue(not(isempty(app)), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TabulatedLiftDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
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
