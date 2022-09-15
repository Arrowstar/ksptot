classdef (Abstract) AbstractForceModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [forceVect, tankMdots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, CdA, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, grav3Body, storageSoCs, powerStorageStates, attState);
    end
end