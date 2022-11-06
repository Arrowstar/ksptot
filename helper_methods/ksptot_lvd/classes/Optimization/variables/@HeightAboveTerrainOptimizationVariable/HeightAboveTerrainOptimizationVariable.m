classdef HeightAboveTerrainOptimizationVariable < AbstractOptimizationVariable
    %HeightAboveTerrainOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varObj(1,1) HeightAboveTerrainCondition = HeightAboveTerrainCondition(0);
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
        
        useTf(1,1) = false;
    end
    
    methods
        function obj = HeightAboveTerrainOptimizationVariable(varObj)
            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end
        
        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.heightAboveTerrain;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
        end
        
        function [lb, ub] = getAllBndsForVariable(obj)
            lb = obj.lwrBnd;
            ub = obj.uprBnd;
        end
        
        function setBndsForVariable(obj, lb, ub)
            obj.lb = lb;
            obj.ub = ub;
        end
        
        function useTf = getUseTfForVariable(obj)
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
        
        function updateObjWithVarValue(obj, x)
            obj.varObj.heightAboveTerrain = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            nameStrs = {sprintf('Event %i Height Above Terrain Termination Condition', evtNum)};
        end
    end
end