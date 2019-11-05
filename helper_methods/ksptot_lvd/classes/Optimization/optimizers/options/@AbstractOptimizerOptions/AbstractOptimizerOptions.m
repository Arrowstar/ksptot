classdef(Abstract) AbstractOptimizerOptions < matlab.mixin.SetGet
    %AbstractOptimizerOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        options = getOptionsForOptimizer(obj, x0);
        
        tf = usesParallel(obj);
    end
end