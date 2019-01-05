classdef NormalForceModel < AbstractForceModel
    %NormalForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = NormalForceModel()
            
        end
        
        function [forceVect ,tankMdots] = getForce(obj, ~, rVect, vVect, mass, bodyInfo, ~, ~, ~, ~, ~, ~, ~, ~)  
            r = norm(rVect);
            alt = r - bodyInfo.radius;
            
            if(alt <= 0)
                bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
                spinVect = [0;0;bodySpinRate];
                centripAccel = crossARH(spinVect,crossARH(spinVect,rVect));
                
                gravAccel = -((bodyInfo.gm)/(r^3)) * rVect;
                
                forceVect = mass * (-gravAccel + centripAccel);
            else
                forceVect = [0;0;0];
            end
            
            tankMdots = [];
        end
    end
end