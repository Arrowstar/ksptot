classdef LvdSweepOptimVarParameter < AbstractLvdSweepParameter
    %LvdSweepOptimVarParameter Sweeps one element of any optimization
    %variable in the mission.
    %
    %   "Any" is meant literally: a throttle, a burn duration, a steering
    %   coefficient, a launch epoch, a tank fill fraction and a state vector
    %   component are all AbstractOptimizationVariable elements, and none of
    %   the ~40 subclasses needs to know this class exists.  The mechanism is
    %   the one-hot use mask in LvdOptimTableModel.setElementValue.
    %
    %   Values are handled in DISPLAY units -- degrees, percent, metres --
    %   the same as the variable table shows, because a user asked to sweep a
    %   pitch angle from 0 to 90 means degrees.  Conversion to stored units
    %   happens on the way in.

    properties
        varId(1,1) double = 0;
        elemInd(1,1) double = 1;

        varName(1,:) char = '';
        unitType(1,:) char = 'none';
    end

    properties(Transient)
        var AbstractOptimizationVariable
        lvdData LvdData
    end

    methods
        function obj = LvdSweepOptimVarParameter(var, elemInd, varName, unitType)
            arguments
                var AbstractOptimizationVariable = AbstractOptimizationVariable.empty(1,0);
                elemInd(1,1) double = 1;
                varName(1,:) char = '';
                unitType(1,:) char = 'none';
            end

            if(not(isempty(var)))
                obj.var = var(1);
                obj.varId = var(1).id;
                obj.isResolved = true;
            end

            obj.elemInd = elemInd;
            obj.varName = varName;
            obj.unitType = unitType;

            obj.id = rand();
        end

        function name = getName(obj)
            name = obj.varName;

            if(isempty(name))
                name = sprintf('%s (element %u)', class(obj.var), obj.elemInd);
            end
        end

        function unit = getUnit(obj)
            switch obj.unitType
                case 'rad'
                    unit = 'deg';
                case 'percent'
                    unit = '%';
                case 'meters'
                    unit = 'm';
                otherwise
                    unit = '';
            end
        end

        function group = getGroupName(~)
            group = 'Optimization Variables';
        end

        function tf = resolve(obj, lvdData)
            arguments
                obj(1,1) LvdSweepOptimVarParameter
                lvdData(1,1) LvdData
            end

            obj.var = AbstractOptimizationVariable.empty(1,0);
            obj.lvdData = lvdData;
            obj.isResolved = false;

            vars = lvdData.optimizer.vars.vars;
            for(i=1:length(vars)) %#ok<*NO4LP>
                if(vars(i).id == obj.varId)
                    obj.var = vars(i);
                    obj.isResolved = true;
                    break;
                end
            end

            tf = obj.isResolved;
        end

        function value = getCurrentValue(obj)
            if(isempty(obj.var))
                value = NaN;
                return;
            end

            stored = LvdOptimTableModel.getElementValue(obj.var, obj.elemInd);
            value = LvdOptimTableModel.toDisplayUnits(stored, obj.unitType);
        end

        function applyValue(obj, value)
            if(isempty(obj.var))
                error('LvdSweepParameter:unresolved', ...
                      'Optimization variable "%s" could not be found in this mission.', obj.varName);
            end

            stored = LvdOptimTableModel.toStoredUnits(value, obj.unitType);
            LvdOptimTableModel.setElementValue(obj.var, obj.elemInd, stored);

            %Pin it: an element the sweep is setting must not also be
            %something the optimizer is free to move, or the swept value is
            %just an initial guess that the first case throws away.
            useTf = logical(obj.var.getUseTfForVariable());
            if(obj.elemInd >= 1 && obj.elemInd <= numel(useTf))
                useTf(obj.elemInd) = false;
                obj.var.setUseTfForVariable(useTf);
            end

            if(not(isempty(obj.lvdData)))
                LvdOptimTableModel.clearOptimCaches(obj.lvdData);
            end
        end

        function [lb, ub] = getSuggestedBounds(obj)
            if(not(isempty(obj.var)))
                [lbAll, ubAll] = obj.var.getAllBndsForVariable();
                lbAll = lbAll(:)';
                ubAll = ubAll(:)';

                if(obj.elemInd >= 1 && obj.elemInd <= numel(lbAll))
                    lb = LvdOptimTableModel.toDisplayUnits(lbAll(obj.elemInd), obj.unitType);
                    ub = LvdOptimTableModel.toDisplayUnits(ubAll(obj.elemInd), obj.unitType);

                    if(isfinite(lb) && isfinite(ub) && ub > lb)
                        return;
                    end
                end
            end

            [lb, ub] = getSuggestedBounds@AbstractLvdSweepParameter(obj);
        end
    end
end
