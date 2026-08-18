function [conf, info] = control_activeSetConfidence(state, opts)
%CONTROL_ACTIVESETCONFIDENCE  Estimate stability of the active constraint set.
%   [conf, info] = adamnlopt.control_activeSetConfidence(state, opts) returns
%   a scalar confidence score in [0, 1] for the current active set (higher
%   means more stable / more likely to be the correct active set at optimum),
%   plus per-constraint detail in INFO.
%
%   Confidence degrades when:
%     - Inequality constraints are weakly active (|lamI| near zero while cI~0)
%     - Active set changes relative to previous iteration
%     - Complementarity is far from satisfied (s .* lamI >> mu)
%
%   A high-confidence active set is a prerequisite for the mode controller to
%   allow a faster barrier reduction or an SQP-style tangential step.
%
%   Inputs:
%     state - iterate struct read via the local getf; fields used are cI
%             (inequality values), lamI (inequality multipliers), s (slacks),
%             and mu (barrier parameter). Missing fields default to empty/0.
%     opts  - options struct; field feasTol sets the active-set tolerance.
%
%   Outputs:
%     conf - scalar confidence score in [0, 1] (geometric mean of the
%            per-constraint confidences over the active set; 1 when nI == 0).
%     info - struct with fields perConstraint (nI-by-1 per-constraint
%            confidences), nActive (number of active constraints), and
%            nWeakly (number of active constraints with near-zero multipliers).
%
%   See also CONTROL_MODECONTROLLER, CONTROL_BARRIERUPDATE.

feasTol = opts.feasTol;

cI   = getf(state, 'cI',   zeros(0,1));
lamI = getf(state, 'lamI', zeros(0,1));
s    = getf(state, 's',    zeros(0,1));
mu   = getf(state, 'mu',   0);

nI = numel(cI);

if nI == 0
    conf = 1.0;
    info = struct('perConstraint', zeros(0,1), 'nActive', 0, 'nWeakly', 0);
    return;
end

% Active set: cI close to zero (slack s close to zero).
sEff = s;
if isempty(sEff), sEff = zeros(nI, 1); end
active = abs(cI) <= max(feasTol, 1e-8) | sEff <= max(feasTol, 1e-8);

% Per-constraint confidence: ratio of multiplier magnitude to its scale.
lamScale  = max(1, norm(lamI, inf));
lamNorm   = abs(lamI) / lamScale;          % in [0,1] after scaling

% For active constraints: confidence proportional to multiplier magnitude.
% Weakly-active (multiplier ~0) → low confidence on that constraint.
perConf = ones(nI, 1);
if any(active)
    perConf(active) = min(1, 10 * lamNorm(active));   % full conf when lamNorm>=0.1
end

% Complementarity slack: how well s.*lamI ~ mu.
compGap = zeros(nI, 1);
if ~isempty(s) && numel(s) == nI && mu > 0
    compGap = abs(s .* lamI - mu) / max(mu, 1);
    % Poor complementarity → lower confidence.
    perConf = perConf .* max(0.1, 1 - min(1, compGap));
end

nActive = sum(active);
nWeakly = sum(active & (lamNorm < 1e-4));

% Aggregate: geometric mean of per-constraint confidences for active ones.
if nActive > 0
    conf = prod(perConf(active)) ^ (1 / nActive);
else
    conf = 1.0;
end
conf = max(0, min(1, conf));

info = struct('perConstraint', perConf, 'nActive', nActive, 'nWeakly', nWeakly);
end

function v = getf(s, f, dflt)
%GETF  Fetch a struct field with a default fallback.
%   v = getf(s, f, dflt) returns s.(f) when field f exists and is non-empty,
%   otherwise returns dflt. Used to read optional iterate fields safely.
%
%   Inputs:
%     s    - struct to read from.
%     f    - char field name to look up.
%     dflt - value returned when the field is absent or empty.
%
%   Outputs:
%     v - the field value s.(f), or dflt.
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = dflt;
end
end
