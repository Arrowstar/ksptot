classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = DragForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~)
            if(norm(rVect) - (bodyInfo.radius + bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                [~, forceVect] = getDragAccel(bodyInfo, ut, rVect, vVect, aero, mass);
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end

function [dragAccel, dragForce] = getDragAccel(bodyInfo, ut, rVectECI, vVectECI, aero, mass)
%getDragAccel Summary of this function goes here
%   Detailed explanation goes here
            arguments
                bodyInfo(1,1) KSPTOT_BodyInfo
                ut(1,1) double 
                rVectECI(3,1) double 
                vVectECI(3,1) double 
                aero(1,1) LaunchVehicleAeroState
                mass(1,1) double
            end

    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    altitude = norm(rVectECI) - bodyInfo.radius;
    
    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
        density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long); 
    elseif(altitude <= 0)
        density = 0;
    else 
        density = 0;
    end
    
    if(density > 0)                
        vVectEcefMag = norm(vVectECEF);

        aoa = 0; %still not implemented anywhere yet
        CdA = aero.getDragCoeff(ut, rVectECI, vVectECI, bodyInfo, mass, altitude, vVectEcefMag, aoa); 
        
        Fd = -(1/2) * density * (vVectEcefMag^2) * CdA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2
        dragAccelMag = Fd/mass; % (1000)*kg*km/s^2/kg/1000 = 1000*km/s^2/1000 = km/s^2
        dragAccel = dragAccelMag * normVector(vVectECI);
        dragForce = Fd * normVector(vVectECI);
    else
        dragAccel = [0;0;0];
        dragForce = [0;0;0];
    end
end