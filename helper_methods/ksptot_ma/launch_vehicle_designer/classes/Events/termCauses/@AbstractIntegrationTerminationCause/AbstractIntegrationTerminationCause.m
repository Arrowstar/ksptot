classdef(Abstract) AbstractIntegrationTerminationCause < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractIntegrationTerminationCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        tf = shouldRestartIntegration(obj)
        
        newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
    end
    
    methods(Static, Access=protected)
        function defaultObject = getDefaultScalarElement()
            defaultObject = SoITransitionDownIntTermCause();
        end
    end
end