classdef LvdCaseMatrixTaskStatusEnum < matlab.mixin.SetGet
    %LvdCaseMatrixTaskStatusEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        NotRun('Not Run', '')
        Running('Running', 'Spin-1s-200px_transparentBg.gif');
        Completed('Completed', 'success')
        Failed('Failed', 'error')
        Canceled('Canceled', 'warning');
    end
    
    properties
        name(1,:) char
        icon(1,:) char
    end
    
    methods
        function obj = LvdCaseMatrixTaskStatusEnum(name, icon)
            obj.name = name;
            obj.icon = icon;
        end
    end
end