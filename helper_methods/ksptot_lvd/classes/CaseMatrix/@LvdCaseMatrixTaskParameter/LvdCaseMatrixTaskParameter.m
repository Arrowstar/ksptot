classdef LvdCaseMatrixTaskParameter < LvdSweepPluginVarParameter
    %LvdCaseMatrixTaskParameter DEPRECATED.  A plugin variable sweep
    %parameter carrying the value for one case.
    %
    %   Superseded by LvdSweepPluginVarParameter, which is one of several
    %   AbstractLvdSweepParameter kinds, and by LvdCaseMatrixTask's own
    %   params/paramValues pair.  Kept as a subclass so case files and
    %   missions saved by an older build still load: an old object
    %   deserializes into something that is still a usable sweep parameter.
    %
    %   Do not use in new code.

    properties
        newVal(1,1) double = 0;
    end

    methods
        function obj = LvdCaseMatrixTaskParameter(pluginVar, newVal)
            arguments
                pluginVar LvdPluginOptimVarWrapper = LvdPluginOptimVarWrapper.empty(1,0);
                newVal(1,1) double = 0;
            end

            obj@LvdSweepPluginVarParameter(pluginVar);

            obj.newVal = newVal;
        end

        function updatePluginVar(obj)
            %updatePluginVar DEPRECATED.  Use applyValue.
            obj.applyValue(obj.newVal);
        end
    end
end
