classdef ConicalSensor < AbstractSensor
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
        origin AbstractGeometricPoint
        steeringModel AbstractSensorSteeringModel
    end
    
    methods
        function obj = ConicalSensor(angle, range, origin, steeringModel)
            obj.angle = angle;
            obj.range = range;
            obj.origin = origin;
            obj.steeringModel = steeringModel;
        end
               
        function [V,F] = getSensorMesh(obj, scElem, inFrame)
            time = scElem.time;
            sensorRange = obj.range;
            
            rVectSc = scElem.rVect;
            boreDir = obj.getSensorBoresightDirection(time, scElem, inFrame); 

            sensorOutlineCenter = rVectSc + sensorRange*boreDir;
            sensorRadius = obj.range*(sin(obj.angle) / sin(pi/2 - obj.angle));
            sensorOutlinePtsRaw = AbstractSensor.getCircleInSpace(boreDir, sensorOutlineCenter, sensorRadius);
            
            V = vertcat(rVectSc(:)', sensorOutlinePtsRaw');
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj, time, scElem, inFrame)
            boreDir = obj.steeringModel.getBoresightVector(time, scElem, inFrame);
            
%             boreDir = vect_normVector([4;1;0]);
        end
        
        function maxRange = getMaximumRange(obj)
            maxRange = obj.range;
        end
        
        function rVectOrigin = getOriginInFrame(obj, time, scElem, inFrame)
            newCartElem = obj.origin.getPositionAtTime(time, scElem, inFrame);
            rVectOrigin = [newCartElem.rVect];
        end
    end
end