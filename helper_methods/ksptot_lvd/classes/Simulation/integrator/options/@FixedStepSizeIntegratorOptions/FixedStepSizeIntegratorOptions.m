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
        
        function setIntegratorStepSize(obj, integratorStepSize)
            if(integratorStepSize <= 0)
                warning('Could not set fixed step size integrator step to %0.3f seconds: fixed step size integrators must have positive step sizes.');
            else
                obj.integratorStepSize = integratorStepSize;
            end
        end
        
        function openOptionsDialog(obj)
%             lvd_fixedStepSizeIntegratorOptionsGUI(obj);
            output = AppDesignerGUIOutput({false});
            lvd_fixedStepSizeIntegratorOptionsGUI_App(obj,output);
        end
    end
end