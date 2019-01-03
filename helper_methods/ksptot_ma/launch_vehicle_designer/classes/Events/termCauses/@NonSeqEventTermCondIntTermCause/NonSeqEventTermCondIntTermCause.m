classdef NonSeqEventTermCondIntTermCause < AbstractIntegrationTerminationCause
    %NonSeqEventTermCondIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nonSeqEvt LaunchVehicleNonSeqEvent
    end
    
    methods
        function obj = NonSeqEventTermCondIntTermCause(nonSeqEvt)
            obj.nonSeqEvt = nonSeqEvt;
        end
        
        function tf = shouldRestartIntegration(obj)
            tf = true;
        end
        
        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            actionStateLogEntries = obj.nonSeqEvt.evt.cleanupEvent(newStateLogEntry);
            
            if(not(isempty(actionStateLogEntries)))
%                 stateLog.appendStateLogEntries(actionStateLogEntries);
                newStateLogEntry = actionStateLogEntries(end).deepCopy();
            end
            
            newStateLogEntry.lvState.clearCachedConnEnginesTanks();
            obj.nonSeqEvt.decrementNumExecsRemaining();
        end
    end
end