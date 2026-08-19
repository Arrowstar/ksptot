function [value, isterminal, direction] = refNeverEvent2ndOrder(~, ~, ~)
% refNeverEvent2ndOrder An event function that never triggers.
%
% Second-order form.  rkn1210 calls event functions as evt(t, y, yp), so
% the first-order refNeverEvent cannot be reused here.

    value      = 1;
    isterminal = 0;
    direction  = 0;
end
