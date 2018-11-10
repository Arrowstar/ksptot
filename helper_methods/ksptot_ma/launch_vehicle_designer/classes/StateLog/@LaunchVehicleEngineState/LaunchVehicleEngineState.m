classdef LaunchVehicleEngineState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState(1,1) LaunchVehicleStageState = LaunchVehicleStageState(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())));
        engine(1,1) LaunchVehicleEngine = LaunchVehicleEngine(LaunchVehicleStage(LaunchVehicle(LvdData.getEmptyLvdData())))
        active(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleEngineState(stageState)
            obj.stageState = stageState;
        end
        
        function newEngineState = deepCopy(obj)
%             newEngineState = LaunchVehicleEngineState(obj.stageState);
            newEngineState = obj.copy();

%             newEngineState.engine = obj.engine;
            newEngineState.active = obj.active;
        end
        
        function obj = createCopiesOfCopyableInternals(obj)
%             obj.active = obj.active;
        end
    end
end