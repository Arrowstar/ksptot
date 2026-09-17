classdef LaunchVehicleNonSeqEvent <  matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleNonSeqEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evt LaunchVehicleEvent
        
        lwrBndEvt LaunchVehicleEvent
        uprBndEvt LaunchVehicleEvent
        
        maxNumExecs(1,1) double = 1;
        numExecsRemaining(1,1) double = 1;

        %A8: explicit control over non-sequential events.  enabled lets a
        %non-sequential event be switched off without deleting it or zeroing
        %its execution count; priority breaks ties when more than one
        %non-sequential event is armed on the same integration step (higher
        %fires first); logExecutions surfaces the discontinuity the event's
        %actions introduce as its own state log entries.  The defaults
        %reproduce the historical behavior exactly.
        enabled(1,1) logical = true;
        priority(1,1) double = 0;
        logExecutions(1,1) logical = false;
    end

    methods
        function obj = LaunchVehicleNonSeqEvent(evt)
            obj.evt = evt;
        end

        function tf = isActive(obj)
            %isActive True when this non-sequential event can still fire.
            tf = obj.enabled && obj.numExecsRemaining > 0;
        end

        function resetNumExecsRemaining(obj)
            obj.numExecsRemaining = obj.maxNumExecs;
        end
        
        function initEvent(obj, initialState)
            obj.evt.initEvent(initialState);
        end
        
        function termCond = getTerminationCondition(obj)
            %getTerminationCondition The event function for the first (or
            %only) termination condition.  Kept for callers that predate
            %multiple conditions; getTerminationConditions covers them all.
            termConds = obj.getTerminationConditions();
            termCond = termConds{1};
        end

        function termConds = getTerminationConditions(obj)
            %getTerminationConditions One event function per termination
            %condition on the wrapped event.  A non-sequential event fires
            %when ANY of them crosses (first-of logic): each handle is armed
            %separately by the simulation driver, all sharing this event's
            %termination cause, so the wrapped event's termCondLogic setting
            %does not apply here.
            conds = obj.evt.getAllTermConds();
            dirs = obj.evt.getAllTermCondDirs();

            termConds = cell(1, numel(conds));
            for(i=1:numel(conds)) %#ok<*NO4LP>
                termCondTemp = conds(i).getEventTermCondFuncHandle();
                direction = dirs(i).direction;

                termConds{i} = @(t,y) nonSeqEvtTermCond(t,y, termCondTemp, direction);
            end
        end
        
        function decrementNumExecsRemaining(obj)
            obj.numExecsRemaining = obj.numExecsRemaining - 1;
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = obj.evt.name;

            if(not(obj.enabled))
                listBoxStr = sprintf('%s [disabled]', listBoxStr);
            end

            if(obj.priority ~= 0)
                listBoxStr = sprintf('%s [priority %g]', listBoxStr, obj.priority);
            end
        end
    end
    
	methods(Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj); 
        end
	end
end

function [value,isterminal,direction] = nonSeqEvtTermCond(t,y, termCond, direction)
    arguments
        t double
        y double
        termCond(1,1) function_handle
        direction(1,1) double
    end

    [value,isterminal] = termCond(t,y);
end