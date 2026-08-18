classdef AdamNlOptPrecondEnum < matlab.mixin.SetGet
    %AdamNlOptPrecondEnum Preconditioner used by AdamNLOpt's Krylov KKT solve.

    enumeration
        Jacobi('jacobi', 'Jacobi')
        None('none', 'None')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptPrecondEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptPrecondEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptPrecondEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptPrecondEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
