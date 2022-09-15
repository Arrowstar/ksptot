classdef FminconBarrierParamUpdateEnum < matlab.mixin.SetGet
    %FminconBarrierParamUpdateEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PredictorCorrector('predictor-corrector', 'Predictor-Corrector')
        Monotone('monotone', 'Monotone');
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = FminconBarrierParamUpdateEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('FminconBarrierParamUpdateEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('FminconBarrierParamUpdateEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('FminconBarrierParamUpdateEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end