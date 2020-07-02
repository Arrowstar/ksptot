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
        function [forceVect, tankMdots] = getForce(fmEnums, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity)
            forceVect = [0;0;0];
            tankMdots = zeros(length(tankStates),1);
            
            if(mass > 0)
%                 forceModelsVar = obj.forceModels;
                for(i=1:length(fmEnums)) %#ok<*NO4LP>
                    [fv, mdots] = fmEnums(i).model.getForce(ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity);
                    forceVect = forceVect + fv;
                    
                    if(not(isempty(mdots)))
                        tankMdots = tankMdots + mdots;
                    end
                end
            end
        end
   end
end