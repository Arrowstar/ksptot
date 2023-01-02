classdef LaunchVehicleDataValidationOK < AbstractLaunchVehicleValidatorOutput
    %LaunchVehicleDataValidation Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        str char = 'No errors or warnings found.'
    end
    
    methods
        function obj = LaunchVehicleDataValidationOK()
            
        end

        function writeToLabel(obj, hLbl)
            styleLabelAsValid(hLbl,obj.str);
        end

        function [str, style] = getUiTableStringAndRowStyle(obj)
            str = obj.str;
            style = uistyle('BackgroundColor',[34,139,34]/255, 'FontColor',[1,1,1], 'FontWeight','bold');
        end
    end
end