classdef LaunchVehicleAttitudeState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dcm(3,3) double = eye(3)
    end
    
    methods
        function obj = LaunchVehicleAttitudeState()
            
        end
        
        function [rollAngle, pitchAngle, yawAngle] = getEulerAngles(obj, ut, rVect, vVect, bodyInfo)
            bodyX = obj.dcm(:,1);
            bodyY = obj.dcm(:,2);
            bodyZ = obj.dcm(:,3);
            
            [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ);
        end
        
        function [bankAng,angOfAttack,angOfSideslip] = getAeroAngles(obj, rVect, vVect)
            bodyX = obj.dcm(:,1);
            bodyY = obj.dcm(:,2);
            bodyZ = obj.dcm(:,3);
            
            [bankAng,angOfAttack,angOfSideslip] = computeAeroAnglesFromBodyAxes(rVect, vVect, bodyX, bodyY, bodyZ);
        end
        
        function newAttState = deepCopy(obj)
            newAttState = LaunchVehicleAttitudeState();
            newAttState.dcm = obj.dcm;
        end
    end
end