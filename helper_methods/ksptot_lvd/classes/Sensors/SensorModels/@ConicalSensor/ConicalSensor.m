classdef ConicalSensor < AbstractSensor
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char = 'Untitled Sensor';
        
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
        origin AbstractGeometricPoint
        steeringModel AbstractSensorSteeringModel
        
        lvdData LvdData
        
        %drawing properties
        color(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        alpha(1,1) double = 0.3;
        showMeshEdges(1,1) logical = false;
    end
    
    methods
        function obj = ConicalSensor(name, angle, range, origin, steeringModel, lvdData)
            arguments
                name(1,:) char
                angle(1,1) double {mustBeGreaterThanOrEqual(angle,0), mustBeLessThanOrEqual(angle,3.141592654)}
                range(1,1) double {mustBeGreaterThan(range, 0)}
                origin(1,1) AbstractGeometricPoint
                steeringModel(1,1) AbstractSensorSteeringModel
                lvdData(1,1) LvdData
            end
            
            if(angle > pi)
                angle = pi;
            end
            
            obj.name = name;
            obj.angle = angle;
            obj.range = range;
            obj.origin = origin;
            obj.steeringModel = steeringModel;
            obj.lvdData = lvdData;
        end
               
        function [V,F] = getSensorMesh(obj, scElem, dcm, inFrame)
            time = scElem.time;
            sensorRange = obj.range;
            
            rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);
            boreDir = obj.getSensorBoresightDirection(time, scElem, dcm, inFrame); 
            
            S = [0,0,0, sensorRange];
            sphere = sphereMesh(S, 'nTheta', ceil(5*2*pi/obj.angle), 'nPhi', 16);
            sPtsRaw = unique(sphere.vertices,'rows');
            sPtsAngs = dang(repmat([0;0;1],1,size(sPtsRaw,1)), sPtsRaw');
            sPts = sPtsRaw(sPtsAngs <= obj.angle+1E-10, :);
            
            r = vrrotvec([0;0;1],boreDir);            
            M = makehgtform('translate',rVectSensorOrigin(:)', 'axisrotate',r(1:3),r(4));
            sPts = transformPoint3d(sPts(:,1), sPts(:,2), sPts(:,3), M);
            
            V = vertcat(rVectSensorOrigin(:)', sPts);
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj, time, scElem, dcm, inFrame)
            boreDir = obj.steeringModel.getBoresightVector(time, scElem, dcm, inFrame);
        end
        
        function sensorDcm = getSensorDcmToInertial(obj, scElem, dcm, inFrame)
            time = scElem.time;
            sensorDcm = obj.steeringModel.getSensorDcmToInertial(time, scElem, dcm, inFrame);
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
        
        function color = getMeshColor(obj)
            color = obj.color;
        end
        
        function alpha = getMeshAlpha(obj)
            alpha = obj.alpha;
        end
        
        function tf = getDisplayMeshEdges(obj)
            tf = obj.showMeshEdges;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = false;
        end
        
        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditConicalSensorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.origin == point;
        end
    end
end