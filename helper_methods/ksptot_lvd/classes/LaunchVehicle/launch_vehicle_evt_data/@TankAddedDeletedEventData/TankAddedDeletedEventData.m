classdef TankAddedDeletedEventData < event.EventData
    properties
        tank LaunchVehicleTank
    end
    
    methods
        function obj = TankAddedDeletedEventData(tank)
            obj.tank = tank;
        end
    end
end