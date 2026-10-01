function flags = degeneracy_detectDegeneracy(state, opts)
%DEGENERACY_DETECTDEGENERACY Detect constraint degeneracy at the current iterate.
%   flags = adamnlopt.degeneracy_detectDegeneracy(state, opts) inspects the
%   equality Jacobian JE and the active inequality Jacobian to report common
%   degeneracies that break the standard regularity (LICQ / strict
%   complementarity) assumptions and would otherwise stall a Newton-KKT solve:
%
%     .rankE        rank of JE
%     .linDepE      true if JE has linearly dependent rows (rank < mE)
%     .rankActive   rank of the active Jacobian [JE; JI(active,:)]
%     .linDepActive true if the active set violates LICQ (rank < #active)
%     .active       logical index of active inequalities (|cI| <= feasTol)
%     .weaklyActive logical index of active inequalities with near-zero
%                   multiplier (strict complementarity failure)
%     .degenerate   true if any of the above degeneracies is present
%
%   Detection is via a tolerance on the pivoted-QR diagonal (rank), scaled by
%   its largest entry so it is invariant to constraint scaling.
%
%   NOTE ON WHAT ROUTES THE STEP.  Only .linDepE and .linDepActive do;
%   degeneracy_detectStep reads nothing else.  .weaklyActive and .degenerate
%   are reported for the trace and for callers, and .degenerate is deliberately
%   the BROADER condition -- it also fires on a strict-complementarity failure,
%   which the degenerate-step route does not address.  They are diagnostics,
%   not switches; do not swap one in for the routing test.
%
%   Inputs:
%     state - iterate struct; uses fields x (current point), JE (mE-by-n
%             equality Jacobian), JI (mI-by-n inequality Jacobian), cI (mI-by-1
%             inequality values) and lamI (mI-by-1 inequality multipliers).
%             Missing/empty fields default to empty.
%     opts  - options struct; uses opts.feasTol, the feasibility tolerance used
%             to decide which inequalities are active.
%
%   Outputs:
%     flags - struct of degeneracy diagnostics with the fields listed above
%             (rankE, linDepE, rankActive, linDepActive, active, weaklyActive,
%             degenerate) plus n, the problem dimension.
%
%   See also DEGENERACY_DROPCONSTRAINTS, DEGENERACY_REGULARIZEDRECOVERY.

feasTol = opts.feasTol;

JE = getf(state, 'JE', zeros(0,0));
JI = getf(state, 'JI', zeros(0,0));
cI = getf(state, 'cI', zeros(0,1));
lamI = getf(state, 'lamI', zeros(0,1));

n = numel(state.x);
mE = size(JE, 1);

flags = struct();

% Equality Jacobian rank.
flags.rankE = matrixRank(JE);
flags.linDepE = flags.rankE < mE;

% Active inequality set (|cI| within feasibility tolerance of the boundary).
if isempty(cI)
    active = false(0,1);
else
    active = abs(cI) <= max(feasTol, 1e-8);
end
flags.active = active;

% Active constraint Jacobian and LICQ.  With no active inequality the active
% Jacobian IS JE, so the second factorization was re-deriving a rank that had
% just been computed -- and on an inequality-free problem that is every
% iteration of the solve.
Aact = [JE; JI(active, :)];
if isempty(Aact)
    flags.rankActive = 0;
elseif ~any(active)
    flags.rankActive = flags.rankE;
else
    flags.rankActive = matrixRank(Aact);
end
flags.linDepActive = flags.rankActive < size(Aact, 1);

% Weakly active inequalities: active but with a vanishing multiplier.
weak = false(size(active));
if ~isempty(lamI) && any(active)
    lamScale = max(1, norm(lamI, inf));
    weak = active & (abs(lamI) <= 1e-6 * lamScale);
end
flags.weaklyActive = weak;

flags.degenerate = flags.linDepE || flags.linDepActive || any(weak);
flags.n = n;
end

function r = matrixRank(A)
%MATRIXRANK  Numerical rank of A from a column-pivoted QR.
%   r = matrixRank(A) counts the entries of |diag(R)| from a column-pivoted QR
%   of A that exceed a tolerance scaled by the largest of them, giving a
%   scale-invariant rank. Returns 0 for an empty matrix.
%
%   This used to be a full SVD, and degeneracy detection runs every iteration,
%   so each solver step paid for up to two complete singular value
%   decompositions of the constraint Jacobian to answer two integer rank
%   questions.  Pivoted QR answers the same questions for a fraction of the
%   work and is what DEGENERACY_DROPCONSTRAINTS and STEP_TANGENTIALSTEP already
%   use elsewhere in the package, so the three now agree on what "rank" means.
%   It is the slightly weaker test -- a contrived near-dependency can defeat the
%   pivoting that would show up in the singular values -- which is the right
%   trade for a per-iteration heuristic that only routes the step.
%
%   Inputs:
%     A - matrix whose numerical rank is wanted.
%
%   Outputs:
%     r - numerical rank of A.
if isempty(A)
    r = 0;
    return;
end
[~, R, ~] = qr(full(A), 'vector');   % pivoted: |diag(R)| decays, rank-revealing
p  = min(size(R));
dR = abs(diag(R(1:p, 1:p)));
if isempty(dR)
    r = 0;
    return;
end
dmax = max(dR);
tol  = max(size(A)) * eps(dmax);
r    = sum(dR > max(tol, 1e-12 * dmax));
end

function v = getf(s, f, dflt)
%GETF  Fetch a struct field with a default fallback.
%   v = getf(s, f, dflt) returns s.(f) when the field exists and is nonempty,
%   otherwise the default dflt.
%
%   Inputs:
%     s    - struct to read from.
%     f    - field name (char) to fetch.
%     dflt - value returned when the field is absent or empty.
%
%   Outputs:
%     v - the field value or the default.
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = dflt;
end
end
