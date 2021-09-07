classdef AbstractSensorSteeringModel < matlab.mixin.SetGet
    %AbstractSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    methods       
        [boreDir] = getBoresightVector(obj, time, vehElemSet, steeringModel, inFrame)
        
        rollAngle = getBoresightRollAngle(obj)
    end
end