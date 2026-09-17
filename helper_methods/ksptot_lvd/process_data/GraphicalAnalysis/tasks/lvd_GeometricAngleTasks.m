function [datapt, unitStr] = lvd_GeometricAngleTasks(stateLogEntry, subTask, angle, inFrame)
%lvd_GeometricAngleTasks Summary of this function goes here
%   Detailed explanation goes here

    stateLogCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    time = stateLogCartElem.time;
%     frame = stateLogCartElem.frame;
    
    switch subTask
        case 'Mag'
            isDimensionless = angle.isDimensionless();
            angle = angle.getAngleAtTime(time, stateLogCartElem, inFrame);

            if(isDimensionless)
                %A dimensionless scalar (dot product) is reported as is.
                datapt = angle;
                unitStr = '';
            else
                datapt = rad2deg(angle);
                unitStr = 'deg';
            end
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end