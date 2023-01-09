classdef SetSensorMaxRangeAction < AbstractEventAction
    %SetSensorMaxRangeAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        sensorMaxRange(1,1) double {mustBeGreaterThan(sensorMaxRange, 0)} = 1;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetSensorMaxRangeAction(sensor, maxRange)
            if(nargin > 0)
                obj.sensor = sensor;
                obj.sensorMaxRange = maxRange;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            sensorState = newStateLogEntry.getSensorStateForSensor(obj.sensor);
            sensorState.setSensorMaxRange(obj.sensorMaxRange);
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            name = sprintf('Set Sensor Max Range (%s => %0.3f km)',obj.sensor.name,obj.sensorMaxRange);
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
            tf = obj.sensor == sensor;
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
                lvd_EditActionSetSensorMaxRangeGUI_App(action, lvdData, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no sensors in this scenario.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end