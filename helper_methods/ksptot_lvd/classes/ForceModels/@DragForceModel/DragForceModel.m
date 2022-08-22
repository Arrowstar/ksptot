classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = DragForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, attState, ~)
            if(norm(rVect) - (bodyInfo.radius + bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                forceVect = getDragForce(bodyInfo, ut, rVect, vVect, aero, mass, attState);
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end

function dragForce = getDragForce(bodyInfo, ut, rVectECI, vVectECI, aero, mass, attState)
%getDragForce Summary of this function goes here
%   Detailed explanation goes here
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
        vVectEcefMag = norm(vVectECEF);

        %helps to prevent wasting time on the potentially expensive total
        %AoA calculation if it's not needed
        if(aero.dragCoeffModel.usesTotalAoA() || aero.dragCoeffModel.usesAoaAndSideslip())
            [~,angOfAttack,angOfSideslip,totalAoA] = attState.getAeroAngles(ut, rVectECI, vVectECI, bodyInfo);
        else
            angOfAttack = 0;
            angOfSideslip = 0;
            totalAoA = 0;
        end

        CdA = aero.getDragCoeff(ut, rVectECI, vVectECI, bodyInfo, mass, altitude, pressureKPA, density, vVectEcefMag, totalAoA, angOfAttack, angOfSideslip); 
        
        %all forces are returned in units of mT*km/s^2
        Fd = -(1/2) * density * (vVectEcefMag^2) * CdA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(km/m)*km/s^2 = kg*(1000)*km/s^2 => kg*(1000)*km/s^2 * (1 mT/1000 kg) = mT*km/s^2
        
        bff = bodyInfo.getBodyFixedFrame();
        bci = bodyInfo.getBodyCenteredInertialFrame();

        R_ecef_to_global_inertial = bff.getRotMatToInertialAtTime(ut,[],[]);
        R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
        R_ecef_to_bci = R_bci_to_global_inertial' * R_ecef_to_global_inertial;

        dragForceECEF = Fd * normVector(vVectECEF);
        dragForce = R_ecef_to_bci * dragForceECEF;
    else
        dragForce = [0;0;0];
    end
end