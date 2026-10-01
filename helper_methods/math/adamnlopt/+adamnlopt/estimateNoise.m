function [epsf, info] = estimateNoise(fun, x0, dir, ncOpts)
%ESTIMATENOISE  Moré-Wild (2011) ECnoise estimate of a function's noise level.
%   [epsf, info] = adamnlopt.estimateNoise(fun, x0, dir, ncOpts) estimates the
%   computational noise level of a scalar function by sampling it at equally
%   spaced points along a line through x0 and analysing the finite-difference
%   table (Moré & Wild, "Estimating Computational Noise", SIAM J. Sci. Comput.
%   33(3), 2011). The noise level is the amplitude of the non-smooth part of
%   fun (e.g. the error floor of an ODE integrator or an iterative solver), and
%   is what determines the optimal finite-difference step: h ~ sqrt(epsf) for
%   forward differences, epsf^(1/3) for central.
%
%   The estimate is robust to the sampling spacing across roughly two orders of
%   magnitude; when the initial spacing is too large (the smooth trend
%   dominates) or too small (every sample is identical) the method reports which
%   way to adjust and one automatic retry is attempted before giving up.
%
%   Inputs:
%     fun    - function handle @(x) returning a scalar.
%     x0     - n-by-1 base point.
%     dir    - n-by-1 sampling direction; [] draws a seeded random unit vector
%              (the global RNG stream is saved and restored, so calibration does
%              not perturb any downstream randomness).
%     ncOpts - struct with optional fields:
%                nPts        - number of samples (default 7; odd, 6-8 typical).
%                baseSpacing - line spacing h ([] -> 1e-3*max(1,norm(x0))).
%
%   Outputs:
%     epsf - estimated noise level; 0 when noise could not be detected.  Check
%            info.detected before reading anything into a zero: it is also what
%            an inconclusive or failed probe returns.
%     info - struct with fields:
%              epsf     - the returned noise level.
%              detected - true only when the table actually resolved a noise
%                         level.  Every other flag returns epsf = 0, and a
%                         caller that cannot tell "measured as clean" from
%                         "could not measure" will silently trust a default
%                         step on a function it never characterised.
%              flag     - 'noise'        (detected),
%                         'inconclusive' (two spacings apart, the smooth trend
%                                         still dominates: either a genuinely
%                                         analytic-precision function or a
%                                         spacing more than 1e4 too large --
%                                         two attempts cannot separate these),
%                         'flat'         (spacing too small, could not
%                                         converge),
%                         'error'        (an evaluation threw).
%              hUsed    - the spacing the returned result was SAMPLED at, not
%                         the one the next retry would have used.
%              levels   - per-level noise estimates sigma_k.
%              nEvals   - number of evaluations of fun consumed.
%
%   See also FINITEDIFFGRADIENT, ECNOISECORE, COMPUTESCALING.

if nargin < 4 || isempty(ncOpts), ncOpts = struct(); end
nf = getfield_default(ncOpts, 'nPts', 7);
if mod(nf, 2) == 0, nf = nf + 1; end        % keep odd so x0 is centred
nf = max(nf, 4);                            % need at least a few differences

x0 = x0(:);
n  = numel(x0);

info = struct('epsf', 0, 'detected', false, 'flag', 'inconclusive', ...
              'hUsed', 0, 'levels', zeros(0,1), 'nEvals', 0);
epsf = 0;

% --- Sampling direction (seeded random unit vector when not supplied) ---
if nargin < 3 || isempty(dir)
    s = rng;                                % save global stream
    rng(12345, 'twister');                  % deterministic probe direction
    p = randn(n, 1);
    rng(s);                                 % restore
else
    p = dir(:);
end
% Respect the relative-step convention used by finiteDiffGradient (per-coord
% scaling by max(1,|x_i|)) so the probe explores the same geometry the gradient
% will later difference over.
p = p .* max(1, abs(x0));
np = norm(p);
if ~(np > 0), info.flag = 'error'; return; end
p = p / np;

% --- Base spacing ---
h = getfield_default(ncOpts, 'baseSpacing', []);
if isempty(h)
    h = 1e-3 * max(1, norm(x0));
end

% --- Sample, analyse, and retry once if the spacing was off ---
nEvals = 0;
% hUsed is the spacing the reported result came from.  It used to be assigned
% from h after the retry branch had already scaled it, so every non-'noise'
% return advertised a spacing that was never sampled -- off by the 100x the
% retry was about to apply, in whichever direction.
hUsed = h;
for attempt = 1:2
    hUsed = h;
    [fval, ok] = sampleLine(fun, x0, p, h, nf);
    nEvals = nEvals + nf;
    if ~ok
        info.flag = 'error';  info.nEvals = nEvals;  info.hUsed = hUsed;
        return;
    end

    [fnoise, level, inform] = ecnoise(fval);
    info.levels = level;

    if inform == 1
        epsf = fnoise;
        info.epsf = fnoise;  info.flag = 'noise';  info.detected = true;
        info.hUsed = hUsed;  info.nEvals = nEvals;
        return;
    elseif inform == 2
        % Values essentially identical: spacing too small -> grow it and retry.
        info.flag = 'flat';
        h = h * 100;
    else % inform == 3
        % Smooth trend dominates the table: spacing too large -> shrink it.
        info.flag = 'inconclusive';
        h = h / 100;
    end
end

% Nothing resolved after the retry.  epsf = 0 makes the caller keep its default
% finite-difference step, which is the right fallback -- but the flag stays
% 'inconclusive' or 'flat' rather than being rewritten to a confident
% 'analytic'.  Two spacings cannot distinguish a clean function from one probed
% four orders of magnitude too coarsely, and claiming otherwise handed callers
% a measurement that was never made.
info.epsf = 0;  info.detected = false;
info.hUsed = hUsed;  info.nEvals = nEvals;
epsf = 0;
end

% ------------------------------------------------------------------------
function [fval, ok] = sampleLine(fun, x0, p, h, nf)
%SAMPLELINE  Evaluate fun at nf equally spaced points centred on x0 along p.
%   Points are x0 + t_j*h*p with t_j = j-(nf+1)/2, j=1..nf. Any evaluation that
%   throws or returns a non-finite/non-scalar value aborts with ok=false.
fval = zeros(nf, 1);
ok = true;
mid = (nf + 1) / 2;
for j = 1:nf
    t  = (j - mid);
    xj = x0 + (t * h) * p;
    try
        v = fun(xj);
    catch
        ok = false;  return;
    end
    if ~isscalar(v) || ~isfinite(v)
        ok = false;  return;
    end
    fval(j) = v;
end
end

% ------------------------------------------------------------------------
function [fnoise, level, inform] = ecnoise(fval)
%ECNOISE  Thin wrapper around the shared ECnoise core (see adamnlopt.ecnoiseCore).
[fnoise, level, inform] = adamnlopt.ecnoiseCore(fval);
end

% ------------------------------------------------------------------------
function v = getfield_default(s, name, dflt)
%GETFIELD_DEFAULT  s.(name) when present and non-empty, else dflt.
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = dflt;
end
end
