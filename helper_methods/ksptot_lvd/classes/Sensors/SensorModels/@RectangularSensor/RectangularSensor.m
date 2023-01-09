classdef RectangularSensor < AbstractSensor
    %RectangularSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char = 'Untitled Sensor';
        
        %Initial sensor properties (can be changed in sensor state later)
        azAngle(1,1) double = deg2rad(10) %rad
        decAngle(1,1) double = deg2rad(10) %rad
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
        typeEnum = SensorEnum.RectangularSensor;
    end
    
    methods
        function obj = RectangularSensor(name, azAngle, decAngle, range, origin, steeringModel, lvdData)
            arguments
                name(1,:) char
                azAngle(1,1) double {mustBeGreaterThanOrEqual(azAngle,0)}
                decAngle(1,1) double {mustBeGreaterThanOrEqual(decAngle,0)}
                range(1,1) double {mustBeGreaterThan(range, 0)}
                origin(1,1) AbstractGeometricPoint
                steeringModel(1,1) AbstractSensorSteeringModel
                lvdData(1,1) LvdData
            end
            
            if(azAngle > pi/2)
                azAngle = pi/2;
            end
            
            if(decAngle < -pi/2)
                decAngle = -pi/2;
            elseif(decAngle > pi/2)
                decAngle = pi/2;
            end
            
            obj.name = name;
            obj.azAngle = azAngle;
            obj.decAngle = decAngle;
            obj.range = range;
            obj.origin = origin;
            obj.steeringModel = steeringModel;
            obj.lvdData = lvdData;
        end
               
        function [V,F] = getSensorMesh(obj, sensorState, scElem, dcm, inFrame)
            arguments
                obj(1,1) RectangularSensor
                sensorState(1,1) RectangularSensorState
                scElem(1,1) CartesianElementSet
                dcm(3,3) double
                inFrame(1,1) AbstractReferenceFrame
            end
            
            active = sensorState.getSensorActiveState();
            if(active)
                time = scElem.time;
                sensorSteering = sensorState.getSensorSteeringMode();
                sensorRange = sensorState.getSensorMaxRange();
                azimuthAngle = sensorState.getSensorAzAngle();
                declinationAngle = sensorState.getSensorDecAngle();
                
                azAngles = linspace(-azimuthAngle, azimuthAngle, 10);
                decAngles = linspace(-declinationAngle, declinationAngle,10);
                
                angles = combvec(azAngles, decAngles);
                sphCoords = vertcat(angles, sensorRange*ones(1, width(angles)));
                
                [x,y,z] = sph2cart(sphCoords(1,:), sphCoords(2,:), sphCoords(3,:));
                r = [x', y', z'];
                
                sPts = vertcat([0,0,0], r);
                F = convhull(sPts);
                fvc.vertices = sPts;
                fvc.faces = F;
                
                rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);

                MM = sensorSteering.getSensorDcmToInertial(time, scElem, dcm, inFrame);
                r = rotm2axang(MM);  
                M = makehgtform('translate',rVectSensorOrigin(:)', 'axisrotate',r(1:3),r(4));
                fvc = transformPoint3d(fvc, M);
                    
                [V, F] = meshVertexClustering(fvc, 1);
            else
                V = [];
                F = [];
            end
        end
        
        function boreDir = getSensorBoresightDirection(~, sensorState, time, scElem, dcm, inFrame)
            boreDir = sensorState.getSensorSteeringMode().getBoresightVector(time, scElem, dcm, inFrame);
        end
        
        function sensorDcm = getSensorDcmToInertial(obj, sensorState, scElem, dcm, inFrame)
            time = scElem.time;
            sensorDcm = sensorState.getSensorSteeringMode().getSensorDcmToInertial(time, scElem, dcm, inFrame);
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
            lvd_EditRectangularSensorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function state = getInitialState(obj)
            state = RectangularSensorState(obj, obj.initActiveTf, obj.steeringModel, obj.azAngle, obj.decAngle, obj.range);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.origin == point;
        end
    end
end