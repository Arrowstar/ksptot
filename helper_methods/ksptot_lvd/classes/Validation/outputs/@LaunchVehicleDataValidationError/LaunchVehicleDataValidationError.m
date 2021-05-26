classdef LaunchVehicleDataValidationError < AbstractLaunchVehicleValidatorOutput
    %LaunchVehicleDataValidation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        str  char = ''
    end
    
    methods
        function obj = LaunchVehicleDataValidationError(str)
            obj.str = str;
        end

        function writeToLabel(obj, hLbl)
            styleLabelAsError(hLbl,obj.str)
        end
    end
end