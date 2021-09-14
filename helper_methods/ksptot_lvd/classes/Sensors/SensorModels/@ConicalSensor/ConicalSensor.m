classdef ConicalSensor < AbstractSensor
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char = 'Untitled Sensor';
        
        %Initial sensor properties (can be changed in sensor state later)
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
        origin AbstractGeometricPoint
        steeringModel AbstractSensorSteeringModel
        initActiveTf(1,1) logical = true;
        
        %LVD Data
        lvdData LvdData
        
        %drawing properties
        color(1,1) ColorSpecEnum = ColorSpecEnum.Green;
        alpha(1,1) double = 0.3;
        showMeshEdges(1,1) logical = false;
    end
    
    properties(Constant)
        typeEnum = SensorEnum.ConicalSensor;
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
               
        function [V,F] = getSensorMesh(obj, sensorState, scElem, dcm, inFrame)
            arguments
                obj(1,1) ConicalSensor
                sensorState(1,1) ConicalSensorState
                scElem(1,1) CartesianElementSet
                dcm(3,3) double
                inFrame(1,1) AbstractReferenceFrame
            end
            
            active = sensorState.getSensorActiveState();
            if(active)
                time = scElem.time;
                sensorRange = sensorState.getSensorMaxRange();
                sensorAngle = sensorState.getSensorAngle();
                
                theta = linspace(pi/2, pi/2 + sensorAngle, 10);
                xPts = sensorRange*cos(theta);
                yPts = sensorRange*sin(theta);
                
                xPts = [0, 0, xPts];
                yPts = [0, sensorRange/2, yPts];
                
                v = normVector([xPts(end); yPts(end)]);
                xPts = [xPts 0.5*v(1)*sensorRange];
                yPts = [yPts 0.5*v(2)*sensorRange];
                
                xPts = [xPts, 0];
                yPts = [yPts, 0];
                
                PV = [xPts(:), yPts(:)];

                [X,Y,Z] = revolutionSurface(PV, 15, [0,0, 0, 1]);
                fvc = surf2patch(X,Y,Z);
                fvc.faces = triangulateFaces(fvc.faces);
                
                rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);
                boreDir = obj.getSensorBoresightDirection(sensorState, time, scElem, dcm, inFrame); 
                
                r = vrrotvec([0;0;1],boreDir);            
                M = makehgtform('translate',rVectSensorOrigin(:)', 'axisrotate',r(1:3),r(4));
                fvc = transformPoint3d(fvc, M);
                    
                [V, F] = meshVertexClustering(fvc, 1);
                
%                 [V, F] = ensureManifoldMesh(fvc);
%                 [V, F] = removeInvalidBorderFaces(V, F);
%                 
%                 faceRowToRemove = NaN(height(F),1);
%                 for(i=1:height(F))
%                     if(numel(unique(F(i,:))) < 3)
%                         faceRowToRemove(i) = i;
%                     end
%                 end
%                 faceRowToRemove(isnan(faceRowToRemove)) = [];
%                 [V,F] = removeMeshFaces(V, F, faceRowToRemove);
%                 
%                 V(abs(V)<1E-10) = 0;
                
%                 [~,~,IC] = uniquetol(V, 1E-10, 'ByRows',true);
%                 vertsToRemove = setdiff([1:height(V)], unique(IC));
%                 [V,F] = removeMeshVertices(V, F, vertsToRemove);
                
                a=1;
            else
                V = [];
                F = [];
            end
        end
        
        function boreDir = getSensorBoresightDirection(~, sensorState, time, scElem, dcm, inFrame)
            boreDir = sensorState.getSensorSteeringMode().getBoresightVector(time, scElem, dcm, inFrame);
        end
        
        function sensorDcm = getSensorDcmToInertial(obj, scElem, dcm, inFrame)
            time = scElem.time;
            sensorDcm = obj.steeringModel.getSensorDcmToInertial(time, scElem, dcm, inFrame);
        end
               
        function rVectOrigin = getOriginInFrame(obj, time, scElem, inFrame)
            newCartElem = obj.origin.getPositionAtTime(time, scElem, inFrame);
            rVectOrigin = [newCartElem.rVect];
        end
        
        function tf = isVehDependent(obj, sensorState)
            tf = obj.origin.isVehDependent() || sensorState.getSensorSteeringMode().isVehDependent();
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
        
        function state = getInitialState(obj)
            state = ConicalSensorState(obj, obj.initActiveTf, obj.steeringModel, obj.angle, obj.range);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.origin == point;
        end
    end
end