classdef ApoapsisAltitudeTermCondition < AbstractEventTerminationCondition
    %PeriapsisAltitudeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        apoalt(1,1) double = 0; %km
        bodyInfo KSPTOT_BodyInfo
    end
    
    methods
        function obj = ApoapsisAltitudeTermCondition(apoalt)
            obj.apoalt = apoalt;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Apoapsis Altitude (%.3f km)', obj.apoalt);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Apo. Altitude';
            params.paramUnit = 'km';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.apoalt;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = ApoapsisAltitudeOptimizationVariable(obj);
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
            termCond = ApoapsisAltitudeTermCondition(paramValue);
        end
    end
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)            
            rVect = y(1:3);
            vVect = y(4:6);
            cartElem = CartesianElementSet(t, rVect(:), vVect(:), obj.bodyInfo.getBodyCenteredInertialFrame());
            kepElem = cartElem.convertToFrame(obj.frame).convertToKeplerianElementSet();
            
            value =  kepElem.getAltitudeApoapsis() - obj.apoalt;
            isterminal = 1;
            direction = 0;
        end
    end
end