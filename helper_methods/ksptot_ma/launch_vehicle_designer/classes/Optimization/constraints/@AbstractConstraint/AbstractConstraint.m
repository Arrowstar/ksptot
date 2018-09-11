classdef(Abstract) AbstractConstraint < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [c, ceq, value, lb, ub, type, eventNum] = evalConstraint(stateLog);
    end
end