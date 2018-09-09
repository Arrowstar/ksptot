classdef LaunchVehicleEngineState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState(1,1) LaunchVehicleStageState = LaunchVehicleStageState(LaunchVehicleStage(LaunchVehicle()));
        engine(1,1) LaunchVehicleEngine = LaunchVehicleEngine(LaunchVehicleStage(LaunchVehicle()))
        active(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleEngineState(stageState)
            obj.stageState = stageState;
        end
        
        function newEngineState = deepCopy(obj)
            newEngineState = LaunchVehicleEngineState(obj.stageState);
            
            newEngineState.engine = obj.engine;
            newEngineState.active = obj.active;
        end
    end
end