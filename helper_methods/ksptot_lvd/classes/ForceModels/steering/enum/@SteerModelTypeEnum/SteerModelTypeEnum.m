classdef SteerModelTypeEnum < matlab.mixin.SetGet
    %SteerModelTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PolyAngles('Polynomial Euler Angles');
        QuaterionInterp('Attitude Interpolation');
        LinearTangentAngles('Linear Tangent Euler Angles')
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = SteerModelTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('SteerModelTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SteerModelTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SteerModelTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

