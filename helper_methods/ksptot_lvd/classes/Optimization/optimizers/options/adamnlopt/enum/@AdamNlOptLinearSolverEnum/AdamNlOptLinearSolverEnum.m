classdef AdamNlOptLinearSolverEnum < matlab.mixin.SetGet
    %AdamNlOptLinearSolverEnum Method used by AdamNLOpt to solve the Newton-KKT system.

    enumeration
        Direct('direct', 'Direct (LDL'')')
        Krylov('krylov', 'Krylov (Matrix Free)')
        Auto('auto', 'Automatic')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptLinearSolverEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptLinearSolverEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptLinearSolverEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptLinearSolverEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
