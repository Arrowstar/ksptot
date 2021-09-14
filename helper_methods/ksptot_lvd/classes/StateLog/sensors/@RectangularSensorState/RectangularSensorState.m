classdef RectangularSensorState < AbstractSensorState
    %RectangularSensorState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor RectangularSensor
        
        activeTf(1,1) logical = true;
        steeringModel(1,1) AbstractSensorSteeringModel
        azAngle(1,1) double {mustBeGreaterThan(azAngle,0)} = deg2rad(10);
        decAngle(1,1) double {mustBeGreaterThan(decAngle,0)} = deg2rad(10);
        range(1,1) double {mustBeGreaterThan(range,0)} = 1;
    end
    
    methods
        function obj = RectangularSensorState(sensor, activeTf, steeringModel, azAngle, decAngle, range)
            obj.sensor = sensor;
            obj.activeTf = activeTf;
            obj.steeringModel = steeringModel;
            obj.azAngle = azAngle;
            obj.decAngle = decAngle;
            obj.range = range; 
        end
        
        function sensor = getSensor(obj)
            sensor = obj.sensor;
        end
        
        function activeTf = getSensorActiveState(obj)
            activeTf = obj.activeTf;
        end
        
        function setSensorActiveState(obj, activeTf)
            obj.activeTf = activeTf;
        end
        
        function steeringModel = getSensorSteeringMode(obj)
            steeringModel = obj.steeringModel;
        end
        
        function setSteeringModel(obj, steeringModel)
            obj.steeringModel = steeringModel;
        end
        
        function range = getSensorMaxRange(obj)
            range = obj.range;
        end
        
        function setSensorMaxRange(obj, range)
            obj.range = range;
        end
        
        function azAngle = getSensorAzAngle(obj)
            azAngle = obj.azAngle;
        end
        
        function setSensorAzAngle(obj, azAngle)
            obj.azAngle = azAngle;
        end
        
        function decAngle = getSensorDecAngle(obj)
            decAngle = obj.decAngle;
        end
        
        function setSensorDecAngle(obj, decAngle)
            obj.decAngle = decAngle;
        end
        
        function angle = getMaxAngle(obj)
            angle = max([obj.getSensorAzAngle, obj.getSensorDecAngle()]);
        end
    end
end

