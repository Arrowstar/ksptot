classdef DynamicPressureTermCondition < AbstractEventTerminationCondition
    %AltitudeTermCondition Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dynP(1,1) double = 0; %km
        bodyInfo KSPTOT_BodyInfo
    end
    
    methods
        function obj = DynamicPressureTermCondition(dynP)
            obj.dynP = dynP;
        end
        
        function evtTermCondFcnHndl = getEventTermCondFuncHandle(obj)            
            evtTermCondFcnHndl = @(t,y) obj.eventTermCond(t,y, obj.dynP, obj.bodyInfo);
        end
        
        function initTermCondition(obj, initialStateLogEntry)
            obj.bodyInfo = initialStateLogEntry.centralBody;
        end
        
        function name = getName(obj)
            name = sprintf('Dynamic Pressure (%.3f kPa)', obj.dynP);
        end
        
        function tf = shouldBeReinitOnRestart(obj)
            tf = true;
        end
        
        function params = getTermCondUiStruct(obj)
            params = struct();
            
            params.paramName = 'Dynamic Pressure';
            params.paramUnit = 'kPa';
            params.useParam = 'on';
            params.useStages = 'off';
            params.useTanks = 'off';
            params.useEngines = 'off';
            params.useStopwatches = 'off';
            
            params.value = obj.dynP;
            params.refStage = LaunchVehicleStage.empty(1,0);
            params.refTank = LaunchVehicleEngine.empty(1,0);
            params.refEngine = LaunchVehicleEngine.empty(1,0);
            params.refStopwatch = LaunchVehicleStopwatch.empty(1,0);
        end
        
        function optVar = getNewOptVar(obj)
            optVar = DynPressOptimizationVariable(obj);
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
            termCond = DynamicPressureTermCondition(paramValue);
        end
    end
    
    methods(Static, Access=private)
        function [value,isterminal,direction] = eventTermCond(ut,y, targetDynP, bodyInfo)
            rVectECI = y(1:3);
            vVectECI = y(4:6);
            
            altitude = norm(rVectECI) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long, struct()); 
            elseif(altitude <= 0)
                density = 0;
                vVectECEF = [0;0;0];
            else 
                density = 0;
                vVectECEF = [0;0;0];
            end
            
            vVectEcefMag = norm(vVectECEF);
            vVectEcefMagMS = vVectEcefMag*1000;
            
            dynP = density * (vVectEcefMagMS^2) / 2; %kg/m^3 * m^2 / s^2  = kg/(m*s^2)
            dynP_kPa = dynP/1000;
                       
            value = dynP_kPa - targetDynP;
            isterminal = 1;
            direction = 0;
        end
    end
end