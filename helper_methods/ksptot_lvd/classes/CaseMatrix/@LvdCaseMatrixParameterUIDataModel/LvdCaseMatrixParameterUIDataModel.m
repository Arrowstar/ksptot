classdef LvdCaseMatrixParameterUIDataModel < matlab.mixin.SetGet
    %LvdCaseMatrixParameterUIDataModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pluginVar LvdPluginOptimVarWrapper
        useTf(1,1) logical = false;
        lowerBnd(1,1) double
        upperBnd(1,1) double
        step(1,1) double
    end
    
    methods
        function obj = LvdCaseMatrixParameterUIDataModel(pluginVar, useTf, lowerBnd, upperBnd, step)
            obj.pluginVar = pluginVar;
            obj.useTf = useTf;
            obj.lowerBnd = lowerBnd;
            obj.upperBnd = upperBnd;
            obj.step = step;
        end
    end
end