classdef (Abstract) AbstractForceModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [forceVect, tankMdots, ecDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attState, srp, atmoState, engineToTankCache);
    end
end