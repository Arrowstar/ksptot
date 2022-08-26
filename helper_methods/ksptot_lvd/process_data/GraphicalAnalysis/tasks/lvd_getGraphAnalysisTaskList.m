function [taskList] = lvd_getGraphAnalysisTaskList(lvdData, excludeList)
%lvd_getGraphAnalysisTaskList Summary of this function goes here
%   Detailed explanation goes here
    taskList = ma_getGraphAnalysisTaskList(excludeList);
    taskList = setdiff(taskList,excludeList);

    taskList{end+1} = 'Yaw Angle';
    taskList{end+1} = 'Pitch Angle';
    taskList{end+1} = 'Roll Angle';
    taskList{end+1} = 'Bank Angle';
    taskList{end+1} = 'Angle of Attack';
    taskList{end+1} = 'SideSlip Angle';
    taskList{end+1} = 'Total Angle of Attack';
    taskList{end+1} = 'Throttle';
    taskList{end+1} = 'Thrust to Weight Ratio';
    taskList{end+1} = 'Total Thrust';
    taskList{end+1} = 'Two-Body Time To Impact';
    taskList{end+1} = 'Two-Body Impact Latitude';
    taskList{end+1} = 'Two-Body Impact Longitude';
    taskList{end+1} = 'Drag Coefficient';
    taskList{end+1} = 'Event Number';
    taskList{end+1} = 'Total Effective Isp';
    taskList{end+1} = 'Total Thrust Vector X Component';
    taskList{end+1} = 'Total Thrust Vector Y Component';
    taskList{end+1} = 'Total Thrust Vector Z Component';
    taskList{end+1} = 'Power Net Charge Rate';
    taskList{end+1} = 'Power Cumulative Storage State of Charge';
    taskList{end+1} = 'Power Maximum Available Storage';
    
    taskList{end+1} = 'Position Vector (X)';
    taskList{end+1} = 'Position Vector (Y)';
    taskList{end+1} = 'Position Vector (Z)';
    taskList{end+1} = 'Velocity Vector (X)';
    taskList{end+1} = 'Velocity Vector (Y)';
    taskList{end+1} = 'Velocity Vector (Z)';
    taskList{end+1} = 'Position Vector Magnitude';
    taskList{end+1} = 'Velocity Vector Magnitude';
    taskList{end+1} = 'Surface Velocity';
    taskList{end+1} = 'Vertical Velocity';
    taskList{end+1} = 'Semi-major Axis';
    taskList{end+1} = 'Eccentricity';
    taskList{end+1} = 'Inclination';
    taskList{end+1} = 'Right Asc. of the Asc. Node';
    taskList{end+1} = 'Argument of Periapsis';
    taskList{end+1} = 'True Anomaly';
    taskList{end+1} = 'Mean Anomaly';
    taskList{end+1} = 'Orbital Period';
    taskList{end+1} = 'Radius of Periapsis';
    taskList{end+1} = 'Radius of Apoapsis';
    taskList{end+1} = 'Altitude of Apoapsis';
    taskList{end+1} = 'Altitude of Periapsis';
    taskList{end+1} = 'Equinoctial H1';
    taskList{end+1} = 'Equinoctial K1';
    taskList{end+1} = 'Equinoctial H2';
    taskList{end+1} = 'Equinoctial K2';
    taskList{end+1} = 'Flight Path Angle';
    taskList{end+1} = 'Altitude';
    taskList{end+1} = 'Longitude (East)';
    taskList{end+1} = 'Latitude (North)';
    taskList{end+1} = 'Velocity Azimuth';
    taskList{end+1} = 'Velocity Elevation';
    taskList{end+1} = 'Longitudinal Drift Rate';
    taskList{end+1} = 'C3 Energy';
    taskList{end+1} = 'Seconds Past Periapsis';
    taskList{end+1} = 'Central Body ID';
    taskList{end+1} = 'Hyperbolic Velocity Unit Vector X';
    taskList{end+1} = 'Hyperbolic Velocity Unit Vector Y';
    taskList{end+1} = 'Hyperbolic Velocity Unit Vector Z';
    taskList{end+1} = 'Hyperbolic Velocity Vector Right Ascension';
    taskList{end+1} = 'Hyperbolic Velocity Vector Declination';
    taskList{end+1} = 'Hyperbolic Velocity Magnitude';

    taskList{end+1} = 'Drag Force';

    taskList{end+1} = 'Solar Radiation Pressure Force Vector X Component';
    taskList{end+1} = 'Solar Radiation Pressure Force Vector Y Component';
    taskList{end+1} = 'Solar Radiation Pressure Force Vector Z Component';
    taskList{end+1} = 'Solar Radiation Pressure Force Vector Magnitude';

    taskList{end+1} = 'Height Above Terrain';
    
    [fluidTypesGAStr, ~] = lvdData.launchVehicle.tankTypes.getFluidTypesGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, fluidTypesGAStr);
    
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
    
    ptGAStr = lvdData.geometry.points.getAllPointGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, ptGAStr);
    
    vectGAStr = lvdData.geometry.vectors.getAllVectorGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, vectGAStr);
    
    angleGAStr = lvdData.geometry.angles.getAllAngleGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, angleGAStr);
    
    planeGAStr = lvdData.geometry.planes.getAllPlaneGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, planeGAStr);
    
    pluginGAStr = lvdData.plugins.getAllPluginGraphAnalysisTaskStrs();
    taskList = horzcat(taskList, pluginGAStr);
    
    taskList = sort(taskList);
end