classdef LatitudeTermCondition < AbstractEventTerminationCondition
    %LatitudeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat(1,1) double = 0; %rad
        bodyInfo KSPTOT_BodyInfo
        direction(1,1) double = 0;
    end
    
    methods
        function obj = LatitudeTermCondition(lat)
            obj.lat = lat;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Latitude (%.3f deg)', rad2deg(obj.lat));
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Latitude';
            params.paramUnit = 'deg';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.lat;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = LatitudeOptimizationVariable(obj);
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
            termCond = LatitudeTermCondition(paramValue);
        end
    end
    
    methods(Access=protected)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)            
            rVect = y(1:3);
            vVect = y(4:6);
            cartElem = CartesianElementSet(t, rVect(:), vVect(:), obj.bodyInfo.getBodyCenteredInertialFrame());
            geoElem = cartElem.convertToFrame(obj.frame).convertToGeographicElementSet();
            
            value = geoElem.lat - obj.lat;
            isterminal = 1;
            direction = obj.direction;
        end
    end
end