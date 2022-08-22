classdef PropagationDirectionEnum < matlab.mixin.SetGet
    %PropagationDirectionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Forward('Forward Propagation in Time')
        Backward('Backward Propagation in Time');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = PropagationDirectionEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PropagationDirectionEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PropagationDirectionEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PropagationDirectionEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end