function tf = globalize_filterAccept(entries, theta, phi, gammaTheta, gammaPhi)
%GLOBALIZE_FILTERACCEPT  Test a trial (theta, phi) against a filter set.
%   tf = adamnlopt.globalize_filterAccept(entries, theta, phi, gammaTheta,
%   gammaPhi) returns true when the trial pair is not dominated by any row of
%   ENTRIES ([theta_j phi_j]). Acceptance requires, for every entry,
%       theta <= (1 - gammaTheta) * theta_j   OR   phi <= phi_j - gammaPhi * theta_j
%   so the trial must beat each stored point by a small margin in feasibility
%   or objective. An empty filter accepts everything.
%
%   Inputs:
%     entries    - N-by-2 matrix of stored [theta_j, phi_j] rows; empty accepts
%                  everything.
%     theta      - scalar constraint violation of the trial point.
%     phi        - scalar objective of the trial point.
%     gammaTheta - (optional) feasibility acceptance margin (default 1e-5).
%     gammaPhi   - (optional) objective acceptance margin (default 1e-5).
%
%   Outputs:
%     tf - logical; true if the trial is not dominated by any entry.
%
%   See also FILTER, GLOBALIZE_FILTERLINESEARCH, GLOBALIZE_CONSTRAINTVIOLATION.

if nargin < 4 || isempty(gammaTheta), gammaTheta = 1e-5; end
if nargin < 5 || isempty(gammaPhi),   gammaPhi   = 1e-5; end

if isempty(entries)
    tf = true;  return;
end

thetaJ = entries(:, 1);
phiJ   = entries(:, 2);
dominated = (theta > (1 - gammaTheta) * thetaJ) & ...
            (phi   > phiJ - gammaPhi * thetaJ);
tf = ~any(dominated);
end
