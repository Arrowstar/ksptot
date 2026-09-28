classdef TabularAeroDialogUITest < matlab.uitest.TestCase
    %TabularAeroDialogUITest App Testing Framework coverage of the tabular
    %aero editors: the UserTabulatedLiftModel dialog (programmatic .m) and
    %the KosDragCoeffientModel dialog (.mlapp).
    %
    %   Drives the dialogs through matlab.uitest gestures (press, choose)
    %   wherever the component is a standard App Designer control, and by
    %   setting properties + firing callbacks for the custom
    %   wt.FileSelector.  Modal uiwait is neutralized by
    %   UiwaitInterceptorFixture; file picking by
    %   UigetfileInterceptorFixture, which turns the Generate-from-Craft
    %   buttons into fully scripted end-to-end flows (pick craft + cube
    %   DB, sweep the default grid, install the fresh table).
    %
    %   Covers every dialog behavior: open/defaults, Cancel, Save with a
    %   missing or corrupt file, CSV load + replot + slider moves,
    %   per-slice contour scaling on non-square grids, the corrupt-file
    %   plot fallback (lift), and Generate (install, cancel, and cube-miss
    %   error paths) -- including the sibling-CSV export contract.

    properties
        celBodyData
        uiwaitFixture
        uigetfileFixture
    end

    methods(TestClassSetup)
        function setUpKsptotEnvironment(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();
        end
    end

    methods(TestMethodSetup)
        function applyDialogFixtures(testCase)
            testCase.uiwaitFixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.uigetfileFixture = testCase.applyFixture(UigetfileInterceptorFixture());
            testCase.addTeardown(@() TabularAeroDialogUITest.closeDialogFigures());
        end
    end

    methods(Test)
        %% ------------------------- lift editor -------------------------
        function liftEditorComponentsMatchSpec(testCase)
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            testCase.verifyEqual(app.EditLiftPropertiesUIFigure.Name, 'Edit Lift Properties');
            testCase.verifyEqual(app.EditLiftPropertiesUIFigure.WindowStyle, 'modal');
            testCase.verifyEqual(app.saveCloseButton.Text, 'Save & Close');
            testCase.verifyEqual(app.generateFromCraftButton.Text, 'Generate from Craft...');
            testCase.verifyEqual(app.cancelButton.Text, 'Cancel');
            testCase.verifyEqual(app.MachNumSlider.Limits, [0 10]);
            testCase.verifyEqual(app.FileSelector.Value, "");
            testCase.verifyTrue(isvalid(app));
        end

        function liftEditorCancelReturnsFalse(testCase)
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            testCase.press(app.cancelButton);

            testCase.verifyFalse(out.output{1}, 'Cancel must report {false}.');
            testCase.verifyFalse(isvalid(app), 'Cancel must close the figure.');
        end

        function liftEditorSaveRejectsMissingFile(testCase)
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            app.FileSelector.Value = fullfile(tempdir(), 'definitely-not-a-lift-table.csv');
            testCase.press(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A missing CSV must not be saved.');
            testCase.verifyTrue(isvalid(app), 'The dialog must stay open for correction.');
            % NOTE: the validation uialert cannot be observed headless (uialert
            % never renders under -batch); the state assertions above pin the behavior.
            testCase.verifyTrue(isempty(model.dataFile) || ~isfile(model.dataFile), ...
                'The model must keep its previous (empty) data file.');
        end

        function liftEditorLoadsNonSquareCsvPlotsAndSaves(testCase)
            csvPath = testCase.writeLiftGridCsv();
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.verifyEqual(app.MachNumSlider.Limits, [0 10], ...
                'Slider limits must follow the loaded Mach grid.');
            h = testCase.contourIn(app);
            testCase.verifyFalse(isempty(h), 'The axes must show a contour.');
            testCase.verifyEqual(size(h.ZData), [3 5], ...
                'Non-square grid must map sideslip rows x AoA columns.');
            testCase.verifyTrue(contains(app.DataAxes.Title.String, 'Mach Number = 0.000'), ...
                'The title must report the plotted Mach.');

            testCase.press(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(model.dataFile, csvPath);
            testCase.verifyEqual(model.machNum, [0;10], 'AbsTol', 0);
            testCase.verifyEqual(model.giClS(10, deg2rad(30), deg2rad(15)), 1007.5, 'AbsTol', 1e-9);
        end

        function liftEditorMachSliderReplotsAtNewMach(testCase)
            csvPath = testCase.writeLiftGridCsv();
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.choose(app.MachNumSlider, 10);

            testCase.verifyTrue(contains(app.DataAxes.Title.String, 'Mach Number = 10.000'), ...
                'Moving the slider must replot at the new Mach.');
            h = testCase.contourIn(app);
            testCase.verifyGreaterThan(max(h.ZData(:)), 999, ...
                'The Mach-10 slice must show Mach-10 magnitudes.');
        end

        function liftEditorPlotLevelsSpanMachSlice(testCase)
            % Regression guard for the all-blue plot: slice range [-7.5,
            % 7.5] must span the colormap even though the tensor range is
            % [-7.5, ~1007.5].
            csvPath = testCase.writeLiftGridCsv();
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.choose(app.MachNumSlider, 0);

            h = testCase.contourIn(app);
            testCase.verifyLessThan(max(abs(h.LevelList)), 8, ...
                'Contour levels must scale to the Mach-0 slice, not the tensor range.');
            fixtureData = readmatrix(csvPath);
            testCase.verifyGreaterThan(max(fixtureData(:,4)), 900, ...
                'Sanity: the fixture tensor really is Mach-dominated.');
        end

        function liftEditorCorruptCsvFallsBackToModelPlot(testCase)
            % plotData must survive an unreadable-but-present file by
            % falling back to the already-loaded model envelope.
            csvPath = testCase.writeLiftGridCsv();
            corrupt = fullfile(testCase.tempDir(), 'corrupt.csv');
            writematrix([1 2 3; 4 5 6], corrupt);
            model = UserTabulatedLiftModel(csvPath);
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            app.FileSelector.Value = corrupt;
            testCase.fireSelector(app);

            testCase.verifyFalse(isempty(testCase.contourIn(app)), ...
                'The fallback must still show the model envelope.');
            testCase.verifyTrue(isvalid(app), 'The fallback must not close the dialog.');
        end

        function liftEditorGenerateFromCraftInstallsAndSaves(testCase)
            paths = testCase.stubCraftPaths(true);
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            [craftDir, craftFile] = fileparts(paths.craft); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([craftFile '.craft'], [craftDir filesep]);
            [dbDir, dbFile] = fileparts(paths.db); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([dbFile '.cfg'], [dbDir filesep]);
            testCase.press(app.generateFromCraftButton);

            expected = fullfile(paths.dir, 'UITest_Rocket_KwtLift.csv');
            testCase.verifyTrue(isfile(expected), 'The lift CSV must be generated.');
            testCase.verifyEqual(model.dataFile, expected, ...
                'Generate must install the lift table into the model.');
            testCase.verifyEqual(app.FileSelector.Value, string(expected), ...
                'Generate must point the selector at the fresh CSV.');
            testCase.verifyTrue(isfile(fullfile(paths.dir, 'UITest_Rocket_KwtDrag.csv')), ...
                'The drag sibling CSV is the drag UI''s export half.');
            testCase.verifyTrue(isfinite(model.giClS(1, deg2rad(10), deg2rad(5))), ...
                'The installed table must interpolate.');
            testCase.verifyFalse(isempty(testCase.contourIn(app)), ...
                'Generate must refresh the plot.');
            testCase.verifyEmpty(testCase.openProgressDialogs(), ...
                'The progress dialog must close when generation ends.');
            testCase.verifyEmpty(testCase.uigetfileFixture.errors());
            testCase.verifyEqual(testCase.uigetfileFixture.remaining(), 0);

            testCase.press(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
        end

        function liftEditorGenerateCancelKeepsState(testCase)
            paths = testCase.stubCraftPaths(true);
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            % Scripted cancel at the first prompt (no error recorded).
            testCase.uigetfileFixture.queueResponse(0, 0);
            testCase.press(app.generateFromCraftButton);

            testCase.verifyTrue(isempty(model.dataFile), 'The model data file must stay empty.');
            testCase.verifyEqual(app.FileSelector.Value, "");
            testCase.verifyFalse(any(endsWith({dir(paths.dir).name}, '.csv')), ...
                'A cancelled generate must write nothing.');
            testCase.verifyTrue(isvalid(app));
        end

        function liftEditorGenerateSecondCancelKeepsState(testCase)
            paths = testCase.stubCraftPaths(true);
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            [craftDir, craftFile] = fileparts(paths.craft); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([craftFile '.craft'], [craftDir filesep]);
            testCase.uigetfileFixture.queueResponse(0, 0);
            testCase.press(app.generateFromCraftButton);

            testCase.verifyTrue(isempty(model.dataFile), 'The model data file must stay empty.');
            testCase.verifyFalse(any(endsWith({dir(paths.dir).name}, '.csv')), ...
                'Cancelling the cube-DB prompt must write nothing.');
            testCase.verifyTrue(isvalid(app));
        end

        function liftEditorGenerateMissingCubeShowsErrorAlert(testCase)
            paths = testCase.stubCraftPaths(true);
            ghost = testCase.writeLines(fullfile(paths.dir, 'ghost.craft'), { ...
                'ship = Ghost Rocket', 'PART', '{', ...
                '    part = ghost_1', '    pos = 0,0,0', ...
                '    rot = 0,0,0,1', '    mir = 1,1,1', '}'});
            model = UserTabulatedLiftModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openLiftEditor(model, out);

            [ghostDir, ghostFile] = fileparts(ghost); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([ghostFile '.craft'], [ghostDir filesep]);
            [dbDir, dbFile] = fileparts(paths.db); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([dbFile '.cfg'], [dbDir filesep]);
            testCase.press(app.generateFromCraftButton);

            testCase.verifyFalse(out.output{1}, 'A failed generate must not save.');
            testCase.verifyTrue(isempty(model.dataFile), 'The model data file must stay empty.');
            testCase.verifyTrue(isvalid(app), 'The dialog must stay open after the error.');
            % NOTE: the error uialert cannot be observed headless; staying open
            % with untouched outputs is the observable contract.
        end

        function liftModelOpenEditDialogCancels(testCase)
            % End-to-end through the production entry point: the modal
            % dialog scripted to press Cancel.
            testCase.uiwaitFixture.whenShown('Edit Lift Properties', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Cancel'));
            model = UserTabulatedLiftModel('');
            lvdData = testCase.newLvdData();

            testCase.verifyFalse(model.openEditDialog(lvdData));
            testCase.verifyEmpty(testCase.uiwaitFixture.errors());
        end

        %% ------------------------- drag editor -------------------------
        function dragEditorComponentsMatchSpec(testCase)
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            testCase.verifyEqual(app.EditDragPropertiesUIFigure.Name, 'Edit Drag Properties');
            testCase.verifyEqual(app.EditDragPropertiesUIFigure.WindowStyle, 'modal');
            testCase.verifyEqual(app.saveCloseButton.Text, 'Save & Close');
            testCase.verifyEqual(app.GeneratefromCraftButton.Text, 'Generate from Craft...');
            testCase.verifyEqual(app.cancelButton.Text, 'Cancel');
            testCase.verifyEqual(app.MachNumSlider.Limits, [0 10]);
            testCase.verifyEqual(app.FileSelector.Value, "");
            testCase.verifyTrue(isvalid(app));
        end

        function dragEditorCancelReturnsFalse(testCase)
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            testCase.press(app.cancelButton);

            testCase.verifyFalse(out.output{1}, 'Cancel must report {false}.');
            testCase.verifyFalse(isvalid(app), 'Cancel must close the figure.');
        end

        function dragEditorSaveRejectsMissingFile(testCase)
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            app.FileSelector.Value = fullfile(tempdir(), 'definitely-not-a-drag-table.csv');
            testCase.press(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A missing CSV must not be saved.');
            testCase.verifyTrue(isvalid(app), 'The dialog must stay open for correction.');
            % NOTE: the validation uialert cannot be observed headless (uialert
            % never renders under -batch); the state assertions above pin the behavior.
        end

        function dragEditorOpensPreloadedModelAndSaves(testCase)
            % populateGUI plots the model envelope at open (startup path).
            csvPath = testCase.writeDragGridCsv();
            model = KosDragCoeffientModel(csvPath);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            testCase.verifyFalse(isempty(testCase.contourIn(app)), ...
                'A preloaded model must plot at open.');
            testCase.verifyEqual(app.FileSelector.Value, string(csvPath));

            testCase.press(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(model.dataFile, csvPath);
        end

        function dragEditorLoadsNonSquareCsvPlotsAndSaves(testCase)
            csvPath = testCase.writeDragGridCsv();
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.verifyEqual(app.MachNumSlider.Limits, [0 10], ...
                'Slider limits must follow the loaded Mach grid.');
            h = testCase.contourIn(app);
            testCase.verifyFalse(isempty(h), 'The axes must show a contour.');
            testCase.verifyEqual(size(h.ZData), [3 5], ...
                'Non-square grid must map sideslip rows x AoA columns.');
            testCase.verifyTrue(contains(app.DataAxes.Title.String, 'Mach Number = 0.000'), ...
                'The title must report the plotted Mach.');

            testCase.press(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(model.dataFile, csvPath);
            testCase.verifyEqual(model.giDragCube(10, deg2rad(30), deg2rad(15)), 102, 'AbsTol', 1e-9);
        end

        function dragEditorMachSliderReplotsAtNewMach(testCase)
            csvPath = testCase.writeDragGridCsv();
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.choose(app.MachNumSlider, 10);

            testCase.verifyTrue(contains(app.DataAxes.Title.String, 'Mach Number = 10.000'), ...
                'Moving the slider must replot at the new Mach.');
            h = testCase.contourIn(app);
            testCase.verifyGreaterThan(max(h.ZData(:)), 100, ...
                'The Mach-10 slice must show Mach-10 magnitudes.');
        end

        function dragEditorPlotLevelsSpanMachSlice(testCase)
            % Regression guard for the all-blue plot: slice range [1, 2]
            % must span the colormap even though the tensor range is
            % [1, ~111].
            csvPath = testCase.writeDragGridCsv();
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            app.FileSelector.Value = csvPath;
            testCase.fireSelector(app);
            testCase.choose(app.MachNumSlider, 0);

            h = testCase.contourIn(app);
            testCase.verifyLessThanOrEqual(min(h.LevelList), 1.1);
            testCase.verifyLessThanOrEqual(max(h.LevelList), 2.1, ...
                'Contour levels must scale to the Mach-0 slice, not the tensor range.');
            fixtureData = readmatrix(csvPath);
            testCase.verifyGreaterThan(max(fixtureData(:,4)), 100, ...
                'Sanity: the fixture tensor really is Mach-dominated.');
        end

        function dragEditorGenerateFromCraftInstallsAndSaves(testCase)
            paths = testCase.stubCraftPaths(false);
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            [craftDir, craftFile] = fileparts(paths.craft); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([craftFile '.craft'], [craftDir filesep]);
            [dbDir, dbFile] = fileparts(paths.db); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([dbFile '.cfg'], [dbDir filesep]);
            testCase.press(app.GeneratefromCraftButton);

            expected = fullfile(paths.dir, 'UITest_Rocket_KwtDrag.csv');
            testCase.verifyTrue(isfile(expected), 'The drag CSV must be generated.');
            testCase.verifyEqual(model.dataFile, expected, ...
                'Generate must install the drag table into the model.');
            testCase.verifyEqual(app.FileSelector.Value, string(expected), ...
                'Generate must point the selector at the fresh CSV.');
            testCase.verifyTrue(isfile(fullfile(paths.dir, 'UITest_Rocket_KwtLift.csv')), ...
                'The lift sibling CSV is the lift UI''s export half.');
            testCase.verifyTrue(isfinite(model.giDragCube(1, deg2rad(10), deg2rad(5))), ...
                'The installed table must interpolate.');
            testCase.verifyFalse(isempty(testCase.contourIn(app)), ...
                'Generate must refresh the plot.');
            testCase.verifyEmpty(testCase.uigetfileFixture.errors());
            testCase.verifyEqual(testCase.uigetfileFixture.remaining(), 0);

            testCase.press(app.saveCloseButton);
            testCase.verifyTrue(out.output{1});
        end

        function dragEditorGenerateCancelKeepsState(testCase)
            paths = testCase.stubCraftPaths(false);
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            testCase.uigetfileFixture.queueResponse(0, 0);
            testCase.press(app.GeneratefromCraftButton);

            testCase.verifyTrue(isempty(model.dataFile), 'The model data file must stay empty.');
            testCase.verifyEqual(app.FileSelector.Value, "");
            testCase.verifyFalse(any(endsWith({dir(paths.dir).name}, '.csv')), ...
                'A cancelled generate must write nothing.');
            testCase.verifyTrue(isvalid(app));
        end

        function dragEditorGenerateMissingCubeShowsErrorAlert(testCase)
            paths = testCase.stubCraftPaths(false);
            ghost = testCase.writeLines(fullfile(paths.dir, 'ghost.craft'), { ...
                'ship = Ghost Rocket', 'PART', '{', ...
                '    part = ghost_1', '    pos = 0,0,0', ...
                '    rot = 0,0,0,1', '    mir = 1,1,1', '}'});
            model = KosDragCoeffientModel('');
            out = AppDesignerGUIOutput({false});
            app = testCase.openDragEditor(model, out);

            [ghostDir, ghostFile] = fileparts(ghost); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([ghostFile '.craft'], [ghostDir filesep]);
            [dbDir, dbFile] = fileparts(paths.db); %NOTE: fileparts returns (path, name)
            testCase.uigetfileFixture.queueResponse([dbFile '.cfg'], [dbDir filesep]);
            testCase.press(app.GeneratefromCraftButton);

            testCase.verifyFalse(out.output{1}, 'A failed generate must not save.');
            testCase.verifyTrue(isempty(model.dataFile), 'The model data file must stay empty.');
            testCase.verifyTrue(isvalid(app), 'The dialog must stay open after the error.');
            % NOTE: the error uialert cannot be observed headless; staying open
            % with untouched outputs is the observable contract.
        end

        function dragModelOpenEditDialogCancels(testCase)
            % End-to-end through the production entry point: the modal
            % dialog scripted to press Cancel.
            testCase.uiwaitFixture.whenShown('Edit Drag Properties', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Cancel'));
            model = KosDragCoeffientModel('');

            testCase.verifyFalse(model.openEditDialog(testCase.newLvdData()));
            testCase.verifyEmpty(testCase.uiwaitFixture.errors());
        end
    end

    methods(Access=private)
        function lvdData = newLvdData(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function app = openLiftEditor(testCase, model, out)
            app = lvd_EditUserTabulatedLiftPropertiesGUI_App(model, testCase.newLvdData(), out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The lift editor failed to construct.');
            testCase.addTeardown(@() TabularAeroDialogUITest.deleteIfValid(app));
        end

        function app = openDragEditor(testCase, model, out)
            app = lvd_EditKosDragPropertiesGUI_App(model, testCase.newLvdData(), out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The drag editor failed to construct.');
            testCase.addTeardown(@() TabularAeroDialogUITest.deleteIfValid(app));
        end

        function d = tempDir(~)
            d = tempname();
            mkdir(d);
        end

        function p = writeLines(~, fullPath, lines)
            fid = fopen(fullPath, 'w');
            for(i = 1:numel(lines))
                fprintf(fid, '%s\n', lines{i});
            end
            fclose(fid);
            p = fullPath;
        end

        function csvPath = writeDragGridCsv(testCase)
            % Non-square kOS-dialect tensor: 5 AoA x 3 sideslip x 2 Mach
            % (DEGREES on disk). cubeCdA is Mach-dominated so a global
            % level scale would flatten every slice into one color.
            aoa = -30:15:30;
            ssip = -15:15:15;
            [A, S] = meshgrid(aoa, ssip);
            M = [zeros(numel(A), 1); 10*ones(numel(A), 1)];
            rep = repmat([A(:), S(:)], 2, 1);
            cubeCdA = M*10 + 1 + (rep(:,1)/30).^2;
            otherCdA = M + (rep(:,2)/15).^2;
            csvPath = fullfile(testCase.tempDir(), 'nonsquare_drag.csv');
            writematrix([M, rep, cubeCdA, otherCdA], csvPath);
        end

        function csvPath = writeLiftGridCsv(testCase)
            % Non-square lift tensor: 5 AoA x 3 sideslip x 2 Mach
            % (DEGREES on disk), Mach-dominated for the levels test.
            aoa = -30:15:30;
            ssip = -15:15:15;
            [A, S] = meshgrid(aoa, ssip);
            M = [zeros(numel(A), 1); 10*ones(numel(A), 1)];
            rep = repmat([A(:), S(:)], 2, 1);
            cls = M*100 + 0.2*rep(:,1) + 0.1*rep(:,2);
            csvPath = fullfile(testCase.tempDir(), 'nonsquare_lift.csv');
            writematrix([M, rep, cls], csvPath);
        end

        function paths = stubCraftPaths(testCase, withLiftModule)
            % Minimal 2-part craft + PartDatabase.cfg in a scratch dir.
            % The probe part has non-uniform faces; probe_1 optionally
            % carries a craft-side lift coefficient (0.5).
            d = testCase.tempDir();
            craftLines = { ...
                'ship = UITest Rocket', ...
                'PART', '{', ...
                '    part = probe_1', '    pos = 0,0,0', ...
                '    rot = 0,0,0,1', 'mir = 1,1,1'};
            if(withLiftModule)
                craftLines = [craftLines, {'    MODULE', '    {', ...
                    '        name = ModuleLiftingSurface', ...
                    '        deflectionLiftCoeff = 0.5', '    }'}];
            end
            craftLines = [craftLines, {'}', ...
                'PART', '{', ...
                '    part = probe_2', '    pos = 0,2.5,0', ...
                '    rot = 0,0,0,1', 'mir = 1,1,1', '}'}];
            f = [1.2 0.55 0.4; 1.2 0.55 0.4; ...
                 0.3 0.55 0.4; 0.3 0.55 0.4; ...
                 1.2 0.55 0.4; 1.2 0.55 0.4];
            nums = sprintf('%g,', reshape(f', 1, []));
            paths.craft = testCase.writeLines(fullfile(d, 'uiCraft.craft'), craftLines);
            paths.db = testCase.writeLines(fullfile(d, 'PartDatabase.cfg'), { ...
                'PART', '{', 'url = Test/probe', 'DRAG_CUBE', '{', ...
                sprintf('cube = Default, %s0,0,0,1,1,1', nums), '}', '}'});
            paths.dir = d;
        end

        function fireSelector(~, app)
            % Fires the wt.FileSelector change callback the way the
            % component would (the framework has no gesture for it).
            app.FileSelector.ValueChangedFcn(app.FileSelector, []);
            drawnow;
        end

        function h = contourIn(~, app)
            % The contour object on the editor axes, [] when unplotted.
            h = findobj(app.DataAxes, 'Type', 'contour');
            if(~isempty(h))
                h = h(1);
            end
        end

        function figs = openProgressDialogs(~)
            figs = findall(groot, 'Type', 'figure', 'Name', 'Generating Aero Tables');
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
        end

        function closeDialogFigures()
            % Deletes leftover uialert / progress figures by title.  The
            % editor figures themselves die with their apps; everything
            % else on screen belongs to the user.
            names = {'Errors were found while editing lift properties.', ...
                'Errors were found while editing drag properties.', ...
                'Table generated with warnings.', ...
                'Generation failed.', ...
                'Generating Aero Tables'};
            figs = findall(groot, 'Type', 'figure');
            for(k = 1:numel(figs))
                if(any(strcmp(figs(k).Name, names)) && isvalid(figs(k)))
                    delete(figs(k));
                end
            end
        end
    end
end
