classdef EpsSrcAddedDeletedEventData < event.EventData
    properties
        src AbstractLaunchVehicleElectricalPowerSrcSnk
    end
    
    methods
        function obj = EpsSrcAddedDeletedEventData(src)
            obj.src = src;
        end
    end
end