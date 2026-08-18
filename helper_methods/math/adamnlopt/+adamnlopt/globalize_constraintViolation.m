function theta = globalize_constraintViolation(cE, cI)
%GLOBALIZE_CONSTRAINTVIOLATION  l1 constraint-violation measure theta(x).
%   theta = adamnlopt.globalize_constraintViolation(cE, cI) returns
%       theta = ||cE||_1 + ||max(cI, 0)||_1,
%   the standard infeasibility measure for equalities cE = 0 and inequalities
%   cI <= 0. Either argument may be empty. This is the theta coordinate the
%   filter and merit functions share.
%
%   Inputs:
%     cE - vector of equality-constraint values (target cE = 0); may be empty.
%     cI - vector of inequality-constraint values (target cI <= 0); may be empty.
%
%   Outputs:
%     theta - scalar l1 constraint violation ||cE||_1 + ||max(cI, 0)||_1.
%
%   See also GLOBALIZE_MERITFUNCTION, FILTER, GLOBALIZE_FILTERLINESEARCH.

v = zeros(0, 1);
if ~isempty(cE), v = [v; cE(:)]; end
if ~isempty(cI), v = [v; max(cI(:), 0)]; end
if isempty(v)
    theta = 0;
else
    theta = norm(v, 1);
end
end
