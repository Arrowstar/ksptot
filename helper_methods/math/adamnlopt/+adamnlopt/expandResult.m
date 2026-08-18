function [x, grad, hessian, lambda, output] = ...
        expandResult(xr, grad, hessian, lambda, output, fx, problem)
%EXPANDRESULT  Map reduced-space solver outputs back to the full variable set.
%   [x,grad,hessian,lambda,output] = adamnlopt.expandResult(xr,grad,hessian,
%   lambda,output,fx,problem) inverts REDUCEPROBLEM's change of variables
%   x = E*xr + xF, so everything returned to the caller is indexed by the
%   ORIGINAL variables. Pass-through when fx.applied is false.
%
%   Three of these maps involve a real choice, documented here because each one
%   is a value the caller may act on:
%
%   1. BOUND MULTIPLIERS AT A FIXED VARIABLE ARE NOT IDENTIFIABLE.  Both bounds
%      are active, so stationarity supplies one equation in two unknowns,
%      r_i = zL_i - zU_i with r_i = (g + JE'*lamE + JI'*lamI)_i, and every
%      nonnegative split of r_i satisfies complementarity.  We follow fmincon:
%      the whole magnitude goes to lambda.lower when r_i > 0 and to
%      lambda.upper when r_i < 0.  Read either as the sensitivity of the
%      objective to RELAXING THE FIX in that direction; the pair is not two
%      independent sensitivities.
%
%   2. THE FIXED ROWS OF grad AND hessian CANNOT BE FINITE-DIFFERENCED.  A
%      zero-width coordinate has no probe: adamnlopt.fdBoundedStep correctly
%      returns hs = 0 there, so an FD estimate would come back as 0 -- and a
%      zero in a gradient row reads as "this direction is already stationary",
%      which is the single most misleading value we could return.  So those rows
%      are filled from the user's ANALYTIC derivative when one exists (one extra
%      evaluation at the solution, whose cost is recorded in
%      output.funcCount) and are NaN otherwise.  NaN is deliberate: it makes an
%      unavailable derivative impossible to mistake for a computed one.
%      output.fixedVars.gradKnown says which it was.
%
%   3. output.diag IS EXPANDED; output.trace IS NOT.  diag carries the vectors a
%      caller localises a residual with (x, rd, lb, ub, zL, zU) and diagnose.m
%      reads d.lb/d.ub directly, so leaving it reduced would mis-index every
%      report.  trace is a per-iteration matrix of the solve as it actually ran;
%      re-expanding every row would be a large copy of a diagnostic, so it stays
%      in reduced coordinates and output.fixedVars.traceIsReduced says so.
%
%   Inputs:
%     xr      - nr-by-1 solution in the reduced variables.
%     grad    - nr-by-1 reduced objective gradient (or []).
%     hessian - nr-by-nr reduced Lagrangian Hessian model (or []).
%     lambda  - multiplier struct from the reduced solve (or []).
%     output  - output struct from the reduced solve.
%     fx      - reduction map from REDUCEPROBLEM.
%     problem - the ORIGINAL (unreduced) problem struct, used for the analytic
%               gradient fill and the original bounds.
%
%   Outputs:
%     x, grad, hessian, lambda, output - the same quantities over all n
%     variables.  output gains a fixedVars sub-struct describing the reduction.
%
%   See also REDUCEPROBLEM, UNSCALERESULT, SOLVE.

if ~fx.applied
    x = xr;
    return;
end

n    = fx.n;
free = fx.free;
fixd = fx.fixed;

x = fx.xFull;
x(free) = xr(:);

% --- Gradient: analytic where we can get it, NaN where we cannot ------------
gradKnown = false;
if ~isempty(grad)
    gFull = NaN(n, 1);
    gFull(free) = grad(:);
    if problem.hasObjGrad
        try
            [~, gAll] = problem.objFun(x);
            gAll = gAll(:);
            if numel(gAll) == n
                gFull(fixd) = gAll(fixd);
                gradKnown = true;
            end
        catch
            % Leave NaN: a probe failure at the solution must not fail the solve.
        end
    end
    grad = gFull;
end

% --- Hessian: free block in place, fixed rows/cols NaN ----------------------
% Not filled even when HessianFcn exists.  The reduced solve's Hessian is a
% SECANT MODEL built from steps that never moved a fixed coordinate, so grafting
% exact rows onto it would return a matrix that is part model and part truth,
% with no way for the caller to tell which is which.
if ~isempty(hessian)
    HFull = NaN(n, n);
    HFull(free, free) = hessian;
    hessian = HFull;
end

% --- Multipliers ------------------------------------------------------------
if ~isempty(lambda) && isstruct(lambda)
    lambda = expandLambda(lambda, fx, problem, x, grad);
end

% --- Diagnostics ------------------------------------------------------------
if isfield(output, 'diag') && isstruct(output.diag)
    output.diag = expandDiag(output.diag, fx, problem, x);
end

output.fixedVars = struct( ...
    'applied',        true, ...
    'idxFixed',       fx.idxFixed, ...
    'values',         fx.xF, ...
    'nFixed',         fx.nFixed, ...
    'nFree',          fx.nr, ...
    'nDropEqLin',     fx.nDropEqLin, ...
    'nDropIneqLin',   fx.nDropIneqLin, ...
    'gradKnown',      gradKnown, ...
    'traceIsReduced', isfield(output, 'trace') && ~isempty(output.trace));
