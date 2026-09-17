function [hFig, sens] = lvd_showSensitivityTornado(lvdData, hParent, varargin)
%LVD_SHOWSENSITIVITYTORNADO Tornado chart of objective and constraint sensitivities.
%
%   hFig = lvd_showSensitivityTornado(lvdData, hParent) finite-differences
%   the composite objective and the stacked constraint vector [c; ceq] with
%   respect to every enabled (scaled) optimization variable at the current
%   x, using the step size, difference type and stencil configured on the
%   mission's CustomFiniteDiffsCalculationMethod, and plots two horizontal
%   bar charts sorted by magnitude:
%
%       left  - |dJ/dx_i| for each variable
%       right - max_j |dc_j/dx_i| for each variable, annotated with the
%               name of the constraint row that attains the maximum
%
%   hParent may be an existing figure handle to draw into, or [] to create
%   a new figure.  Name/value pairs are forwarded to figure() when one is
%   created; pass 'Visible','off' to run headless.
%
%   [hFig, sens] = ... also returns a struct with fields varNames, objGrad
%   (1 x numX), constrJac (numRows x numX), constrNames, and the two
%   plotted magnitude vectors (objMag, constrMag).  The struct is filled
%   even when there are no constraints (constrJac is 0 x numX).

    arguments
        lvdData(1,1) LvdData
        hParent = []
    end
    arguments(Repeating)
        varargin
    end

    lvdOpt = lvdData.optimizer;

    [x0, ~, varNames] = lvdOpt.vars.getTotalScaledXVector();
    x0 = x0(:);
    numX = numel(x0);

    if(numX == 0)
        error('lvd_showSensitivityTornado:noVariables', ...
              'There are no enabled optimization variables, so there is nothing to compute sensitivities against.');
    end

    evtToStartScriptExecAt = lvdData.script.getEventForInd(1);
    fdMethod = lvdOpt.customFiniteDiffsCalcMethod;
    useParallel = lvdOpt.constraints.getGradientUseParallelFlag();

    %Objective gradient (evalObjFcn applies x, propagates, and scores).
    objFun = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
    fAtX0 = objFun(x0);
    objGrad = computeGradAtPoint(objFun, x0, fAtX0, fdMethod.h, fdMethod.diffType, double(fdMethod.numPts), [], useParallel);
    objGrad = objGrad(:)';

    %Constraint Jacobian, one pass over the stacked vector.
    [c0, ceq0] = lvdOpt.constraints.evalConstraints(x0, true, evtToStartScriptExecAt, false, []);
    stacked0 = [c0(:); ceq0(:)];
    numRows = numel(stacked0);

    if(numRows > 0)
        cFun = @(x) ConstraintSet.stackedConstraintFcn(lvdOpt.constraints, x, true, evtToStartScriptExecAt, false, []);
        sparsity = lvdOpt.constraints.getConstraintJacobianSparsity();
        if(not(isequal(size(sparsity), [numRows, numX])))
            sparsity = [];
        end
        constrJac = fdMethod.computeJacobian(cFun, x0, stacked0, useParallel, sparsity); %[numRows x numX]
        constrNames = lvd_constraintRowNames(lvdOpt.constraints.lastRunValues, numel(c0), numel(ceq0));
    else
        constrJac = zeros(0, numX);
        constrNames = {};
    end

    %Restore the mission to x0: the finite differences left the variables
    %at the last perturbed point.
    lvdOpt.vars.updateObjsWithScaledVarValues(x0);

    objMag = abs(objGrad);
    if(numRows > 0)
        [constrMag, worstRowInd] = max(abs(constrJac), [], 1);
    else
        constrMag = zeros(1, numX);
        worstRowInd = zeros(1, numX);
    end

    sens = struct();
    sens.varNames = varNames(:)';
    sens.objGrad = objGrad;
    sens.constrJac = constrJac;
    sens.constrNames = constrNames;
    sens.objMag = objMag;
    sens.constrMag = constrMag;
    sens.worstConstrRowInd = worstRowInd;

    %----------------------------------------------------------------------
    % Plot
    %----------------------------------------------------------------------
    if(isempty(hParent) || not(isgraphics(hParent)))
        hFig = figure('Name', 'Optimization Sensitivities (Tornado)', 'NumberTitle', 'off', varargin{:});
    else
        hFig = hParent;
        clf(hFig);
    end

    tl = tiledlayout(hFig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('Sensitivities at current x (h = %g, %s)', fdMethod.h, fdMethod.diffType.name), 'Interpreter', 'none');

    [objSorted, objOrder] = sort(objMag, 'ascend'); %barh draws first element at bottom
    hAxObj = nexttile(tl, 1);
    hBarObj = barh(hAxObj, 1:numX, objSorted);
    hBarObj.Tag = 'objectiveSensitivityBars';
    set(hAxObj, 'YTick', 1:numX, 'YTickLabel', varNames(objOrder), 'TickLabelInterpreter', 'none');
    xlabel(hAxObj, '|dJ/dx_i| (scaled x)', 'Interpreter', 'tex');
    title(hAxObj, 'Objective', 'Interpreter', 'none');
    grid(hAxObj, 'on');

    [constrSorted, constrOrder] = sort(constrMag, 'ascend');
    hAxConstr = nexttile(tl, 2);
    hBarConstr = barh(hAxConstr, 1:numX, constrSorted);
    hBarConstr.Tag = 'constraintSensitivityBars';
    set(hAxConstr, 'YTick', 1:numX, 'YTickLabel', varNames(constrOrder), 'TickLabelInterpreter', 'none');
    xlabel(hAxConstr, 'max_j |dc_j/dx_i| (scaled x)', 'Interpreter', 'tex');
    title(hAxConstr, 'Constraints', 'Interpreter', 'none');
    grid(hAxConstr, 'on');

    if(numRows > 0)
        for(k = 1:numX) %#ok<*NO4LP>
            rowInd = worstRowInd(constrOrder(k));
            if(rowInd >= 1 && rowInd <= numel(constrNames) && constrSorted(k) > 0)
                text(hAxConstr, constrSorted(k), k, ['  ', constrNames{rowInd}], ...
                     'Interpreter', 'none', 'FontSize', 7, 'VerticalAlignment', 'middle', 'Clipping', 'on');
            end
        end
    end

    global GLOBAL_AppThemer %#ok<GVMIS>
    if(isa(GLOBAL_AppThemer, 'AppThemer'))
        try
            GLOBAL_AppThemer.themeWidget(hAxObj, GLOBAL_AppThemer.selTheme);
            GLOBAL_AppThemer.themeWidget(hAxConstr, GLOBAL_AppThemer.selTheme);
        catch
            %theming is cosmetic
        end
    end
end

function names = lvd_constraintRowNames(lrv, numC, numCeq)
    names = cell(1, numC + numCeq);

    cInds = lrv.cCInds(:)';
    ceqInds = lrv.cCeqInds(:)';

    for(k = 1:numC) %#ok<*NO4LP>
        if(numel(cInds) == numC && cInds(k) >= 1 && cInds(k) <= numel(lrv.consts))
            base = lrv.consts(cInds(k)).getName();
            sameRows = find(cInds == cInds(k));
            if(numel(sameRows) >= 2 && k == sameRows(1))
                names{k} = sprintf('%s (Lwr Bnd)', base);
            elseif(numel(sameRows) >= 2)
                names{k} = sprintf('%s (Upr Bnd)', base);
            else
                names{k} = sprintf('%s (Ineq)', base);
            end
        else
            names{k} = sprintf('Inequality %u', k);
        end
    end

    for(k = 1:numCeq)
        if(numel(ceqInds) == numCeq && ceqInds(k) >= 1 && ceqInds(k) <= numel(lrv.consts))
            names{numC + k} = sprintf('%s (Eq)', lrv.consts(ceqInds(k)).getName());
        else
            names{numC + k} = sprintf('Equality %u', k);
        end
    end
end
