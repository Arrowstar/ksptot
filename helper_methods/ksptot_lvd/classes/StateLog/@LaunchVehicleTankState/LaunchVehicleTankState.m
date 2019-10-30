classdef LaunchVehicleTankState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %validators commented out to improve performance
        stageState = LaunchVehicleStageState.empty(1,0)% LaunchVehicleStageState
        tank% LaunchVehicleTank
        tankMass = 0%(1,1) double = 0; %mT
    end
    
    methods
        function obj = LaunchVehicleTankState(stageState)
            obj.stageState = stageState;
        end
        
        function tankMass = getTankMass(obj)
            tankMass = obj.tankMass;
        end
        
        function setTankMass(obj, tankMass)
            obj.tankMass = tankMass;
        end
        
        function newTankState = deepCopy(obj)
%             newTankState = LaunchVehicleTankState(obj.stageState);
            newTankState = obj.copy();
            
%             newTankState.tank = obj.tank;
%             newTankState.tankMass = obj.tankMass;
        end
    end
end