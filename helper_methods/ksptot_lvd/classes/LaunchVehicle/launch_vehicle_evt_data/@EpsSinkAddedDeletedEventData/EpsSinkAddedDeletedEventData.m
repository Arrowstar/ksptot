classdef EpsSinkAddedDeletedEventData < event.EventData
    properties
        sink AbstractLaunchVehicleElectricalPowerSrcSnk
    end
    
    methods
        function obj = EpsSinkAddedDeletedEventData(sink)
            obj.sink = sink;
        end
    end
end