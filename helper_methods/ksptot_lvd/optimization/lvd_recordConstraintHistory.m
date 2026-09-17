function lvd_recordConstraintHistory(recorder, lvdOpt, x, evtToStartScriptExecAt)
%LVD_RECORDCONSTRAINTHISTORY Appends the constraint vector at x to a recorder.
%
%   lvd_recordConstraintHistory(recorder, lvdOpt, x, evtToStartScriptExecAt)
%   evaluates the mission's constraints at the scaled x vector and stores
%   the full [c, ceq] row (with per-row names) on the ma_OptimRecorder.
%   Called from the optimizer output functions once per iteration, right
%   after the maximum violation is recorded.
%
%   The evaluation goes through ConstraintSet.evalConstraints, so it is
%   served by LvdOptimization's same-x propagation cache whenever the most
%   recent propagation was already at x (the usual case at an iteration
%   boundary) and otherwise costs one propagation, which the output
%   function's own objective re-evaluation then reuses.
%
%   Any error is swallowed: the history is diagnostic and must never stop
%   an optimization.

    arguments
        recorder(1,1) ma_OptimRecorder
        lvdOpt(1,1) LvdOptimization
        x double
        evtToStartScriptExecAt(1,:) LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0)
    end

    try
        if(isempty(evtToStartScriptExecAt))
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(1);
        end

        constraints = lvdOpt.constraints;
        [c, ceq] = constraints.evalConstraints(x, true, evtToStartScriptExecAt, false, []);

        names = lvd_getConstraintRowNames(constraints.lastRunValues, numel(c), numel(ceq));
        recorder.recordConstraintValues(c, ceq, names);
    catch ME %#ok<NASGU>
        %diagnostic only
    end
end

function names = lvd_getConstraintRowNames(lrv, numC, numCeq)
    names = cell(1, numC + numCeq);

    cInds = lrv.cCInds(:)';
    ceqInds = lrv.cCeqInds(:)';

    if(numel(cInds) ~= numC || numel(ceqInds) ~= numCeq)
        for(k = 1:numC) %#ok<*NO4LP>
            names{k} = sprintf('Inequality %u', k);
        end
        for(k = 1:numCeq)
            names{numC + k} = sprintf('Equality %u', k);
        end
        return;
    end

    for(k = 1:numC)
        constInd = cInds(k);
        baseName = constraintNameForInd(lrv, constInd);

        sameConstRows = find(cInds == constInd);
        if(numel(sameConstRows) >= 2)
            if(k == sameConstRows(1))
                suffix = 'Lwr Bnd';
            else
                suffix = 'Upr Bnd';
            end
        else
            suffix = 'Ineq';
        end

        names{k} = sprintf('%s (%s)', baseName, suffix);
    end

    for(k = 1:numCeq)
        names{numC + k} = sprintf('%s (Eq)', constraintNameForInd(lrv, ceqInds(k)));
    end
end

function name = constraintNameForInd(lrv, constInd)
    name = sprintf('Constraint %u', constInd);

    if(constInd >= 1 && constInd <= numel(lrv.consts))
        try
            name = lrv.consts(constInd).getName();
        catch
            %keep fallback
        end
    end
end
