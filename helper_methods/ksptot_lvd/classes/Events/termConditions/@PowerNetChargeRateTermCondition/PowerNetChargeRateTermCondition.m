classdef PowerNetChargeRateTermCondition < AbstractEventTerminationCondition
    %PowerNetChargeRateTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        netChargeRate(1,1) double = 0; %km
        initialStateLogEntry LaunchVehicleStateLogEntry
    end
    
    methods
        function obj = PowerNetChargeRateTermCondition(netChargeRate)
            obj.netChargeRate = netChargeRate;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.initialStateLogEntry = initialStateLogEntry;
        end
        
        function name = getName(obj)
            name = sprintf('Power Net Charge Rate (%.3f EC)', obj.netChargeRate);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Net Charge Rate';
            params.paramUnit = 'EC/s';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.netChargeRate;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = NetChargeRateOptimizationVariable(obj);
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
            termCond = PowerNetChargeRateTermCondition(paramValue);
        end
    end
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)
            initStateLogEntry = obj.initialStateLogEntry;
            
            powerStorageStates = initStateLogEntry.getAllActivePwrStorageStates();

            numTankStates = initStateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = initStateLogEntry.getNumActivePwrStorageStates();
            [~, ~, ~, ~, storageSoCs] = AbstractPropagator.decomposeIntegratorTandY(t,y, numTankStates, numPwrStorageStates);
            
            stgStates = initStateLogEntry.stageStates;
            
            ut = initStateLogEntry.time;
            rVect = initStateLogEntry.position(:);
            vVect = initStateLogEntry.velocity(:);
            bodyInfo = initStateLogEntry.centralBody;
            
            steeringModel = initStateLogEntry.steeringModel;
            
            storageRates = LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks(storageSoCs, powerStorageStates, stgStates, ut, rVect, vVect, bodyInfo, steeringModel);
            actualNetStorageRate = sum(storageRates);
            
            value = actualNetStorageRate - obj.netChargeRate;
            isterminal = 1;
            direction = 0;
        end
    end
end