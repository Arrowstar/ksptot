classdef LvdCaseMatrixTaskNotifyEventData < event.EventData
    %LvdCaseMatrixTaskNotifyEventData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        task LvdCaseMatrixTask
        updatedData
    end
    
    methods
        function obj = LvdCaseMatrixTaskNotifyEventData(task, updatedData)
            obj.task = task;
            obj.updatedData = updatedData;
        end
    end
end

