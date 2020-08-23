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
        function [forceVect, tankMdots, ecStgDots] = getForce(fmEnums, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates)
            forceVect = [0;0;0];
            tankMdots = zeros(length(tankStates),1);
            ecStgDots = zeros(length(powerStorageStates),1);
            
            if(mass > 0)
%                 forceModelsVar = obj.forceModels;
                for(i=1:length(fmEnums)) %#ok<*NO4LP>
                    [fv, mdots, ecDots] = fmEnums(i).model.getForce(ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, powerStorageStates);
                    forceVect = forceVect + fv;
                    
                    if(not(isempty(mdots)))
                        tankMdots = tankMdots + mdots;
                    end
                    
                    if(not(isempty(ecDots)))
                        ecStgDots = ecStgDots + ecDots; 
                    end
                end
            end
        end
   end
end