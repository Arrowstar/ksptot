classdef LaunchVehicleBasicElectricalBatteryState < AbstractLaunchVehicleEpsStorageState
    %LaunchVehicleBasicElectricalBatteryState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stageState = LaunchVehicleStageState.empty(1,0)% LaunchVehicleStageState
        battery% LaunchVehicleBasicElectricalBattery
        
        stateOfCharge = 0%(1,1) double = 0; %mT
        active(1,1) logical = true;
    end
    
    methods
        function obj = LaunchVehicleBasicElectricalBatteryState(stageState, battery)
            obj.stageState = stageState;
            obj.battery = battery;
        end
        
        function epsStorageComponent = getEpsStorageComponent(obj)
            epsStorageComponent = obj.battery;
        end
        
        function active = getActiveState(obj)
            active = obj.active;
        end
        
        function setActiveState(obj,active)
            obj.active = active;
        end
        
        function stateOfCharge = getStateOfCharge(obj)
            stateOfCharge = obj.stateOfCharge;
        end
        
        function setStateOfCharge(obj, stateOfCharge)
            obj.stateOfCharge = stateOfCharge;
        end
    end
end