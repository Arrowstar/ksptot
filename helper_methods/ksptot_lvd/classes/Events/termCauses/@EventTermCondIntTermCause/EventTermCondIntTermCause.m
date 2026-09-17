classdef EventTermCondIntTermCause < AbstractIntegrationTerminationCause
    %EventTermCondIntTermCause The event's own termination condition fired.
    %
    %   termCondInd identifies which of the event's termination conditions
    %   this cause belongs to, counted over the *active* list the integrator
    %   was given (see LaunchVehicleEvent.getActiveTermCondFuncHandles).  The
    %   simulation driver maps it back to the event's full condition list.

    properties
        termCondInd(1,1) double = 1;
    end

    methods
        function obj = EventTermCondIntTermCause(termCondInd)
            if(nargin > 0)
                obj.termCondInd = termCondInd;
            end
        end

        function tf = shouldRestartIntegration(obj)
            %"All" logic is handled by the driver, which knows the event and
            %its latches; from the integrator's point of view a termination
            %condition always ends the propagation segment.
            tf = false;
        end

        function newStateLogEntry = getRestartInitialState(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry; %should probably never be called
        end
    end
end
