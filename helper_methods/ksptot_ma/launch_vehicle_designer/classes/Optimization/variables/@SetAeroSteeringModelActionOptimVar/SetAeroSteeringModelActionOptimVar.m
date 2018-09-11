classdef SetAeroSteeringModelActionOptimVar < AbstractOptimizationVariable
    %SetRPYSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) AeroAnglesPolySteeringModel = AeroAnglesPolySteeringModel.getDefaultSteeringModel()
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        varBankConst = true;
        varBankLin   = true;
        varBankAccel = true;
        
        varAoAConst = true;
        varAoALin   = true;
        varAoAAccel = true;
        
        varSlipConst = true;
        varSlipLin   = true;
        varSlipAccel = true;
    end
    
    methods
        function obj = SetAeroSteeringModelActionOptimVar(varObj)
            obj.varObj = varObj;
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,9);
            
            if(obj.varBankConst)
                x(1) = obj.varObj.bankModel.constTerm;
            end
            if(obj.varBankLin)
                x(2) = obj.varObj.bankModel.linearTerm;
            end
            if(obj.varBankAccel)
                x(3) = obj.varObj.bankModel.accelTerm;
            end
            
            if(obj.varAoAConst)
                x(4) = obj.varObj.aoAModel.constTerm;
            end
            if(obj.varAoALin)
                x(5) = obj.varObj.aoAModel.linearTerm;
            end
            if(obj.varAoAAccel)
                x(6) = obj.varObj.aoAModel.accelTerm;
            end
            
            if(obj.varSlipConst)
                x(7) = obj.varObj.slipModel.constTerm;
            end
            if(obj.varSlipLin)
                x(8) = obj.varObj.slipModel.linearTerm;
            end
            if(obj.varSlipAccel)
                x(9) = obj.varObj.slipModel.accelTerm;
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
            
            if(obj.varBankConst)
                obj.varObj.bankModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varBankLin)
                obj.varObj.bankModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varBankAccel)
                obj.varObj.bankModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varAoAConst)
                obj.varObj.aoAModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAoALin)
                obj.varObj.aoAModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAoAAccel)
                obj.varObj.aoAModel.accelTerm = x(ind);
                ind = ind + 1;
            end
            
            if(obj.varSlipConst)
                obj.varObj.slipModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varSlipLin)
                obj.varObj.slipModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varSlipAccel)
                obj.varObj.slipModel.accelTerm = x(ind);
                ind = ind + 1; %#ok<NASGU>
            end
        end
    end
end