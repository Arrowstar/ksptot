function [datapt, unitStr] = lvd_GeometricVectorTasks(stateLogEntry, subTask, vector, inFrame)
%lvd_GeometricPointTasks Summary of this function goes here
%   Detailed explanation goes here

    stateLogCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    time = stateLogCartElem.time;
%     frame = stateLogCartElem.frame;
    origin = vector.getOriginPointInViewFrame(time, stateLogCartElem, inFrame);
    vect = vector.getVectorAtTime(time, stateLogCartElem, inFrame);
    
    switch subTask
        case 'VectorX'
            datapt = vect(1);
            unitStr = 'km';

        case 'VectorY'
            datapt = vect(2);
            unitStr = 'km';
            
        case 'VectorZ'
            datapt = vect(3);
            unitStr = 'km';
            
        case 'VectMag'
            datapt = norm(vect);
            unitStr = 'km';
            
        case 'OriginX'
            datapt = origin(1);
            unitStr = 'km';

        case 'OriginY'
            datapt = origin(2);
            unitStr = 'km';
            
        case 'OriginZ'
            datapt = origin(3);
            unitStr = 'km';
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end