classdef LaunchVehicleDataValidationWarning < AbstractLaunchVehicleValidatorOutput
    %LaunchVehicleDataValidation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        str  char = ''
    end
    
    methods
        function obj = LaunchVehicleDataValidationWarning(str)
            obj.str = str;
        end

        function writeToLabel(obj, hLbl)
            styleLabelAsWarn(hLbl,obj.str)
        end
    end
end