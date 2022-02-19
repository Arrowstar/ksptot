classdef(Abstract) AbstractSteeringMathModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSteeringMathModel Summary of this class goes here
    %   Detailed explanation goes here
    
    methods       
        value = getValueAtTime(obj,ut)    
        
        newModel = deepCopy(obj)
        
        t0 = getT0(obj)
        
        setT0(obj, newT0)
        
        timeOffset = getTimeOffset(obj)
        
        setTimeOffset(obj, timeOffset)
        
        setConstValueForContinuity(obj, contValue)
        
        numVars = getNumVars(obj)
        
        x = getXsForVariable(obj)
        
        updateObjWithVarValue(obj, x)
        
        [lb, ub] = getBndsForVariable(obj)
        
        setBndsForVariable(obj, lb, ub)
        
        useTf = getUseTfForVariable(obj)
        
        setUseTfForVariable(obj, useTf) 
        
        nameStrs = getStrNamesOfVars(obj)
    end
end

