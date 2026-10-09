function [lamE, lamI, zL, zU, mu, ok] = initWarmStart(lambda0, muWarmOpt, muCold, fx, sc, ev, s)
%INITWARMSTART  Map a fmincon-style warm-start multiplier struct onto the
%   reduced, scaled core space (A3).
%   lambda0 is in the caller's physical units over the FULL problem indexing
%   (fields eqlin/eqnonlin/ineqlin/ineqnonlin/lower/upper, exactly as
%   adamnlopt.solve returns it), so LVD can replay a previous run's lambda
%   after small edits.  Dropped linear rows are removed, fixed variables are
%   selected out, and the survivors are converted by the inverse of
%   unscaleResult (lamE_s = lamE.*wf./Dc, lamI_s = lamI.*wf./Di,
%   z_s = z.*Dx.*wf).  Inequality multipliers are floored at 1e-8 and bound
%   multipliers at 0.  mu is muWarmOpt when given and positive, else
%   max(muCold, mean(s.*lamI)) -- pass the core's cold mu as muCold
%   (mu0 in the IP core; [] when the caller ignores mu, as the equality core
%   does).  Any shape mismatch returns ok = false with empty outputs, and the
%   caller falls back to the cold start: a stale warm start must never fail
%   -- or silently perturb -- a solve.
%
%   Inputs:
%     lambda0   - multiplier struct in physical, full-space units, or [].
%     muWarmOpt - barrier seed (opts.muWarm), or [] to derive from complementarity.
%     muCold    - cold-start mu (floor when deriving); [] if mu is not used.
%     fx        - fixed-variable reduction map from REDUCEPROBLEM (needs n,
%                 free, keepEqLin, keepIneqLin).
%     sc        - scaling struct from COMPUTESCALING (needs Dx, Dc, Di, wf).
%     ev        - working Evaluator (needs n, mE, mI, mEnl, mInl counts).
%     s         - fresh inequality slacks at the (new) x0, for the mu mean.
%
%   Outputs:
%     lamE, lamI, zL, zU - mapped multipliers in scaled, reduced space.
%     mu      - barrier seed (muCold-derived when s/lamI are empty).
%     ok      - logical; false on any mismatch (outputs then empty).
%
%   See also INITIALIZEITERATE, UNSCALERESULT, REDUCEPROBLEM.

lamE = []; lamI = []; zL = []; zU = []; mu = []; ok = false;
if ~isstruct(lambda0) || isempty(fx) || ~isfield(fx, 'free') || ...
        isempty(sc) || ~isfield(sc, 'Dx')
    return;
end
lamEfull = getCol(lambda0, 'eqlin');
lamEfull = [lamEfull; getCol(lambda0, 'eqnonlin')];
lamIfull = getCol(lambda0, 'ineqlin');
lamIfull = [lamIfull; getCol(lambda0, 'ineqnonlin')];
zLf = getCol(lambda0, 'lower');
zUf = getCol(lambda0, 'upper');

nFull     = fx.n;
nElinFull = numel(fx.keepEqLin);
nIlinFull = numel(fx.keepIneqLin);
if numel(lamEfull) ~= nElinFull + ev.mEnl, return; end
if numel(lamIfull) ~= nIlinFull + ev.mInl, return; end
if numel(zLf) ~= nFull || numel(zUf) ~= nFull, return; end

lamEr = [lamEfull(logical(fx.keepEqLin)); ...
         lamEfull(nElinFull+1:end)];
lamIr = [lamIfull(logical(fx.keepIneqLin)); ...
         lamIfull(nIlinFull+1:end)];
zLr = zLf(fx.free);
zUr = zUf(fx.free);

Dc = sc.Dc(:);  Di = sc.Di(:);  Dx = sc.Dx(:);  wf = sc.wf;
if numel(Dc) ~= ev.mE || numel(Di) ~= ev.mI || numel(Dx) ~= ev.n, return; end
if ~all(isfinite([Dc; Di; Dx])) || ~all(Dc > 0) || ~all(Di > 0) || ...
        ~all(Dx > 0) || ~isfinite(wf) || wf <= 0
    return;
end

lamE = lamEr .* (wf ./ Dc);
lamI = max(lamIr, 1e-8);
zL = max(zLr, 0);
zU = max(zUr, 0);

if ~isempty(muWarmOpt) && isfinite(muWarmOpt) && muWarmOpt > 0
    mu = muWarmOpt;
elseif ~isempty(lamI) && numel(s) == numel(lamI)
    muFloor = muCold;
    if isempty(muFloor) || ~isfinite(muFloor), muFloor = 0; end
    mu = max(muFloor, mean(s(:) .* lamI(:)));
else
    mu = muCold;
end
ok = true;
end

function v = getCol(s, name)
%GETCOL  s.(name)(:) as a column, or empty when absent/non-numeric.
v = zeros(0, 1);
if isstruct(s) && isfield(s, name) && isnumeric(s.(name))
    v = s.(name)(:);
end
end
