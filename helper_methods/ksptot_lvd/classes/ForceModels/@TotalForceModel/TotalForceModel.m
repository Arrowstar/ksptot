classdef TotalForceModel < matlab.mixin.SetGet
    %TotalForceModel Generates the total force on the vehicle using sub
    %models
    %   Detailed explanation goes here
    
    properties(Transient)

    end
    
    methods
        function obj = TotalForceModel()

        end
    end
    
   methods (Static)
        function [forceVect, tankMdots, ecStgDots] = getForce(fmEnums, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, srp, altitude, pressure, density, engineToTankCache)
            arguments
                fmEnums ForceModelsEnum
                ut
                rVect
                vVect
                mass
                bodyInfo
                aero
                throttleModel
                steeringModel
                tankStates
                stageStates
                lvState
                dryMass
                tankStatesMasses
                thirdBodyGravity
                storageSoCs
                powerStorageStates
                srp
                altitude
                pressure
                density
                engineToTankCache struct = struct('engines',[])
            end

            forceVect = [0;0;0];
            tankMdots = zeros(length(tankStates),1);
            ecStgDots = zeros(length(powerStorageStates),1);
            
            persistent attState;
            if(isempty(attState))
                attState = LaunchVehicleAttitudeState();
            end

            if(mass > 0)
                if(any([fmEnums.usesAttitudeState]))
                    attState.dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);
                    attStateToUse = attState;
                else
                    attStateToUse = [];
                end

                for(i=1:length(fmEnums)) %#ok<*NO4LP>
                    %all thrusts should be in units of mT*km/s^2
                    if(isa(fmEnums(i).model, 'ThrustForceModel'))
                        [fv, mdots, ecDots] = fmEnums(i).model.getForce(ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attStateToUse, srp, altitude, pressure, density, engineToTankCache);
                    else
                        [fv, mdots, ecDots] = fmEnums(i).model.getForce(ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates, attStateToUse, srp, altitude, pressure, density);
                    end
                    forceVect = forceVect + fv;
                    
                    if(not(isempty(mdots)))
                        tankMdots = tankMdots + mdots(:);
                    end
                    
                    if(not(isempty(ecDots)))
                        ecStgDots = ecStgDots + ecDots(:); 
                    end
                end
            end
        end
   end
end