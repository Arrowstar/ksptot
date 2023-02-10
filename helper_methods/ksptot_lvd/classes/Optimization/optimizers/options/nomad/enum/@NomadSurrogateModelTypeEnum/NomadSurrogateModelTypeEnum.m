classdef NomadSurrogateModelTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateModelTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PRS('PRS', 'Polynomial Response Surface', "A polynomial response surface model.")
        PRS_EDGE('PRS_EDGE', 'Polynomial Response Surface EDGE', "PRS_EDGE (Polynomial Response Surface EDGE) is a type of model that allows to model discontinuities at 0 by using additional basis functions.")
        PRS_CAT('PRS_CAT', 'Categorical Polynomial Response Surface', "PRS_CAT (Categorical Polynomial Response Surface) is a type of model that allows to build one PRS model for each different value of the first component of x.")
        RBF('RBF', 'Radial Basis Function', "A Radial Basis Function model.")
        KS('KS', 'Kernel Smoothing', "A  Kernel Smoothing model.")
        KRIGING('KRIGING', 'KRIGING', "A KRIGING model.")
        LOWESS('LOWESS', 'Locally Weighted Regression', "A LOWESS model.")
        CN('CN', 'Closest Neighbours', "A closest neighbors model.")
        ENSEMBLE('ENSEMBLE', 'ENSEMBLE', "ENSEMBLE is a type of model that uses multiple models simultaneously.")
        ENSEMBLE_STAT('ENSEMBLE_STAT', 'ENSEMBLE_STAT', "Statistical Surrogate Formulation")
    end
    
    properties
        optionStr char = ''
        name char = '';
        desc(1,1) string = "";
    end
    
    methods
        function obj = NomadSurrogateModelTypeEnum(optionStr, name, desc)
            obj.optionStr = optionStr;
            obj.name = name;
            obj.desc = desc;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateModelTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateModelTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateModelTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end