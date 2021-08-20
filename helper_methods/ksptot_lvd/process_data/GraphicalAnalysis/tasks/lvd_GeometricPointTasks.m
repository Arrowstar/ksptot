function [datapt, unitStr] = lvd_GeometricPointTasks(stateLogEntry, subTask, point, inFrame)
%lvd_GeometricPointTasks Summary of this function goes here
%   Detailed explanation goes here

    stateLogCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    time = stateLogCartElem.time;
%     frame = stateLogCartElem.frame;
    pointCartElem = point.getPositionAtTime(time, stateLogCartElem, inFrame);
    ptRVect = pointCartElem.rVect;
    
    switch subTask
        case 'PosX'
            datapt = ptRVect(1);
            unitStr = 'km';

        case 'PosY'
            datapt = ptRVect(2);
            unitStr = 'km';
            
        case 'PosZ'
            datapt = ptRVect(3);
            unitStr = 'km';
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end