classdef ObjFcnDirectionTypeEnum < matlab.mixin.SetGet
    %ObjFcnDirectionTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Minimize('Minimize')
        Maximize('Maximize')
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = ObjFcnDirectionTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ObjFcnDirectionTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ObjFcnDirectionTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ObjFcnDirectionTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end