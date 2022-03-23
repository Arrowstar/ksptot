classdef LvdPluginOptimVarSet < matlab.mixin.SetGet
    %LvdPluginOptimVarSet Summary of this class goes here
    %   Detailed explanation goes here

    properties
        pluginVars(1,:) LvdPluginOptimVarWrapper

        lvdData LvdData
    end

    methods
        function obj = LvdPluginOptimVarSet(lvdData)
            obj.lvdData = lvdData;
        end

        function addPluginVar(obj, newPluginVar)
            obj.pluginVars(end+1) = newPluginVar;
        end
        
        function removePluginVar(obj, pluginVar)
            obj.pluginVars([obj.pluginVars] == pluginVar) = [];
        end
        
        function [listBoxStr, pluginVars] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.pluginVars)) %#ok<*NO4LP> 
                if(obj.pluginVars(i).isVariableActive())
                    varStr = '* ';
                else
                    varStr = '';
                end

                listBoxStr{end+1} = sprintf('%u - %s%s', i, varStr, obj.pluginVars(i).name); %#ok<AGROW>
            end
            
            pluginVars = obj.pluginVars;
        end
        
        function pluginVars = getPluginVarsArray(obj)
            pluginVars = obj.pluginVars;
        end
        
        function inds = getIndsForPluginVars(obj, pluginVars)
            inds = find(ismember(obj.pluginVars, pluginVars));
        end
        
        function plugin = getPluginVarAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.pluginVars))
                plugin = obj.pluginVars(ind);
            else
                plugin = LvdPluginOptimVarWrapper.empty(1,0);
            end
        end
        
        function numPluginVars = getNumPluginVars(obj)
            numPluginVars = length(obj.pluginVar);
        end

        function varValues = getPluginVarValues(obj)
            varValues = [obj.pluginVars.value];
            varValues = varValues(:);
        end

        function tf = isVarAPluginVar(obj, var)
            if(not(isempty(obj)))
                vars = [obj.pluginVars.optVar];
                tf = any(var == vars);
            else
                tf = true;
            end
        end
    end
end