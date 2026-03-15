classdef DragForceModel < AbstractForceModel
    %DragForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = DragForceModel()

        end
        
        function [forceVect,tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, attState, ~, altitude, pressure, density)
            if(nargin < 20)
                altitude = norm(rVect) - bodyInfo.radius;
            end

            if(altitude - (bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                if(nargin < 21 || nargin < 22)
                    forceVect = getDragForce(bodyInfo, ut, rVect, vVect, aero, mass, attState);
                else
                    forceVect = getDragForce(bodyInfo, ut, rVect, vVect, aero, mass, attState, altitude, pressure, density);
                end
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end

function dragForce = getDragForce(bodyInfo, ut, rVectECI, vVectECI, aero, mass, attState, altitude, pressureKPA, density)
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
        altitude double = NaN
        pressureKPA double = NaN
        density double = NaN
    end

    persistent cache;
    if(isempty(cache))
        cache.ut = NaN;
        cache.rVectECI = [NaN;NaN;NaN];
        cache.vVectECI = [NaN;NaN;NaN];
        cache.aero = LaunchVehicleAeroState.empty(0,1);
        cache.dragForce = [0;0;0];
    end

    if(ut == cache.ut && all(rVectECI == cache.rVectECI) && all(vVectECI == cache.vVectECI) && (isempty(aero) || aero == cache.aero))
        dragForce = cache.dragForce;
        return;
    end

    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    if(isnan(altitude))
        altitude = norm(rVectECI) - bodyInfo.radius;
    end
    
    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        [lat, long, ~, ~, ~, ~, ~, vVectECEF, R_Eci_2_Ecef] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
        
        if(isnan(density) || isnan(pressureKPA))
            [density, pressureKPA, ~] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long); 
        end
    elseif(altitude <= 0)
        density = 0;
        pressureKPA = 0; %Added this
    else 
        density = 0;
        pressureKPA = 0; %Added this
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
        Fd = -(1/2) * density * (vVectEcefMag^2) * CdA; %kg/m^3 * (km^2/s^2) * m^2 = kg/m * km^2/s^2 = kg*(1000)*km/s^2 = kg*(1000)*km/s^2 * (1 mT/1000 kg) = mT*km/s^2

        bci = bodyInfo.getBodyCenteredInertialFrame();
        R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);

        R_ecef_to_bci = R_bci_to_global_inertial' * R_Eci_2_Ecef';

        dragForceECEF = Fd * (vVectECEF / vVectEcefMag);
        dragForce = R_ecef_to_bci * dragForceECEF;
    else
        dragForce = [0;0;0];
    end

    cache.ut = ut;
    cache.rVectECI = rVectECI;
    cache.vVectECI = vVectECI;
    cache.aero = aero;
    cache.dragForce = dragForce;
    end