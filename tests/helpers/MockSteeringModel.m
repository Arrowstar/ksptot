classdef MockSteeringModel < handle
    %MockSteeringModel Records whether the attitude DCM was ever requested.
    %
    % TotalForceModel only asks a steering model for one thing --
    % getBody2InertialDcmAtTime -- and only when at least one active force
    % model reports usesAttitudeState.  Counting those calls is therefore a
    % direct probe of whether the attitude state was built for a given set
    % of force models.

    properties
        callCount(1,1) double = 0;
        dcmToReturn(3,3) double = eye(3);
    end

    methods
        function dcm = getBody2InertialDcmAtTime(obj, ~, ~, ~, ~)
            obj.callCount = obj.callCount + 1;
            dcm = obj.dcmToReturn;
        end

        function reset(obj)
            obj.callCount = 0;
        end
    end
end
