classdef ThrustForceModel < AbstractForceModel
    %ThrustForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = ThrustForceModel()
            
        end
        
        function [forceVect, tankMdots] = getForce(obj, ut, rVect, vVect, ~, bodyInfo, ~, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, ~)    
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);
            
            [tankMdots, ~, forceVect] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);
        end
    end
end