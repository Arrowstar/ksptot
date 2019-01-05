classdef TankMassTermCondition < AbstractEventTerminationCondition
    %TankMassTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank(1,:) LaunchVehicleTank
        targetMass(1,1) double = 0;
        tankStateInd(1,1) double = 1;
    end
    
    methods
        function obj = TankMassTermCondition(tank,targetMass)
            obj.tank = tank;
            obj.targetMass = targetMass;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.tankStateInd, obj.targetMass);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.tankStateInd = NaN;
            
            tankStates = initialStateLogEntry.getAllActiveTankStates();
            if(not(isempty(tankStates)))
                tankStateIndex = find([tankStates.tank] == obj.tank); %#ok<EFIND>
                if(not(isempty(tankStateIndex)))
                    obj.tankStateInd = find([tankStates.tank] == obj.tank);
                end
            end
        end
        
        function name = getName(obj)
            name = sprintf('Tank Mass (%s = %0.3f mT)', obj.tank.name, obj.targetMass);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Target Mass';
            params.paramUnit = 'mT';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'on';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.targetMass;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = obj.tank;
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = TankMassOptimizationVariable(obj);
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
            tf = ([obj.tank] == tank);
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine, stopwatch)
            termCond = TankMassTermCondition(tank,paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, tankStateInd, targetMass)
            if(not(isnan(tankStateInd)))
                value = y(6+tankStateInd) - targetMass;
            else
                value = -Inf;
            end
            isterminal = 1;
            direction = 0;
        end
    end
end