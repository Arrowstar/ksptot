classdef EventDurationTermCondition < AbstractEventTerminationCondition
    %EventDurationTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        t0(1,1) double = 0;
        duration(1,1) double = 0;
    end
    
    methods
        function obj = EventDurationTermCondition(duration)
            obj.duration = duration;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.t0, obj.duration);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.t0 = initialStateLogEntry.time;
        end
        
        function name = getName(obj)
            name = 'Event Duration';
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,~, t0, duration)
            value = t - (t0+duration);
            isterminal = 1;
            direction = 0;
        end
    end
end