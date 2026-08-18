function [pr, fx, opts] = reduceProblem(problem, opts)
%REDUCEPROBLEM  Eliminate fixed variables (lb == ub) by change of variables.
%   [pr, fx, opts] = adamnlopt.reduceProblem(problem, opts) returns a problem
%   equivalent to PROBLEM in the free variables only, using
%
%       x = E*xr + xF,     E = I(:, free),   xF(fixed) = lb(fixed), xF(free) = 0
%
%   together with the map FX that EXPANDRESULT uses to carry the solution,
%   gradient, Hessian and multipliers back to the full space. OPTS is returned
%   with JacobPattern/HessPattern sub-selected and HessianFcn wrapped, since
%   those three see the variable vector directly.
%
%   WHY THIS IS NOT OPTIONAL.  A variable with lb(i) == ub(i) has no interior,
%   so the log-barrier term is undefined there: x(i)-lb(i) == 0 makes the bound
%   dual zL(i) = mu/(x(i)-lb(i)) infinite and the KKT matrix fills with Inf-Inf.
%   That used to surface as x = [NaN NaN] returned with EXITFLAG 1 -- a
%   converged status on an all-NaN answer.  Eliminating the variable is the only
%   treatment that neither perturbs the solution nor evaluates outside the box:
%   widening the bound by +-eps would do both, and would break the promise
%   opts.HonorBounds exists to keep.  There is therefore no option to disable
%   this; when nothing is fixed the reduction is the identity (fx.applied =
%   false) and PR is the input struct unchanged, so ordinary problems are
%   bit-for-bit unaffected.
%
%   LINEAR ROWS.  Substituting the fixed values shifts the right-hand sides:
%   A*x <= b becomes A(:,free)*xr <= b - A(:,fixed)*xF (likewise Aeq/beq).  A row
%   that involved ONLY fixed variables becomes all-zero and is then either
%     - inconsistent (0 == nonzero, or 0 <= negative): the problem is infeasible
%       for reasons no free variable can fix, so this errors rather than letting
%       the solver grind to a local-infeasibility exit with an obscure message;
%     - or trivially satisfied, in which case it is DROPPED.  Keeping a 0 == 0
%       row would leave JE rank-deficient, which this solver's Schur complement
%       is measurably sensitive to.  fx.keepEqLin/keepIneqLin record the drops so
%       EXPANDRESULT can re-insert zero multipliers at those rows.
%
%   Inputs:
%     problem - validated problem struct (see VALIDATEPROBLEM); needs fields
%               objFun, hasObjGrad, nlcon, hasConGrad, Aineq/bineq,
%               Aeqlin/beqlin, lb, ub, x0, n, mInl, mEnl.
%     opts    - resolved options struct.
%
%   Outputs:
%     pr   - reduced problem struct (n = nr, all bounds strictly ordered).
%            Equal to PROBLEM when nothing is fixed.
%     fx   - reduction map with fields:
%              applied   - logical; false when no variable is fixed.
%              free,fixed- n-by-1 logicals partitioning the variables.
%              idxFree, idxFixed - the same as indices.
%              xF        - nFixed-by-1 fixed values (= lb(fixed)).
%              xFull     - n-by-1 template with the fixed values in place.
%              n, nr, nFixed - full / reduced / eliminated counts.
%              keepEqLin, keepIneqLin - logicals over the ORIGINAL linear rows.
%              nDropEqLin, nDropIneqLin - counts of rows dropped as vacuous.
%     opts - OPTS with JacobPattern(:,free), HessPattern(free,free) and a
%            HessianFcn wrapped to take/return reduced quantities.
%
%   See also EXPANDRESULT, VALIDATEPROBLEM, SCALEPROBLEM, SOLVE.

n  = problem.n;
lb = problem.lb(:);
ub = problem.ub(:);

fixed = isfinite(lb) & isfinite(ub) & (lb == ub);   % exact: see the note below
free  = ~fixed;

