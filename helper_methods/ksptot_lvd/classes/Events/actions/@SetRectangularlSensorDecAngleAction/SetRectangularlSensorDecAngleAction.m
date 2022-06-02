classdef SetRectangularlSensorDecAngleAction < AbstractEventAction
    %SetRectangularlSensorDecAngleAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor RectangularSensor
        sensorDecAngle(1,1) double {mustBeGreaterThan(sensorDecAngle, 0)} = deg2rad(10);
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetRectangularlSensorDecAngleAction(sensor, sensorDecAngle)
            if(nargin > 0)
                obj.sensor = sensor;
                obj.sensorDecAngle = sensorDecAngle;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            sensorState = newStateLogEntry.getSensorStateForSensor(obj.sensor);
            sensorState.setSensorDecAngle(obj.sensorDecAngle);
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            name = sprintf('Set Sensor Declination Half-Angle (%s => %0.3f deg)', obj.sensor.name, rad2deg(obj.sensorDecAngle));
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
            
            if(not(isempty(sensors)) && any([sensors.typeEnum] == SensorEnum.RectangularSensor))
                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetRectangularSensorDecAngleGUI_App(action, lvdData, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no rectangular sensors in this scenario.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end