function tf = globalize_filterAccept(entries, theta, phi)
%GLOBALIZE_FILTERACCEPT  Test a trial (theta, phi) against a filter set.
%   tf = adamnlopt.globalize_filterAccept(entries, theta, phi) returns true
%   when the trial pair is not dominated by any row of ENTRIES
%   ([theta_j phi_j]):
%       theta < theta_j   OR   phi < phi_j
%   so the trial must strictly beat each stored point in feasibility or
%   objective. An empty filter accepts everything.
%
%   The entries are the MARGIN-SHIFTED corners Filter.augment stores --
%   [(1-gammaTheta)*theta_j, phi_j - gammaPhi*theta_j] -- so the Waechter-
%   Biegler acceptance margin is already in them and must NOT be applied a
%   second time here.  Applying it here too (theta <= (1-gamma)*thetaJ ...)
%   double-counted the margin: a trial had to beat the twice-shifted corner,
%   vetoing full Newton steps along curved equalities that the single margin
%   accepts.
%
%   Inputs:
%     entries    - N-by-2 matrix of stored (shifted) [theta_j, phi_j] rows;
%                  empty accepts everything.
%     theta      - scalar constraint violation of the trial point.
%     phi        - scalar objective of the trial point.
%
%   Outputs:
%     tf - logical; true if the trial is not dominated by any entry.
%
%   See also FILTER, GLOBALIZE_FILTERLINESEARCH, GLOBALIZE_CONSTRAINTVIOLATION.

if isempty(entries)
    tf = true;  return;
end

thetaJ = entries(:, 1);
phiJ   = entries(:, 2);
dominated = (theta >= thetaJ) & (phi >= phiJ);
tf = ~any(dominated);
end
