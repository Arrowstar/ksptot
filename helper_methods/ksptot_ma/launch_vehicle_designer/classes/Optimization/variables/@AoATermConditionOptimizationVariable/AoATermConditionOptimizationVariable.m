classdef AoATermConditionOptimizationVariable < AbstractOptimizationVariable
    %AoATermConditionOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) AngleOfAttackTermCondition = AngleOfAttackTermCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = true;
    end
    
    methods
        function obj = AoATermConditionOptimizationVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
        end
        
        function x = getXsForVariable(obj)
            x = [];
            if(obj.useTf)
                x = obj.varObj.targetAoA;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.targetAoA = x;
        end
    end
end