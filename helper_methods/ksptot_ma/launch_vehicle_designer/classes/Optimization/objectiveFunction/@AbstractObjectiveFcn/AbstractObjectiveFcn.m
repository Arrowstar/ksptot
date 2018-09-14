classdef(Abstract) AbstractObjectiveFcn < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [f, stateLog] = evalObjFcn(obj, x, maData);
    end
end