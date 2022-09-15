classdef SensorSteeringModelEnum < matlab.mixin.SetGet
    %SensorSteeringModelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        FixedVehicleBodyFrame('Fixed in Vehicle Body Frame (Attitude)');
        FixedInCoordSys('Fixed in Coordinate System');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = SensorSteeringModelEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('SensorSteeringModelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SensorSteeringModelEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SensorSteeringModelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end