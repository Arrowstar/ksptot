classdef ActionExecNodeEnum < matlab.mixin.SetGet
    %ActionExecNodeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        BeforeProp('Execute Actions Before Propagation')
        AfterProp('Execute Actions After Propagation');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = ActionExecNodeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('ActionExecNodeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m;
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ActionExecNodeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ActionExecNodeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end