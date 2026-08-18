function phi = globalize_meritFunction(f, theta, rho)
%GLOBALIZE_MERITFUNCTION  l1 penalty merit function.
%   phi = adamnlopt.globalize_meritFunction(f, theta, rho) returns the exact
%   l1 penalty merit phi = f + rho*theta, where theta is the constraint
%   violation (see globalize_constraintViolation) and rho > 0 the penalty
%   weight (see control_penaltyUpdate). Used as the backup globalization when
%   the filter stalls.
%
%   Inputs:
%     f     - scalar objective value.
%     theta - scalar constraint violation (see globalize_constraintViolation).
%     rho   - positive scalar l1 penalty weight.
%
%   Outputs:
%     phi - scalar l1 penalty merit f + rho*theta.
%
%   See also GLOBALIZE_MERITACCEPT, GLOBALIZE_CONSTRAINTVIOLATION,
%   CONTROL_PENALTYUPDATE.

phi = f + rho * theta;
end
