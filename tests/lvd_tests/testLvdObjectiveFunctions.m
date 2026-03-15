classdef testLvdObjectiveFunctions < matlab.unittest.TestCase
    properties
        LvdData LvdData
    end
    
    methods(TestMethodSetup)
        function setup(testCase)
            % Load a simple LVD scenario
            % This file is assumed to exist in the KSPTOT distribution
            exampleFile = 'lvdExample_MunarLanding.mat';
            l = load(exampleFile);
            testCase.LvdData = l.lvdData;
            
            % Ensure we have a valid state log
            testCase.LvdData.script.executeScript(false, LaunchVehicleEvent.empty(1,0), false, false, false, false);
        end
    end
    
    methods(Test)
        function testObjectiveScalingAndDirection(testCase)
            lvdData = testCase.LvdData;
            stateLog = lvdData.stateLog;
            event = lvdData.script.getEventForInd(1);
            lvdOptim = lvdData.optimizer;
            
            % Create a simple constraint (Time)
            constr = GenericMAConstraint('Universal Time', event, 0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            constr.frame = lvdData.initialState.centralBody.getBodyCenteredInertialFrame();
            
            % Create Generic Objective Function
            scale = 10;
            genObj = GenericObjectiveFcn(event, constr.frame, constr, scale, lvdOptim, lvdData);
            
            % Evaluate unscaled
            [~, ~, valUnscaled] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            
            [f, fUnscaled] = genObj.evalObjFcn(stateLog);
            
            testCase.verifyEqual(fUnscaled, valUnscaled, 'AbsTol', 1e-8);
            testCase.verifyEqual(f, valUnscaled/scale, 'AbsTol', 1e-8);
            
            % Test Composite Objective Function with Direction
            composite = CompositeObjectiveFcn(genObj, ObjFcnDirectionTypeEnum.Minimize, ObjFcnCompositeMethodEnum.Sum, lvdOptim, lvdData);
            
            % x vector for evalObjFcn (optimizer variables)
            x = lvdOptim.vars.getTotalScaledXVector();
            
            fComp = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(fComp, f, 'AbsTol', 1e-8);
            
            composite.dirType = ObjFcnDirectionTypeEnum.Maximize;
            fCompMax = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(fCompMax, -f, 'AbsTol', 1e-8);
        end
        
        function testCompositeMethods(testCase)
            lvdData = testCase.LvdData;
            stateLog = lvdData.stateLog;
            event = lvdData.script.getEventForInd(1);
            lvdOptim = lvdData.optimizer;
            
            someFrame = lvdData.initialState.centralBody.getBodyCenteredInertialFrame();
            
            % Objective 1: Time (val1)
            c1 = GenericMAConstraint('Universal Time', event, 0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            c1.frame = someFrame;
            o1 = GenericObjectiveFcn(event, someFrame, c1, 1, lvdOptim, lvdData);
            
            % Objective 2: Mass (val2)
            c2 = GenericMAConstraint('Total Spacecraft Mass', event, 0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            c2.frame = someFrame;
            o2 = GenericObjectiveFcn(event, someFrame, c2, 1, lvdOptim, lvdData);
            
            % Get values
            [~, ~, v1] = c1.evalConstraint(stateLog, lvdData.celBodyData);
            [~, ~, v2] = c2.evalConstraint(stateLog, lvdData.celBodyData);
            
            composite = CompositeObjectiveFcn([o1, o2], ObjFcnDirectionTypeEnum.Minimize, ObjFcnCompositeMethodEnum.Sum, lvdOptim, lvdData);
            x = lvdOptim.vars.getTotalScaledXVector();
            
            % Sum
            composite.compositeMethod = ObjFcnCompositeMethodEnum.Sum;
            f = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(f, v1 + v2, 'AbsTol', 1e-8);
            
            % RSS
            composite.compositeMethod = ObjFcnCompositeMethodEnum.RSS;
            f = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(f, sqrt(v1^2 + v2^2), 'AbsTol', 1e-8);
            
            % MaxJ
            composite.compositeMethod = ObjFcnCompositeMethodEnum.MaxJ;
            f = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(f, max(v1, v2), 'AbsTol', 1e-8);
            
            % MinJ
            composite.compositeMethod = ObjFcnCompositeMethodEnum.MinJ;
            f = composite.evalObjFcn(x, LaunchVehicleEvent.empty(1,0));
            testCase.verifyEqual(f, min(v1, v2), 'AbsTol', 1e-8);
        end
    end
end
