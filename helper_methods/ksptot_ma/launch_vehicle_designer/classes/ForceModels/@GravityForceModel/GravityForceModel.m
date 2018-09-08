classdef GravityForceModel < AbstractForceModel
    %GravityForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = GravityForceModel()
        end
        
        function forceVect = getForce(obj, stateLogEntry)
            [~, rVect, ~, mass, bodyInfo, ~] = obj.getParamsFromStateLogEntry(stateLogEntry);
            
            r = norm(rVect);
            forceVect = -((bodyInfo.gm * mass)/(r^3)) * rVect;
        end
    end
end