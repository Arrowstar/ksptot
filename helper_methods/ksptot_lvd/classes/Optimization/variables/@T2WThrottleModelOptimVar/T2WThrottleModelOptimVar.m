classdef T2WThrottleModelOptimVar < AbstractOptimizationVariable
    %T2WThrottleModelOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj = T2WThrottleModel.getDefaultThrottleModel()
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) logical = false;
    end
    
    methods
        function obj = T2WThrottleModelOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.targetT2W;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)            
            lb = obj.lb(logical(obj.useTf));
            ub = obj.ub(logical(obj.useTf));
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.lb;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = logical(obj.useTf);
        end
        
        function setUseTfForVariable(obj, useTf)                 
            obj.useTf = logical(useTf);
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.targetT2W = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
           if(evtNum > 0)
                subStr = sprintf('Event %i',evtNum);
            else
                subStr = varLocType;
            end
            
            nameStrs = {sprintf('%s Throttle Thrust to Weight', subStr)};
        end
    end
end