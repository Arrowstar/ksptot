classdef GeometricAngleEnum < matlab.mixin.SetGet
    %GeometricAngleEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        AngleBetweenVectors('Angle Between Vectors');
        AngleBetweenVectorPlane('Angle Between Vector and Plane');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = GeometricAngleEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('GeometricAngleEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('GeometricAngleEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('GeometricAngleEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end