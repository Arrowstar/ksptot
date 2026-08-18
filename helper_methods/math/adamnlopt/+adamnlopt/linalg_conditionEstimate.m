function c = linalg_conditionEstimate(A, k)
%LINALG_CONDITIONESTIMATE Cheap 2-norm condition estimate of the KKT system.
%   c = adamnlopt.linalg_conditionEstimate(A) estimates cond_2(K). A may be a
%   numeric matrix or a kkt_KKTOperator struct with an .apply handle. For a
%   matrix, MATLAB's condest (sparse) or cond (dense) is used. For an operator,
%   a k-step symmetric Lanczos builds a tridiagonal whose extreme Ritz values
%   approximate the extreme eigenvalues, giving c = max|theta|/min|theta|.
%   The operator estimate is a diagnostic lower bound, not an exact condition
%   number; it is used to trigger regularization, not to certify accuracy.
%
%   Inputs:
%     A - either a numeric (dense or sparse) KKT matrix, or a kkt_KKTOperator
%         struct exposing A.apply plus dimensions A.n and A.mE for the
%         matrix-free Lanczos path.
%     k - (optional) number of Lanczos steps for the operator estimate;
%         defaults to 20 and is capped at the problem dimension.
%
%   Outputs:
%     c - estimated 2-norm condition number cond_2(K). Inf when no nonzero
%         Ritz value is found.
%
%   See also LINALG_SOLVEKKTDIRECT, KKT_INERTIACORRECTION, KKT_KKTOPERATOR.

if nargin < 2 || isempty(k), k = 20; end

if isnumeric(A)
    if issparse(A)
        % CONDEST IS NOT A PURE FUNCTION.  It calls normest1, whose Hager-Higham
        % power iteration draws random start columns from the GLOBAL RNG stream.
        % So a sparse condition estimate both (a) advances the stream, changing
        % every later random draw in the run, and (b) returns a different number
        % each call on the same matrix.  Both were measured directly.
        %
        % This matters because the only caller is traceCondK at traceLevel 2, a
        % pure diagnostic -- and on orbitRaiseTest (sparse JE from multiple
        % shooting, so K is sparse) merely turning the trace on moved the iterates
        % in the 6th digit by iteration 50 and put the run on a completely
        % different trajectory by 100 (feas 4.99e-04 traced vs 1.71e-05 untraced).
        % 1.8 h of run time producing a trace of a solve no untraced run would
        % ever reproduce.  A measurement that perturbs the thing it measures is
        % worse than no measurement, because the output still looks plausible.
        %
        % Save/restore around a fixed seed -- the idiom already used by
        % Evaluator.m and estimateNoise.m -- makes the probe both observational
        % and repeatable, which a condition number in a trace should be.
        s = rng;
        cleanup = onCleanup(@() rng(s));
        rng(42, 'twister');
        c = condest(A);
    else
        c = cond(A);            % deterministic, touches no stream
    end
    return;
end

% Matrix-free: symmetric Lanczos on the operator.
n = A.n + A.mE;
k = min(k, n);
% The Lanczos start vector is drawn from a PRIVATE stream, not the global one,
% for the same observational reason as the condest branch above.  Note this
% branch currently has NO caller: the sole caller of this function, traceCondK,
% passes the matrix from kkt_assemble, which always returns a numeric K.  The
% guard is here so the operator path is safe if it is ever wired up -- it is not
% what fixed the measured orbitRaiseTest perturbation.
v = randn(RandStream('twister', 'Seed', 42), n, 1);
nv = norm(v);
if nv > 0, v = v / nv; end
alpha = zeros(k, 1);  beta = zeros(k, 1);
vPrev = zeros(n, 1);  bPrev = 0;
for j = 1:k
    w = A.apply(v);
    a = v.' * w;
    w = w - a * v - bPrev * vPrev;
    w = w - (w.' * v) * v;          % one reorthogonalization step
    b = norm(w);
    alpha(j) = a;  beta(j) = b;
    if b < 1e-14, k = j; break; end
    vPrev = v;  v = w / b;  bPrev = b;
end
alpha = alpha(1:k);
if k > 1
    off = beta(1:k-1);
    T = diag(alpha) + diag(off, 1) + diag(off, -1);
else
    T = alpha;
end
theta = abs(eig(T));
theta = theta(theta > 0);
if isempty(theta)
    c = Inf;
else
    c = max(theta) / min(theta);
end
end
