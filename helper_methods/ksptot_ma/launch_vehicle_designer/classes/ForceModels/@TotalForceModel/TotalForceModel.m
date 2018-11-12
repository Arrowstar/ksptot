classdef TotalForceModel < AbstractForceModel
    %TotalForceModel Generates the total force on the vehicle using sub
    %models
    %   Detailed explanation goes here
    
    properties
        forceModels(1,:) AbstractForceModel
    end
    
    methods
        function obj = TotalForceModel()
            obj.forceModels(end+1) = GravityForceModel();
            obj.forceModels(end+1) = DragForceModel();
            obj.forceModels(end+1) = ThrustForceModel();
            obj.forceModels(end+1) = NormalForceModel();
        end
        
        function forceVect = getForce(obj, ut, rVect, vVect, mass, bodyInfo, CdA, throttleModel, steeringModel, tankStates, stageStates, lvState)
            forceVect = [0;0;0];
            
            if(mass > 0)
                forceModelsVar = obj.forceModels;
                for(i=1:length(obj.forceModels)) %#ok<*NO4LP>
                    forceVect = forceVect + forceModelsVar(i).getForce(ut, rVect, vVect, mass, bodyInfo, CdA, throttleModel, steeringModel, tankStates, stageStates, lvState);
                end
            end
        end
    end
end