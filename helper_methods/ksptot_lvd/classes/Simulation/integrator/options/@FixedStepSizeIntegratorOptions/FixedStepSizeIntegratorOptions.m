classdef FixedStepSizeIntegratorOptions < AbstractIntegratorOptions
    %FixedStepSizeIntegratorOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        integratorStepSize(1,1) double = 1;
    end
    
    methods       
        function [options, integratorStepSize] = getIntegratorOptions(obj)
            options = odeset();
            integratorStepSize = obj.integratorStepSize;
        end
        
        function integratorStepSize = getIntegratorStepSize(obj)
            integratorStepSize = obj.integratorStepSize;
        end
        
        function openOptionsDialog(obj)
            lvd_fixedStepSizeIntegratorOptionsGUI(obj);
        end
    end
end