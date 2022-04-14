classdef GeometricVectorXConstraint < AbstractGeometricVectorConstraint
    %GeometricVectorMagConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = GeometricVectorXConstraint(vector, event, lb, ub)
            obj.vector = vector;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   

            obj.type = 'VectorX';
            
            obj.id = rand();
        end

        function type = getConstraintType(obj)
            type = 'Geometric Vector X Component';
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = GeometricVectorXConstraint(AbstractGeometricVector.empty(1,0), LaunchVehicleEvent.empty(1,0), 0, 0);
        end
    end
end