function [value, isterminal, direction] = refNeverEvent(~, ~)
% refNeverEvent An event function that never triggers.
%
% The LVD integrator wrappers always request the event outputs from the
% underlying MATLAB solver, so an event function must always be supplied.
% This one keeps a constant non-zero value so no root is ever found.

    value      = 1;
    isterminal = 0;
    direction  = 0;
end
