classdef SensorTargetEnum < matlab.mixin.SetGet
    %SensorTargetEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PointTarget('Point Target');
        LatLongRectGrid('Lat/Long Rectangular Grid')
        LatLongCircGrid('Lat/Long Circular Grid');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = SensorTargetEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('SensorTargetEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SensorTargetEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SensorTargetEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end