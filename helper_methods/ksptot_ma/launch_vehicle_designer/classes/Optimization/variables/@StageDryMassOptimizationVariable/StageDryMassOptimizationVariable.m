classdef StageDryMassOptimizationVariable < AbstractOptimizationVariable
    %AbstractOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,:) LaunchVehicleStage
        
        lwrBnd(1,1) double = 0;
        uprBnd(1,1) double = 0;
        
        useTf(1,1) = true;
    end
    
    methods
        function obj = StageDryMassOptimizationVariable(stage)
            obj.stage = stage;
            obj.stage.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = obj.stage.dryMass;
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lwrBnd;
            ub = obj.uprBnd;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lwrBnd = lb;
            obj.uprBnd = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = true;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)
            if(any(isnan(x)))
                a = 1;
            end
            
            obj.stage.dryMass = x;
        end
    end
end