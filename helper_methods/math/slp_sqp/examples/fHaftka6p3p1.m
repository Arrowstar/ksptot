function [f,g]=fHaftka6p3p1( x )
% Function evaluation for Example 6.3.1 taken from
% "Elements of Structural Optimization" by Haftka and Gurdal
% N.B., Haftka uses g>=0; whereas, Matlab uses g<=0.
%
%--Input
%
%  x........ Design variable vector of length 2
%
%--Ouput
%
%  f........ Objective function value (scalar) - linear in x
%  g........ Constraint function values (vector)

f = [-2 -1]*x(:);
g = [(sum(x.^2)-25)
     x(1)^2-x(2)^2-7];