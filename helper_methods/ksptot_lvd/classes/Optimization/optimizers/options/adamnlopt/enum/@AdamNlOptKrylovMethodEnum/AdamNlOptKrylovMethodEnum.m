classdef AdamNlOptKrylovMethodEnum < matlab.mixin.SetGet
    %AdamNlOptKrylovMethodEnum Iterative linear solver used by AdamNLOpt's matrix-free KKT solve.

    enumeration
        MinRes('minres', 'MINRES')
        GMRes('gmres', 'GMRES')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptKrylovMethodEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptKrylovMethodEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptKrylovMethodEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptKrylovMethodEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
