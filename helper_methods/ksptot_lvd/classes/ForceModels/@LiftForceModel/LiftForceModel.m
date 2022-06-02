classdef LiftForceModel < AbstractForceModel
    %LiftForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = LiftForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, attState)  
            if(norm(rVect) - (bodyInfo.radius + bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                forceVect = getLiftForce(bodyInfo, ut, rVect, vVect, aero, mass, attState);
            end

            tankMdots = [];
            ecStgDots = [];
        end
    end
end

function forceVect = getLiftForce(bodyInfo, ut, rVectECI, vVectECI, aero, mass, attState)
    arguments
        bodyInfo(1,1) KSPTOT_BodyInfo
        ut(1,1) double 
        rVectECI(3,1) double 
        vVectECI(3,1) double 
        aero(1,1) LaunchVehicleAeroState
        mass(1,1) double
        attState(1,1) LaunchVehicleAttitudeState
    end

    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    altitude = norm(rVectECI) - bodyInfo.radius;

    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
        [density, pressureKPA, ~] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long); 
    elseif(altitude <= 0)
        density = 0;
    else 
        density = 0;
    end
    
    if(density > 0)         
        [ClS, liftUnitVectInertial] = aero.getLiftCoeffAndDir(ut, rVectECI, vVectECI, bodyInfo, mass, altitude, pressureKPA, density, vVectECEF, attState);

        vVectECEFMag = norm(vVectECEF);

        %all forces are returned in units of mT*km/s^2 = (1000000)*N
        FL = (1/2)*density*(vVectECEFMag^2)*ClS; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2

        forceVect = FL * liftUnitVectInertial;

%         Cl_level = aero.Cl_0;
%         A = aero.areaLift;        
%         bodyLiftVect = normVector(aero.bodyLiftVect);
%         
%         vVectEcefMag = norm(vVectECEF);
%         
%         body2InertDcm = steeringModel.getBody2InertialDcmAtTime(ut, rVectECI, vVectECI, bodyInfo);
%         [~,angOfAttack,~] = computeAeroAnglesFromBodyAxes(ut, rVectECI, vVectECI, bodyInfo, body2InertDcm(:,1), body2InertDcm(:,2), body2InertDcm(:,3));
%         
%         Cl = Cl_level + 2*pi*angOfAttack;
%         
%         ClA = Cl * A;
%         
%         L = (1/2) * density * (vVectEcefMag^2) * ClA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2
%         
%         bodyLiftForce = L * bodyLiftVect;
%         
%         liftForce = body2InertDcm * bodyLiftForce;
    else
        forceVect = [0;0;0];
    end
end