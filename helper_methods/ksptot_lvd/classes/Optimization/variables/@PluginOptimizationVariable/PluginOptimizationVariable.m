classdef PluginOptimizationVariable < AbstractOptimizationVariable
    %LvdPluginOptimizationVariable Summary of this class goes here
    %   Detailed explanation goes here

    properties
        varObj(1,1) LvdPluginOptimVarWrapper = LvdPluginOptimVarWrapper();

        lb(1,1) double = -1;
        ub(1,1) double = 1;
        
        useTf(1,1) = false;
    end

    methods
        function obj = PluginOptimizationVariable(varObj)
            arguments
                varObj(1,1) LvdPluginOptimVarWrapper
            end

            obj.varObj = varObj;
            obj.varObj.optVar = obj;
            
            obj.id = rand();
        end

        function x = getXsForVariable(obj)
            x = [];
            
            if(obj.useTf)
                x = obj.varObj.value;
            end
        end
        
        function [lb, ub] = getBndsForVariable(obj)
            lb = obj.lb(obj.useTf);
            ub = obj.ub(obj.useTf);
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
            useTf = obj.useTf;
        end
        
        function setUseTfForVariable(obj, useTf)
            obj.useTf = useTf;
        end
                
        function updateObjWithVarValue(obj, x)
            obj.varObj.value = x;
        end
        
        function nameStrs = getStrNamesOfVars(obj, evtNum, varLocType)
            nameStrs = {sprintf('Plugin Variable "%s"', obj.varObj.name)};
        end
    end
end