classdef(Abstract) AbstractThrottleModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        throttle = getThrottleAtTime(obj,ut)
        
        setT0(obj, newT0)
        
        setPolyTerms(obj, const, linear, accel)
        
        addActionTf = openEditThrottleModelUI(obj, lv)
    end
end