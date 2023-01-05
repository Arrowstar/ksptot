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
        
        function tf = isInUse(obj, lvdData)
            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            
            tf = false;
            for(i=1:length(tanks))
                if(tanks(i).tankType == obj)
                    tf = true;
                    break;
                end
            end
        end
    end
end