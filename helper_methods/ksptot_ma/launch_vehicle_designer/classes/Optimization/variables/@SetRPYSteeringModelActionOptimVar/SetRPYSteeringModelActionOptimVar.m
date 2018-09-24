classdef SetRPYSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetRPYSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
        
        lb(1,9) double
        ub(1,9) double
        
        varRollConst(1,1) logical = false;
        varRollLin(1,1) logical   = false;
        varRollAccel(1,1) logical = false;
        
        varPitchConst(1,1) logical = false;
        varPitchLin(1,1) logical   = false;
        varPitchAccel(1,1) logical = false;
        
        varYawConst(1,1) logical = false;
        varYawLin(1,1) logical   = false;
        varYawAccel(1,1) logical = false;
    end
    
    methods
        function obj = SetRPYSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,9);
            
            if(obj.varRollConst)
                x(1) = obj.varObj.rollModel.constTerm;
            end
            if(obj.varRollLin)
                x(2) = obj.varObj.rollModel.linearTerm;
            end
            if(obj.varRollAccel)
                x(3) = obj.varObj.rollModel.accelTerm;
            end
            
            if(obj.varPitchConst)
                x(4) = obj.varObj.pitchModel.constTerm;
            end
            if(obj.varPitchLin)
                x(5) = obj.varObj.pitchModel.linearTerm;
            end
            if(obj.varPitchAccel)
                x(6) = obj.varObj.pitchModel.accelTerm;
            end
            
            if(obj.varYawConst)
                x(7) = obj.varObj.yawModel.constTerm;
            end
            if(obj.varYawLin)
                x(8) = obj.varObj.yawModel.linearTerm;
            end
            if(obj.varYawAccel)
                x(9) = obj.varObj.yawModel.accelTerm;
            end
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 9 && length(ub) == 9)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varRollConst obj.varRollLin obj.varRollAccel ...
                     obj.varPitchConst obj.varPitchLin obj.varPitchAccel ...
                     obj.varYawConst obj.varYawLin obj.varYawAccel];
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.varRollConst = useTf(1);
            obj.varRollLin = useTf(2);
            obj.varRollAccel = useTf(3);
            
            obj.varPitchConst = useTf(4);
            obj.varPitchLin = useTf(5);
            obj.varPitchAccel = useTf(6);
            
            obj.varYawConst = useTf(7);
            obj.varYawLin = useTf(8);
            obj.varYawAccel = useTf(9);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            
            if(obj.varRollConst)
                obj.varObj.rollModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varRollLin)
                obj.varObj.rollModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varRollAccel)
                obj.varObj.rollModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varPitchConst)
                obj.varObj.pitchModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varPitchLin)
                obj.varObj.pitchModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varPitchAccel)
                obj.varObj.pitchModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varYawConst)
                obj.varObj.yawModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varYawLin)
                obj.varObj.yawModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varYawAccel)
                obj.varObj.yawModel.accelTerm = x(ind);
                ind = ind + 1; %#ok<NASGU>
            end
        end
    end
end