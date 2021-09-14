classdef ScriptEventPropagationData < event.EventData
    properties
        event LaunchVehicleEvent
    end
    
    methods
        function obj = ScriptEventPropagationData(event)
            obj.event = event;
        end
    end
end