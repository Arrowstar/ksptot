classdef LaunchVehicleStageState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage = LaunchVehicleStage(LaunchVehicle())
        
        active(1,1) logical = true;
        
        engineStates(1,:) LaunchVehicleEngineState
        tankStates(1,:) LaunchVehicleTankState
    end
    
    methods
        function obj = LaunchVehicleStageState(stage)
            obj.stage = stage;
        end
        
        function tankMass = getStageTotalTankMass(obj)
            tankMass = sum([obj.tankStates.tankMass]);
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.stage.dryMass + obj.getStageTotalTankMass();
        end
        
        function newStageState = deepCopy(obj)
            newStageState = LaunchVehicleStageState(obj.stage);
            newStageState.active = obj.active;
            
            for(i=1:length(obj.engineStates)) %#ok<*NO4LP>
                newStageState.engineStates(end+1) = obj.engineStates(i).deepCopy();
            end
            
            for(i=1:length(obj.tankStates))
                newStageState.tankStates(end+1) = obj.tankStates(i).deepCopy();
            end
        end
    end
end