fx = struct();
fx.applied   = any(fixed);
fx.free      = free;
fx.fixed     = fixed;
fx.idxFree   = find(free);
fx.idxFixed  = find(fixed);
fx.n         = n;
fx.nr        = nnz(free);
fx.nFixed    = nnz(fixed);
fx.xF        = lb(fixed);
fx.xFull     = zeros(n, 1);  fx.xFull(fixed) = lb(fixed);
fx.keepEqLin    = true(size(problem.Aeqlin, 1), 1);
fx.keepIneqLin  = true(size(problem.Aineq,  1), 1);
fx.nDropEqLin   = 0;
fx.nDropIneqLin = 0;

if ~fx.applied
    pr = problem;
    return;
end

% The lb == ub test is deliberately EXACT.  A tolerance would silently convert a
% caller's narrow-but-genuine box into a fixed variable and return a different
% problem's answer; a narrow box is a normal bounded variable, and keeping the
% finite-difference probes inside it is exactly what opts.HonorBounds handles.

% x0 at a fixed coordinate must BE the fixed value.  With HonorBounds on,
% validateProblem has already clipped it there, so this only fires when the
% caller turned that off and started away from their own fix.
x0 = problem.x0(:);
off = fixed & (x0 ~= lb);
if any(off)
    [worst, k] = max(abs(x0(off) - lb(off)));
    idx = find(off);
    warning('adamnlopt:fixedVariableX0', ...
            ['x0 disagrees with the fixed value lb == ub in %d component(s); ' ...
             'the fixed value is used (largest disagreement %g, at index %d).'], ...
            nnz(off), worst, idx(k));
end

pr = problem;
pr.n  = fx.nr;
pr.x0 = x0(free);
pr.lb = lb(free);
pr.ub = ub(free);

% --- Objective and nonlinear constraint handles ---
% The user's functions always see the FULL-length vector; only the derivative
% rows they return are sub-selected (fmincon's gradient convention is n-by-m, so
% variables index the ROWS of gc/gceq).
f0 = problem.objFun;
if problem.hasObjGrad
    pr.objFun = @(xr) reducedObjWithGrad(f0, xr, fx);
else
    pr.objFun = @(xr) f0(expand(xr, fx));
end
if ~isempty(problem.nlcon)
    c0 = problem.nlcon;
    if problem.hasConGrad
        pr.nlcon = @(xr) reducedConWithGrad(c0, xr, fx);
    else
        pr.nlcon = @(xr) reducedCon(c0, xr, fx);
    end
end

% --- Linear rows: column sub-select, RHS shift, vacuous-row handling ---
[pr.Aineq, pr.bineq, fx.keepIneqLin] = reduceLinear( ...
    problem.Aineq, problem.bineq, fx, 'ineq');
[pr.Aeqlin, pr.beqlin, fx.keepEqLin] = reduceLinear( ...
    problem.Aeqlin, problem.beqlin, fx, 'eq');
fx.nDropIneqLin = nnz(~fx.keepIneqLin);
fx.nDropEqLin   = nnz(~fx.keepEqLin);

% --- Options that address variables directly ---
if isfield(opts, 'JacobPattern') && ~isempty(opts.JacobPattern) && ...
        size(opts.JacobPattern, 2) == n
    opts.JacobPattern = opts.JacobPattern(:, free);
end
if isfield(opts, 'HessPattern') && ~isempty(opts.HessPattern) && ...
        all(size(opts.HessPattern) == [n n])
    opts.HessPattern = opts.HessPattern(free, free);
end
if isfield(opts, 'HessianFcn') && ~isempty(opts.HessianFcn)
    % The user's Hessian handle is the one place their code sees the variable
    % vector DURING the solve rather than at entry/exit, so the wrap has to be
    % live.  Nonlinear constraint multipliers are passed through untouched --
    % only linear rows are ever dropped, and lagrangianHessian supplies just
    % eqnonlin/ineqnonlin.
    %
    % Known pre-existing gap, unrelated to this reduction: scaleProblem does NOT
    % wrap HessianFcn, so an explicit Hessian is already inconsistent with
    % autoScale ~= 'none'.  Reducing before scaling keeps this wrapper in the
    % same (unscaled) space the handle was written for, so it neither causes nor
    % worsens that.
    H0 = opts.HessianFcn;
    opts.HessianFcn = @(xr, lam) reducedHess(H0, xr, lam, fx);
