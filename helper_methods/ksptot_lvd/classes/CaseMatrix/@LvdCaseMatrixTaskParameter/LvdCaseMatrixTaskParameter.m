classdef LvdCaseMatrixTaskParameter < matlab.mixin.SetGet
    %LvdCaseMatrixTaskParameters Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pluginVar LvdPluginOptimVarWrapper
        newVal(1,1) double
        
        id(1,1) double
    end
    
    methods
        function obj = LvdCaseMatrixTaskParameter(pluginVar, newVal)
            obj.pluginVar = pluginVar;
            obj.newVal = newVal;
            
            obj.id = rand();
        end
        
        function updatePluginVar(obj)
            obj.pluginVar.value = obj.newVal;
            obj.pluginVar.setIfVariableIsActive(false); %need to turn off any parameters that could be optimized so they stay put at the fixed value
        end
    end
end