classdef LvdSweepPluginVarParameter < AbstractLvdSweepParameter
    %LvdSweepPluginVarParameter Sweeps a plugin variable's value.
    %
    %   This is the one kind of parameter the original case matrix supported,
    %   reimplemented on the general interface.  The behaviour is unchanged:
    %   set the wrapper's value and deactivate the backing optimization
    %   variable so the optimizer leaves the swept value alone.

    properties
        pluginVarId(1,1) double = 0;
        pluginVarName(1,:) char = '';
    end

    properties(Transient)
        pluginVar LvdPluginOptimVarWrapper
    end

    methods
        function obj = LvdSweepPluginVarParameter(pluginVar)
            arguments
                pluginVar LvdPluginOptimVarWrapper = LvdPluginOptimVarWrapper.empty(1,0);
            end

            if(not(isempty(pluginVar)))
                obj.pluginVar = pluginVar(1);
                obj.pluginVarId = pluginVar(1).id;
                obj.pluginVarName = pluginVar(1).name;
                obj.isResolved = true;
            end

            obj.id = rand();
        end

        function name = getName(obj)
            if(not(isempty(obj.pluginVar)))
                name = obj.pluginVar.name;
            else
                name = obj.pluginVarName;
            end
        end

        function unit = getUnit(~)
            unit = '';
        end

        function group = getGroupName(~)
            group = 'Plugin Variables';
        end

        function tf = resolve(obj, lvdData)
            arguments
                obj(1,1) LvdSweepPluginVarParameter
                lvdData(1,1) LvdData
            end

            obj.pluginVar = LvdPluginOptimVarWrapper.empty(1,0);
            obj.isResolved = false;

            pluginVars = lvdData.pluginVars.getPluginVarsArray();
            for(i=1:length(pluginVars)) %#ok<*NO4LP>
                if(pluginVars(i).id == obj.pluginVarId)
                    obj.pluginVar = pluginVars(i);
                    obj.isResolved = true;
                    break;
                end
            end

            tf = obj.isResolved;
        end

        function value = getCurrentValue(obj)
            if(isempty(obj.pluginVar))
                value = NaN;
            else
                value = obj.pluginVar.value;
            end
        end

        function applyValue(obj, value)
            if(isempty(obj.pluginVar))
                error('LvdSweepParameter:unresolved', ...
                      'Plugin variable "%s" could not be found in this mission.', obj.pluginVarName);
            end

            obj.pluginVar.value = value;
            obj.pluginVar.setIfVariableIsActive(false);
        end

        function [lb, ub] = getSuggestedBounds(obj)
            if(not(isempty(obj.pluginVar)) && not(isempty(obj.pluginVar.optVar)))
                [lb, ub] = obj.pluginVar.getBounds();

                if(isfinite(lb) && isfinite(ub) && ub > lb)
                    return;
                end
            end

            [lb, ub] = getSuggestedBounds@AbstractLvdSweepParameter(obj);
        end
    end
end
