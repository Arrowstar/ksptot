classdef PattSrchSearchFcnEnum < matlab.mixin.SetGet
    %PattSrchSearchFcnEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        None([],'None')
        GPSPositiveBasis2N(@GPSPositiveBasis2N, 'GPSPositiveBasis2N');
        GPSPositiveBasisNp1(@GPSPositiveBasisNp1 , 'GPSPositiveBasisNp1');
        GSSPositiveBasis2N(@GSSPositiveBasis2N, 'GSSPositiveBasis2N');
        GSSPositiveBasisNp1(@GSSPositiveBasisNp1, 'GSSPositiveBasisNp1');
        MADSPositiveBasis2N(@MADSPositiveBasis2N, 'MADSPositiveBasis2N');
        MADSPositiveBasisNp1(@MADSPositiveBasisNp1, 'MADSPositiveBasisNp1');
        LatinHypercube(@searchlhs, 'Latin Hypercube');
    end
    
    properties
        optionFcn = [];
        name char = '';
    end
    
    methods
        function obj = PattSrchSearchFcnEnum(optionFcn, name)
            obj.optionFcn = optionFcn;
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PattSrchSearchFcnEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PattSrchSearchFcnEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PattSrchSearchFcnEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end