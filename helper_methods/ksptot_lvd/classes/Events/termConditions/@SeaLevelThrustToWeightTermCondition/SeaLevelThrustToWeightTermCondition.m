classdef SeaLevelThrustToWeightTermCondition < AbstractEventTerminationCondition
    %SeaLevelThrustToWeightTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        targetTtW(1,1) double = 0;
        
        dryMass(1,1) double = 0;
        tankStates LaunchVehicleTankState
        stgStates LaunchVehicleStageState
        lvState LaunchVehicleState
        throttleModel AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
        bodyInfo KSPTOT_BodyInfo
        pwrStorageStates AbstractLaunchVehicleEpsStorageState
    end
    
    methods
        function obj = SeaLevelThrustToWeightTermCondition(targetTtW)
            obj.targetTtW = targetTtW;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
            obj.dryMass = initialStateLogEntry.getTotalVehicleDryMass();
            
            obj.tankStates = initialStateLogEntry.getAllActiveTankStates();
            obj.stgStates = initialStateLogEntry.stageStates;
            obj.lvState = initialStateLogEntry.lvState;
            obj.throttleModel = initialStateLogEntry.throttleModel;
            obj.pwrStorageStates = initialStateLogEntry.getAllActivePwrStorageStates();
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function name = getName(obj)
            name = sprintf('Thrust to Weight Ratio (Sea Level) (%.3f)', obj.targetTtW);
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Target T2W';
            params.paramUnit = '';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.targetTtW;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = Thr2WghtTermCondOptimVar(obj);
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
            termCond = SeaLevelThrustToWeightTermCondition((paramValue));
        end
    end
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)
            targetTtWVal = obj.targetTtW;
            dryMassVal = obj.dryMass;
            stgStatesVal = obj.stgStates;
            lvStateVal = obj.lvState;
            throttleModelVal = obj.throttleModel;
            tankStatesVal = obj.tankStates;
            bodyInfoVal = obj.bodyInfo;
            pwrStorageStatesVal = obj.pwrStorageStates;
            
            [ut, rVect, vVect, tankMasses, storageSoCs] = ForceModelPropagator.decomposeIntegratorTandY(t,y, length(tankStatesVal), length(pwrStorageStatesVal));

            throttle = throttleModelVal.getThrottleAtTime(ut, rVect, vVect, tankMasses, dryMassVal, stgStatesVal, lvStateVal, tankStatesVal, bodyInfoVal, storageSoCs, pwrStorageStatesVal);
            
            altitude = norm(rVect) - bodyInfoVal.radius;
            presskPa = getPressureAtAltitude(bodyInfoVal, altitude); 
            
            [~, totalThrust]= LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStatesVal, tankMasses, stgStatesVal, throttle, lvStateVal, presskPa, ut, rVect, vVect, bodyInfoVal, [], storageSoCs, pwrStorageStatesVal, []);
            
            totalMass = (dryMassVal + sum(tankMasses))*1000; %kg          
            totalThrust = totalThrust * 1000; % N
            
            twRatio = computeSLThrustToWeight(bodyInfoVal, totalThrust, totalMass);
            
            value = twRatio - targetTtWVal;
            isterminal = 1;
            direction = 0;
        end
    end
end