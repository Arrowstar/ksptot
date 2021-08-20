classdef Gravity3rdBodyForceModel < AbstractForceModel
    %Gravity3rdBodyForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = Gravity3rdBodyForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVectSC, vVectSC, mass, bodySC, ~, ~, ~, ~, ~, ~, ~, ~, grav3Body, ~, ~)      
            cartElemSC = CartesianElementSet(ut, rVectSC, vVectSC, bodySC.getBodyCenteredInertialFrame());
            cartElemSCBody = CartesianElementSet(ut, [0;0;0], [0;0;0], bodySC.getBodyCenteredInertialFrame());
            
            bodies = grav3Body.bodies;

            forceVect = [0;0;0]; 
            for(i=1:length(bodies))
                if(bodies(i) ~= bodySC)
                    bodyInfoJ = bodies(i);
                    
                    cartElemSC_JBody = cartElemSC.convertToFrame(bodyInfoJ.getBodyCenteredInertialFrame());
                    r_sat_to_j = -1 * cartElemSC_JBody.rVect;
                    
                    cartElemSCBody_JBody = cartElemSCBody.convertToFrame(bodyInfoJ.getBodyCenteredInertialFrame());
                    r_1_to_j = -1 * cartElemSCBody_JBody.rVect;
                    
                    if(norm(r_sat_to_j) > 0)
                        term1 = r_sat_to_j/norm(r_sat_to_j)^3;  %km/km^3 = km^-2
                    else
                        term1 = 0;
                    end
                    
                    if(norm(r_1_to_j) > 0)
                        term2 = r_1_to_j/norm(r_1_to_j)^3;      %km/km^3 = km^-2
                    else
                        term2 = 0;
                    end
                    
                    accel = bodyInfoJ.gm * (term1 - term2); %km^3/s^2 * km^-2 = km/s^3
                    forceVect = forceVect + mass * accel; %mT * km/s^3 = km*mT/s^2

%                     rVect = -1 * getAbsPositBetweenSpacecraftAndBody(ut, rVectSC, bodySC, bodies(i), celBodyData);

%                     r = norm(rVect);
%                     forceVect = -((bodies(i).gm * mass)/(r^3)) * rVect; %km^3/s^2 * mT / km^2 = km*mT/s^2
                end
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end