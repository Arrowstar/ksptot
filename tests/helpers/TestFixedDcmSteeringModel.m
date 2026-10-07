classdef TestFixedDcmSteeringModel < TestIdentitySteeringModel
    %TestFixedDcmSteeringModel Steering model that returns a DCM the test
    %chose, so attitude-derived quantities can be checked against angles
    %the test composed itself rather than against another trip through
    %the production Euler/aero angle machinery.
    %
    % dcmFcn maps ut -> body-to-inertial DCM (columns are the body axes in
    % the central body's inertial frame).  Pass a constant 3x3 matrix for a
    % fixed attitude, or a function handle for a time-varying one (used by
    % the angular rate checks, which finite-difference the steering model).

    properties
        dcmFcn function_handle = @(~) eye(3);
    end

    methods
        function obj = TestFixedDcmSteeringModel(dcm)
            if(nargin >= 1)
                if(isa(dcm, 'function_handle'))
                    obj.dcmFcn = dcm;
                else
                    obj.dcmFcn = @(~) dcm;
                end
            end
        end

        function dcm = getBody2InertialDcmAtTime(obj, ut, ~, ~, ~)
            dcm = obj.dcmFcn(ut);
        end

        function newSteeringModel = deepCopy(obj)
            newSteeringModel = TestFixedDcmSteeringModel(obj.dcmFcn);
        end
    end
end
