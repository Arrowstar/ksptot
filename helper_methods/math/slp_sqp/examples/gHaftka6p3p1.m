function [gradf,gradg]=gHaftka6p3p1( x )
% Gradient evaluation for Example 6.3.1 taken from
% "Elements of Structural Optimization" by Haftka and Gurdal
% N.B., Haftka uses g>=0; whereas, Matlab uses g<=0.
%
%--Input
%
%  x........ Design variable vector of length 2
%
%--Ouput
%
%  gradf.... Gradient of objective function (column vector)
%  gradg.... Gradients of constraints (#variables by #constraints matrix)
%            i.e., a constraint gradient in each column
gradf = [-2; -1];
gradg = [2*x(:), [2; -2].*x(:)];