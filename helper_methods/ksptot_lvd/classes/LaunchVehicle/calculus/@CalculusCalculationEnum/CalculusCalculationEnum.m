classdef CalculusCalculationEnum < matlab.mixin.SetGet
    %CalculusCalculationEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Derivative('Derivative');
        Integral('Integral');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = CalculusCalculationEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('CalculusCalculationEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('CalculusCalculationEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('CalculusCalculationEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

