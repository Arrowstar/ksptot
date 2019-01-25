classdef LiftForceModel < AbstractForceModel
    %LiftForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = LiftForceModel()
            
        end
        
        function [liftForce, tankMdots] = getForce(obj, ut, rVectECI, vVectECI, ~, bodyInfo, aero, ~, steeringModel, ~, ~, ~, ~, ~, ~)  
            tankMdots = [];
            if(aero.useLift == false)
                liftForce = [0;0;0];
                return;
            end
            
            rVectECI = reshape(rVectECI,3,1);
            vVectECI = reshape(vVectECI,3,1);

            altitude = norm(rVectECI) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, ~, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat); 
            elseif(altitude <= 0)
                density = 0;
            else 
                density = 0;
            end
            
            if(density > 0)               
                Cl_level = aero.Cl_0;
                A = aero.areaLift;        
                bodyLiftVect = normVector(aero.bodyLiftVect);
                
                vVectEcefMag = norm(vVectECEF);
                
                body2InertDcm = steeringModel.getBody2InertialDcmAtTime(ut, rVectECI, vVectECI, bodyInfo);
                [~,angOfAttack,~] = computeAeroAnglesFromBodyAxes(ut, rVectECI, vVectECI, bodyInfo, body2InertDcm(:,1), body2InertDcm(:,2), body2InertDcm(:,3));
                
                Cl = Cl_level + 2*pi*angOfAttack;
                
                ClA = Cl * A;
                
                L = (1/2) * density * (vVectEcefMag^2) * ClA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2
                
                bodyLiftForce = L * bodyLiftVect;
                
                liftForce = body2InertDcm * bodyLiftForce;
            else
                liftForce = [0;0;0];
            end
        end
    end
end