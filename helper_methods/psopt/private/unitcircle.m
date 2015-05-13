function [c, ceq] = unitcircle(x)
% Unit disk. The vector x should be a row vector. This is to test the
% non-linear constraint functionality of pso.
% 
% Non-linear constraints such that
% c(x) <= 0
% ceq(x) = 0
% Within a tolerance of options.TolCon

ceq = x*x' - 1 ;
c = [] ;