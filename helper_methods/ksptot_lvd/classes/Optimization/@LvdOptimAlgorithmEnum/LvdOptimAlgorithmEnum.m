classdef LvdOptimAlgorithmEnum < matlab.mixin.SetGet
    %LvdOptimAlgorithmEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        InteriorPoint('interior-point');
        SQP('sqp');
        ActiveSet('active-set');
    end
    
    properties
        algoName char
    end
    
    methods
        function obj = LvdOptimAlgorithmEnum(algoName)
            obj.algoName = algoName;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('LvdOptimAlgorithmEnum');
            [~,I] = sort({m.algoName});
            listBoxStr = {m(I).algoName};
        end
        
        function [ind, enum] = getIndForName(nameStr)
            m = enumeration('LvdOptimAlgorithmEnum');
            [~,I] = sort({m.algoName});
            m = m(I);
            ind = find(ismember({m.algoName},nameStr),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdOptimAlgorithmEnum');
            ind = find(ismember({m.algoName},nameStr),1,'first');
            enum = m(ind);
        end
    end
end