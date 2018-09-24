classdef EventDurationOptimizationVariable < AbstractOptimizationVariable
    %EventDurationOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) EventDurationTermCondition = EventDurationTermCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = true;
    end
    
    methods
        function obj = EventDurationOptimizationVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
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
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.duration = x;
        end
    end
end