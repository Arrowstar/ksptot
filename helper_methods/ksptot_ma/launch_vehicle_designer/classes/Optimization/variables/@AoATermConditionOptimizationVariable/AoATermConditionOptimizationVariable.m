classdef AoATermConditionOptimizationVariable < AbstractOptimizationVariable
    %EventDurationOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) AngleOfAttackTermCondition = AngleOfAttackTermCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = AoATermConditionOptimizationVariable(varObj)
            obj.varObj = varObj;
        end
        
        function x = getXsForVariable(obj)
            x = obj.varObj.targetAoA;
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
            obj.varObj.targetAoA = x;
        end
    end
end