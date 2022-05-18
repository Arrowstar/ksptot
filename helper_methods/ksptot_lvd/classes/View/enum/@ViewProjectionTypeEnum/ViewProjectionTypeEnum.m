classdef ViewProjectionTypeEnum < matlab.mixin.SetGet
    %ViewPerspectiveTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Orthographic('Orthographic')
        Perspective('Perspective')
    end
    
    properties
        name(1,:) char = '';
    end
    
    methods
        function obj = ViewProjectionTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('ViewProjectionTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ViewProjectionTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ViewProjectionTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end