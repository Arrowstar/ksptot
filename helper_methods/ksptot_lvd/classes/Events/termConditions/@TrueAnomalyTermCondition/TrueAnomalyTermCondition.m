classdef TrueAnomalyTermCondition < AbstractEventTerminationCondition
    %TrueAnomalyTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tru(1,1) double = 0; %rad
        bodyInfo KSPTOT_BodyInfo
        
        hasGoneThroughZero(1,1) logical = false;
        mustGoThrough0(1,1) logical = false;
        prevDeltaM(1,1) double = NaN;
    end
    
    methods
        function obj = TrueAnomalyTermCondition(tru)
            obj.tru = tru;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)           
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
            
            targetTru = obj.tru;
            
            rVect = initialStateLogEntry.position;
            vVect = initialStateLogEntry.velocity;
            
            gmu = obj.bodyInfo.gm;
            [~, ecc, ~, ~, ~, curTru] = getKeplerFromState(rVect,vVect,gmu,true);
            curTru = AngleZero2Pi(curTru);
            
            M0 = computeMeanFromTrueAnom(curTru, ecc);
            Mtgt = computeMeanFromTrueAnom(targetTru, ecc);
            
            if(ecc >= 1)
                M0 = angleNegPiToPi(M0);
                Mtgt = angleNegPiToPi(Mtgt);
            else
                M0 = AngleZero2Pi(M0);
                Mtgt = AngleZero2Pi(Mtgt);
            end
            
            if(M0 > Mtgt)
                obj.mustGoThrough0 = true;
            else
                obj.mustGoThrough0 = false;
            end
            
            obj.hasGoneThroughZero = false;
            obj.prevDeltaM = NaN;
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
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)
            targetTru = obj.tru;
            
            if(targetTru > 2*pi || targetTru < -pi)
                targetTru = AngleZero2Pi(targetTru);
            end
            
            rVect = y(1:3);
            vVect = y(4:6);
            cartElem = CartesianElementSet(t, rVect(:), vVect(:), obj.bodyInfo.getBodyCenteredInertialFrame());
            cartElem = cartElem.convertToFrame(obj.frame);
                 
            rVect = cartElem.rVect;
            vVect = cartElem.vVect;
            
            gmu = obj.frame.getOriginBody().gm;
            [deltaT, deltaM, ~] = getDeltaTime(rVect, vVect, gmu, targetTru, obj.mustGoThrough0, obj.hasGoneThroughZero);
            
            if(not(isnan(obj.prevDeltaM)) && deltaM > obj.prevDeltaM)
                obj.hasGoneThroughZero = true;
                [deltaT, deltaM, ~] = getDeltaTime(rVect, vVect, gmu, targetTru, obj.mustGoThrough0, obj.hasGoneThroughZero);
            end
            
            obj.prevDeltaM = deltaM;
            
            value = deltaT;
            isterminal = 1;
            direction = 0;
        end
    end
end

function [deltaT, deltaM, curTru] = getDeltaTime(rVect, vVect, gmu, targetTru, mustGoThrough0, hasGoneThroughZero)
    [sma, ecc, ~, ~, ~, curTru] = getKeplerFromState(rVect,vVect,gmu,true);

    M0 = computeMeanFromTrueAnom(curTru, ecc);
    Mtgt = computeMeanFromTrueAnom(targetTru, ecc);
    
    if(mustGoThrough0)
        Mtgt = Mtgt + 2*pi;
        
        if(hasGoneThroughZero)
            M0 = M0 + 2*pi;
        end
    end
    
    deltaM = Mtgt - M0;   

    n = computeMeanMotion(sma, gmu);
    deltaT = deltaM/n;
end