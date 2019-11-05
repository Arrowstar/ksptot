classdef FminconHessApproxAlgEnum < matlab.mixin.SetGet
    %FminconFiniteDiffTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        BFGS('bfgs', 'BFGS');
        FiniteDifferences('finite-difference', 'Finite Differences');
        LBFGS('lbfgs', 'LBFGS');
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = FminconHessApproxAlgEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('FminconHessApproxAlgEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('FminconHessApproxAlgEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end