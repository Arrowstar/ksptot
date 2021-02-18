function [datapt, unitStr] = lvd_GeometricAngleTasks(stateLogEntry, subTask, angle)
%lvd_GeometricAngleTasks Summary of this function goes here
%   Detailed explanation goes here

    stateLogCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    time = stateLogCartElem.time;
    frame = stateLogCartElem.frame;
    
    switch subTask
        case 'Mag'
            angle = angle.getAngleAtTime(time, stateLogCartElem, frame);
            datapt = rad2deg(angle);
            unitStr = 'deg';
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end