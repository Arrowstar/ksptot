classdef ViewTypeEnum < matlab.mixin.SetGet
    %ViewTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Inertial3D('3D Inertial')
        BodyFixed3D('3D Body Fixed')
        Mercator('2D Mercator Projection')
    end
    
    properties
        name(1,:) char = '';
    end
    
    methods
        function obj = ViewTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ViewTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ViewTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ViewTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end