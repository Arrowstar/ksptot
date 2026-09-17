classdef NonSeqEventTermCondIntTermCause < AbstractIntegrationTerminationCause
    %NonSeqEventTermCondIntTermCause Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nonSeqEvt LaunchVehicleNonSeqEvent
    end

    properties(Transient)
        %A8: the state log entries produced by the non-sequential event's
        %actions on the most recent execution.  Only populated when the event
        %asks for its executions to be logged; the simulation driver drains
        %this so the discontinuity (an impulsive dV, a staging event, ...)
        %appears in the mission's state log instead of being invisible.
        lastLoggedStateLogEntries LaunchVehicleStateLogEntry
    end

    methods
        function obj = NonSeqEventTermCondIntTermCause(nonSeqEvt)
            obj.nonSeqEvt = nonSeqEvt;
            obj.lastLoggedStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
        end

        function tf = shouldRestartIntegration(obj)
            tf = true;
        end

        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry.deepCopy();
            actionStateLogEntries = obj.nonSeqEvt.evt.cleanupEvent(newStateLogEntry);

            obj.lastLoggedStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);

            if(not(isempty(actionStateLogEntries)))
                if(obj.nonSeqEvt.logExecutions)
                    obj.lastLoggedStateLogEntries = actionStateLogEntries;
                end

                newStateLogEntry = actionStateLogEntries(end).deepCopy();
            end

            newStateLogEntry.lvState.clearCachedConnEnginesTanks();
            obj.nonSeqEvt.decrementNumExecsRemaining();
        end

        function entries = drainLoggedStateLogEntries(obj)
            %drainLoggedStateLogEntries Returns and clears the entries stashed
            %by the last getRestartInitialState call.
            entries = obj.lastLoggedStateLogEntries;
            obj.lastLoggedStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
        end
    end
end