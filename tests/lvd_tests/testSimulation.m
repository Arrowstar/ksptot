classdef testSimulation < matlab.unittest.TestCase
    % testSimulation Unit tests for LVD simulation driver and integrators
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_SimpleHohmannTransfer.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testSimulationExecution(testCase)
            lvdData = testCase.LvdData;
            % Reset and run simulation
            lvdData.script.executeScript(false, LaunchVehicleEvent.empty(1,0), true, false, false, false);
            
            stateLog = lvdData.stateLog;
            testCase.verifyGreaterThan(stateLog.getNumberOfEntries(), 1);
        end
        
        function testIntegratorLogic(testCase)
            lvdData = testCase.LvdData;
            % getEventForInd instead of getEventNum
            evt = lvdData.script.getEventForInd(1);
            
            integrator = evt.integratorObj;
            testCase.verifyNotEmpty(integrator);
            testCase.verifyTrue(isa(integrator, 'AbstractIntegrator'));
        end
        
        function testStateLog(testCase)
            lvdData = testCase.LvdData;
            stateLog = lvdData.stateLog;
            
            entry = stateLog.getFinalStateLogEntry();
            testCase.verifyNotEmpty(entry);
            % entry.position instead of entry.r
            testCase.verifySize(entry.position, [3, 1]);
            testCase.verifyGreaterThan(entry.time, 0);
        end
    end
end
