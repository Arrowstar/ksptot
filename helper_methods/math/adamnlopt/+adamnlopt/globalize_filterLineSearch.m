function [alpha, augment, rho, lsFailed] = globalize_filterLineSearch( ...
        phiTheta, phi0, theta0, gd, filter, rho, aMax, thetaCap, multInfNorm)
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
%   is true when no trial passed any test, in which case ALPHA is returned as the
%   minimum step length so the caller can detect a genuine line-search failure.
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
%     alpha    - accepted step length (amin when lsFailed).
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
thetaMin = 1e-4 * max(1, theta0);
amin = 1e-10;  c = 1e-4;
lsFailed = false;

alpha = aMax;
while alpha > amin
    [phiT, thetaT] = phiTheta(alpha);
    if thetaT <= thetaCap && filter.isAcceptable(thetaT, phiT)
        switching = gd < 0 && theta0 <= thetaMin && ...
                    alpha * (-gd)^sPhi > delta * theta0^sTheta;
        if switching
            if phiT <= phi0 + etaPhi * alpha * gd
                augment = false;  return;   % f-type step: do not augment
            end
        else
            if thetaT <= (1 - filter.gammaTheta) * theta0 || ...
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
alpha = aMax;
while alpha > amin
    [phiT, thetaT] = phiTheta(alpha);
    if thetaT <= thetaCap && filter.isAcceptable(thetaT, phiT) && ...
            globalize_meritAccept(phiM0, phiT + rho * thetaT, dphiM, alpha, c)
        augment = true;  return;
    end
    alpha = 0.5 * alpha;
end

% Nothing passed.  Report the failure rather than silently returning a step the
% caller believes was accepted: the restoration trigger keys off exactly this.
alpha = amin;  augment = true;  lsFailed = true;
end
