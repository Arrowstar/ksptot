classdef(Abstract) AbstractEventTerminationCondition < matlab.mixin.SetGet
    %AbstractEventTerminationCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
        
        initTermCondition(obj, initialStateLogEntry)
        
        name = getName(obj)
    end
end