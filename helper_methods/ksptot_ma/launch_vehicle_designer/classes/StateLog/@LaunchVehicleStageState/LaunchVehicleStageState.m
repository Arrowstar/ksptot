classdef LaunchVehicleStageState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage
        
        active(1,1) logical = true;
        
        engineStates(1,:) LaunchVehicleEngineState
        tankStates(1,:) LaunchVehicleTankState
    end
    
    methods
        function obj = LaunchVehicleStageState()
            
        end
        
        function tankMass = getStageTotalTankMass(obj)
            tankMass = sum([obj.tankStates.tankMass]);
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.stage.dryMass + obj.getStageTotalTankMass();
        end
    end
end