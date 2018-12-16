classdef TrueAnomalyTermCondition < AbstractEventTerminationCondition
    %TrueAnomalyTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tru(1,1) double = 0; %rad
        bodyInfo(1,:) KSPTOT_BodyInfo
    end
    
    methods
        function obj = TrueAnomalyTermCondition(tru)
            obj.tru = tru;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)
            truToUse = obj.tru;
            
            if(truToUse > 2*pi || truToUse < -pi)
                truToUse = AngleZero2Pi(truToUse);
            end
            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, truToUse, obj.bodyInfo);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('True Anomaly (%.3f deg)', rad2deg(obj.tru));
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'True Anomaly';
            params.paramUnit = 'deg';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = rad2deg(obj.tru);
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = TrueAnomalyOptimizationVariable(obj);
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
            termCond = TrueAnomalyTermCondition(paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(~,y, targetTru, bodyInfo)
            rVect = y(1:3);
            vVect = y(4:6);
            
            [~, ecc, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,bodyInfo.gm,true);
            
            if(ecc >= 1.0)
                targetTru = angleNegPiToPi(targetTru);
                tru = angleNegPiToPi(tru);
            else
                if(abs(targetTru) <= 0.1)
                    targetTru = angleNegPiToPi(targetTru);
                    tru = angleNegPiToPi(tru);
                else
                    targetTru = AngleZero2Pi(targetTru);
                    tru = AngleZero2Pi(tru);
                end
            end
            
            value = targetTru - tru;
            isterminal = 1;
            direction = 0;
        end
    end
end