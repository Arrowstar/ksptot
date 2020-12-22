classdef TotalVehicleEpsStateOfChargeTermCondition < AbstractEventTerminationCondition
    %TotalVehicleEpsStateOfChargeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        totalStateOfCharge(1,1) double = 0; %km
        initialStateLogEntry LaunchVehicleStateLogEntry
    end
    
    methods
        function obj = TotalVehicleEpsStateOfChargeTermCondition(totalStateOfCharge)
            obj.totalStateOfCharge = totalStateOfCharge;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.totalStateOfCharge, obj.initialStateLogEntry);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.initialStateLogEntry = initialStateLogEntry;
        end
        
        function name = getName(obj)
            name = sprintf('Power Total State of Charge (%.3f EC)', obj.totalStateOfCharge);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Total State of Charge';
            params.paramUnit = 'EC';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.totalStateOfCharge;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = TotalStateOfChargeOptimizationVariable(obj);
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
            tf = false;
        end
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine, stopwatch)
            termCond = TotalVehicleEpsStateOfChargeTermCondition(paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, targetSoC, initialStateLogEntry)
            numTankStates = initialStateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = initialStateLogEntry.getNumActivePwrStorageStates();
            [~, ~, ~, ~, pwrStorageStates] = AbstractPropagator.decomposeIntegratorTandY(t,y, numTankStates, numPwrStorageStates);
            
            totalActualSoC = sum(pwrStorageStates);
            
            value = totalActualSoC - targetSoC;
            isterminal = 1;
            direction = 0;
        end
    end
end