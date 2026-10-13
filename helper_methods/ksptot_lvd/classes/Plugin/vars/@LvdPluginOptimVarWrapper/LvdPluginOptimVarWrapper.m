classdef LvdPluginOptimVarWrapper < matlab.mixin.SetGet
    %LvdPluginOptimVarWrapper Summary of this class goes here
    %   Detailed explanation goes here

    properties
        name(1,:) char = 'Untitled Plugin Variable';
        value(1,1) double = 0;

        optVar PluginOptimizationVariable
        
        id(1,1) double = 0
    end

    methods
        function obj = LvdPluginOptimVarWrapper()
            obj.id = lvdGetNextUniqueId();
        end

        function optVar = getNewOptVar(obj)
            optVar = PluginOptimizationVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end

        function [lb, ub] = getBounds(obj)
            if(isempty(obj.optVar))
                lb = [];
                ub = [];
                return;
            end
            lb = obj.optVar.lb;
            ub = obj.optVar.ub;
        end

        function setBounds(obj, lb, ub)
            if(isempty(obj.optVar))
                return;
            end
            obj.optVar.lb = lb;
            obj.optVar.ub = ub;
        end

        function useTf = isVariableActive(obj)
            if(isempty(obj.optVar))
                useTf = false;
                return;
            end
            useTf = obj.optVar.useTf;
        end

        function setIfVariableIsActive(obj, useTf)
            if(isempty(obj.optVar))
                return;
            end
            obj.optVar.useTf = useTf;
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.id) || obj.id == 0)
                obj.id = lvdGetNextUniqueId();
            end
        end
    end
end