classdef LvdSweepSamplingEnum < matlab.mixin.SetGet
    %LvdSweepSamplingEnum How a sweep picks the points it runs.
    %
    %   Listbox order here is declaration order rather than alphabetical
    %   because these run from "cheapest to explain" to "cheapest to run",
    %   and full factorial is the historical default that must stay first.

    enumeration
        FullFactorial('Full Factorial (Grid)')
        LatinHypercube('Latin Hypercube')
        Random('Random')
    end

    properties
        name char = '';
    end

    methods
        function obj = LvdSweepSamplingEnum(name)
            obj.name = name;
        end

        function tf = usesNumSamples(obj)
            %usesNumSamples False for full factorial, whose case count is
            %fixed by the parameter levels instead of being asked for.
            tf = obj ~= LvdSweepSamplingEnum.FullFactorial;
        end
    end

    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            enums = enumeration('LvdSweepSamplingEnum');
            listBoxStr = {enums.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdSweepSamplingEnum');
            ind = find(ismember({m.name}, name), 1, 'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdSweepSamplingEnum');
            ind = find(ismember({m.name}, nameStr), 1, 'first');
            enum = m(ind);
        end
    end
end
