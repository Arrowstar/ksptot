classdef AddMassToTankActionOptimVar < AbstractOptimizationVariable
    %AddMassToTankActionOptimVar Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) AddMassToTankAction = AddMassToTankAction();
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = false;
    end
    
    methods
        function obj = AddMassToTankActionOptimVar(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.massToAdd;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(logical(obj.useTf));
            ub = obj.ub(logical(obj.useTf));
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = logical(obj.useTf);
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = logical(useTf);
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.massToAdd = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum)
            nameStrs = {sprintf('Event %i Add Mass To Tank Action', evtNum)};
        end
    end
end