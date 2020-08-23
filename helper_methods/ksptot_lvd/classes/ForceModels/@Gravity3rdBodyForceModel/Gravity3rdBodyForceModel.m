classdef Gravity3rdBodyForceModel < AbstractForceModel
    %Gravity3rdBodyForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = Gravity3rdBodyForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVectSC, ~, mass, bodySC, ~, ~, ~, ~, ~, ~, ~, ~, grav3Body, ~, ~)      
            forceVect = [0;0;0];
            
            bodies = grav3Body.bodies;
            celBodyData = grav3Body.celBodyData;
            for(i=1:length(bodies))
                if(bodies(i) ~= bodySC)
                    rVect = -1 * getAbsPositBetweenSpacecraftAndBody(ut, rVectSC, bodySC, bodies(i), celBodyData);

                    r = norm(rVect);
                    forceVect = -((bodies(i).gm * mass)/(r^3)) * rVect; %km^3/s^2 * mT / km^2 = km*mT/s^2
                end
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end