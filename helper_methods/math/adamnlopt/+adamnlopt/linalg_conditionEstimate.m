function c = linalg_conditionEstimate(A, nMax)
%LINALG_CONDITIONESTIMATE Cheap 2-norm condition estimate of the KKT system.
%   c = adamnlopt.linalg_conditionEstimate(A) estimates cond_2(K). A may be a
%   numeric matrix or an operator struct with an .apply handle. For a
%   matrix, MATLAB's condest (sparse) or cond (dense) is used. For an operator
%   small enough to materialize, K is rebuilt one column at a time and the
%   numeric path is used; above that size the answer is NaN, meaning "not
%   available", which a caller must not read as a small condition number.
%
%   WHY NOT LANCZOS.  This function used to run a 20-step symmetric Lanczos on
%   the operator and return max|theta| / min|theta| over the Ritz values,
%   documented as "a diagnostic lower bound".  For an indefinite KKT matrix it
%   is not a bound in either direction.  The Ritz values interlace inside
%   [lambda_min, lambda_max], an interval that STRADDLES ZERO for a saddle-point
%   system, so a Ritz value can land arbitrarily close to 0 on a perfectly
%   well-conditioned K (unbounded overestimate), while max|theta| <= ||K||_2
%   always (underestimate of the numerator).  The product of the two errors has
%   no sign.  A number used to trigger regularization cannot be one that is
%   wrong in an unknown direction, so the branch no longer produces one.
%
%   Inputs:
%     A    - either a numeric (dense or sparse) KKT matrix, or an operator
%            struct exposing A.apply plus dimensions A.n and A.mE.
%     nMax - (optional) largest operator dimension that will be materialized;
%            defaults to 500.  Materializing costs n mat-vecs.
%
%   Outputs:
%     c - estimated 2-norm condition number cond_2(K); NaN when A is an
%         operator too large to materialize.
%
%   See also LINALG_SOLVEKKTDIRECT, KKT_INERTIACORRECTION.

if nargin < 2 || isempty(nMax), nMax = 500; end

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

% Matrix-free.  This branch has no caller today: the sole caller of this
% function, traceCondK, passes the matrix from kkt_assemble, which always
% returns a numeric K.  It exists so the operator path is safe if it is ever
% wired up.
n = A.n + A.mE;
if n > nMax
    c = NaN;                    % honest "unknown", not a fabricated number
    return;
end

% n mat-vecs rebuild K exactly.  Expensive, but this is a traceLevel-2
% diagnostic, and an exact condition number beats an unsigned-error estimate.
K = zeros(n, n);
e = zeros(n, 1);
for j = 1:n
    e(j) = 1;
    K(:, j) = A.apply(e);
    e(j) = 0;
end
c = adamnlopt.linalg_conditionEstimate(K);
end
