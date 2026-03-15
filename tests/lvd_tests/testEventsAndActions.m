classdef testEventsAndActions < matlab.unittest.TestCase
    % testEventsAndActions Unit tests for LVD events and actions
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_ElecPowerExample.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testFuelFlowAndConsumption(testCase)
            lvdData = testCase.LvdData;
            lv = lvdData.initialState.lvState.lv;
            
            % Get an engine and verify its properties
            engineStrs = lv.getEnginesListBoxStr();
            testCase.verifyNotEmpty(engineStrs);
            
            engine = lv.getEngineForInd(1);
            testCase.verifyNotEmpty(engine);
            
            % Verify math: mdot = F / (g0 * Isp)
            ut = 0;
            pressure = 101.325; % 1 atm
            throttle = 1.0;
            [thrust, mdot] = engine.getThrustFlowRateForPressure(pressure);
            testCase.verifyNotEmpty(mdot);
            
            [~, isp] = engine.getThrustIspForPressure(pressure);
            % KSPTOT uses g0 = 9.80665 m/s^2 for Isp conversion, but thrust is kN and mdot is mT/s.
            % mdot (mT/s) = Thrust (kN) / (g0_standard (m/s^2) * Isp (s))
            g0_standard = 9.80665; 
            
            expectedMdotTotal = thrust / (g0_standard * isp);
            actualMdotTotal = abs(mdot);
            
            testCase.verifyEqual(actualMdotTotal, expectedMdotTotal, 'RelTol', 1e-4, 'Fuel flow rate mismatch based on thrust/Isp');
        end
        
        function testElectricalCharge(testCase)
            lv = testCase.LvdData.launchVehicle;
            % getPowerStoragesListBoxStr to see what we have
            [~, storages] = lv.getPowerStoragesListBoxStr();
            
            if isempty(storages)
                testCase.assumeFail('No electrical storage in this example');
            end
            
            storage = storages(1);
            testCase.verifyNotEmpty(storage.getName());
        end
        
        function testTerminationConditions(testCase)
            lvdData = testCase.LvdData;
            % getEventForInd instead of getEventNum
            evt = lvdData.script.getEventForInd(1);
            testCase.verifyNotEmpty(evt);
            
            termCond = evt.termCond;
            testCase.verifyNotEmpty(termCond);
        end
    end
end
