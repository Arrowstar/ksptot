classdef(Abstract) AbstractSteeringModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
    end
end