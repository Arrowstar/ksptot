classdef(Abstract) AbstractOptimizationVariable < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        x = getXsForVariable(obj)
        
        [lb, ub] = getBndsForVariable(obj)
        
        setBndsForVariable(obj, lb, ub)
        
        useTf = getUseTfForVariable(obj)
        
        setUseTfForVariable(obj, useTf)
        
        updateObjWithVarValue(obj, x)
    end
    
    methods(Sealed)
        function numVars = getNumOfVars(obj)
            [lb,~] = obj.getBndsForVariable();
            numVars = numel(lb);
        end
    end
end