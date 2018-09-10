classdef(Abstract) AbstractEventAction < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractEventAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        newStateLogEntry = exectuteAction(obj, stateLogEntry)
        
        initAction(obj, initialStateLogEntry)
        
        name = getName(obj)
    end
end