classdef LaunchVehicleNonSeqEvent <  matlab.mixin.SetGet
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
            termCond = obj.evt.termCond.getEventTermCondFuncHandle();
        end
        
        function decrementNumExecsRemaining(obj)
            obj.numExecsRemaining = obj.numExecsRemaining - 1;
        end
        
        function listBoxStr = getListboxStr(obj)
            listBoxStr = obj.evt.name;
        end
    end
end