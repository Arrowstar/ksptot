classdef LvdSweepBoundEnum < matlab.mixin.SetGet
    %LvdSweepBoundEnum Which bound of a constraint a sweep parameter moves.
    %
    %   Both is what an equality-style requirement needs: sweeping the target
    %   altitude of a "== 200 km" constraint has to move lb and ub together
    %   or the constraint becomes unsatisfiable at the first off-nominal
    %   level.

    enumeration
        Lower('Lower Bound')
        Upper('Upper Bound')
        Both('Both Bounds')
    end

    properties
        name char = '';
    end

    methods
        function obj = LvdSweepBoundEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            enums = enumeration('LvdSweepBoundEnum');
            listBoxStr = {enums.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdSweepBoundEnum');
            ind = find(ismember({m.name}, name), 1, 'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdSweepBoundEnum');
            ind = find(ismember({m.name}, nameStr), 1, 'first');
            enum = m(ind);
        end
    end
end
