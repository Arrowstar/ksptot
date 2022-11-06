classdef SetSolarRadPressPropertiesAction < AbstractEventAction
    %SetSolarRadPressPropertiesAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        srpModel LaunchVehicleSolarRadPressState
    end
    
    methods
        function obj = SetSolarRadPressPropertiesAction(srpModel)
            arguments
                srpModel(1,1) LaunchVehicleSolarRadPressState = LaunchVehicleSolarRadPressState();
            end
            
            obj.srpModel = srpModel;
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) SetSolarRadPressPropertiesAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry 
            end

            newStateLogEntry = stateLogEntry;
            
            newStateLogEntry.srp = obj.srpModel;
        end
        
        function initAction(obj, initialStateLogEntry)
            %none
        end
        
        function name = getName(obj)           
            name = 'Set Solar Radiation Pressure Properties';
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            arguments
                action(1,1) SetSolarRadPressPropertiesAction
                lv(1,1) LaunchVehicle
            end

            addActionTf = action.srpModel.openEditDialog(lv.lvdData);
        end
    end
end