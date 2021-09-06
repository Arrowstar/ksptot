classdef(Abstract) AbstractSensorTarget < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSensorTarget Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        rVect = getTargetPositions(obj, time, vehElemSet, inFrame);
    end
end

