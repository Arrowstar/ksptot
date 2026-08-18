function problem = validateProblem(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, opts)
%VALIDATEPROBLEM  Normalize fmincon-style inputs into an internal problem struct.
%   problem = adamnlopt.validateProblem(fun, x0, A, b, Aeq, beq, lb, ub,
%   nonlcon, opts) checks sizes/finiteness, expands bounds, probes nonlcon at
%   x0 to count nonlinear constraints, and packages everything the Evaluator
%   needs into a single struct.
%
%   x0 is forced to a column vector and validated as finite numeric; fun must
%   be a function handle. Linear (A,b) and (Aeq,beq) pairs and the bounds
%   (lb,ub) are checked and expanded by the local helpers. When opts.HonorBounds
%   is true, x0 is then clipped into [lb,ub] BEFORE nonlcon is probed. When
%   nonlcon is a handle it is evaluated once at x0 to determine the number of
%   nonlinear inequality (mInl) and equality (mEnl) constraints.
%
%   Inputs:
%     fun     - objective function handle (returns f, or [f,g] with gradient).
%     x0      - initial point; any numeric array, reshaped to n-by-1.
%     A, b    - linear inequality data A*x <= b; A is mI-by-n, b is mI-by-1.
%               Both empty means no linear inequalities.
%     Aeq,beq - linear equality data Aeq*x = beq; Aeq is mEq-by-n, beq mEq-by-1.
%               Both empty means no linear equalities.
%     lb, ub  - lower/upper bounds; empty, scalar, or n-by-1. Expanded to n-by-1
%               with -Inf/+Inf fill for missing bounds.
%     nonlcon - nonlinear constraint handle returning [c, ceq] (and optionally
%               gradients), or [] for none.
%     opts    - options struct; SpecifyObjectiveGradient and
%               SpecifyConstraintGradient set the has*Grad flags.
%
%   Outputs:
%     problem - struct with fields objFun, hasObjGrad, nlcon, hasConGrad,
%               Aineq/bineq, Aeqlin/beqlin, lb, ub, x0, n, mInl, mEnl.
%
%   See also DEFAULTOPTIONS, MAPOPTIONS, INITIALIZEITERATE.

x0 = x0(:);
n = numel(x0);
if ~isnumeric(x0) || ~all(isfinite(x0))
    error('adamnlopt:x0', 'x0 must be a finite numeric vector.');
end
if ~isa(fun, 'function_handle')
    error('adamnlopt:fun', 'Objective FUN must be a function handle.');
end

[A, b]       = checkLinear(A, b, n, 'A', 'b');
[Aeq, beq]   = checkLinear(Aeq, beq, n, 'Aeq', 'beq');
[lb, ub]     = checkBounds(lb, ub, n);

