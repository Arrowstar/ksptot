classdef AdamNlOptParallelEnum < matlab.mixin.SetGet
    %AdamNlOptParallelEnum Parallel evaluation mode used by AdamNLOpt.
    %   optionVal is the logical "does this need a parallel pool" answer that the
    %   optimizer's usesParallel() contract expects.

    enumeration
        DoNotUseParallel('off', 'Do Not Use Parallel', false)
        FiniteDiffs('finitediff', 'Parallel Finite Differences', true)

        %Async is NOT offered in the UI (see selectable).  The solver's
        %Evaluator routes 'async' through exactly the same parallel
        %finite-difference path as 'finitediff' (the standalone
        %parallel_asyncEvaluator is deleted) -- so picking it promised a
        %different evaluation strategy and delivered the other one.  The member
        %stays so saved cases that already hold it still load;
        %AdamNlOptOptions.loadobj rewrites them.
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
        function m = selectable()
            %selectable The members a user may actually choose, sorted by name.
            %   getListBoxStr and getIndForName must agree on both membership
            %   and order, so they share this one list.
            m = enumeration('AdamNlOptParallelEnum');
            m = m(m ~= AdamNlOptParallelEnum.Async);
            [~,I] = sort({m.name});
            m = m(I);
        end

        function listBoxStr = getListBoxStr()
            m = AdamNlOptParallelEnum.selectable();
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = AdamNlOptParallelEnum.selectable();
            ind = find(ismember({m.name},name),1,'first');
            if(isempty(ind))
                %Async, or anything else no longer offered: show the mode it
                %actually behaves as rather than leaving the control blank.
                ind = find(m == AdamNlOptParallelEnum.FiniteDiffs,1,'first');
            end
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AdamNlOptParallelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
