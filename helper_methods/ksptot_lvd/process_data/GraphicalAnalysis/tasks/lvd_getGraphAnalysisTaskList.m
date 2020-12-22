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
    taskList{end+1} = 'Drag Area';
    taskList{end+1} = 'Event Number';
    taskList{end+1} = 'Total Effective Isp';
    taskList{end+1} = 'Total Thrust Vector X Component';
    taskList{end+1} = 'Total Thrust Vector Y Component';
    taskList{end+1} = 'Total Thrust Vector Z Component';
    taskList{end+1} = 'Power Net Charge Rate';
    taskList{end+1} = 'Power Cumulative Storage State of Charge';
    taskList{end+1} = 'Power Maximum Available Storage';
    
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
    
    [grdObjAzGAStr, ~] = lvdData.groundObjs.getGrdObjAzGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, grdObjAzGAStr);
    
    [grdObjElevGAStr, ~] = lvdData.groundObjs.getGrdObjElevGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, grdObjElevGAStr);
    
    [grdObjRngGAStr, ~] = lvdData.groundObjs.getGrdObjRangeGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, grdObjRngGAStr);
    
    [grdObjLoSGAStr, ~] = lvdData.groundObjs.getGrdObjLoSGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, grdObjLoSGAStr);
    
    [calcObjsGAStr, ~] = lvdData.launchVehicle.getCalculusCalcObjGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, calcObjsGAStr);
    
    [pwrStorageGAStr, ~] = lvdData.launchVehicle.getPowerStorageGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, pwrStorageGAStr);
    
    [powerSinkGAStr, ~] = lvdData.launchVehicle.getPowerSinksGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, powerSinkGAStr);
    
    [powerSrcsGAStr, ~] = lvdData.launchVehicle.getPowerSrcsGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, powerSrcsGAStr);
    
    taskList = setdiff(taskList,excludeList);
end