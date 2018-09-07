classdef GravityForceModel < AbstractForceModel
    %AbstractForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = GravityForceModel()
        end
        
        function forceVect = getForce(obj, stateLogEntry)
            [ut, rVect, vVect, mass, bodyInfo] = obj.getParamsFromStateLogEntry(stateLogEntry);
            
            r = norm(rVect);
            forceVect = -((obj.bodyInfo.gm * mass)/(r^3)) * rVect;
        end
    end
end