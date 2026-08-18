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
%   Detection is via a tolerance on singular values (rank), scaled by the
%   largest singular value so it is invariant to constraint scaling.
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

% Active constraint Jacobian and LICQ.
Aact = [JE; JI(active, :)];
if isempty(Aact)
    flags.rankActive = 0;
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
%MATRIXRANK  Numerical rank of A from its singular values.
%   r = matrixRank(A) counts the singular values of A that exceed a tolerance
%   scaled by the largest singular value, giving a scale-invariant rank. Returns
%   0 for an empty matrix.
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
s = svd(full(A));
tol = max(size(A)) * eps(max(s));
r = sum(s > max(tol, 1e-12 * max(s)));
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
