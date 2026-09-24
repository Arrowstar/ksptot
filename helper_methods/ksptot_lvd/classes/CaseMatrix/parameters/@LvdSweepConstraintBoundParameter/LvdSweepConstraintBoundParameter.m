classdef LvdSweepConstraintBoundParameter < AbstractLvdSweepParameter
    %LvdSweepConstraintBoundParameter Sweeps a constraint's bound.
    %
    %   This is the "how does the design change if I ask for a different
    %   orbit" parameter: sweep the bound of the apoapsis constraint and
    %   re-optimize each case.  It only makes sense in Optimize run mode --
    %   a propagate-only case never evaluates constraints, so moving a bound
    %   would do nothing at all -- and it is deliberately not offered as a
    %   Monte Carlo dispersion source for that reason.
    %
    %   There is no setBounds on AbstractConstraint; every concrete
    %   constraint declares public lb/ub properties which
    %   computeCAndCeqValues reads directly, so the write is a guarded
    %   property set.

    properties
        constId(1,1) double = 0;
        whichBound(1,1) LvdSweepBoundEnum = LvdSweepBoundEnum.Both;

        constName(1,:) char = '';
        constUnit(1,:) char = '';
    end

    properties(Transient)
        const AbstractConstraint
    end

    methods
        function obj = LvdSweepConstraintBoundParameter(const, whichBound)
            arguments
                const AbstractConstraint = AbstractConstraint.empty(1,0);
                whichBound(1,1) LvdSweepBoundEnum = LvdSweepBoundEnum.Both;
            end

            if(not(isempty(const)))
                obj.const = const(1);
                obj.constId = const(1).id;
                obj.constName = const(1).getName();
                obj.constUnit = LvdSweepConstraintBoundParameter.getConstraintUnit(const(1));
                obj.isResolved = true;
            end

            obj.whichBound = whichBound;

            obj.id = rand();
        end

        function name = getName(obj)
            name = sprintf('%s [%s]', obj.constName, obj.whichBound.name);
        end

        function unit = getUnit(obj)
            unit = obj.constUnit;
        end

        function group = getGroupName(~)
            group = 'Constraint Bounds';
        end

        function tf = isPinnable(~)
            %A constraint bound is not an optimization variable, so there is
            %nothing to pin.
            tf = false;
        end

        function tf = resolve(obj, lvdData)
            arguments
                obj(1,1) LvdSweepConstraintBoundParameter
                lvdData(1,1) LvdData
            end

            obj.const = AbstractConstraint.empty(1,0);
            obj.isResolved = false;

            consts = lvdData.optimizer.constraints.consts;
            for(i=1:length(consts)) %#ok<*NO4LP>
                if(consts(i).id == obj.constId)
                    obj.const = consts(i);
                    obj.isResolved = true;
                    break;
                end
            end

            tf = obj.isResolved;
        end

        function value = getCurrentValue(obj)
            if(isempty(obj.const))
                value = NaN;
                return;
            end

            [lb, ub] = obj.const.getBounds();

            switch obj.whichBound
                case LvdSweepBoundEnum.Lower
                    value = lb;
                case LvdSweepBoundEnum.Upper
                    value = ub;
                otherwise
                    %the midpoint is the meaningful single number for a two
                    %sided bound, and equals both of them for an equality
                    value = (lb + ub)/2;
            end
        end

        function applyValue(obj, value)
            if(isempty(obj.const))
                error('LvdSweepParameter:unresolved', ...
                      'Constraint "%s" could not be found in this mission.', obj.constName);
            end

            if(not(isprop(obj.const, 'lb')) || not(isprop(obj.const, 'ub')))
                error('LvdSweepParameter:constraintHasNoBounds', ...
                      'Constraint "%s" (%s) does not expose editable bounds.', ...
                      obj.constName, class(obj.const));
            end

            switch obj.whichBound
                case LvdSweepBoundEnum.Lower
                    obj.const.lb = value;

                case LvdSweepBoundEnum.Upper
                    obj.const.ub = value;

                otherwise
                    obj.const.lb = value;
                    obj.const.ub = value;
            end
        end

        function [lb, ub] = getSuggestedBounds(obj)
            [lb, ub] = getSuggestedBounds@AbstractLvdSweepParameter(obj);
        end
    end

    methods(Static)
        function unit = getConstraintUnit(const)
            %getConstraintUnit The constraint's display unit, or '' when the
            %constraint type does not report one.
            unit = '';

            try
                u = const.getConstraintStaticDetails();

                if(ischar(u) || isstring(u))
                    unit = char(u);
                end
            catch
                %a constraint type that cannot describe itself still sweeps
                %fine; it just has no unit to show
            end
        end
    end
end
