classdef AltitudeTermCondition < AbstractEventTerminationCondition
    %TrueAnomalyTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        altitude(1,1) double = 0; %km
        bodyInfo(1,:) KSPTOT_BodyInfo
    end
    
    methods
        function obj = AltitudeTermCondition(tru)
            obj.altitude = tru;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.altitude, obj.bodyInfo);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Altitude (%.3f km)', obj.altitude);
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Altitude';
            params.paramUnit = 'km';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            
            params.value = obj.altitude;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = AltitudeOptimizationVariable(obj);
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
    end
    
    methods(Static)
        function termCond = getTermCondForParams(paramValue, stage, tank, engine)
            termCond = AltitudeTermCondition(paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(~,y, targetAlt, bodyInfo)
            rVect = y(1:3);

            rMag = norm(rVect);
            bRadius = bodyInfo.radius;
            altitude = rMag - bRadius;
            
            value = altitude - targetAlt;
            isterminal = 1;
            direction = 0;
        end
    end
end