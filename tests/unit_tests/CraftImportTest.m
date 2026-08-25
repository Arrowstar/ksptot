classdef CraftImportTest < KsptotTestCase
    %CraftImportTest End-to-end tests for the KSP craft-file import
    %pipeline: part database loading, craft analysis (stage/tank/engine
    %inference incl. asparagus detection), vehicle construction, and
    %installation into LVD case data.

    properties
        dragDataDir
        mainCraftPath
        noBoostersCraftPath
        noFirstStageCraftPath
        partDB
    end

    methods(TestClassSetup)
        function locateFixtures(testCase)
            root = ksptotTestRoot();
            testCase.dragDataDir = fullfile(root, 'examples', ...
                'LaunchVehicleDesigner', 'kOSOpenLoopControlKerbinLaunch', ...
                'DragData');
            testCase.mainCraftPath = fullfile(testCase.dragDataDir, ...
                'Kerbal 1-5_3.craft');
            testCase.noBoostersCraftPath = fullfile(testCase.dragDataDir, ...
                'Kerbal 1-5_3_NoBoosters.craft');
            testCase.noFirstStageCraftPath = fullfile(testCase.dragDataDir, ...
                'Kerbal 1-5_3_NoBoosters_NoFirstStage.craft');

            testCase.assertTrue(isfile(testCase.mainCraftPath), ...
                'Example craft file missing');
        end

        function loadSharedData(testCase)
            testCase.partDB = lvd_import_getPartDatabase();
        end
    end

    methods(Test)
        %% ------------------------------------------------- part database
        function loadsBundledDatabase(testCase)
            db = testCase.partDB;

            testCase.verifyEqual(db.schemaVersion, 1);
            testCase.verifyTrue(db.parts.Count() >= 17);

            eng = db.parts(lower('liquidEngine3.v2'));
            testCase.verifyEqual(eng.mass_t, 0.5, 'AbsTol', 1e-9);
            testCase.verifyEqual(eng.engines(1).maxThrust_kN, 60, 'AbsTol', 1e-9);
            testCase.verifyEqual(eng.engines(1).ispVac_s, 345, 'AbsTol', 1e-9);

            srb = db.parts('solidbooster.v2');
            testCase.verifyEqual(srb.resources_u.SolidFuel, 365, 'AbsTol', 1e-9);
        end

        function rejectsMissingDatabaseFile(testCase)
            testCase.verifyError( ...
                @() lvd_import_getPartDatabase('no_such_db_file.json'), ...
                'lvd_import:fileNotFound');
        end

        %% --------------------------------------------------- analysis
        function analyzesFullExampleIntoFourStages(testCase)
            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);

            testCase.verifyEqual(spec.name, 'Kerbal 1-5_3');
            testCase.verifyEqual(numel(spec.stages), 4);
            testCase.verifyEmpty(spec.warnings);
        end

        function stageOrderAndContentsMatchKspStaging(testCase)
            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);

            % Stage 1: the two radial solid boosters (ignite at istg 6,
            % separate at istg 5).
            s1 = spec.stages(1);
            testCase.verifyNumElements(s1.engines, 2);
            testCase.verifyNumElements(s1.tanks, 2);
            testCase.verifyEqual(s1.engines(1).vacThrust_kN, 227, 'AbsTol', 1e-9);
            testCase.verifyEqual(s1.tanks(1).fluidTypeName, 'Solid Fuel');

            % Each booster engine draws only from its own internal tank.
            testCase.verifyNumElements(s1.e2tConns, 2);
            for(c = 1:2)
                conn = s1.e2tConns(c);
                testCase.verifyEqual(conn.engineIdx, conn.tankIdx);
            end

            % Stage 2: first liquid stage - Swivel + FL-T800.
            s2 = spec.stages(2);
            testCase.verifyNumElements(s2.engines, 1);
            testCase.verifyEqual(s2.engines(1).partName, 'liquidEngine2');
            testCase.verifyEqual(s2.tanks(1).partName, 'fuelTank.long');
            testCase.verifyEqual(s2.tanks(1).propMass_mT, 4.0, 'AbsTol', 1e-9);

            % Stage 3: second stage - Terrier + FL-T400 (+ pod section
            % merged in).
            s3 = spec.stages(3);
            testCase.verifyNumElements(s3.engines, 1);
            testCase.verifyEqual(s3.engines(1).partName, 'liquidEngine3.v2');
            testCase.verifyEqual(s3.tanks(1).partName, 'fuelTank');
            testCase.verifyEqual(s3.tanks(1).propMass_mT, 2.0, 'AbsTol', 1e-9);
        end

        function glowMatchesSumOfParts(testCase)
            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);

            expectedGlow = 17.725; % hand-summed from fixture DB values
            testCase.verifyEqual(spec.stats.glow_mT, expectedGlow, ...
                'AbsTol', 1e-6);
        end

        function engineSeaLevelThrustDerivesFromIspRatio(testCase)
            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);

            terrier = spec.stages(3).engines(1);
            expectedSL = 60 * 85 / 345;
            testCase.verifyEqual(terrier.ispSL_s, 85, 'AbsTol', 1e-9);
            testCase.verifyEqual(expectedSL, 14.782608695652174, 'AbsTol', 1e-12);
        end

        function variantCraftsAnalyzeConsistently(testCase)
            sp2 = lvd_import_analyzeCraft(testCase.noBoostersCraftPath, ...
                                          testCase.partDB);
            sp3 = lvd_import_analyzeCraft(testCase.noFirstStageCraftPath, ...
                                          testCase.partDB);

            % No boosters: Hammer engines gone.
            testCase.verifyEqual(sp2.stats.numEngines, 2);
            testCase.assertTrue(sp2.stats.glow_mT < ...
                lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                        testCase.partDB).stats.glow_mT);

            % No first stage either: Swivel gone.
            testCase.verifyEqual(sp3.stats.numEngines, 1);
            engineNames = arrayfun(@(e) e.partName, sp3.stages(1).engines, ...
                                   'UniformOutput', false);
            testCase.assertTrue(any(strcmp(engineNames, 'liquidEngine3.v2')));
        end

        function unknownPartProducesWarningAndPlaceholder(testCase)
            craftText = sprintf(['ship = UnknownPartTest\n', ...
                'PART\n{\n\tpart = mystery_part_999\n\tistg = -1\n}\n']);
            spec = lvd_import_analyzeCraft(craftText, testCase.partDB);

            testCase.verifyNotEmpty(spec.warnings);
            testCase.verifyEqual(spec.stats.glow_mT, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(spec.stats.numStages, 1);
        end

        %% ------------------------------------------------- asparagus
        function fuelLineCreatesTankToTankConnection(testCase)
            % Synthetic drop-tank craft: a core stack plus one radial tank
            % cluster feeding the core through a fuel line. The radial
            % decoupler (istg 1) fires after the core engine ignition
            % (istg 2).
            craftText = sprintf([ ...
                'ship = DropTankTest\n' ...
                'PART\n{\n\tpart = mk1pod.v2_100\n\tistg = -1\n\tlink = fuelTank_101\n\tlink = radialDecoupler2_102\n}\n' ...
                'PART\n{\n\tpart = fuelTank_101\n\tistg = 2\n\tlink = liquidEngine2_105\n}\n' ...
                'PART\n{\n\tpart = radialDecoupler2_102\n\tistg = 1\n\tlink = fuelTank.long_103\n}\n' ...
                'PART\n{\n\tpart = fuelTank.long_103\n\tistg = 1\n\tlink = fuelLineSmall_104\n}\n' ...
                'PART\n{\n\tpart = fuelLineSmall_104\n\ttarget = fuelTank_101\n}\n' ...
                'PART\n{\n\tpart = liquidEngine2_105\n\tistg = 2\n}\n']);

            spec = lvd_import_analyzeCraft(craftText, testCase.partDB);

            testCase.verifyEqual(spec.stats.numStages, 2, ...
                'Cluster and core should form two sequential stages');
            testCase.verifyNumElements(spec.t2tConns, 1);

            conn = spec.t2tConns(1);
            srcTank = spec.stages(conn.srcStageIdx).tanks(conn.srcTankIdx);
            tgtTank = spec.stages(conn.tgtStageIdx).tanks(conn.tgtTankIdx);

            testCase.verifyEqual(srcTank.instanceID, 'fuelTank.long_103');
            testCase.verifyEqual(tgtTank.instanceID, 'fuelTank_101');
            testCase.verifyGreaterThan(conn.flowRate_mTs, 0);
        end

        %% ----------------------------------------------- vehicle build
        function buildsLaunchVehicleWithCorrectMasses(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);
            newLv = lvd_import_createLaunchVehicle(lvdData, spec);

            testCase.verifyEqual(newLv.getNumStages(), 4);

            totalProp = 0;
            for(i = 1:newLv.getNumStages())
                stage = newLv.getStageForInd(i);
                totalProp = totalProp + stage.getStageInitPropMass();
            end
            testCase.verifyEqual(totalProp, 11.755, 'AbsTol', 1e-6);
            testCase.verifyEqual(numel(newLv.engineTankConns), 4);
        end

        function builtEnginesHavePressureCurvesFromFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);
            newLv = lvd_import_createLaunchVehicle(lvdData, spec);

            swivel = [];
            for(i = 1:newLv.getNumStages())
                stage = newLv.getStageForInd(i);
                for(j = 1:length(stage.engines))
                    if(strcmp(stage.engines(j).name, ...
                              'LV-T45 "Swivel" Liquid Fuel Engine'))
                        swivel = stage.engines(j);
                    end
                end
            end

            testCase.assertFalse(isempty(swivel));
            testCase.verifyEqual(swivel.getVacThrust(), 215, 'AbsTol', 1e-6);
            testCase.verifyEqual(swivel.getVacIsp(), 320, 'AbsTol', 1e-6);
            testCase.verifyEqual(swivel.getSeaLvlThrust(), 215*250/320, ...
                'AbsTol', 1e-6);
            testCase.verifyEqual(swivel.getSeaLvlIsp(), 250, 'AbsTol', 1e-6);
        end

        function applyToLvdDataRegeneratesInitialStates(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);
            newLv = lvd_import_createLaunchVehicle(lvdData, spec);
            lvdData = lvd_import_applyToLvdData(lvdData, newLv);

            ism = lvdData.initStateModel;
            testCase.verifyEqual(numel(ism.stageStates), 4);

            numTankStates = sum(cellfun(@numel, ...
                                        {ism.stageStates.tankStates}));
            numEngineStates = sum(cellfun(@numel, ...
                                          {ism.stageStates.engineStates}));
            testCase.verifyEqual(numTankStates, 6);
            testCase.verifyEqual(numEngineStates, 4);

            % Tank states must reference the new tanks with full masses.
            s1State = ism.stageStates(1);
            testCase.verifyEqual(s1State.tankStates(1).tankMass, ...
                2.7375, 'AbsTol', 1e-9);
        end

        function addsSolidFuelFluidTypeOnDemand(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);
            newLv = lvd_import_createLaunchVehicle(lvdData, spec);

            typeNames = {};
            for(i = 1:length(newLv.tankTypes.types))
                typeNames{end+1} = newLv.tankTypes.types(i).name; %#ok<AGROW>
            end
            testCase.assertTrue(any(strcmp(typeNames, 'Solid Fuel')));
        end
    end
end
