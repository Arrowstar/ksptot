classdef ConicalSensor < AbstractSensor
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
    end
    
    methods
        function obj = ConicalSensor(angle, range)
            obj.angle = angle;
            obj.range = range;
        end
               
        function [V,F] = getSensorMesh(obj, scElem)
            sensorRange = obj.range;
            
            rVectSc = scElem.rVect;
            boreDir = obj.getSensorBoresightDirection(); 

            sensorOutlineCenter = rVectSc + sensorRange*boreDir;
            sensorRadius = obj.range*(sin(obj.angle) / sin(pi/2 - obj.angle));
            sensorOutlinePtsRaw = AbstractSensor.getCircleInSpace(boreDir, sensorOutlineCenter, sensorRadius);
            
            V = vertcat(rVectSc(:)', sensorOutlinePtsRaw');
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj)
%             dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo) %AbstractSteeringModel
%             [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, vehElemSet) %AbstractReferenceFrame
            
            boreDir = vect_normVector([3;1;0]);
        end
        
        function maxRange = getMaximumRange(obj)
            maxRange = obj.range;
        end
    end
end