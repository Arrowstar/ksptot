classdef TankFluidType < matlab.mixin.SetGet
    %TankFluidType Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = TankFluidType(name)
            obj.name = name;
        end
    end
end