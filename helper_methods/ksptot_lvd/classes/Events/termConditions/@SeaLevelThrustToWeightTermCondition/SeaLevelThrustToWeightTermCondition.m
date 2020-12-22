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
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.targetTtW, obj.dryMass, obj.stgStates, obj.lvState, obj.throttleModel, obj.tankStates, obj.bodyInfo, obj.pwrStorageStates);
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
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(t,y, targetTtW, dryMass, stgStates, lvState, throttleModel, tankStates, bodyInfo, powerStorageStates)
%             ut = t;
%             rVect = y(1:3);
%             vVect = y(4:6);
%             tankMasses = y(7:6+length(tankStates));
            [ut, rVect, vVect, tankMasses, storageSoCs] = ForceModelPropagator.decomposeIntegratorTandY(t,y, length(tankStates), length(powerStorageStates));

            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            
            altitude = norm(rVect) - bodyInfo.radius;
            presskPa = getPressureAtAltitude(bodyInfo, altitude); 
            
            [~, totalThrust]= LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankMasses, stgStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, [], storageSoCs, powerStorageStates);
            
            totalMass = (dryMass + sum(tankMasses))*1000; %kg          
            totalThrust = totalThrust * 1000; % N
            
            twRatio = computeSLThrustToWeight(bodyInfo, totalThrust, totalMass);
            
            value = twRatio - targetTtW;
            isterminal = 1;
            direction = 0;
        end
    end
end