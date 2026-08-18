function rho = control_penaltyUpdate(rho, multInfNorm, gd, theta, buffer)
%CONTROL_PENALTYUPDATE  Raise the l1 penalty weight to guarantee descent.
%   rho = adamnlopt.control_penaltyUpdate(rho, multInfNorm, gd, theta) returns
%   an updated penalty weight for the merit phi = f + rho*theta such that
%     * rho dominates the multiplier magnitude (rho >= ||lambda||_inf + buffer),
%       which makes the l1 merit exact, and
%     * the predicted directional derivative dphi = gd - rho*theta is negative
%       (rho >= gd/theta + buffer when theta > 0).
%   rho is monotonically non-decreasing. BUFFER defaults to 1e-2.
%   (Nocedal & Wright, Numerical Optimization, eq. 18.36.)
%
%   Inputs:
%     rho         - current penalty weight (scalar >= 0).
%     multInfNorm - infinity norm of the current multiplier estimate.
%     gd          - directional derivative g'*d of the objective along the step.
%     theta       - current constraint violation measure (scalar >= 0).
%     buffer      - (optional) safety margin added to each bound; defaults 1e-2.
%
%   Outputs:
%     rho - updated (monotonically non-decreasing) penalty weight.
%
%   See also GLOBALIZE_MERITFUNCTION, GLOBALIZE_MERITACCEPT.

if nargin < 5 || isempty(buffer), buffer = 1e-2; end

rho = max(rho, multInfNorm + buffer);
if theta > 0
    rho = max(rho, gd / theta + buffer);
end
end