end

% ------------------------------------------------------------------------
function lambda = expandLambda(lambda, fx, problem, x, grad)
%EXPANDLAMBDA  Re-index multipliers onto the original variables and rows.
%   Bound multipliers get a zero-padded free block plus the fixed-variable
%   entries derived from stationarity (see note 1 in the main help). Linear-row
%   multipliers get zeros re-inserted where REDUCELINEAR dropped a vacuous row.
n = fx.n;

zL = zeros(n, 1);  zU = zeros(n, 1);
if isfield(lambda, 'lower') && numel(lambda.lower) == fx.nr
    zL(fx.free) = lambda.lower(:);
end
if isfield(lambda, 'upper') && numel(lambda.upper) == fx.nr
    zU(fx.free) = lambda.upper(:);
end

% Re-insert dropped linear rows as zero multipliers BEFORE the fixed-variable
% split uses them, so J'*lambda below is indexed consistently.
lambda.eqlin   = padDropped(lambda.eqlin,   fx.keepEqLin);
lambda.ineqlin = padDropped(lambda.ineqlin, fx.keepIneqLin);

% Fixed-variable split.  r = (grad f + JE'*lamE + JI'*lamI) at the solution,
% restricted to the fixed rows; positive goes to lower, negative to upper.
r = fixedStationarity(problem, x, lambda, grad, fx);
if ~isempty(r)
    pos = r > 0;
    zL(fx.idxFixed(pos))  =  r(pos);
    zU(fx.idxFixed(~pos)) = -r(~pos);
end

lambda.lower = zL;
lambda.upper = zU;
end

function r = fixedStationarity(problem, x, lambda, grad, fx)
%FIXEDSTATIONARITY  (grad f + J'*lambda) at the fixed rows, or [] if unavailable.
%   Uses the analytic objective gradient when the caller supplied one (grad
%   already holds it); otherwise there is no derivative at a zero-width
%   coordinate to build from and the multipliers are left at zero rather than
%   fabricated from a step that was never taken.
r = [];
idx = fx.idxFixed;
if isempty(idx)
    return;
end
if isempty(grad) || any(~isfinite(grad(idx)))
    return;   % note 2: no analytic gradient => no defensible split
end

r = grad(idx);
r = r + linearPart(problem.Aeqlin, lambda.eqlin,   idx);
r = r + linearPart(problem.Aineq,  lambda.ineqlin, idx);

% Nonlinear rows need the constraint Jacobian at the solution in FULL space.
% Only available analytically, for the same reason as the gradient.
if ~isempty(problem.nlcon) && problem.hasConGrad
    try
        [~, ~, gc, gceq] = problem.nlcon(x);
        r = r + nlPart(gceq, lambda.eqnonlin,   idx);
        r = r + nlPart(gc,   lambda.ineqnonlin, idx);
    catch
        r = [];   % partial sum would be worse than none
    end
elseif ~isempty(problem.nlcon)
    r = [];
end
end

function v = linearPart(A, lam, idx)
%LINEARPART  A(:,idx)'*lam, or zeros when the block or multiplier is empty.
if isempty(A) || isempty(lam) || size(A, 1) ~= numel(lam)
    v = zeros(numel(idx), 1);
else
    v = A(:, idx).' * lam(:);
end
end

function v = nlPart(G, lam, idx)
%NLPART  G(idx,:)*lam for an fmincon-convention (n-by-m) gradient block.
if isempty(G) || isempty(lam) || size(G, 2) ~= numel(lam)
    v = zeros(numel(idx), 1);
else
    v = G(idx, :) * lam(:);
end
end

function v = padDropped(v, keep)
%PADDROPPED  Re-insert zeros where reduceLinear dropped a vacuous row.
%   A row dropped because it reduced to 0 == 0 is satisfied by every point, so
%   its multiplier is genuinely zero -- it exerts no force on the solution.
if isempty(keep) || all(keep)
    return;
end
full_ = zeros(numel(keep), 1);
if ~isempty(v)
    full_(keep) = v(:);
end
v = full_;
end

function d = expandDiag(d, fx, problem, x)
%EXPANDDIAG  Re-index the termination-diagnostic vectors onto all n variables.
%   Variable-indexed entries are zero-padded (rd) or filled from the original
%   problem (x, lb, ub); constraint-indexed entries are left alone. JE has
%   variable COLUMNS, so it is padded column-wise.
n = fx.n;
d.x  = x;
d.lb = problem.lb;
d.ub = problem.ub;

d.rd = padVar(d, 'rd', fx);
d.g  = padVar(d, 'g',  fx);
d.zL = padVar(d, 'zL', fx);
d.zU = padVar(d, 'zU', fx);

if isfield(d, 'JE') && ~isempty(d.JE) && size(d.JE, 2) == fx.nr
    JE = zeros(size(d.JE, 1), n);
    JE(:, fx.free) = d.JE;
    d.JE = JE;
end
d.fixedVars = fx.idxFixed;
end

function v = padVar(d, name, fx)
%PADVAR  Zero-pad a reduced variable-indexed diagnostic vector to length n.
if ~isfield(d, name) || isempty(d.(name)) || numel(d.(name)) ~= fx.nr
    v = [];
    if isfield(d, name), v = d.(name); end
    return;
end
v = zeros(fx.n, 1);
v(fx.free) = d.(name)(:);
end
