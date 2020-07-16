classdef(Abstract) AbstractThrottleModel < matlab.mixin.SetGet
    %AbstractSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
        
        throttleContinuity = false;
    end
    
    methods
        initThrottleModel(obj, ut, prevThrottleAtUt)
        
        throttle = getThrottleAtTime(obj, ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo)
                
        addActionTf = openEditThrottleModelUI(obj, lv)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
    end
end