% Clip x0 into the box before ANY user function is called.  initializeIterate
% projects x0 strictly inside the bounds, but only after solve() has already
% evaluated the objective and nonlcon at the raw x0 -- here for the constraint
% count, then again in computeScaling and Evaluator.calibrateStep.  An x0 the
% caller left outside the box therefore reached fun/nonlcon on every one of those
% paths (tHohmannTransfer's z0(1) sits 0.027 over ub(1), which is the true origin
% of the out-of-bounds evaluations that test's comment blames on the iterates).
% Warn rather than error: an out-of-box x0 is a common, recoverable modelling
% slip, and silently moving the caller's starting point would be worse.
if opts.HonorBounds
    xc = min(max(x0, lb), ub);
    moved = find(xc ~= x0);
    if ~isempty(moved)
        [worst, k] = max(abs(xc(moved) - x0(moved)));
        warning('adamnlopt:x0OutOfBounds', ...
                ['x0 violates the bounds in %d component(s) and has been clipped ' ...
                 'into [lb,ub] (largest move %g, at index %d).  Set ' ...
                 'opts.HonorBounds = false to evaluate at the original x0.'], ...
                numel(moved), worst, moved(k));
        x0 = xc;
    end
end

if ~isempty(nonlcon)
    if ~isa(nonlcon, 'function_handle')
        error('adamnlopt:nonlcon', 'NONLCON must be a function handle or [].');
    end
    [c0, ceq0] = nonlcon(x0);
    mInl = numel(c0);
    mEnl = numel(ceq0);
else
    mInl = 0;  mEnl = 0;
end

problem = struct();
problem.objFun     = fun;
problem.hasObjGrad = logical(opts.SpecifyObjectiveGradient);
problem.nlcon      = nonlcon;
problem.hasConGrad = ~isempty(nonlcon) && logical(opts.SpecifyConstraintGradient);
problem.Aineq  = A;    problem.bineq  = b;
problem.Aeqlin = Aeq;  problem.beqlin = beq;
problem.lb = lb;       problem.ub = ub;
problem.x0 = x0;       problem.n = n;
problem.mInl = mInl;   problem.mEnl = mEnl;
end

function [M, v] = checkLinear(M, v, n, nameM, namev)
%CHECKLINEAR  Validate and normalize a linear constraint (matrix, vector) pair.
%   Errors unless the pair is both-empty or both-given, M has n columns, and
%   its row count matches numel(v). Empty pairs become 0-by-n / 0-by-1.
%
%   Inputs:
%     M     - constraint matrix (mrows-by-n) or empty.
%     v     - right-hand-side vector or empty; forced to a column.
%     n     - number of optimization variables (required column count of M).
%     nameM - char name of M used in error messages (e.g. 'A').
%     namev - char name of v used in error messages (e.g. 'b').
%
%   Outputs:
%     M - validated matrix, 0-by-n when the pair was empty.
%     v - validated column vector, 0-by-1 when the pair was empty.
if isempty(M) && isempty(v)
    M = zeros(0, n);  v = zeros(0, 1);  return;
end
if isempty(M) ~= isempty(v)
    error('adamnlopt:linear', '%s and %s must both be given or both empty.', nameM, namev);
end
if size(M, 2) ~= n
    error('adamnlopt:linear', '%s must have %d columns.', nameM, n);
end
v = v(:);
if size(M, 1) ~= numel(v)
    error('adamnlopt:linear', '%s rows must match numel(%s).', nameM, namev);
end
end

function [lb, ub] = checkBounds(lb, ub, n)
%CHECKBOUNDS  Expand and validate lower/upper bound vectors.
%   Expands lb/ub to n-by-1 (with -Inf/+Inf fill) and errors if any lb > ub.
%
%   Inputs:
%     lb - lower bounds; empty, scalar, or n-by-1.
%     ub - upper bounds; empty, scalar, or n-by-1.
%     n  - number of optimization variables.
%
%   Outputs:
%     lb - n-by-1 lower bounds (-Inf where unspecified).
%     ub - n-by-1 upper bounds (+Inf where unspecified).
lb = expandBound(lb, n, -Inf, 'lb');
ub = expandBound(ub, n,  Inf, 'ub');
if any(lb > ub)
    error('adamnlopt:bounds', 'Each lb must be <= ub.');
end
% lb(i) == ub(i) fixes variable i.  The interior-point core cannot represent one
% (the barrier needs a non-empty interior, and with x-lb == 0 the bound dual
% zL/(x-lb) is Inf, so the KKT matrix fills with Inf-Inf), which used to surface
% as x = [NaN NaN] returned with EXITFLAG 1 -- a converged status on an all-NaN
% answer.  Fixed variables are now ELIMINATED before the solve rather than
% rejected here: see reduceProblem/expandResult, called from solve.  Validation
% only has to let lb == ub through, so there is no check at this point; lb > ub
% above remains an error.
end

function v = expandBound(v, n, fillval, name)
%EXPANDBOUND  Expand a scalar/empty bound to an n-by-1 vector.
%   Returns fillval*ones(n,1) when v is empty, replicates a scalar to length n,
%   and passes an n-by-1 vector through; errors on any other length.
%
%   Inputs:
%     v       - bound value; empty, scalar, or n-by-1.
%     n       - target length.
%     fillval - value used to fill when v is empty (-Inf or +Inf).
%     name    - char name of the bound for error messages.
%
%   Outputs:
%     v - n-by-1 bound vector.
if isempty(v)
    v = fillval * ones(n, 1);  return;
end
v = v(:);
if isscalar(v)
    v = v * ones(n, 1);
elseif numel(v) ~= n
    error('adamnlopt:bounds', '%s must be scalar, empty, or length %d.', name, n);
end
end
