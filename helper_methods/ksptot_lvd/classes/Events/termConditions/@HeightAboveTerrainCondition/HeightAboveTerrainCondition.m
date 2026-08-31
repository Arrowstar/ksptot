classdef HeightAboveTerrainCondition < AbstractEventTerminationCondition
    %HeightAboveTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        heightAboveTerrain(1,1) double = 0; %km
        bodyInfo KSPTOT_BodyInfo
    end
    
    methods
        function obj = HeightAboveTerrainCondition(heightAboveTerrain)
            obj.heightAboveTerrain = heightAboveTerrain;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Height Above Terrain (%.3f km)', obj.heightAboveTerrain);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Height Above Terrain';
            params.paramUnit = 'km';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.heightAboveTerrain;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = HeightAboveTerrainOptimizationVariable(obj);
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
            termCond = HeightAboveTerrainCondition(paramValue);
        end
    end
    
    methods(Access=private)
        function [value,isterminal,direction] = eventTermCond(obj, t,y)             
            rVect = y(1:3);
            vVect = y(4:6);
            if(obj.frame.getOriginBody() == obj.bodyInfo)
                [lat, lon, alt] = getLatLongAltFromInertialVect(t, rVect(:), obj.bodyInfo);
            else
                cartElem = CartesianElementSet(t, rVect(:), vVect(:), obj.bodyInfo.getBodyCenteredInertialFrame());
                geoElemSet = cartElem.convertToFrame(obj.frame.getOriginBody().getBodyFixedFrame(), true).convertToGeographicElementSet();
                lat = geoElemSet.lat;
                lon = geoElemSet.long;
                alt = geoElemSet.alt;
            end
            %getHeightMap() re-reads a cached property on the body object on
            %every event evaluation; the height map depends only on the
            %body, so memoize the interpolant here to skip the repeated
            %getter overhead.  The exact same griddedInterpolant object is
            %returned, so results are bit-identical.
            %Keyed on OBJECT IDENTITY, not bodyInfo.id: ids are unique only
            %within one body database, and every mission file carries its own
            %serialized celBodyData, so two missions open in the same session
            %present distinct KSPTOT_BodyInfo objects sharing an id and
            %carrying different height maps.  An id-keyed cache would hand the
            %previous mission's terrain to this one.  KSPTOT_BodyInfo is a
            %handle class, so ~= is an identity test.
            persistent hmapBody hmapGI
            if(isempty(hmapGI) || hmapBody ~= obj.bodyInfo)
                hmapGI = obj.bodyInfo.getHeightMap();
                hmapBody = obj.bodyInfo;
            end
            heightMapGI = hmapGI;

            actualHeightAboveTerrain = alt - heightMapGI(angleNegPiToPi(lat), angleNegPiToPi(lon)); %subtract because it's our alt relative to terrain height
            
            value = actualHeightAboveTerrain - obj.heightAboveTerrain;
            isterminal = 1;
            direction = 0;
        end
    end
end