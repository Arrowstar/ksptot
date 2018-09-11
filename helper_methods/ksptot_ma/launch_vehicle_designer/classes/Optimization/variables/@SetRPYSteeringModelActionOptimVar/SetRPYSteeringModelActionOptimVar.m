classdef SetRPYSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetRPYSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) RollPitchYawPolySteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel()
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        varRollConst = true;
        varRollLin   = true;
        varRollAccel = true;
        
        varPitchConst = true;
        varPitchLin   = true;
        varPitchAccel = true;
        
        varYawConst = true;
        varYawLin   = true;
        varYawAccel = true;
    end
    
    methods
        function obj = SetRPYSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
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
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
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