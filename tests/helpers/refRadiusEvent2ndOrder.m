function [value, isterminal, direction] = refRadiusEvent2ndOrder(~, y, ~, targetRadius)
% refRadiusEvent2ndOrder Terminal event on |position| crossing a radius.
%
% Second-order form: y is the position only, yp the velocity.

    value      = norm(y(1:3)) - targetRadius;
    isterminal = 1;
    direction  = 0;
end
