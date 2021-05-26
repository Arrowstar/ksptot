function [c,ceq] = heart(x)
% For nonlinear constraint demonstration.

c = (x(1)^2 + x(2)^2 - 1)^3 - x(1)^2*x(2)^3 ;
% c(2) = -x(1) ; % Half-heart
% ceq = x(1) - 1 ;
ceq = [] ;