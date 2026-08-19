function [value, isterminal, direction] = refRadiusEventNonTerminal2ndOrder(~, y, ~, targetRadius)
% refRadiusEventNonTerminal2ndOrder Non-terminal radius crossing event.
%
% Second-order form.  Because it does not terminate, an eccentric orbit
% crosses the target radius twice per revolution, which exercises how the
% integrator accumulates multiple event records.

    value      = norm(y(1:3)) - targetRadius;
    isterminal = 0;
    direction  = 0;
end
