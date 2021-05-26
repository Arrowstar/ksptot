classdef(Abstract) AbstractIntegratorOptions < matlab.mixin.SetGet
    %AbstractIntegratorOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    methods        
        [options, integratorStepSize] = getIntegratorOptions(obj)
        
        integratorStepSize = getIntegratorStepSize(obj)
        
        setIntegratorStepSize(obj, integratorStepSize);
        
        openOptionsDialog(obj)
    end
end