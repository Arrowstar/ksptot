classdef(Abstract) AbstractLvdSweepParameter < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractLvdSweepParameter One mission quantity a sweep or Monte Carlo
    %run varies.
    %
    %   The original case matrix could only sweep plugin variables, because
    %   its parameter class was hard typed to LvdPluginOptimVarWrapper.  This
    %   interface is the generalization: anything that can be found again in
    %   a mission and written to is a sweep parameter.
    %
    %   The critical detail is resolve().  A case never runs against the
    %   mission the user configured; it runs against a byte stream clone of
    %   it, in which every handle is new.  So a parameter stores the *id* of
    %   whatever it targets -- ids survive cloning, and the optimization
    %   variable, constraint, stage, tank, engine and plugin variable classes
    %   all carry one -- and re-finds its handle inside each case's LvdData
    %   before applying anything.  A parameter that cannot find its target
    %   (the user deleted the event that owned it) reports false rather than
    %   erroring in a worker.
    %
    %   applyValue must also PIN the parameter: if the run mode is Optimize,
    %   a swept quantity that is still an active optimization variable would
    %   simply be optimized straight back off the value the sweep just set.

    properties
        id(1,1) double = 0;
    end

    properties(Transient)
        %Resolved against the current case's LvdData.  Transient because a
        %handle into one mission is meaningless in another.
        isResolved(1,1) logical = false;
    end

    methods(Abstract)
        %getName Display label, unique enough to identify the target.
        name = getName(obj)

        %getUnit Display unit string, '' when dimensionless.
        unit = getUnit(obj)

        %getGroupName Heading this parameter is listed under.
        group = getGroupName(obj)

        %resolve Re-binds onto the given mission.  Returns false when the
        %target no longer exists.
        tf = resolve(obj, lvdData)

        %getCurrentValue The resolved target's present value.
        value = getCurrentValue(obj)

        %applyValue Sets the value and pins it against the optimizer.
        applyValue(obj, value)
    end

    methods
        function captureBaseline(obj, lvdData) %#ok<INUSD>
            %captureBaseline Records whatever the parameter needs from the
            %pristine template before any case runs.  Only the multiplier
            %style knobs need it; everything else applies absolutely.
        end

        function [lb, ub] = getSuggestedBounds(obj)
            %getSuggestedBounds A starting grid for the GUI, +/- 10% of the
            %current value (or [0, 1] when the current value is zero).
            v = obj.getCurrentValue();

            if(not(isfinite(v)) || v == 0)
                lb = 0;
                ub = 1;
            else
                lb = v - 0.1*abs(v);
                ub = v + 0.1*abs(v);
            end
        end

        function str = getFullLabel(obj)
            %getFullLabel Name with the unit appended, for a column header.
            u = obj.getUnit();

            if(isempty(u))
                str = obj.getName();
            else
                str = sprintf('%s (%s)', obj.getName(), u);
            end
        end

        function tf = isPinnable(~)
            %isPinnable True when applying a value takes the target out of
            %the optimizer's hands.  Constraint bounds are not pinnable --
            %they are not variables to begin with.
            tf = true;
        end

        function pairs = getPinnedOptimElements(~)
            %getPinnedOptimElements The optimizer elements applying a value
            %switches off, as a struct array with fields:
            %
            %   key   class and id of the variable, unique enough to tell
            %         apart variables that share an id
            %   var   the variable object the apply would touch
            %   elem  the 1-based element index switched off
            %
            %Empty when the parameter leaves the optimizer alone (constraint
            %bounds).  LvdSweepSetup.validate uses this to refuse an Optimize
            %run whose dispersions would leave nothing to optimize.
            pairs = struct('key', {}, 'var', {}, 'elem', {});
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end

            obj.isResolved = false;
        end

        function key = optimVarKey(var)
            %optimVarKey Identity string for an optimization variable.
            %Ids alone are not unique: missions in the wild carry distinct
            %variables that share an id, so the class rides along.
            key = sprintf('%s|%.17g', class(var), var(1).id);
        end

        function member = findSetOptimVar(lvdData, sampleVar)
            %findSetOptimVar The member of the optimizer's variable set
            %with this variable's id and class.  Empty when the set holds
            %no such member -- the handle the parameter resolved may be a
            %detached twin the optimizer never reads, in which case pinning
            %the twin would silently do nothing.
            member = AbstractOptimizationVariable.empty(1,0);

            if(isempty(sampleVar))
                return;
            end

            vars = lvdData.optimizer.vars.vars;
            for(i=1:length(vars)) %#ok<*NO4LP>
                if(vars(i).id == sampleVar(1).id && strcmp(class(vars(i)), class(sampleVar(1))))
                    member = vars(i);
                    return;
                end
            end
        end
    end

    methods(Sealed)
        function tf = eq(A, B)
            tf = [A.id] == [B.id];
        end

        function tf = ne(A, B)
            tf = [A.id] ~= [B.id];
        end
    end
end
