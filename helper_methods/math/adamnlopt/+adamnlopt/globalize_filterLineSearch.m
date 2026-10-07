function [alpha, augment, rho, lsFailed, firstBlocked] = globalize_filterLineSearch( ...
        phiTheta, phi0, theta0, gd, filter, rho, aMax, thetaCap, multInfNorm)
%   FIRSTBLOCKED (A4) is true when the first, full-length trial was rejected by
%   a STORED filter entry (or thetaMax) -- the signal IPOPT's filter-reset
%   heuristic counts.
%   theta_min comes from filter.thetaMin when set (D18), else 1e-4*max(1,theta0).
%GLOBALIZE_FILTERLINESEARCH  Backtracking filter line search with merit backup.
%   [alpha, augment, rho, lsFailed] = adamnlopt.globalize_filterLineSearch(
%   phiTheta, phi0, theta0, gd, filter, rho, aMax, thetaCap, multInfNorm) runs
%   the Waechter-Biegler filter line search along a step. PHITHETA is a handle
%   a -> [phi, theta] evaluating the objective (or barrier objective) PHI and the
%   constraint violation THETA at step length a; PHI0/THETA0 are their values at
%   a = 0; GD is the directional derivative of PHI along the step; FILTER is an
%   adamnlopt.Filter; RHO is the current l1 penalty weight for the merit backup;
%   AMAX (default 1) is the starting step length (e.g. the fraction-to-boundary
%   cap).
%
%   Backtracking from AMAX, a trial is accepted when it is acceptable to the
%   filter AND either
%     * (switching/f-type step) the Armijo condition on PHI holds, or
%     * (theta-type step) it gives sufficient feasibility or objective decrease.
%   AUGMENT is true when the accepted step must be added to the filter (every
%   accepted step except a switching step that passed Armijo).
%
%   THETACAP (default inf) is an absolute ceiling on the trial constraint
%   violation: any trial with THETA > THETACAP is vetoed outright and
%   backtracking continues.  This closes a hole in the theta-type rule, whose
%   objective-decrease disjunct (phiT <= phi0 - gammaPhi*theta0) degenerates to
%   "any decrease at all" when theta0 is small, and so would otherwise accept an
%   unbounded feasibility blow-up in exchange for an infinitesimal objective
%   gain.  The veto applies to the merit backup as well.
%
%   If the filter backtracking stalls, the search falls back to an l1-merit
%   Armijo search (RHO raised to guarantee descent) whose trials must still clear
%   both THETACAP and the filter itself -- the backup tightens the acceptance
%   rule, it does not bypass it.  MULTINFNORM (default 0) is the multiplier
%   inf-norm used to keep the l1 merit exact (rho >= ||lambda||_inf).  LSFAILED
%   is true when no trial passed any test, in which case ALPHA is returned as
%   min(amin, AMAX) -- the minimum step length, never longer than the caller's
%   fraction-to-boundary cap -- so the caller can detect a genuine failure.
%
%   Inputs:
%     phiTheta    - function handle a -> [phi, theta] evaluating the objective (or
%                   barrier objective) PHI and constraint violation THETA at step a.
%     phi0        - scalar PHI at a = 0.
%     theta0      - scalar THETA at a = 0.
%     gd          - scalar directional derivative of PHI along the step.
%     filter      - adamnlopt.Filter used for the acceptance test.
%     rho         - current l1 penalty weight for the merit backup.
%     aMax        - (optional) starting/maximum step length; defaults to 1.
%     thetaCap    - (optional) absolute ceiling on trial constraint violation;
%                   defaults to inf (no veto).
%     multInfNorm - (optional) multiplier inf-norm lower-bounding rho in the merit
%                   backup; defaults to 0.
%
%   Outputs:
%     alpha    - accepted step length (min(1e-10, aMax) when lsFailed).
%     augment  - logical; true when the accepted step must be added to the filter.
%     rho      - penalty weight, possibly increased by the merit backup.
%     lsFailed - logical; true when no trial satisfied any acceptance test.
%
%   See also FILTER, GLOBALIZE_MERITACCEPT, GLOBALIZE_FILTERACCEPT,
%   CONTROL_PENALTYUPDATE.

import adamnlopt.*

if nargin < 7 || isempty(aMax),        aMax = 1;        end
if nargin < 8 || isempty(thetaCap),    thetaCap = inf;  end
if nargin < 9 || isempty(multInfNorm), multInfNorm = 0; end

sTheta = 1.1;  sPhi = 2.3;  delta = 1;  etaPhi = 1e-4;
% D18: theta_min is fixed per solve (WB: 1e-4*max(1, theta(x0))).  Computing it
% from the CURRENT theta made "theta0 <= thetaMin" read "theta0 <= 1e-4", a
% constant: Case I (the switching/f-type rule) was unreachable above 1e-4, so
% on row-scaled problems every step before then was theta-type.
thetaMin = 1e-4 * max(1, theta0);
if isprop(filter, 'thetaMin') && isfinite(filter.thetaMin)
    thetaMin = filter.thetaMin;
