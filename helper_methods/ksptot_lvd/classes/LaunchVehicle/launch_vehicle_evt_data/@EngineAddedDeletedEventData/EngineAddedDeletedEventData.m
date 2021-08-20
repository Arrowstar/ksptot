classdef EngineAddedDeletedEventData < event.EventData
    properties
        engine LaunchVehicleEngine
    end
    
    methods
        function obj = EngineAddedDeletedEventData(engine)
            obj.engine = engine;
        end
    end
end