classdef NoOptimizationObjectiveFcn < AbstractObjectiveFcn
    %NoOptimizationObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = NoOptimizationObjectiveFcn()
            
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, ~)
            obj.lvdOptim.vars.updateObjsWithVarValues(x);
            stateLog = obj.lvdData.script.executeScript();
            
            f = 1;
        end
    end
end