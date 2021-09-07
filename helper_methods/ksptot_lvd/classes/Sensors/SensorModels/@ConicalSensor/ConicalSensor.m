classdef ConicalSensor < AbstractSensor
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char = 'Untitled Sensor';
        
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
        origin AbstractGeometricPoint
        steeringModel AbstractSensorSteeringModel
    end
    
    methods
        function obj = ConicalSensor(name, angle, range, origin, steeringModel)
            arguments
                name(1,:) char
                angle(1,1) double {mustBeGreaterThanOrEqual(angle,0), mustBeLessThanOrEqual(angle,1.5707963267949)}
                range(1,1) double {mustBeGreaterThan(range, 0)}
                origin(1,1) AbstractGeometricPoint
                steeringModel(1,1) AbstractSensorSteeringModel
            end
            obj.name = name;
            obj.angle = angle;
            obj.range = range;
            obj.origin = origin;
            obj.steeringModel = steeringModel;
        end
               
        function [V,F] = getSensorMesh(obj, scElem, scSteeringModel, inFrame)
            time = scElem.time;
            sensorRange = obj.range;
            
            rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);
            boreDir = obj.getSensorBoresightDirection(time, scElem, scSteeringModel, inFrame); 
            
            S = [0,0,0, sensorRange];
            sphere = sphereMesh(S, 'nTheta', ceil(2*pi/obj.angle), 'nPhi', 25);
            sPtsRaw = unique(sphere.vertices,'rows');
            sPtsAngs = dang(repmat([0;0;1],1,size(sPtsRaw,1)), sPtsRaw');
            sPts = sPtsRaw(sPtsAngs <= obj.angle+1E-10, :);
            
            r = vrrotvec([0;0;1],boreDir);            
            M = makehgtform('translate',rVectSensorOrigin(:)', 'axisrotate',r(1:3),r(4));
            sPts = transformPoint3d(sPts(:,1), sPts(:,2), sPts(:,3), M);
            
            V = vertcat(rVectSensorOrigin(:)', sPts);
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj, time, scElem, scSteeringModel, inFrame)
            boreDir = obj.steeringModel.getBoresightVector(time, scElem, scSteeringModel, inFrame);
        end
        
        function maxRange = getMaximumRange(obj)
            maxRange = obj.range;
        end
        
        function rVectOrigin = getOriginInFrame(obj, time, scElem, inFrame)
            newCartElem = obj.origin.getPositionAtTime(time, scElem, inFrame);
            rVectOrigin = [newCartElem.rVect];
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = obj.name;
        end
                
        function tf = usesGeometricPoint(obj, point)
            tf = obj.origin == point;
        end
    end
end