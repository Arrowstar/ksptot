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
            style = uistyle('BackgroundColor',[238,210,2]/255, 'FontColor',[0,0,0], 'FontWeight','bold', 'Icon','yellowalert_blackoutline.png', 'IconAlignment','leftmargin');
        end
    end
end