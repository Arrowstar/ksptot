classdef CraftFileParserTest < KsptotTestCase
    %CraftFileParserTest Tests for the generic SFS/config-node parser
    %against the example KSP craft files checked into the repository.

    properties
        dragDataDir
        mainCraftPath
        noBoostersCraftPath
        noFirstStageCraftPath
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
    end

    methods(Test)
        function parsesHeaderFields(testCase)
            craft = sfsParse(testCase.mainCraftPath);

            testCase.verifyEqual(craft.ship, 'Kerbal 1-5_3');
            testCase.verifyEqual(craft.version, '1.12.0');
            testCase.verifyEqual(craft.type, 'VAB');
            testCase.verifyEqual(craft.vesselType, 'Debris');
        end

        function parsesPartCountsForAllExampleCrafts(testCase)
            craftMain = sfsParse(testCase.mainCraftPath);
            craftNoBoosters = sfsParse(testCase.noBoostersCraftPath);
            craftNoFirstStage = sfsParse(testCase.noFirstStageCraftPath);

            testCase.verifyNumElements(craftMain.PART, 28);
            testCase.verifyNumElements(craftNoBoosters.PART, 22);
            testCase.verifyNumElements(craftNoFirstStage.PART, 15);
        end

        function parsesNestedModuleAndResourceBlocks(testCase)
            craft = sfsParse(testCase.mainCraftPath);
            pod = craft.PART{1};

            testCase.verifyEqual(pod.part, 'mk1pod.v2_4294620364');
            testCase.verifyEqual(pod.istg, '-1');
            testCase.verifyEqual(pod.dstg, '0');
            testCase.verifyNumElements(pod.MODULE, 14);
            testCase.verifyNumElements(pod.RESOURCE, 2);

            testCase.verifyEqual(pod.RESOURCE{1}.name, 'ElectricCharge');
            testCase.verifyEqual(pod.RESOURCE{1}.maxAmount, '50');
            testCase.verifyEqual(pod.RESOURCE{2}.name, 'MonoPropellant');
        end

        function collectsRepeatedKeysAsCellArrays(testCase)
            craft = sfsParse(testCase.mainCraftPath);
            pod = craft.PART{1};

            testCase.verifyClass(pod.link, 'cell');
            testCase.verifyNumElements(pod.link, 4);
            testCase.verifyEqual(pod.link{3}, 'Decoupler.1_4294606904');

            % attN appears twice (top and bottom attachment nodes).
            testCase.verifyClass(pod.attN, 'cell');
            testCase.verifyNumElements(pod.attN, 2);
            testCase.assertTrue(strncmp(pod.attN{1}, 'bottom,', 7));
        end

        function handlesDeeplyNestedBlocks(testCase)
            craft = sfsParse(testCase.mainCraftPath);
            enginePart = craft.PART{14};
            testCase.verifyEqual(enginePart.part, 'liquidEngine3.v2_4294583320');

            moduleNames = cellfun(@(m) m.name, enginePart.MODULE, ...
                                  'UniformOutput', false);
            testCase.assertTrue(any(strcmp(moduleNames, 'ModuleEngines')));
            testCase.assertTrue(any(strcmp(moduleNames, 'ModuleGimbal')));

            engMod = enginePart.MODULE{strcmp(moduleNames, 'ModuleEngines')};
            testCase.verifyEqual(engMod.thrustPercentage, '100');
        end

        function stripsCommentsOutsideQuotes(testCase)
            sample = sprintf('a = 1 // trailing comment\nb = "x // y"\n');
            node = sfsParse(sample);

            testCase.verifyEqual(node.a, '1');
            testCase.verifyEqual(node.b, 'x // y');
        end

        function handlesLfAndCrlfLineEndings(testCase)
            crlf = sprintf('ship = A\r\nPART\r\n{\r\n\tpart = p_1\r\n}\r\n');
            lf = sprintf('ship = A\nPART\n{\n\tpart = p_1\n}\n');

            nCrlf = sfsParse(crlf);
            nLf = sfsParse(lf);

            testCase.verifyEqual(numel(nCrlf.PART), 1);
            testCase.verifyEqual(numel(nLf.PART), 1);
            testCase.verifyEqual(nCrlf.ship, nLf.ship);
        end

        function acceptsRawTextAndFilePathEqually(testCase)
            text = fileread(testCase.noFirstStageCraftPath);
            fromText = sfsParse(text);
            fromFile = sfsParse(testCase.noFirstStageCraftPath);

            testCase.verifyEqual(fieldnames(fromText), fieldnames(fromFile));
            testCase.verifyEqual(fromText.ship, fromFile.ship);
            testCase.verifyEqual(numel(fromText.PART), numel(fromFile.PART));
        end

        function emptyBlocksProduceCellWithEmptyStruct(testCase)
            sample = sprintf('EVENTS\n{\n}\nafter = yes\n');
            node = sfsParse(sample);

            testCase.verifyEqual(node.after, 'yes');
            testCase.assertEqual(numel(node.EVENTS), 1);
            testCase.assertTrue(isempty(fieldnames(node.EVENTS{1})));
        end
    end
end
