function datapt = lvd_ThrottleTask(stateLogEntry, subTask)
%lvd_SteeringAngleTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'throttle'
            datapt = 100*stateLogEntry.throttle;
    end
end