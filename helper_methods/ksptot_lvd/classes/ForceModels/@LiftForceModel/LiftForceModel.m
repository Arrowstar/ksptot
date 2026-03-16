classdef LiftForceModel < AbstractForceModel
    %LiftForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = LiftForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attState, srp, atmoState, engineToTankCache)  
            if(atmoState.altitude - (bodyInfo.atmohgt) > 0)
                forceVect = [0;0;0];
            else
                forceVect = getLiftForce(bodyInfo, ut, rVect, vVect, aero, mass, attState, atmoState);
            end

            tankMdots = [];
            ecStgDots = [];
        end
    end
end

function forceVect = getLiftForce(bodyInfo, ut, rVectECI, vVectECI, aero, mass, attState, atmoState)
    arguments
        bodyInfo(1,1) KSPTOT_BodyInfo
        ut(1,1) double 
        rVectECI(3,1) double 
        vVectECI(3,1) double 
        aero(1,1) LaunchVehicleAeroState
        mass(1,1) double
        attState(1,1) LaunchVehicleAttitudeState
        atmoState struct
    end

    rVectECI = reshape(rVectECI,3,1);
    vVectECI = reshape(vVectECI,3,1);

    altitude = atmoState.altitude;
    density = atmoState.density;
    pressureKPA = atmoState.pressure;
    vVectECEF = atmoState.vVectECEF;
    
    if(density > 0)         
        [ClS, liftUnitVectInertial] = aero.getLiftCoeffAndDir(ut, rVectECI, vVectECI, bodyInfo, mass, altitude, pressureKPA, density, vVectECEF, attState);

        vVectECEFMag = norm(vVectECEF);

        %all forces are returned in units of mT*km/s^2 = (1000000)*N
        FL = (1/2)*density*(vVectECEFMag^2)*ClS;

        forceVect = FL * liftUnitVectInertial;
    else
        forceVect = [0;0;0];
    end
end