classdef(Abstract) AbstractSensorState < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractSensorState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        sensor = getSensor(obj);
        
        activeTf = getSensorActiveState(obj);
        
        setSensorActiveState(obj, activeTf);
        
        steeringModel = getSensorSteeringMode(obj);
        
        setSteeringModel(obj, steeringModel);
        
        range = getSensorMaxRange(obj);
               
        setSensorMaxRange(obj, range);
        
        angle = getMaxAngle(obj);
    end
end

