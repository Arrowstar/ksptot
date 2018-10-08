classdef(Abstract) AbstractOptimizationVariable < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id(1,1) double
    end
    
    methods
        x = getXsForVariable(obj)
        
        [lb, ub] = getBndsForVariable(obj)
        
        [lb, ub] = getAllBndsForVariable(obj)
        
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
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end  
    end
end