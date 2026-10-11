classdef ImportCraftDialogTest < KsptotTestCase
    %ImportCraftDialogTest Full round-trip UI tests for the .craft import
    %wizard (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_ImportCraftGUI_App.m
    %   (programmatic uifigure wizard, NOT a .mlapp; ctor is (lvdData) with
    %   no output object)
    %   console twin: lvd_importCraft (helper_methods/ksptot_lvd/vehicle_import).
    %
    % PATTERN
    %   The wizard blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live wizard (the
    %   PatchedMlappDialogsTest pattern).  Like MonteCarloGuiTest drives
    %   lvd_runMonteCarlo_App through its public methods with a hidden
    %   window, these tests drive the wizard through its public
    %   analyzeCurrentCraft/doImport methods with the craft path set
    %   directly, so no native file picker (uigetfile/uigetdir/uiputfile) is
    %   ever touched and no test can hang.  Figure cleanup matches the
    %   wizard Name 'Import Craft File'.
    %
    % COVERED
    %   Open points the part database at the bundled stock file with Import
    %   disabled; analyzing the stock test craft enables Import with a
    %   vessel/GLOW preview; analyzing a missing file disables Import with a
    %   failure preview; Import installs stages/engines/tanks into the LVD
    %   data; Import with nothing analyzed is a no-op.  No test propagates
    %   or optimizes.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function wizardOpensWithBundledDatabase(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);

            testCase.verifyTrue(isfile(obj.dbEdit.Value), ...
                'The part database field must point at a real file.');
            testCase.verifyEqual(char(obj.importButton.Enable), 'off', ...
                'With no craft analyzed there is nothing to import.');
            testCase.verifyTrue(contains(obj.statusLabel.Text, '.craft file'), ...
                'The status must prompt for a craft file.');
        end

        function analyzeValidCraftEnablesImport(testCase)
            craftFile = testCase.craftPath();
            testCase.assumeTrue(isfile(craftFile), 'The stock test craft is not in this checkout.');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);

            obj.craftEdit.Value = craftFile;
            obj.analyzeCurrentCraft();

            testCase.verifyEqual(char(obj.importButton.Enable), 'on', ...
                'A successful analysis must enable Import.');
            testCase.verifyTrue(any(contains(obj.previewTextArea.Value, 'Vessel:')), ...
                'The preview must name the vessel.');
            testCase.verifyTrue(contains(obj.statusLabel.Text, 'Analysis complete'), ...
                'The status must confirm the analysis.');
            testCase.verifyFalse(isempty(obj.warningsTextArea.Value), ...
                'The warnings pane must always say something.');
        end

        function analyzeMissingFileDisablesImport(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);

            obj.craftEdit.Value = fullfile(tempname(), 'no-such-craft.craft');
            obj.analyzeCurrentCraft();

            testCase.verifyEqual(char(obj.importButton.Enable), 'off', ...
                'A failed analysis must leave Import disabled.');
            testCase.verifyEqual(obj.previewTextArea.Value, {'Analysis failed.'});
            testCase.verifyFalse(isempty(obj.warningsTextArea.Value), ...
                'The failure reason must land in the warnings pane.');
        end

        function importInstallsVehicleIntoLvdData(testCase)
            craftFile = testCase.craftPath();
            testCase.assumeTrue(isfile(craftFile), 'The stock test craft is not in this checkout.');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);

            obj.craftEdit.Value = craftFile;
            obj.analyzeCurrentCraft();
            testCase.assertEqual(char(obj.importButton.Enable), 'on', ...
                'Fixture: the stock craft must analyze cleanly.');

            obj.doImport();

            [nStg, nEng, nTnk] = testCase.countVehicle(lvdData.launchVehicle);
            testCase.verifyGreaterThan(nStg, 0, 'The import must install stages.');
            testCase.verifyGreaterThan(nEng + nTnk, 0, 'The import must install engines and tanks.');
            testCase.verifyTrue(contains(obj.statusLabel.Text, 'Import complete'), ...
                'The status must confirm the import.');
            testCase.verifyEqual(char(obj.importButton.Enable), 'off', ...
                'Import must disable itself once done.');
        end

        function doImportWithNoAnalysisIsNoOp(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);
            [bStg, bEng, bTnk] = testCase.countVehicle(lvdData.launchVehicle);

            obj.doImport();

            [aStg, aEng, aTnk] = testCase.countVehicle(lvdData.launchVehicle);
            testCase.verifyEqual([aStg, aEng, aTnk], [bStg, bEng, bTnk], ...
                'Import with nothing analyzed must leave the vehicle alone.');
        end

        function previewListsStagesAndPropulsion(testCase)
            craftFile = testCase.craftPath();
            testCase.assumeTrue(isfile(craftFile), 'The stock test craft is not in this checkout.');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            obj = testCase.openWizard(lvdData);

            obj.craftEdit.Value = craftFile;
            obj.analyzeCurrentCraft();

            prev = obj.previewTextArea.Value;
            testCase.verifyTrue(any(contains(prev, 'GLOW')), 'The preview must report the GLOW mass.');
            testCase.verifyTrue(any(contains(prev, 'dry')), 'The preview must break down stage dry mass.');
        end
    end

    methods(Access=private)
        function p = craftPath(~)
            p = fullfile(ksptotTestRoot(), 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', 'Kerbal 1-5_3.craft');
        end

        function obj = openWizard(testCase, lvdData)
            obj = lvd_ImportCraftGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(obj) && isvalid(obj.UIFigure), ...
                'The wizard constructor returned nothing.');
            obj.UIFigure.Visible = 'off';
            testCase.addTeardown(@() ImportCraftDialogTest.deleteWizard(obj));
        end

        function [nStg, nEng, nTnk] = countVehicle(~, lv)
            nStg = numel(lv.stages);
            nEng = 0;
            nTnk = 0;
            for i = 1:numel(lv.stages)
                nEng = nEng + numel(lv.stages(i).engines);
                nTnk = nTnk + numel(lv.stages(i).tanks);
            end
        end
    end

    methods(Static, Access=private)
        function deleteWizard(obj)
            if ~isempty(obj) && isvalid(obj) && isvalid(obj.UIFigure)
                delete(obj.UIFigure);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Import Craft File')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
