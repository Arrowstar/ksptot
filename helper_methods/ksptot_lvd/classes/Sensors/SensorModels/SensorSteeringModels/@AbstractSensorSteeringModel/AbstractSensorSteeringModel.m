classdef AbstractSensorSteeringModel < matlab.mixin.SetGet
    %AbstractSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    methods       
        [boreDir] = getBoresightVector(obj, time, vehElemSet, steeringModel, dcm, inFrame)
        
        rollAngle = getBoresightRollAngle(obj)
        
        dcm = getSensorParentDcmToInertial(obj, time, vehElemSet, steeringModel, dcm, inFrame)
        
        useTf = openEditDialog(obj)
        
        enum = getEnum(obj)
    end
end