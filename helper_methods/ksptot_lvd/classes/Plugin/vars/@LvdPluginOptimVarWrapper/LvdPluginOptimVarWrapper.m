classdef LvdPluginOptimVarWrapper < matlab.mixin.SetGet
    %LvdPluginOptimVarWrapper Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name(1,:) char = 'Untitled Plugin Variable';
        value(1,1) double = 0;

        optVar PluginOptimizationVariable
    end

    methods
        function obj = LvdPluginOptimVarWrapper()

        end

        function optVar = getNewOptVar(obj)
            optVar = PluginOptimizationVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end

        function [lb, ub] = getBounds(obj)
            lb = obj.optVar.lb;
            ub = obj.optVar.ub;
        end

        function setBounds(obj, lb, ub)
            obj.optVar.lb = lb;
            obj.optVar.ub = ub;
        end

        function useTf = isVariableActive(obj)
            useTf = obj.optVar.useTf;
        end

        function setIfVariableIsActive(obj, useTf)
            obj.optVar.useTf = useTf;
        end
    end
end