classdef GeometricVectorZConstraint < AbstractGeometricVectorConstraint
    %GeometricVectorMagConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = GeometricVectorZConstraint(vector, event, lb, ub)
            obj.vector = vector;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   

            obj.type = 'VectorZ';
            
            obj.id = rand();
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = GeometricVectorZConstraint(AbstractGeometricVector.empty(1,0), LaunchVehicleEvent.empty(1,0), 0, 0);
        end
    end
end