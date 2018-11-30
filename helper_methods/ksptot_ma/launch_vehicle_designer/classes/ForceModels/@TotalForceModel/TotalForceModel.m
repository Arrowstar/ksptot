classdef TotalForceModel < AbstractForceModel
    %TotalForceModel Generates the total force on the vehicle using sub
    %models
    %   Detailed explanation goes here
    
    properties(Transient)
        forceModels(1,:) AbstractForceModel
    end
    
    methods
        function obj = TotalForceModel()
            obj.forceModels = TotalForceModel.getForceModels();
        end
        
        function forceVect = getForce(obj, ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState)
            forceVect = [0;0;0];
            
            if(mass > 0)
                forceModelsVar = obj.forceModels;
                for(i=1:length(obj.forceModels)) %#ok<*NO4LP>
                    forceVect = forceVect + forceModelsVar(i).getForce(ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState);
                end
            end
        end
    end
    
   methods (Static)
      function s = loadobj(s)
         s.forceModels = TotalForceModel.getForceModels();
      end
      
      function forceModels = getForceModels()
        forceModels = AbstractForceModel.empty(0,1);
          
        forceModels(end+1) = GravityForceModel();
        forceModels(end+1) = DragForceModel();
        forceModels(end+1) = ThrustForceModel();
%         forceModels(end+1) = NormalForceModel();
        forceModels(end+1) = LiftForceModel();
      end
   end
end