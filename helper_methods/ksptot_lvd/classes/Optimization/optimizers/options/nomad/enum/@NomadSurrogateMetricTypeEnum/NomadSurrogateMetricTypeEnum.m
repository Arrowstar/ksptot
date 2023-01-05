classdef NomadSurrogateMetricTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateMetricTypeEnum Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html
    
    enumeration
        EMAX('EMAX', 'Error Max')
        EMAXCV('EMAXCV', 'Error Max with Cross-Validation')
        RMSE('RMSE', 'Root Mean Square Error')
        RMSECV('RMSECV', 'RMSE with Cross-Validation')
        OE('OE', 'Order Error')
        OECV('OECV', 'Order Error with Cross-Validation')
        LINV('LINV', 'Invert of the Likelihood')
        AOE('AOE', 'Aggregate Order Error')
        AOECV('AOECV', 'Aggregate Order Error with Cross-Validation')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadSurrogateMetricTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateMetricTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateMetricTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateMetricTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end