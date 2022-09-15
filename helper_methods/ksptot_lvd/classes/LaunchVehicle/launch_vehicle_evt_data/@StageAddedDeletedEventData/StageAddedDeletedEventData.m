classdef StageAddedDeletedEventData < event.EventData
    properties
        stage LaunchVehicleStage
    end
    
    methods
        function obj = StageAddedDeletedEventData(stage)
            obj.stage = stage;
        end
    end
end