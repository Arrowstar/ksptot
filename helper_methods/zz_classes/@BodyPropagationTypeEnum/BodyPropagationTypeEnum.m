classdef BodyPropagationTypeEnum < matlab.mixin.SetGet
    %BodyPropagationTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        TwoBody('Analytic Two Body')
        Numerical('Numerical Integration');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = BodyPropagationTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('BodyPropagationTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('BodyPropagationTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('BodyPropagationTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end