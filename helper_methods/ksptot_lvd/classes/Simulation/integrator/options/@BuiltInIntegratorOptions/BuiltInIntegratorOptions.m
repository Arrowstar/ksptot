classdef BuiltInIntegratorOptions < AbstractIntegratorOptions
    %BuiltInIntegratorOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        AbsTol(1,1) double = 1E-10;
        RelTol(1,1) double = 1E-10;
        NormControl(1,1) logical = true;
        Refine(1,1) double = 1;
        InitialStep(1,1) double = 1;
        MaxStep(1,1) double = Inf;
        integratorStepSize(1,1) double = -1;
    end
    
    methods
        function obj = BuiltInIntegratorOptions()

        end
        
        function [options, integratorStepSize] = getIntegratorOptions(obj)
            options = odeset('AbsTol',obj.AbsTol, 'RelTol',obj.RelTol, 'NormControl',obj.NormControl, 'Refine', obj.Refine, 'InitialStep',obj.InitialStep);
            
            if(isfinite(obj.MaxStep))
                options = odeset('MaxStep', obj.MaxStep);
            end
            
            integratorStepSize = obj.integratorStepSize;
        end
        
        function integratorStepSize = getIntegratorStepSize(obj)
            integratorStepSize = obj.integratorStepSize;
        end
        
        function setIntegratorStepSize(obj, integratorStepSize)
            obj.integratorStepSize = integratorStepSize;
        end
        
        function openOptionsDialog(obj)
            lvd_builtInIntegratorOptionsGUI(obj);
        end
    end
end