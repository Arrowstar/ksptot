classdef LvdFminconAlgorithmEnum < matlab.mixin.SetGet
    %LvdFminconAlgorithmEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        InteriorPoint('Interior Point','interior-point');
        SQP('SQP', 'sqp');
        ActiveSet('Active Set', 'active-set');
    end
    
    properties
        name char
        algoName char
    end
    
    methods
        function obj = LvdFminconAlgorithmEnum(name, algoName)
            obj.name = name;
            obj.algoName = algoName;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('LvdFminconAlgorithmEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(nameStr)
            m = enumeration('LvdFminconAlgorithmEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdFminconAlgorithmEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end