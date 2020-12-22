classdef LaunchVehicleBasicElectricalBattery < AbstractLaunchVehicleElectricalPowerStorage
    %AbstractLaunchVehicleElectricalPowerStorage Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        name(1,:) char  = 'Untitled Battery';
        
        maxCapacity(1,1) double = 0;
        initialStateOfCharge(1,1) double = 0;
        
        id = rand(); %(1,1) double
    end
    
    methods
        function obj = LaunchVehicleBasicElectricalBattery(stage)
            obj.stage = stage;
            
            obj.id = rand();
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function stage = getAttachedStage(obj)
            stage = obj.stage;
        end
        
        function newState = createDefaultInitialState(obj, stageState)
            newState = LaunchVehicleBasicElectricalBatteryState(stageState, obj);
            newState.stateOfCharge = obj.initialStateOfCharge;
        end
        
        function useTF = openEditDialog(obj)
            useTF = lvd_EditBasicBatteryGUI(obj);
        end
        
%         function tf = isInUse(obj) %see abstract class
%             tf = false;
%         end
        
        function newObj = copy(obj)
            newObj = LaunchVehicleBasicElectricalBattery(obj.stage);
            newObj.maxCapacity = obj.maxCapacity;
            newObj.initialStateOfCharge = obj.initialStateOfCharge;
            
            newObj.name = sprintf('Copy of %s', obj.name);
        end
        
        function summStr = getSummaryStr(obj)
            summStr = {};
            
            summStr{end+1} = sprintf('\t\t\t%s', obj.name);
            summStr{end+1} = sprintf('\t\t\t\tMax. Capacity = %.3f EC', obj.maxCapacity);
            summStr{end+1} = sprintf('\t\t\t\tInitial State of Charge = %.3f EC', obj.initialStateOfCharge);
        end
        
        function maxCapacity = getMaximumCapacity(obj)
            maxCapacity = obj.maxCapacity;
        end
        
        function initialStateOfCharge = getInitialStateOfCharge(obj)
            initialStateOfCharge = obj.initialStateOfCharge;
        end
    end
end