classdef(Abstract) AbstractThrottleModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        throttle = getThrottleAtTime(obj,ut)
    end
end