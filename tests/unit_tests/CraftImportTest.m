classdef CraftImportTest < KsptotTestCase
    %CraftImportTest End-to-end tests for the KSP craft-file import
    %pipeline: part database loading, craft analysis (stage/tank/engine
    %inference incl. asparagus detection), vehicle construction, and
    %installation into LVD case data.
    %
    %The bundled database (resources/partsDatabaseStockKSP.json) is a full
    %GameData export of stock KSP 1.12 -- 391 parts, keyed by the *cfg*
    %part names, which use '_' (liquidEngine3_v2).  It replaced an earlier
    %hand-built 17-part mini fixture that keyed on the '.' forms.  Craft
    %files write '.' where the cfg has '_' (the '_' is the instance-id
    %separator), so the dot/underscore normalization in
    %lvd_import_analyzeCraft is what bridges the two; a direct
    %db.parts(...) lookup here must use the underscore form.
    %
    %Every numeric expectation below was hand-summed from the JSON's own
    %mass_t / resources_u values against lvd_import_resourceDensities, not
    %read back off the pipeline.  If the database is re-exported from a
    %different KSP install, re-derive them the same way.

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
            testCase.verifyTrue(db.parts.Count() >= 300, ...
                'Bundled DB should be the full stock GameData export.');

            % Underscore keys: these are cfg part names, not craft names.
            eng = db.parts('liquidengine3_v2');
            testCase.verifyEqual(eng.mass_t, 0.5, 'AbsTol', 1e-9);
            testCase.verifyEqual(eng.engines(1).maxThrust_kN, 60, 'AbsTol', 1e-9);
            testCase.verifyEqual(eng.engines(1).ispVac_s, 345, 'AbsTol', 1e-9);
            testCase.verifyEqual(eng.engines(1).ispSL_s, 85, 'AbsTol', 1e-9);

            srb = db.parts('solidbooster_v2');
            testCase.verifyEqual(srb.mass_t, 0.75, 'AbsTol', 1e-9);
            testCase.verifyEqual(srb.resources_u.SolidFuel, 375, 'AbsTol', 1e-9);
            testCase.verifyEqual(srb.engines(1).maxThrust_kN, 227, 'AbsTol', 1e-9);
        end

        function craftDotNamesResolveAgainstUnderscoreDbKeys(testCase)
            % KSP craft files write '.' where the part cfg has '_', so
            % every part in the example craft is spelled differently from
            % its database key. Nothing is aliased into the map -- the
            % normalization happens at lookup time inside
            % lvd_import_analyzeCraft -- so this is the test that catches a
            % regression there, or a re-export that changes the key style.
            db = testCase.partDB;
            testCase.verifyTrue(isKey(db.parts, 'liquidengine3_v2'));
            testCase.verifyTrue(isKey(db.parts, 'solidbooster_v2'));

            [spec, report] = lvd_import_analyzeCraft(testCase.mainCraftPath, db);

            testCase.verifyEmpty(report.unresolvedParts, ...
                'Every craft part must resolve to a database entry.');
            testCase.verifyEmpty(spec.warnings);
        end

        function rejectsMissingDatabaseFile(testCase)
            testCase.verifyError( ...
                @() lvd_import_getPartDatabase('no_such_db_file.json'), ...
                'lvd_import:fileNotFound');
        end

        function bundledDbTitlesAreDisplayNamesNotTags(testCase)
            % Titles drive every engine/tank name the user sees in the
            % import preview and in the built launch vehicle. Stock cfgs
            % store them as '#autoLOC_*' tags, so a DB re-exported without
            % localization resolution silently degrades every title to the
            % internal part name ('liquidEngine2' for the Swivel).
            db = testCase.partDB;

            testCase.verifyEqual(db.parts('liquidengine2').title, ...
                'LV-T45 "Swivel" Liquid Fuel Engine');
            testCase.verifyEqual(db.parts('liquidengine3_v2').title, ...
                'LV-909 "Terrier" Liquid Fuel Engine');
            testCase.verifyEqual(db.parts('solidbooster').title, ...
                'RT-10 "Hammer" Solid Fuel Booster');

            % Nothing anywhere in the DB should still be a raw tag.
            pKeys = keys(db.parts);
            for(i = 1:numel(pKeys))
                entry = db.parts(pKeys{i});
                testCase.verifyFalse(startsWith(entry.title, '#'), ...
                    sprintf('Part "%s" has an unresolved localization title "%s".', ...
                            entry.name, entry.title));
            end
        end

        function gameDataScanResolvesLocalizedTitles(testCase)
            % Builds a miniature GameData tree so this does not need a KSP
            % install: one part whose title is a tag covered by the
            % dictionary, and one whose tag is covered only by the inline
            % '//#autoLOC_x = ...' comment KSP writes beside it.
            gameData = testCase.buildMiniGameData();

            [db, warnings] = lvd_import_getPartDatabase(gameData);

            testCase.verifyEmpty(warnings);
            testCase.verifyEqual(db.parts('testengine').title, ...
                'TE-1 "Kettle" Liquid Fuel Engine');
            testCase.verifyEqual(db.parts('testtank').title, ...
                'TT-100 Fuel Tank');

            % Titles must not disturb the rest of the entry.
            testCase.verifyEqual(db.parts('testengine').mass_t, 1.25, 'AbsTol', 1e-9);
            testCase.verifyEqual(db.parts('testengine').engines(1).maxThrust_kN, ...
                240, 'AbsTol', 1e-9);
        end

        function unresolvableTitleTagFallsBackToPartName(testCase)
            % A tag with no dictionary entry and no inline comment must
            % degrade to the internal name, never to the raw tag.
            gameData = testCase.buildMiniGameData();
            cfgPath = fullfile(gameData, 'TestMod', 'Parts', 'orphan.cfg');
            writeLines(cfgPath, { ...
                'PART', '{', ...
                '    name = orphanPart', ...
                '    title = #autoLOC_doesNotExist', ...
                '    mass = 0.5', '}'});

            db = lvd_import_getPartDatabase(gameData);

            testCase.verifyEqual(db.parts('orphanpart').title, 'orphanPart');
        end

        function localizationLoaderHonoursLanguageSelection(testCase)
            gameData = testCase.buildMiniGameData();

            enMap = lvd_import_loadLocalization(gameData);
            testCase.verifyEqual(enMap('#autoloc_test_engine'), ...
                'TE-1 "Kettle" Liquid Fuel Engine');

            frMap = lvd_import_loadLocalization(gameData, 'fr-fr');
            testCase.verifyEqual(frMap('#autoloc_test_engine'), ...
                'Moteur TE-1 "Kettle"');

            % A language the dictionary does not carry falls back to en-us
            % rather than returning nothing.
            deMap = lvd_import_loadLocalization(gameData, 'de-de');
            testCase.verifyEqual(deMap('#autoloc_test_engine'), ...
                'TE-1 "Kettle" Liquid Fuel Engine');

            frDb = lvd_import_getPartDatabase(struct('gameDataPath', gameData, ...
                                                     'language', 'fr-fr'));
            testCase.verifyEqual(frDb.parts('testengine').title, ...
                'Moteur TE-1 "Kettle"');
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

            % Hand-summed over the craft's 27 part instances as
            % sum(mass_t + sum(resources_u .* density)); the two solid
            % boosters contribute 2*(0.75 + 375*0.0075) = 7.125 of it.
            expectedGlow = 17.44;
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
            % 2*(375*0.0075) SolidFuel + 4.0 FL-T800 + 2.0 FL-T400
            % + 0.04 pod monoprop + 0.08 radial RCS tank.
            testCase.verifyEqual(totalProp, 11.745, 'AbsTol', 1e-6);
            testCase.verifyEqual(numel(newLv.engineTankConns), 4);
        end

        function builtEnginesHavePressureCurvesFromFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            spec = lvd_import_analyzeCraft(testCase.mainCraftPath, ...
                                           testCase.partDB);
            newLv = lvd_import_createLaunchVehicle(lvdData, spec);

            % Built engines are named from the database entry's title.
            % Stock KSP 1.12 cfgs carry localization tags ('#autoLOC_...')
            % rather than literal titles; the GameData scanner resolves
            % them against GameData/**/Localization/*.cfg, so the exported
            % DB titles the Swivel 'LV-T45 "Swivel" Liquid Fuel Engine'.
            % Take the expected name from the DB so this keeps working
            % across re-exports.
            swivelName = testCase.partDB.parts('liquidengine2').title;

            swivel = [];
            for(i = 1:newLv.getNumStages())
                stage = newLv.getStageForInd(i);
                for(j = 1:length(stage.engines))
                    if(startsWith(stage.engines(j).name, swivelName))
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
                375 * 0.0075, 'AbsTol', 1e-9);   % one booster's SolidFuel
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

    methods(Access = private)
        function gameData = buildMiniGameData(testCase)
            %buildMiniGameData Writes a throwaway GameData tree holding one
            %localization dictionary and two part cfgs, mirroring how stock
            %KSP stores titles. Removed automatically at test teardown.

            import matlab.unittest.fixtures.TemporaryFolderFixture;
            tmp = testCase.applyFixture(TemporaryFolderFixture);

            gameData = fullfile(tmp.Folder, 'GameData');
            partsDir = fullfile(gameData, 'TestMod', 'Parts');
            locDir = fullfile(gameData, 'TestMod', 'Localization');
            mkdir(partsDir);
            mkdir(locDir);

            writeLines(fullfile(locDir, 'dictionary.cfg'), { ...
                'Localization', '{', ...
                '    en-us', '    {', ...
                '        #autoLOC_test_engine = TE-1 "Kettle" Liquid Fuel Engine', ...
                '        #autoLOC_test_tank = ignored, the part has no such tag', ...
                '    }', ...
                '    fr-fr', '    {', ...
                '        #autoLOC_test_engine = Moteur TE-1 "Kettle"', ...
                '    }', ...
                '}'});

            % Title covered by the dictionary.
            writeLines(fullfile(partsDir, 'engine.cfg'), { ...
                'PART', '{', ...
                '    name = testEngine', ...
                '    title = #autoLOC_test_engine', ...
                '    mass = 1.25', ...
                '    MODULE', '    {', ...
                '        name = ModuleEngines', ...
                '        maxThrust = 240', ...
                '        atmosphereCurve', '        {', ...
                '            key = 0 300', ...
                '            key = 1 250', ...
                '        }', ...
                '        PROPELLANT', '        {', ...
                '            name = LiquidFuel', ...
                '        }', ...
                '    }', '}'});

            % Title covered only by the inline comment KSP writes.
            writeLines(fullfile(partsDir, 'tank.cfg'), { ...
                'PART', '{', ...
                '    name = testTank', ...
                '    title = #autoLOC_test_tank_inline //#autoLOC_test_tank_inline = TT-100 Fuel Tank', ...
                '    mass = 0.5', ...
                '    RESOURCE', '    {', ...
                '        name = LiquidFuel', ...
                '        amount = 180', ...
                '        maxAmount = 180', ...
                '    }', '}'});
        end
    end
end

function writeLines(filePath, lines)
%writeLines Writes a cellstr out as a newline-terminated text file.

    fid = fopen(filePath, 'w');
    if(fid < 0)
        error('CraftImportTest:writeFailed', 'Could not write %s', filePath);
    end
    closer = onCleanup(@() fclose(fid));

    for(i = 1:numel(lines))
        fprintf(fid, '%s\n', lines{i});
    end

end
