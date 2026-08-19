function [value, isterminal, direction] = refRadiusEvent(~, y, targetRadius)
% refRadiusEvent Terminal event that fires when |position| crosses a radius.
%
% First-order form: y is [rVect; vVect].

    value      = norm(y(1:3)) - targetRadius;
    isterminal = 1;
    direction  = 0;
end
