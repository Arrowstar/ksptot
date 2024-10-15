classdef LaunchVehicleNonSeqEvent <  matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleNonSeqEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evt LaunchVehicleEvent
        
        lwrBndEvt LaunchVehicleEvent
        uprBndEvt LaunchVehicleEvent
        
        maxNumExecs(1,1) double = 1;
        numExecsRemaining(1,1) double = 1;
    end
    
    methods
        function obj = LaunchVehicleNonSeqEvent(evt)
            obj.evt = evt;
        end
        
        function resetNumExecsRemaining(obj)
            obj.numExecsRemaining = obj.maxNumExecs;
        end
        
        function initEvent(obj, initialState)
            obj.evt.initEvent(initialState);
        end
        
        function termCond = getTerminationCondition(obj)
            termCondTemp = obj.evt.termCond.getEventTermCondFuncHandle();

            termCond = @(t,y) nonSeqEvtTermCond(t,y, termCondTemp, obj.evt.termCondDir.direction);
        end
        
        function decrementNumExecsRemaining(obj)
            obj.numExecsRemaining = obj.numExecsRemaining - 1;
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = obj.evt.name;
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