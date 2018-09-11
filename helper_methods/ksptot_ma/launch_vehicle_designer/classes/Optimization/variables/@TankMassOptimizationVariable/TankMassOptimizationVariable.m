classdef TankMassOptimizationVariable < AbstractOptimizationVariable
    %EventDurationOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) TankMassTermCondition = TankMassTermCondition(LaunchVehicleTank(LaunchVehicleStage(LaunchVehicle())),0)
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = TankMassOptimizationVariable(varObj)
            obj.varObj = varObj;
        end
        
        function x = getXsForVariable(obj)
            x = obj.varObj.targetMass;
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.targetMass = x;
        end
    end
end