classdef AdamNlOptParallelEnum < matlab.mixin.SetGet
    %AdamNlOptParallelEnum Parallel evaluation mode used by AdamNLOpt.
    %   optionVal is the logical "does this need a parallel pool" answer that the
    %   optimizer's usesParallel() contract expects.

    enumeration
        DoNotUseParallel('off', 'Do Not Use Parallel', false)
        FiniteDiffs('finitediff', 'Parallel Finite Differences', true)
        Async('async', 'Asynchronous Evaluation', true)
    end

    properties
        optionStr char = ''
        name char = '';
        optionVal(1,1) logical = false;
    end

    methods
        function obj = AdamNlOptParallelEnum(optionStr, name, optionVal)
            obj.optionStr = optionStr;
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end

    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AdamNlOptParallelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('AdamNlOptParallelEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptParallelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
