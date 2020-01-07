classdef FiniteDiffTypeEnum < matlab.mixin.SetGet
    %FiniteDiffTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Central('Central Difference');
        Forward('Forward Difference');
        Backward('Backwards Difference');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = FiniteDiffTypeEnum(name)
            obj.name = name;
        end
    end
end

