classdef EpsStorageAddedDeletedEventData < event.EventData
    properties
        storage AbstractLaunchVehicleElectricalPowerStorage
    end
    
    methods
        function obj = EpsStorageAddedDeletedEventData(storage)
            obj.storage = storage;
        end
    end
end