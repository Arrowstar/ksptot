classdef LvdOptimTableModel
    %LvdOptimTableModel Tabular views of an LVD mission's optimization
    %variables and constraints, plus the edit operations the table windows
    %expose.  Pure data logic with no UI so it can be tested headlessly and
    %shared by lvd_VariableTableGUI_App and lvd_ConstraintTableGUI_App.
    %
    %   Variable rows list EVERY element of every variable in the mission's
    %   OptimizationVariableSet, including elements that are not currently
    %   active and elements whose owning event has optimization disabled, so
    %   the Active column can be edited for any of them.  Values and bounds
    %   are reported in the same display units the rest of LVD uses
    %   (degrees for radian-stored quantities, percent for 0-1 fractions,
    %   meters for kilometre-stored quantities).
    %
    %   Constraint rows list every constraint in the ConstraintSet with the
    %   values recorded by the most recent evaluation (constraints.lastRunValues).
    %   Constraints that have not been evaluated since the last change report
    %   NaN values.

    properties(Constant)
        VarColumns = {'Event', 'Variable', 'Value', 'Lower Bound', 'Upper Bound', 'Active', 'Scaled Value', 'Note'};
        VarColumnEditable = [false false false true true true false false];

        ConstrColumns = {'Constraint', 'Event', 'Type', 'Value', 'Lower Bound', 'Upper Bound', 'Violation', 'Scale Factor', 'Active', 'Scaled Violation', 'Note'};
        ConstrColumnEditable = [false false false false false false false false true false false];

        %Scaled coordinate within this distance of +/-1 counts as "on a bound".
        OnBoundTol = 1E-9;

        %Status is judged on the SCALED violation, i.e. the c / ceq value the
        %optimizer sees (violation / scale factor), so it is unit free and,
        %for a state comparison, does not depend on how big the two compared
        %quantities are - only on their difference.  Up to
        %SatisfiedScaledViolationTol counts as satisfied (fmincon's default
        %ConstraintTolerance: an equality constraint is never exactly zero in
        %floating point); below MarginalScaledViolationTol is marginal
        %(amber); anything larger is violated (red).
        SatisfiedScaledViolationTol = 1E-6;
        MarginalScaledViolationTol = 1E-3;
    end

    methods(Static)
        function [data, meta] = getVariableRows(lvdData)
            %getVariableRows One row per variable element.
            %
            %   data - cell array, columns per LvdOptimTableModel.VarColumns
            %   meta - struct array (one per row) with fields:
            %            var        the AbstractOptimizationVariable handle
            %            elemInd    index of this element within the variable
            %            unitType   'rad' | 'percent' | 'meters' | 'none'
            %            inX        true when the element is part of the x vector
            %            onBound    true when the scaled value sits on a bound
            arguments
                lvdData(1,1) LvdData
            end

            %Events memoize their active-variable lists and the variable set
            %memoizes the "owning event disabled" flags.  Both go stale when
            %variables or actions are added outside the event editor (which
            %is the only production path that clears them), so start from
            %fresh caches the same way the editor does.
            LvdOptimTableModel.clearOptimCaches(lvdData);

            varSet = lvdData.optimizer.vars;
            vars = varSet.vars;

            data = cell(0, numel(LvdOptimTableModel.VarColumns));
            meta = struct('var', {}, 'elemInd', {}, 'unitType', {}, 'inX', {}, 'onBound', {});

            for(i=1:length(vars)) %#ok<*NO4LP>
                var = vars(i);

                [evtNum, varLocType] = getEventNumberForVar(var, lvdData);
                if(isempty(evtNum))
                    evtNum = 0;
                end
                evtLabel = LvdOptimTableModel.getEventLabel(evtNum, varLocType);

                evtOptimDisabled = LvdOptimTableModel.isVarEventOptimDisabled(var, lvdData);

                useTf = logical(var.getUseTfForVariable());
                useTf = useTf(:)';
                numElems = numel(useTf);

                [lbAll, ubAll] = var.getAllBndsForVariable();
                lbAll = lbAll(:)';
                ubAll = ubAll(:)';

                [xAll, nameStrs] = LvdOptimTableModel.getAllElementValuesAndNames(var, evtNum, varLocType);

                %Unit flags are sized per element for multi-element variables
                %but may be scalar for single-element ones.
                isRad = LvdOptimTableModel.expandFlag(var.getVarsStoredInRad(), numElems);
                isPct = LvdOptimTableModel.expandFlag(var.getVarsDisplayedAsPercents(), numElems);
                isMet = LvdOptimTableModel.expandFlag(var.getVarsDisplayedAsMeters(), numElems);

                %Scaled coordinates exist only for active elements.
                xS = [];
                if(any(useTf) && not(evtOptimDisabled))
                    xS = var.getScaledXsForVariable();
                    xS = xS(:)';
                end
                usedInds = find(useTf);

                for(k=1:numElems)
                    unitType = LvdOptimTableModel.getUnitType(isRad(k), isPct(k), isMet(k));

                    inX = useTf(k) && not(evtOptimDisabled);

                    scaledVal = NaN;
                    onBound = false;
                    if(inX)
                        xInd = find(usedInds == k, 1, 'first');
                        if(not(isempty(xInd)) && xInd <= numel(xS))
                            scaledVal = xS(xInd);
                            onBound = abs(abs(scaledVal) - 1) <= LvdOptimTableModel.OnBoundTol;
                        end
                    end

                    if(evtOptimDisabled)
                        note = 'Event optimization disabled';
                    elseif(not(useTf(k)))
                        note = 'Inactive';
                    elseif(onBound)
                        note = 'On bound';
                    else
                        note = '';
                    end

                    if(k <= numel(nameStrs))
                        nameStr = nameStrs{k};
                    else
                        nameStr = sprintf('%s (element %u)', class(var), k);
                    end

                    if(k <= numel(xAll))
                        xVal = xAll(k);
                    else
                        xVal = NaN;
                    end

                    row = {evtLabel, nameStr, ...
                           LvdOptimTableModel.toDisplayUnits(xVal, unitType), ...
                           LvdOptimTableModel.toDisplayUnits(lbAll(k), unitType), ...
                           LvdOptimTableModel.toDisplayUnits(ubAll(k), unitType), ...
                           logical(useTf(k)), scaledVal, note};

                    data(end+1, :) = row; %#ok<AGROW>
                    meta(end+1) = struct('var', var, 'elemInd', k, 'unitType', unitType, 'inX', inX, 'onBound', onBound); %#ok<AGROW>
                end
            end
        end

        function [ok, msg] = applyVariableEdit(lvdData, rowMeta, columnName, newValue)
            %applyVariableEdit Writes an edited Lower Bound / Upper Bound /
            %Active cell back onto the variable object in stored units.
            %
            %   Returns ok = false with an explanatory msg (and makes no
            %   change) when the new value is invalid (non-numeric, or a
            %   bound that would cross the opposite bound).
            arguments
                lvdData(1,1) LvdData
                rowMeta(1,1) struct
                columnName(1,:) char
                newValue
            end

            ok = true;
            msg = '';

            var = rowMeta.var;
            k = rowMeta.elemInd;

            switch columnName
                case {'Lower Bound', 'Upper Bound'}
                    if(ischar(newValue) || isstring(newValue))
                        newValue = str2double(newValue);
                    end

                    if(not(isnumeric(newValue)) || not(isscalar(newValue)) || isnan(newValue))
                        ok = false;
                        msg = sprintf('The %s must be a number.', lower(columnName));
                        return;
                    end

                    storedValue = LvdOptimTableModel.toStoredUnits(double(newValue), rowMeta.unitType);

                    [lbAll, ubAll] = var.getAllBndsForVariable();
                    lbAll = lbAll(:)';
                    ubAll = ubAll(:)';

                    if(strcmp(columnName, 'Lower Bound'))
                        if(storedValue > ubAll(k))
                            ok = false;
                            msg = 'The lower bound must be less than or equal to the upper bound.';
                            return;
                        end
                        lbAll(k) = storedValue;
                    else
                        if(storedValue < lbAll(k))
                            ok = false;
                            msg = 'The upper bound must be greater than or equal to the lower bound.';
                            return;
                        end
                        ubAll(k) = storedValue;
                    end

                    var.setBndsForVariable(lbAll, ubAll);

                case 'Active'
                    if(ischar(newValue) || isstring(newValue))
                        newValue = strcmpi(strtrim(char(newValue)), 'true') || strcmp(strtrim(char(newValue)), '1');
                    end

                    useTf = logical(var.getUseTfForVariable());
                    useTf(k) = logical(newValue);
                    var.setUseTfForVariable(useTf);

                otherwise
                    ok = false;
                    msg = sprintf('Column "%s" is not editable.', columnName);
                    return;
            end

            LvdOptimTableModel.clearOptimCaches(lvdData);
        end

        function [data, meta] = getConstraintRows(lvdData)
            %getConstraintRows One row per constraint in the ConstraintSet.
            %
            %   data - cell array, columns per LvdOptimTableModel.ConstrColumns
            %   meta - struct array with fields:
            %            const      the AbstractConstraint handle
            %            violation  unscaled violation (NaN when not evaluated)
            %            relViol    violation relative to max(|value|, 1), for information
            %            status     'ok' | 'marginal' | 'violated' | 'unknown', judged on
            %                       the scaled violation (see classifyViolation)
            arguments
                lvdData(1,1) LvdData
            end

            constSet = lvdData.optimizer.constraints;
            consts = constSet.consts;
            lastRun = constSet.lastRunValues;

            data = cell(0, numel(LvdOptimTableModel.ConstrColumns));
            meta = struct('const', {}, 'violation', {}, 'relViol', {}, 'status', {});

            for(i=1:length(consts))
                const = consts(i);

                event = const.getConstraintEvent();
                if(isempty(event))
                    evtNum = NaN;
                else
                    evtNum = event.getEventNum();
                    if(isempty(evtNum))
                        evtNum = NaN;
                    end
                end

                typeStr = char(const.getConstraintType());
                [lb, ub] = const.getBounds();
                sF = const.getScaleFactor();

                isStateComp = isprop(const, 'evalType') && const.evalType == ConstraintEvalTypeEnum.StateComparison;
                if(isStateComp)
                    compEvtNum = NaN;
                    if(isprop(const, 'stateCompEvent') && not(isempty(const.stateCompEvent)))
                        compEvtNum = const.stateCompEvent.getEventNum();
                        if(isempty(compEvtNum))
                            compEvtNum = NaN;
                        end
                    end
                    typeStr = sprintf('%s (%s Event %g)', typeStr, const.stateCompType.symbol, compEvtNum);
                end

                [value, valueStateComp, cVals, ceqVals, evaluated] = LvdOptimTableModel.lookupLastRunValues(lastRun, const);

                violation = NaN;
                scaledViolation = NaN;
                if(evaluated)
                    violation = LvdOptimTableModel.computeViolation(const, value, valueStateComp, lb, ub, isStateComp);
                    scaledViolation = max([0, cVals(:)', abs(ceqVals(:)')]);
                    if(isempty(cVals) && isempty(ceqVals))
                        scaledViolation = NaN;
                    end
                end

                %For a state comparison the bound columns show the comparison
                %quantity as the bound it acts as: == is a two-sided bound,
                %>= a lower bound only, <= an upper bound only.
                if(isStateComp)
                    switch const.stateCompType
                        case ConstraintStateComparisonTypeEnum.GreaterThan
                            lbDisp = valueStateComp;
                            ubDisp = Inf;
                        case ConstraintStateComparisonTypeEnum.LessThan
                            lbDisp = -Inf;
                            ubDisp = valueStateComp;
                        otherwise
                            lbDisp = valueStateComp;
                            ubDisp = valueStateComp;
                    end
                else
                    lbDisp = lb;
                    ubDisp = ub;
                end

                [status, relViol] = LvdOptimTableModel.classifyViolation(violation, scaledViolation, value);

                if(not(const.active))
                    note = 'Inactive';
                elseif(LvdOptimTableModel.isConstraintEventOptimDisabled(const, lvdData))
                    note = 'Event optimization disabled';
                elseif(not(evaluated) || isnan(value))
                    note = 'Not evaluated';
                else
                    switch status
                        case 'violated'
                            note = 'Violated';
                        case 'marginal'
                            note = 'Marginal';
                        otherwise
                            note = '';
                    end
                end

                row = {const.getName(), evtNum, typeStr, value, lbDisp, ubDisp, violation, sF, logical(const.active), scaledViolation, note};

                data(end+1, :) = row; %#ok<AGROW>
                meta(end+1) = struct('const', const, 'violation', violation, 'relViol', relViol, 'status', status); %#ok<AGROW>
            end
        end

        function [ok, msg] = applyConstraintEdit(lvdData, rowMeta, columnName, newValue)
            %applyConstraintEdit Writes an edited Active cell back onto the
            %constraint object.
            arguments
                lvdData(1,1) LvdData %#ok<INUSA>
                rowMeta(1,1) struct
                columnName(1,:) char
                newValue
            end

            ok = true;
            msg = '';

            switch columnName
                case 'Active'
                    if(ischar(newValue) || isstring(newValue))
                        newValue = strcmpi(strtrim(char(newValue)), 'true') || strcmp(strtrim(char(newValue)), '1');
                    end

                    rowMeta.const.active = logical(newValue);

                otherwise
                    ok = false;
                    msg = sprintf('Column "%s" is not editable.', columnName);
            end
        end

        function [ok, msg] = evaluateConstraintsNow(lvdData)
            %evaluateConstraintsNow Re-evaluates every constraint against
            %the mission's CURRENT state log without propagating.
            arguments
                lvdData(1,1) LvdData
            end

            ok = true;
            msg = '';

            if(lvdData.stateLog.getNumberOfEntries() == 0)
                ok = false;
                msg = 'The mission has not been propagated yet, so there is no state log to evaluate the constraints against.  Run the script first.';
                return;
            end

            try
                x = lvdData.optimizer.vars.getTotalScaledXVector();
                lvdData.optimizer.constraints.evalConstraints(x, false, lvdData.script.getEventForInd(1), false, []);
            catch ME
                ok = false;
                msg = sprintf('Constraint evaluation failed: %s', ME.message);
            end
        end

        function txt = toClipboardText(columnNames, data)
            %toClipboardText Tab-separated text with a header row.
            arguments
                columnNames(1,:) cell
                data cell
            end

            lines = cell(1, size(data,1) + 1);
            lines{1} = strjoin(columnNames, sprintf('\t'));

            for(i=1:size(data,1))
                cells = cell(1, size(data,2));
                for(j=1:size(data,2))
                    cells{j} = LvdOptimTableModel.cellToText(data{i,j});
                end
                lines{i+1} = strjoin(cells, sprintf('\t'));
            end

            txt = strjoin(lines, newline);
        end

        function value = toDisplayUnits(value, unitType)
            switch unitType
                case 'rad'
                    value = rad2deg(value);
                case 'percent'
                    value = 100*value;
                case 'meters'
                    value = 1000*value;
                otherwise
                    %no conversion
            end
        end

        function value = toStoredUnits(value, unitType)
            switch unitType
                case 'rad'
                    value = deg2rad(value);
                case 'percent'
                    value = value/100;
                case 'meters'
                    value = value/1000;
                otherwise
                    %no conversion
            end
        end

        function violation = computeViolation(const, value, valueStateComp, lb, ub, isStateComp)
            %computeViolation Unscaled constraint violation (>= 0; 0 = satisfied).
            if(isnan(value))
                violation = NaN;
                return;
            end

            if(isStateComp)
                switch const.stateCompType
                    case ConstraintStateComparisonTypeEnum.Equals
                        violation = abs(value - valueStateComp);
                    case ConstraintStateComparisonTypeEnum.GreaterThan
                        violation = max(valueStateComp - value, 0);
                    case ConstraintStateComparisonTypeEnum.LessThan
                        violation = max(value - valueStateComp, 0);
                    otherwise
                        violation = NaN;
                end
            else
                violation = max([lb - value, value - ub, 0]);
            end
        end

        function [status, relViol] = classifyViolation(violation, scaledViolation, value)
            %classifyViolation Status from the scaled violation (see the
            %tolerance constants): 'ok' within the optimizer's constraint
            %tolerance, 'marginal' when small, 'violated' otherwise,
            %'unknown' when the constraint has no value.  The unscaled
            %violation stands in when no scaled value was recorded.  relViol
            %(violation relative to max(|value|, 1)) is reported for
            %information only; it plays no part in the status, so a satisfied
            %"Y == X" reads as satisfied however large Y and X are.
            if(isnan(violation))
                status = 'unknown';
                relViol = NaN;
                return;
            end

            if(isnan(value))
                relViol = violation;
            else
                relViol = violation / max(abs(value), 1);
            end

            if(isnan(scaledViolation))
                scaledViolation = violation;
            end

            if(scaledViolation <= LvdOptimTableModel.SatisfiedScaledViolationTol)
                status = 'ok';
            elseif(scaledViolation < LvdOptimTableModel.MarginalScaledViolationTol)
                status = 'marginal';
            else
                status = 'violated';
            end
        end

        function clearOptimCaches(lvdData)
            %clearOptimCaches Drops the cached "is this variable's event
            %disabled" flags and the per-event active-variable caches, the
            %same way LaunchVehicleEvent.toggleOptimDisable does.
            lvdData.optimizer.vars.clearCachedVarEvtDisabledStatus();

            evts = lvdData.script.evts;
            for(i=1:length(evts))
                evts(i).clearActiveOptVarsCache();
            end

            if(not(isempty(lvdData.script.nonSeqEvts)))
                nonSeqEvts = lvdData.script.nonSeqEvts.evts;
                for(i=1:length(nonSeqEvts))
                    nonSeqEvts(i).clearActiveOptVarsCache();
                end
            end
        end

        function [xAll, nameStrs] = getAllElementValuesAndNames(var, evtNum, varLocType)
            %getAllElementValuesAndNames Values and names for EVERY element.
            %
            %Variables report values and names only for their active
            %elements, so the use flags are temporarily set to all-true and
            %restored afterwards.  The variable objects are handles but no
            %listeners hang off the use flags, so this is side-effect free.
            useTf0 = var.getUseTfForVariable();
            restore = onCleanup(@() var.setUseTfForVariable(useTf0));

            var.setUseTfForVariable(true(size(useTf0)));
            xAll = var.getXsForVariable();
            xAll = xAll(:)';
            nameStrs = var.getStrNamesOfVars(evtNum, varLocType);

            clear restore;
        end

        function x = getElementValue(var, elemInd)
            %getElementValue The stored value of one element of a variable,
            %active or not.
            arguments
                var(1,1) AbstractOptimizationVariable
                elemInd(1,1) double
            end

            useTf0 = var.getUseTfForVariable();
            restore = onCleanup(@() var.setUseTfForVariable(useTf0));

            var.setUseTfForVariable(true(size(useTf0)));
            xAll = var.getXsForVariable();
            xAll = xAll(:)';

            clear restore;

            if(elemInd >= 1 && elemInd <= numel(xAll))
                x = xAll(elemInd);
            else
                x = NaN;
            end
        end

        function setElementValue(var, elemInd, value)
            %setElementValue Writes one element of a variable without
            %disturbing the others.
            %
            %   updateObjWithVarValue consumes its input positionally over
            %   the ACTIVE elements only, so a one-hot use mask makes it
            %   write exactly the element asked for.  That works for every
            %   AbstractOptimizationVariable subclass without any of them
            %   knowing about it, which is the whole reason a sweep can
            %   target an arbitrary variable element.
            arguments
                var(1,1) AbstractOptimizationVariable
                elemInd(1,1) double
                value(1,1) double
            end

            useTf0 = var.getUseTfForVariable();
            restore = onCleanup(@() var.setUseTfForVariable(useTf0));

            oneHot = false(size(useTf0));
            oneHot(elemInd) = true;

            var.setUseTfForVariable(oneHot);
            var.updateObjWithVarValue(value);

            clear restore;
        end
    end

    methods(Static, Access=private)
        function label = getEventLabel(evtNum, varLocType)
            if(evtNum > 0)
                label = sprintf('Event %u', evtNum);
            else
                switch varLocType
                    case 'Initial State'
                        label = 'Init';
                    case 'Launch Vehicle'
                        label = 'LV';
                    case 'Plugins'
                        label = 'Plugin';
                    case ''
                        label = '?';
                    otherwise
                        label = varLocType;
                end
            end
        end

        function tf = isVarEventOptimDisabled(var, lvdData)
            tf = false;

            evtNum = getEventNumberForVar(var, lvdData);
            if(not(isempty(evtNum)))
                evt = lvdData.script.getEventForInd(evtNum);
                if(not(isempty(evt)) && evt.disableOptim)
                    tf = true;
                end
            end
        end

        function tf = isConstraintEventOptimDisabled(const, lvdData) %#ok<INUSD>
            tf = false;

            evt = const.getConstraintEvent();
            if(not(isempty(evt)) && evt.disableOptim)
                tf = true;
            end
        end

        function flags = expandFlag(flags, numElems)
            flags = logical(flags(:)');
            if(isempty(flags))
                flags = false(1, numElems);
            elseif(numel(flags) == 1 && numElems > 1)
                flags = repmat(flags, 1, numElems);
            elseif(numel(flags) < numElems)
                flags(end+1:numElems) = false;
            end
        end

        function unitType = getUnitType(isRad, isPct, isMet)
            if(isRad)
                unitType = 'rad';
            elseif(isPct)
                unitType = 'percent';
            elseif(isMet)
                unitType = 'meters';
            else
                unitType = 'none';
            end
        end

        function [value, valueStateComp, cVals, ceqVals, evaluated] = lookupLastRunValues(lastRun, const)
            value = NaN;
            valueStateComp = NaN;
            cVals = [];
            ceqVals = [];
            evaluated = false;

            if(isempty(lastRun) || isempty(lastRun.consts))
                return;
            end

            constInd = find(lastRun.consts == const, 1, 'first');
            if(isempty(constInd))
                return;
            end

            evaluated = true;
            if(constInd <= numel(lastRun.value))
                value = lastRun.value(constInd);
            end
            if(constInd <= numel(lastRun.valueStateComps))
                valueStateComp = lastRun.valueStateComps(constInd);
            end

            cVals = lastRun.c(lastRun.cCInds == constInd);
            ceqVals = lastRun.ceq(lastRun.cCeqInds == constInd);
        end

        function s = cellToText(v)
            if(ischar(v))
                s = v;
            elseif(isstring(v))
                s = char(v);
            elseif(islogical(v))
                if(v)
                    s = 'true';
                else
                    s = 'false';
                end
            elseif(isnumeric(v))
                if(isscalar(v))
                    s = fullAccNum2Str(v);
                else
                    s = mat2str(v);
                end
            else
                s = char(string(v));
            end
        end
    end
end
