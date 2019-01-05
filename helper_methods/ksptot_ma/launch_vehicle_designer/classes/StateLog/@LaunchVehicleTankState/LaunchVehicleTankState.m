classdef LaunchVehicleTankState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState(1,:) LaunchVehicleStageState
        tank(1,:) LaunchVehicleTank
        tankMass(1,1) double = 0; %mT
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