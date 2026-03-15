classdef testVehicleComponents < matlab.unittest.TestCase
    % testVehicleComponents Unit tests for LVD vehicle components
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_TwoStageToOrbit.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testStageProperties(testCase)
            lv = testCase.LvdData.launchVehicle;
            stage = lv.getStageForInd(1);
            
            testCase.verifyNotEmpty(stage.name);
            testCase.verifyGreaterThanOrEqual(stage.dryMass, 0);
        end
        
        function testTankMassProperties(testCase)
            lv = testCase.LvdData.launchVehicle;
            % [~, tanks] = lv.getTanksListBoxStr();
            [~, tanks] = lv.getTanksListBoxStr();
            
            if ~isempty(tanks)
                tank = tanks(1);
                testCase.verifyNotEmpty(tank.name);
                testCase.verifyGreaterThanOrEqual(tank.initialMass, 0);
            end
        end
        
        function testEngineProperties(testCase)
            lv = testCase.LvdData.launchVehicle;
            % [~, engines] = lv.getEnginesListBoxStr();
            [~, engines] = lv.getEnginesListBoxStr();
            
            if ~isempty(engines)
                engine = engines(1);
                testCase.verifyNotEmpty(engine.name);
                testCase.verifyGreaterThanOrEqual(engine.vacIsp, 0);
            end
        end
    end
end