end
end

% ------------------------------------------------------------------------
function x = expand(xr, fx)
%EXPAND  Full-length variable vector from the reduced one.
x = fx.xFull;
x(fx.free) = xr(:);
end

function [f, g] = reducedObjWithGrad(f0, xr, fx)
%REDUCEDOBJWITHGRAD  Objective and free-variable gradient rows.
[f, g] = f0(expand(xr, fx));
g = g(:);
g = g(fx.free);
end

function [c, ceq] = reducedCon(c0, xr, fx)
%REDUCEDCON  Nonlinear constraint values at the expanded point.
[c, ceq] = c0(expand(xr, fx));
end

function [c, ceq, gc, gceq] = reducedConWithGrad(c0, xr, fx)
%REDUCEDCONWITHGRAD  Constraint values and free-variable gradient rows.
[c, ceq, gc, gceq] = c0(expand(xr, fx));
if ~isempty(gc),   gc   = gc(fx.free, :);   end
if ~isempty(gceq), gceq = gceq(fx.free, :); end
end

function H = reducedHess(H0, xr, lam, fx)
%REDUCEDHESS  Free-variable block of the user's Lagrangian Hessian.
H = H0(expand(xr, fx), lam);
H = H(fx.free, fx.free);
end

function [Ar, br, keep] = reduceLinear(A, b, fx, kind)
%REDUCELINEAR  Column-reduce a linear block, shift its RHS, drop vacuous rows.
%   Rows left with no free variable are checked for consistency: an inconsistent
%   one errors (nothing the solver can do makes it hold), a satisfied one is
%   dropped so it cannot rank-deficiency the KKT system.
%
%   Inputs:
%     A, b - the original linear block (may be 0-by-n / 0-by-1).
%     fx   - reduction map (free/fixed masks and xF).
%     kind - 'eq' (row is 0 == br) or 'ineq' (row is 0 <= br).
%
%   Outputs:
%     Ar, br - reduced block over the kept rows.
%     keep   - logical over the ORIGINAL rows; false where dropped.
m = size(A, 1);
keep = true(m, 1);
if m == 0
    Ar = zeros(0, fx.nr);  br = zeros(0, 1);  return;
end

shift = A(:, fx.fixed) * fx.xF;
Ar = A(:, fx.free);
br = b(:) - shift;

vacuous = ~any(Ar ~= 0, 2);
if ~any(vacuous)
    return;
end

% Tolerance is relative to the magnitudes that went into the subtraction, so a
% large-but-cancelling row is not called infeasible over round-off.
scaleRow = max(1, abs(b(:)) + abs(A(:, fx.fixed)) * abs(fx.xF));
tol = 1e-10 * scaleRow;
if strcmp(kind, 'eq')
    bad = vacuous & (abs(br) > tol);
    relation = '==';
else
    bad = vacuous & (br < -tol);
    relation = '<=';
end
if any(bad)
    k = find(bad, 1);
    error('adamnlopt:fixedInfeasible', ...
          ['Linear %sconstraint row %d involves only fixed variables and is ' ...
           'violated by their values: it reduces to 0 %s %g.  No choice of the ' ...
           'free variables can satisfy it.'], ...
          ternary(strcmp(kind,'eq'), 'equality ', 'inequality '), k, relation, br(k));
end

keep = ~vacuous;
Ar = Ar(keep, :);
br = br(keep);
end

function s = ternary(cond, a, b)
%TERNARY  Select one of two values (keeps the error call on one line).
if cond, s = a; else, s = b; end
end
