classdef ThrustForceModel < AbstractForceModel
    %ThrustForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cacheUt(1,1) double = NaN;
        cacheRVect(3,1) double = [NaN;NaN;NaN];
        cacheVVect(3,1) double = [NaN;NaN;NaN];
        
        cacheForceVect(3,1) double = [0;0;0];
        cacheTankMdots(1,:) double = [];
        cacheEcDots(1,:) double = [];
    end
    
    methods
        function obj = ThrustForceModel()
            
        end
        
        function [forceVect, tankMdots, ecDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attState, srp, altitude, pressure, density, engineToTankCache)    
            arguments
                obj
                ut
                rVect
                vVect
                mass
                bodyInfo
                aero
                throttleModel
                steeringModel
                tankStates
                stageStates
                lvState
                dryMass
                tankStatesMasses
                thirdBodyGravity
                storageSoCs
                powerStorageStates
                attState
                srp
                altitude = NaN
                pressure = NaN
                density = []
                engineToTankCache struct = struct('engines',[])
            end

            if(ut == obj.cacheUt && all(rVect == obj.cacheRVect) && all(vVect == obj.cacheVVect))
                forceVect = obj.cacheForceVect;
                tankMdots = obj.cacheTankMdots;
                ecDots = obj.cacheEcDots;
                return;
            end

            if(isnan(altitude))
                altitude = norm(rVect) - bodyInfo.radius;
            end
            if(isnan(pressure))
                pressure = bodyInfo.getBodyAtmoPressure(altitude);
            end

            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            
            [tankMdots, ~, forceVect, ecDots] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attState, engineToTankCache);
        
            obj.cacheUt = ut;
            obj.cacheRVect = rVect;
            obj.cacheVVect = vVect;
            obj.cacheForceVect = forceVect;
            obj.cacheTankMdots = tankMdots;
            obj.cacheEcDots = ecDots;
        end
    end
end