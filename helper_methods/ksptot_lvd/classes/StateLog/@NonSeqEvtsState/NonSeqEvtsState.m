classdef NonSeqEvtsState < matlab.mixin.SetGet
    %NonSeqEvtsState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nonSeqEvts LaunchVehicleNonSeqEvents
        event LaunchVehicleEvent
    end
    
    methods
        function obj = NonSeqEvtsState(event, nonSeqEvts)
            obj.event = event;
            obj.nonSeqEvts = nonSeqEvts;
        end
    end
end

