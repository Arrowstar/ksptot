classdef AbstractSensorSteeringModel < matlab.mixin.SetGet
    %AbstractSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    methods       
        [boreDir] = getBoresightVector(obj, time, vehElemSet, steeringModel, dcm, inFrame)
        
        rollAngle = getBoresightRollAngle(obj)
        
        parentDcm = getSensorParentDcmToInertial(obj, time, vehElemSet, dcm, inFrame)
        
        sensorDcm = getSensorDcmToInertial(obj, time, vehElemSet, dcm, inFrame)
        
        tf = isVehDependent(obj);
        
        useTf = openEditDialog(obj)
        
        enum = getEnum(obj)
    end
end