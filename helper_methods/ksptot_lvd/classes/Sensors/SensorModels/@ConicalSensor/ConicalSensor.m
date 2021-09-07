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
            arguments
                angle(1,1) double {mustBeGreaterThanOrEqual(angle,0), mustBeLessThanOrEqual(angle,1.5707963267949)}
                range(1,1) double {mustBeGreaterThan(range, 0)}
                origin(1,1) AbstractGeometricPoint
                steeringModel(1,1) AbstractSensorSteeringModel
            end
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
            
            S = [0,0,0, sensorRange];
            sphere = sphereMesh(S, 'nTheta', 5*2*pi/obj.angle, 'nPhi', 5*2*pi/obj.angle);
            sPtsRaw = unique(sphere.vertices,'rows');
            sPtsAngs = dang(repmat(boreDir,1,size(sPtsRaw,1)), sPtsRaw');
            sPts = sPtsRaw(sPtsAngs <= obj.angle+1E-10, :);
            
            M = makehgtform('translate',rVectSc(:)');
            sPts = transformPoint3d(sPts(:,1), sPts(:,2), sPts(:,3), M);
            
            V = vertcat(rVectSc(:)', sPts);
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj, time, scElem, inFrame)
            boreDir = obj.steeringModel.getBoresightVector(time, scElem, inFrame);
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