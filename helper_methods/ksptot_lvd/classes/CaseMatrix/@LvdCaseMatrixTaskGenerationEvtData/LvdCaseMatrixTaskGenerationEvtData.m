classdef LvdCaseMatrixTaskGenerationEvtData < event.EventData
    %LvdCaseMatrixTaskGenerationEvtData Summary of this class goes here
    %   Detailed explanation goes here

    properties
        task LvdCaseMatrixTask
        taskNum(1,1) double
        totalTasks(1,1) double
    end

    methods
        function obj = LvdCaseMatrixTaskGenerationEvtData(task, taskNum, totalTasks)
            obj.task = task;
            obj.taskNum = taskNum;
            obj.totalTasks = totalTasks;
        end
    end
end