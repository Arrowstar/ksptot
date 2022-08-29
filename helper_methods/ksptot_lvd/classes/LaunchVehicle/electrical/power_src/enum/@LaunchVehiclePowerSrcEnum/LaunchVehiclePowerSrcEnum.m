classdef LaunchVehiclePowerSrcEnum < matlab.mixin.SetGet
    %LaunchVehiclePowerSrcEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        RTG('Radioisotope Thermoelectric Generator (RTG)');
        FixedSolarPanel('Fixed Solar Panel');
        RotatingSolarPanel('Rotating Solar Panel');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = LaunchVehiclePowerSrcEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('LaunchVehiclePowerSrcEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('LaunchVehiclePowerSrcEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LaunchVehiclePowerSrcEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end