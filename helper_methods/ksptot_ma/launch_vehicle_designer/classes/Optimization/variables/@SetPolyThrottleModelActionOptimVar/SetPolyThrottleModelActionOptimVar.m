classdef SetPolyThrottleModelActionOptimVar < AbstractOptimizationVariable
    %SetRPYSteeringModelActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = ThrottlePolyModel.getDefaultThrottleModel()
        
        lb(1,3) double
        ub(1,3) double
        
        varConst(1,1) logical = false;
        varLin(1,1) logical   = false;
        varAccel(1,1) logical = false;
    end
    
    methods
        function obj = SetPolyThrottleModelActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = NaN(1,3);
            
            if(obj.varConst)
                x(1) = obj.varObj.throttleModel.constTerm;
            end
            if(obj.varLin)
                x(2) = obj.varObj.throttleModel.linearTerm;
            end
            if(obj.varAccel)
                x(3) = obj.varObj.throttleModel.accelTerm;
            end
            
            x(isnan(x)) = [];
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            useTf = obj.getUseTfForVariable();

            lb = obj.lb(useTf);
            ub = obj.ub(useTf);
        end
        
        function setBndsForVariable(obj, lb, ub)
            if(length(lb) == 3 && length(ub) == 3)
                obj.lb = lb;
                obj.ub = ub;
            else
                useTf = obj.getUseTfForVariable();

                obj.lb(useTf) = lb;
                obj.ub(useTf) = ub;
            end
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = [obj.varConst obj.varLin obj.varAccel];
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.varConst = useTf(1);
            obj.varLin = useTf(2);
            obj.varAccel = useTf(3);
        end
        
        function updateObjWithVarValue(obj, x)
            ind = 1;
            
            if(obj.varConst)
                obj.varObj.throttleModel.constTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varLin)
                obj.varObj.throttleModel.linearTerm = x(ind);
                ind = ind + 1;
            end
            if(obj.varAccel)
                obj.varObj.throttleModel.accelTerm = x(ind);
                ind = ind + 1;
            end
        end
    end
end