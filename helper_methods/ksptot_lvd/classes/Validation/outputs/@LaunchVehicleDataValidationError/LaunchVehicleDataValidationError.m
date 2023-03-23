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

        function [str, style] = getUiTableStringAndRowStyle(obj)
            str = obj.str;
            style = uistyle('BackgroundColor',[208,52,44]/255, 'FontColor',[1,1,1], 'FontWeight','bold', 'Icon','cancel.png', 'IconAlignment','leftmargin');
        end
    end
end