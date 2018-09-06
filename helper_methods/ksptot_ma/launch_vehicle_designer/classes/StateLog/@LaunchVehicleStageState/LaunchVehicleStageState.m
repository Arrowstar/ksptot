classdef LaunchVehicleStageState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,1) LaunchVehicleStage
        
        dryMass(1,1) double = 0; %mT
        tankStates@LaunchVehicleTankState
    end
    
    methods
        function obj = LaunchVehicleStageState()
            
        end
        
        function tankMass = getStageTotalTankMass(obj)
            tankMass = sum([obj.tankStates.tankMass]);
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.dryMass + obj.getStageTotalTankMass();
        end
    end
end