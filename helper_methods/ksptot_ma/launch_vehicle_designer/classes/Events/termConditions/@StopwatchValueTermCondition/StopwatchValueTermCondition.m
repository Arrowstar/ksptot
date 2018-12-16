classdef StopwatchValueTermCondition < AbstractEventTerminationCondition
    %StopwatchValueTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stopwatch LaunchVehicleStopwatch
        value(1,1) double = 0;
        t0(1,1) double = 0;
        
        initStopwatchState LaunchVehicleStopwatchState
    end
    
    methods
        function obj = StopwatchValueTermCondition(stopwatch, value)
            obj.stopwatch = stopwatch;
            obj.value = value;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.value, obj.t0, obj.initStopwatchState);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.t0 = initialStateLogEntry.time;
            if(not(isempty(obj.stopwatch)))
                obj.initStopwatchState = initialStateLogEntry.stopwatchStates(initialStateLogEntry.stopwatchStates.stopwatch == obj.stopwatch);
            else
                obj.initStopwatchState = LaunchVehicleStopwatchState.empty(1,0);
            end
        end
        
        function name = getName(obj)
            name = sprintf('Stopwatch Value (%.3f sec)', obj.value);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = false;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Stopwatch Value';
            params.paramUnit = 'sec';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'on';
            
            params.value = obj.value;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = obj.stopwatch;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = StopwatchValueOptimizationVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
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
            tf = true;
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine, stopwatch)
            termCond = StopwatchValueTermCondition(stopwatch, paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,~, swValue, t0, initStopwatchState)
            if(not(isempty(initStopwatchState)))
                if(initStopwatchState.running == false)
                    value = swValue - initStopwatchState.value;
                else
                    deltaT = t - t0;
                    curTimerValue = initStopwatchState.value + deltaT;
                    value = swValue - curTimerValue;
                end

                isterminal = 1;
                direction = 0;
            else
                value = 1E99;
                isterminal = 0;
                direction = 0;
            end
        end
    end
end