classdef LaunchVehiclePluginVarState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehiclePluginVarState Summary of this class goes here
    %   Detailed explanation goes here

    properties
        pluginVar LvdPluginOptimVarWrapper
        valueAtState(1,1) double = 0;
    end

    methods
        function obj = LaunchVehiclePluginVarState(pluginVar, valueAtState)
            obj.pluginVar = pluginVar;
            obj.valueAtState = valueAtState;
        end
    end
end