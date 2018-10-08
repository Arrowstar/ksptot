classdef LaunchVehicleDataValidationOK < AbstractLaunchVehicleValidatorOutput
    %LaunchVehicleDataValidation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        str(1,:) char = 'No errors or warnings found.'
    end
    
    methods
        function obj = LaunchVehicleDataValidationOK()
            
        end

        function writeToLabel(obj, hLbl)
            styleLabelAsValid(hLbl,obj.str);
        end
    end
end