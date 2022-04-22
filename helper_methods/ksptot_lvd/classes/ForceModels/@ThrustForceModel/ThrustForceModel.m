classdef ThrustForceModel < AbstractForceModel
    %ThrustForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = ThrustForceModel()
            
        end
        
        function [forceVect, tankMdots, ecDots] = getForce(obj, ut, rVect, vVect, ~, bodyInfo, ~, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, ~, storageSoCs, powerStorageStates, ~)    
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = bodyInfo.getBodyAtmoPressure(altitude);
            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            
            [tankMdots, ~, forceVect, ecDots] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates);
        end
    end
end