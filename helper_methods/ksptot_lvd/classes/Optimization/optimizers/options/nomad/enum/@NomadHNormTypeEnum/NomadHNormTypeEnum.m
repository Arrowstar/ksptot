classdef NomadHNormTypeEnum < matlab.mixin.SetGet
    %NomadHNormTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        L1('L1', 'One-Norm')
        L2('L2', 'Two-Norm')
        LInf('Linf', 'Infinity Norm')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadHNormTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('NomadHNormTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadHNormTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadHNormTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end