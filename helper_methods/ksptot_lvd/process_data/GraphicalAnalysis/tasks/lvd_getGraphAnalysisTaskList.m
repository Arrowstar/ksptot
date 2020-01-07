function [taskList] = lvd_getGraphAnalysisTaskList(lvdData, excludeList)
%ma_getGraphAnalysisTaskList Summary of this function goes here
%   Detailed explanation goes here
    taskList = ma_getGraphAnalysisTaskList(excludeList);

    taskList{end+1} = 'Yaw Angle';
    taskList{end+1} = 'Pitch Angle';
    taskList{end+1} = 'Roll Angle';
    taskList{end+1} = 'Bank Angle';
    taskList{end+1} = 'Angle of Attack';
    taskList{end+1} = 'SideSlip Angle';
    taskList{end+1} = 'Throttle';
    taskList{end+1} = 'Thrust to Weight Ratio';
    taskList{end+1} = 'Total Thrust';
    taskList{end+1} = 'Two-Body Time To Impact';
    taskList{end+1} = 'Two-Body Impact Latitude';
    taskList{end+1} = 'Two-Body Impact Longitude';
    taskList{end+1} = 'Drag Coefficient';
    taskList{end+1} = 'Event Number';
    taskList{end+1} = 'Total Effective Isp';
    
    [tanksGAStr, ~] = lvdData.launchVehicle.getTanksGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, tanksGAStr);
    
    [stagesGAStr, ~] = lvdData.launchVehicle.getStagesGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, stagesGAStr);
    
    [engineGAStr, ~] = lvdData.launchVehicle.getEnginesGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, engineGAStr);
    
    [stopwatchGAStr, ~] = lvdData.launchVehicle.getStopwatchGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, stopwatchGAStr);
    
    [extremaGAStr, ~] = lvdData.launchVehicle.getExtremaGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, extremaGAStr);
    
    taskList = setdiff(taskList,excludeList);
end