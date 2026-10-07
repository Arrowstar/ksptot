classdef EventAbsDurationConstraint < EventDurationConstraint
    %EventAbsDurationConstraint Constrains the magnitude of an event's
    %propagated duration, |EventDurationConstraint value|.
    
    methods
        function obj = EventAbsDurationConstraint(event, lb, ub)
            obj@EventDurationConstraint(event, lb, ub);
        end
        
        function type = getConstraintType(obj)
            type = 'Event Duration (Absolute Value)';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            [unit, ~, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails@EventDurationConstraint(obj);
            lbLim = 0;
        end
    end
    
    methods(Access=protected)
        function dt = computeDuration(obj, stateLog, event)
            dt = abs(computeDuration@EventDurationConstraint(obj, stateLog, event));
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = EventAbsDurationConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end
