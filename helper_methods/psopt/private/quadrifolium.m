function [c,ceq] = quadrifolium(x)
% For demonstrating nonlinear constraints. This produces a 2-dimensional
% design space in the shape of a four-leafed clover.
%
% Reference:
% Weisstein, Eric W. "Quadrifolium." From MathWorld--A Wolfram Web
% Resource. http://mathworld.wolfram.com/Quadrifolium.html
%
% Default: a = 2 ; (larger a, larger shape of constraint area)

a = 2 ;
c = (x(1)^2 + x(2)^2)^3 - 4*a*x(1)^2*x(2)^2 ;
ceq = [] ;