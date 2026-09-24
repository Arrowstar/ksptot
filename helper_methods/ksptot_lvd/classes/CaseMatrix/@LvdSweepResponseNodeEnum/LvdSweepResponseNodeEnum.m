classdef LvdSweepResponseNodeEnum < matlab.mixin.SetGet
    %LvdSweepResponseNodeEnum Which point of a case's trajectory a response
    %is read at.
    %
    %   Initial/Final match the ConstraintStateComparisonNodeEnum meanings so
    %   a response reads the same quantity a constraint on the same node
    %   would.  Minimum/Maximum/Mean reduce the whole scoped span, which is
    %   what makes "max dynamic pressure" or "minimum altitude" a response
    %   rather than something the user has to go find on a plot.

    enumeration
        InitialState('Initial State')
        FinalState('Final State')
        Minimum('Minimum')
        Maximum('Maximum')
        Mean('Mean')
    end

    properties
        name char = '';
    end

    methods
        function obj = LvdSweepResponseNodeEnum(name)
            obj.name = name;
        end

        function value = reduce(obj, values)
            %reduce Collapses a span of sampled values to this node's single
            %number, ignoring the NaNs a partly evaluable task leaves.
            values = values(:)';
            values = values(not(isnan(values)));

            if(isempty(values))
                value = NaN;
                return;
            end

            switch obj
                case LvdSweepResponseNodeEnum.InitialState
                    value = values(1);
                case LvdSweepResponseNodeEnum.FinalState
                    value = values(end);
                case LvdSweepResponseNodeEnum.Minimum
                    value = min(values);
                case LvdSweepResponseNodeEnum.Maximum
                    value = max(values);
                otherwise
                    value = mean(values);
            end
        end

        function tf = needsWholeSpan(obj)
            %needsWholeSpan False for the two end nodes, which only need one
            %state log entry evaluated instead of all of them.
            tf = not(ismember(obj, [LvdSweepResponseNodeEnum.InitialState, ...
                                    LvdSweepResponseNodeEnum.FinalState]));
        end
    end

    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            enums = enumeration('LvdSweepResponseNodeEnum');
            listBoxStr = {enums.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdSweepResponseNodeEnum');
            ind = find(ismember({m.name}, name), 1, 'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdSweepResponseNodeEnum');
            ind = find(ismember({m.name}, nameStr), 1, 'first');
            enum = m(ind);
        end
    end
end
