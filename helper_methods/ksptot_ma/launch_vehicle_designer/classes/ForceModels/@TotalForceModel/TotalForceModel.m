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
        end
        
        function forceVect = getForce(obj, stateLogEntry)
            forceVect = [0;0;0];
            
            if(stateLogEntry.getTotalVehicleMass() > 0)
                for(i=1:length(obj.forceModels)) %#ok<*NO4LP>
                    forceVect = forceVect + obj.forceModels(i).getForce(stateLogEntry);
                end
            end
            
            if(any(isnan(forceVect)))
                a = 1;
            end
        end
    end
end