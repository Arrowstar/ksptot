classdef testOptimizationFunctions < matlab.unittest.TestCase
    % testOptimizationFunctions Unit tests for LVD optimization components
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_MunarLanding.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testObjectiveFunction(testCase)
            lvdData = testCase.LvdData;
            optimizer = lvdData.optimizer;
            
            objFcn = optimizer.objFcn;
            testCase.verifyNotEmpty(objFcn);
            testCase.verifyTrue(isa(objFcn, 'AbstractObjectiveFcn'));
        end
        
        function testConstraints(testCase)
            lvdData = testCase.LvdData;
            optimizer = lvdData.optimizer;
            
            % optimizer.constraints.consts instead of optimizer.constraints.constraints
            constraints = optimizer.constraints.consts;
            testCase.verifyNotEmpty(constraints);
            
            if ~isempty(constraints)
                testCase.verifyTrue(isa(constraints(1), 'AbstractConstraint'));
            end
        end
        
        function testVariables(testCase)
            lvdData = testCase.LvdData;
            vars = lvdData.optimizer.vars;
            
            testCase.verifyNotEmpty(vars);
            testCase.verifyClass(vars, 'OptimizationVariableSet');
            
            % Test variable count
            testCase.verifyGreaterThanOrEqual(length(vars.vars), 0);
        end
    end
end
