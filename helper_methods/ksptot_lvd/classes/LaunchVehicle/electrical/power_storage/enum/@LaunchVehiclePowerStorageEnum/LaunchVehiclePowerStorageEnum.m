classdef LaunchVehiclePowerStorageEnum < matlab.mixin.SetGet
    %LaunchVehiclePowerStorageEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Basic('Basic Battery');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = LaunchVehiclePowerStorageEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('LaunchVehiclePowerStorageEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('LaunchVehiclePowerStorageEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LaunchVehiclePowerStorageEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end