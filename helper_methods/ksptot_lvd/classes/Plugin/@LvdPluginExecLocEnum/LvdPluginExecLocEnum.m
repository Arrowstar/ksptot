classdef LvdPluginExecLocEnum < matlab.mixin.SetGet
    %LvdPluginExecLocEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        BeforeProp('Before Propagation')
        BeforeEvent('Before Events')
        AfterTimestep('After Time Step')
        AfterEvent('After Events')
        AfterProp('After Propagation')
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = LvdPluginExecLocEnum(name)
            obj.name = name;
        end
    end
end