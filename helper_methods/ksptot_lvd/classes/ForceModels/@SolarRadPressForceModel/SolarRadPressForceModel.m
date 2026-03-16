classdef SolarRadPressForceModel < AbstractForceModel
    %SolarRadPressForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = SolarRadPressForceModel()

        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attState, srp, atmoState, engineToTankCache)
            forceVect = srp.getSolarRadiationForce(ut, rVect, vVect, bodyInfo, steeringModel);
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end