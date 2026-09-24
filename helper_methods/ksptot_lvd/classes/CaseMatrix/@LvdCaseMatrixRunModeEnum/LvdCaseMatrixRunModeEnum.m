classdef LvdCaseMatrixRunModeEnum < matlab.mixin.SetGet
    %LvdCaseMatrixRunModeEnum What each case in a sweep actually does.
    %
    %   Optimize is the original behaviour: every case re-runs the optimizer,
    %   warm started from the nearest already completed case.  PropagateOnly
    %   just runs the script once with the swept values applied, which is
    %   orders of magnitude faster and is the only sensible mode for a Monte
    %   Carlo dispersion (where the point is how the *as flown* design
    %   scatters, not how a re-optimized one would).

    enumeration
        Optimize('Optimize Each Case')
        PropagateOnly('Propagate Only (No Optimization)')
    end

    properties
        name char = '';
    end

    methods
        function obj = LvdCaseMatrixRunModeEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            enums = enumeration('LvdCaseMatrixRunModeEnum');
            listBoxStr = {enums.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCaseMatrixRunModeEnum');
            ind = find(ismember({m.name}, name), 1, 'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCaseMatrixRunModeEnum');
            ind = find(ismember({m.name}, nameStr), 1, 'first');
            enum = m(ind);
        end
    end
end
