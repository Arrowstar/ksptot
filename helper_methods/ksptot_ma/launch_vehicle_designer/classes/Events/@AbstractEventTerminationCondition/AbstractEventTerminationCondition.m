classdef(Abstract) AbstractEventTerminationCondition < matlab.mixin.SetGet
    %AbstractEventTerminationCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        optVar
    end
    
    methods
        evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
        
        initTermCondition(obj, initialStateLogEntry)
        
        name = getName(obj)
        
        params = getTermCondUiStruct(obj)
        
        optVar = getNewOptVar(obj)
        
        optVar = getExistingOptVar(obj)
    end
    
    methods(Static)
        termCond = getTermCondForParams(paramValue, stage, tank, engine)
    end
end