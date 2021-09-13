classdef SetSensorActiveStateAction < AbstractEventAction
    %SetSensorActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetEngineActiveStateAction(sensor, activeStateToSet)
            if(nargin > 0)
                obj.sensor = sensor;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            sensorState = newStateLogEntry.getSensorStateForSensor(obj.sensor);
            sensorState.setSensorActiveState(obj.activeStateToSet);
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            if(obj.activeStateToSet)
                tf = 'Active';
            else
                tf = 'Inactive';
            end
            
            name = sprintf('Set Sensor State (%s = %s)',obj.sensor.name,tf);
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
        
        function tf = usesSensor(obj, sensor)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = obj.emptyVarArr;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)    
            lvdData = lv.lvdData;
            [~, sensors] = lvdData.sensors.getListboxStr();
            
            if(not(isempty(sensors)))
                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetSensorStateGUI_App(action, lvdData, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no sensors in this scenario.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end