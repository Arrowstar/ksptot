classdef SetStopwatchRunningStateAction < AbstractEventAction
    %SetStageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stopwatch LaunchVehicleStopwatch
        runningStateToSet(1,1) StopwatchRunningEnum = StopwatchRunningEnum.NotRunning;
    end
    
    methods
        function obj = SetStopwatchRunningStateAction(stopwatch, runningStateToSet)
            if(nargin > 0)
                obj.stopwatch = stopwatch;
                obj.runningStateToSet = runningStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            if(not(isempty(obj.stopwatch)))
                stopwatchState = newStateLogEntry.stopwatchStates([newStateLogEntry.stopwatchStates.stopwatch] == obj.stopwatch);
                stopwatchState.running = obj.runningStateToSet;
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            if(not(isempty(obj.stopwatch)))
                nameStr = obj.stopwatch.name;
            else
                nameStr = '<No Stopwatch Selected>';
            end
            
            name = sprintf('Set Stopwatch State (%s = %s)', nameStr, obj.runningStateToSet.nameStr);
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
            tf = [obj.stopwatch] == stopwatch;
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
            addActionTf = lvd_EditActionSetStopwatchRunningStateGUI(action, lv);
        end
    end
end