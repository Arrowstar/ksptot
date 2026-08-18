classdef AdamNlOptHessianApproxEnum < matlab.mixin.SetGet
    %AdamNlOptHessianApproxEnum Hessian of the Lagrangian model used by AdamNLOpt.

    enumeration
        BFGS('bfgs', 'Dense BFGS')
        LBFGS('lbfgs', 'Limited Memory BFGS')
        FiniteDiffs('fd', 'Finite Differences')
        Exact('exact', 'Exact')
    end

    properties
        optionStr char = ''
        name char = '';
    end

    methods
        function obj = AdamNlOptHessianApproxEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptHessianApproxEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptHessianApproxEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptHessianApproxEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