end
c = 1e-4;
% D18: WB alpha_min (eq. 23).  Below it no trial can satisfy any acceptance
% rule, so backtracking further only burns evaluations; ~33 trials per stalled
% search fell to ~20 or fewer, which on a simulation-based problem is the
% difference that matters.  gamma_alpha = 0.05 as in WB.
gammaAlpha = 0.05;
if gd < 0
    aminWB = min(filter.gammaTheta, filter.gammaPhi * theta0 / (-gd));
    if theta0 <= thetaMin
        aminWB = min(aminWB, delta * theta0^sTheta / (-gd)^sPhi);
    end
else
    aminWB = filter.gammaTheta;
end
amin = max(1e-10, gammaAlpha * aminWB);
lsFailed = false;

% Every trial is cached as [alpha, phi, theta] so the merit backup below can
% score the identical backtracking sequence without calling PHITHETA again.
% Both loops start at the same aMax and halve identically, and the filter is
% not mutated between them (the caller augments only after this function
% returns), so every value -- and every isAcceptable verdict -- carries over
% exactly.  Re-deriving them DOUBLED the user objective and constraint calls of
% every stalled line search: ~34 extra evaluation pairs apiece, on precisely
% the iterations that can least spare them.
cache  = zeros(ceil(log2(max(aMax, amin) / amin)) + 2, 3);
nCache = 0;

alpha = aMax;
firstBlocked = false;
while alpha > amin
    [phiT, thetaT] = phiTheta(alpha);
    nCache = nCache + 1;
    cache(nCache, :) = [alpha, phiT, thetaT];
    if nCache == 1
        firstBlocked = ~filter.isAcceptable(thetaT, phiT);
    end
    % D18: the theta-growth veto applies to THETA-TYPE trials only.  An f-type
    % trial (switching condition) is judged by Armijo on phi with theta free to
    % grow up to thetaMax -- that is what lets a full Newton step along a curved
    % constraint be taken (the Maratos remedy).  Vetoing it too collapsed the
    % cap to kappaThetaGrow*feasTol at a feasible iterate and cut such steps to
    % ~0.1, then sent them through SOC.
    if filter.isAcceptable(thetaT, phiT)
        switching = gd < 0 && theta0 <= thetaMin && ...
                    alpha * (-gd)^sPhi > delta * theta0^sTheta;
        if switching
            if phiT <= phi0 + etaPhi * alpha * gd
                augment = false;  return;   % f-type step: do not augment
            end
        elseif thetaT <= thetaCap
            % theta0 > 0 on the theta-reduction branch: at a feasible point
            % thetaT <= (1-gammaTheta)*0 reads 0 <= 0 and accepted ANY objective
            % increase (every bounds-only problem sits at theta = 0).  There
            % the step must at least not raise phi (D27).
            if (theta0 > 0 && thetaT <= (1 - filter.gammaTheta) * theta0) || ...
               phiT   <= phi0 - filter.gammaPhi * theta0
                augment = true;  return;    % theta-type step: augment
            end
        end
    end
    alpha = 0.5 * alpha;
end

% Filter backtracking stalled: fall back to the l1-merit Armijo search.  The
% multiplier norm is passed through so rho keeps the l1 merit exact
% (rho >= ||lambda||_inf); dropping it left rho pinned at its initial value and
% made the penalty far too weak to price a feasibility increase.
rho = control_penaltyUpdate(rho, multInfNorm, gd, theta0);
phiM0 = phi0 + rho * theta0;
dphiM = gd - rho * theta0;
% control_penaltyUpdate can force dphiM < 0 only when theta0 > 0.  At a feasible
% point with an ascent direction (gd >= 0: inexact or indefinite step) the Armijo
% test phiT <= phi0 + c*alpha*dphiM would ACCEPT a merit increase.  Clamp the
% predicted slope at zero so such a direction can only be taken where the trial
% does not raise the merit (D27).
dphiM = min(dphiM, 0);
for iT = 1:nCache
    alpha  = cache(iT, 1);
    phiT   = cache(iT, 2);
    thetaT = cache(iT, 3);
    if thetaT <= thetaCap && filter.isAcceptable(thetaT, phiT) && ...
            globalize_meritAccept(phiM0, phiT + rho * thetaT, dphiM, alpha, c)
        augment = true;  return;
    end
end

% Nothing passed.  Report the failure rather than silently returning a step the
% caller believes was accepted: the restoration trigger keys off exactly this.
%
% min(aMax, ...) because amin is a FLOOR on the backtracking, not a licence to
% exceed the caller's cap.  aMax is the fraction-to-boundary limit, and at the
% endgame -- an inequality slack or a bound distance on its way to zero -- it
% can itself fall below amin, in which case neither loop above ran a single
% trial and the bare amin handed back a step LONGER than the barrier allows.
% The caller takes it unconditionally, so a slack goes negative and the next
% log-barrier evaluation is complex or NaN.
%
% The returned creep stays at 1e-10 (not the WB alpha_min, which can be 5e-7):
% the caller takes it unconditionally, and it is a placeholder, not a step.
alpha = min(1e-10, aMax);  augment = true;  lsFailed = true;
end
