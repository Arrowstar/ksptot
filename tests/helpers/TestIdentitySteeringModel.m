classdef TestIdentitySteeringModel < AbstractSteeringModel
    %TestIdentitySteeringModel Minimal concrete AbstractSteeringModel.
    %
    % Some force models (e.g. SolarRadPressForceModel's underlying
    % LaunchVehicleSolarRadPressState.getSolarRadiationForce) declare an
    % `arguments` block that requires a real AbstractSteeringModel
    % instance, but never actually use anything but
    % getBody2InertialDcmAtTime (only to feed a line-of-sight helper that
    % discards the returned DCM). tests/helpers/MockSteeringModel is not a
    % subclass of AbstractSteeringModel and so fails that type check. This
    % class exists purely to satisfy it: getBody2InertialDcmAtTime always
    % returns the identity DCM, and every other abstract method is a
    % stub that is never exercised by the tests that use this class.

    methods
        function dcm = getBody2InertialDcmAtTime(~, ~, ~, ~, ~)
            dcm = eye(3);
        end

        function t0 = getT0(~)
            t0 = 0;
        end

        function setT0(~, ~)
        end

        function setConstsFromDcmAndContinuitySettings(~, ~, ~, ~, ~, ~)
        end

        function setInitialAttitudeFromState(~, ~, ~)
        end

        function setContinuityTerms(~, ~, ~, ~)
        end

        function [angle1Cont, angle2Cont, angle3Cont] = getContinuityTerms(~)
            angle1Cont = 0;
            angle2Cont = 0;
            angle3Cont = 0;
        end

        function enum = getSteeringModelTypeEnum(~)
            enum = [];
        end

        function newSteeringModel = deepCopy(~)
            newSteeringModel = TestIdentitySteeringModel();
        end

        function optVar = getNewOptVar(~)
            optVar = [];
        end

        function optVar = getExistingOptVar(~)
            optVar = [];
        end

        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, ~, ~)
            addActionTf = false;
            steeringModel = obj;
        end
    end

    methods(Static)
        function model = getDefaultSteeringModel()
            model = TestIdentitySteeringModel();
        end

        function typeStr = getTypeNameStr()
            typeStr = 'TestIdentitySteeringModel';
        end
    end
end
