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

        function [str, style] = getUiTableStringAndRowStyle(obj)
            str = string(obj.str);
            style = uistyle('BackgroundColor',[1,1,0], 'FontColor',[0,0,0], 'FontWeight','bold');
        end
    end
end