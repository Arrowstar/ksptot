classdef InheritStateEnum < matlab.mixin.SetGet
    %InheritStateEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        InheritFromLastState('Inherit From Last State')
        InheritFromSpecifiedEvent('Inherit From Specified Event')
    end
    
    properties
        name
    end
    
    methods
        function obj = InheritStateEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('InheritStateEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('InheritStateEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('InheritStateEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

