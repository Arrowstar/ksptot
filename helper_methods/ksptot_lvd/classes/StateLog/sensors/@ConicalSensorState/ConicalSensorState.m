classdef ConicalSensorState < AbstractSensorState
    %ConicalSensorState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor ConicalSensor
        
        activeTf(1,1) logical = true;
        steeringModel(1,1) AbstractSensorSteeringModel
        angle(1,1) double {mustBeGreaterThan(angle,0)} = deg2rad(10);
        range(1,1) double {mustBeGreaterThan(range,0)} = 1;
    end
    
    methods
        function obj = ConicalSensorState(sensor, activeTf, steeringModel, angle, range)
            obj.sensor = sensor;
            obj.activeTf = activeTf;
            obj.steeringModel = steeringModel;
            obj.angle = angle;
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
        
        function angle = getSensorAngle(obj)
            angle = obj.angle;
        end
        
        function setSensorAngle(obj, angle)
            obj.angle = angle;
        end
        
        function range = getSensorMaxRange(obj)
            range = obj.range;
        end
        
        function setSensorMaxRange(obj, range)
            obj.range = range;
        end
    end
end

