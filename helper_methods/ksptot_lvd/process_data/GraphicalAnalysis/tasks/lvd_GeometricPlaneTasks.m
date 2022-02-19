function [datapt, unitStr] = lvd_GeometricPlaneTasks(stateLogEntry, subTask, plane, inFrame)
%lvd_GeometricPointTasks Summary of this function goes here
%   Detailed explanation goes here

    stateLogCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    time = stateLogCartElem.time;
%     frame = stateLogCartElem.frame;
    normvect = plane.getPlaneNormVectAtTime(time, stateLogCartElem, inFrame);
    
    switch subTask
        case 'NormVectorX'
            datapt = normvect(1);
            unitStr = '';

        case 'NormVectorY'
            datapt = normvect(2);
            unitStr = '';
            
        case 'NormVectorZ'
            datapt = normvect(3);
            unitStr = '';
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end