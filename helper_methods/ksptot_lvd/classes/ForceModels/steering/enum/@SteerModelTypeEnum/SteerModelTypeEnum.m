classdef SteerModelTypeEnum < matlab.mixin.SetGet
    %SteerModelTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PolyAngles('Polynomial Euler Angles', "Includes predefined steering models for common use cases, including surface relative roll/pitch/yaw, inertial velocity relative angle of attack, sideslip angle, and bank angle, and the ability to select angle type generically.  Use this if you're not sure what to select.");
        QuaterionInterp('Attitude Interpolation', "Use this when you know your initial attitude and final targeted attitude and want to smoothly transition from one to the other.");
        SelectableModelAngles('Selectable Model Euler Angles', "Allows you to set different types of mathematical models for each Euler angle and to define those Euler angles in a very generic way.  The more general but most challenging steering model to use.");
    end
    
    enumeration(Hidden)
        LinearTangentAngles('Linear Tangent Euler Angles', '');
        SumOfSinesAngles('Sum of Sines Euler Angles', '');
    end
    
    properties
        name(1,:) char
        desc(1,1) string
    end
    
    methods
        function obj = SteerModelTypeEnum(name, desc)
            obj.name = name;
            obj.desc = desc;
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

