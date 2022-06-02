classdef EventTermCondIntTermCause < AbstractIntegrationTerminationCause
    %EventTermCondIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = EventTermCondIntTermCause()
            
        end
        
        function tf = shouldRestartIntegration(obj)
            tf = false;
        end
        
        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry; %should probably never be called
        end
    end
end