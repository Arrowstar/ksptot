classdef MaxEventSimTimeIntTermCause < AbstractIntegrationTerminationCause
    %MaxEventSimTimeIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = MaxEventSimTimeIntTermCause()
            
        end
        
        function tf = shouldRestartIntegration(obj)
            tf = false;
        end
        
        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry; %should probably never be called
        end
    end
end