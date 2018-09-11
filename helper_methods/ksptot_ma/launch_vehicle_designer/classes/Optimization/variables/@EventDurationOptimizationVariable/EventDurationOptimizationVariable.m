classdef EventDurationOptimizationVariable < AbstractOptimizationVariable
    %EventDurationOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) EventDurationTermCondition = EventDurationTermCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = EventDurationOptimizationVariable(varObj)
            obj.varObj = varObj;
        end
        
        function x = getXsForVariable(obj)
            x = obj.varObj.duration;
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
            obj.varObj.duration = x;
        end
    end
end