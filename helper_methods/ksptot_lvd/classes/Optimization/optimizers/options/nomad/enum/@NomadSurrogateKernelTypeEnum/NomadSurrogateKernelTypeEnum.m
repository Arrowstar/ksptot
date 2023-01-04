classdef NomadSurrogateKernelTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateKernelTypeEnum Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html
    
    enumeration
        D1('D1', 'Gaussian kernel')
        D2('D2', 'Inverse Quadratic Kernel')
        D3('D3', 'Inverse Multiquadratic Kernel')
        D4('D4', 'Bi-quadratic Kernel')
        D5('D5', 'Tri-cubic Kernel')
        D6('D6', 'Exponential Sqrt Kernel')
        D7('D7', 'Epanechnikov Kernel')
        I0('I0', 'Multiquadratic Kernel')
        I1('I1', 'Polyharmonic splines, degree 1')
        I2('I2', 'Polyharmonic splines, degree 2')
        I3('I3', 'Polyharmonic splines, degree 3')
        I4('I4', 'Polyharmonic splines, degree 4')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadSurrogateKernelTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateKernelTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateKernelTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateKernelTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end