function [obj,con]=fgx(x,f,g)
% Utility function to use slp/sqp with anonymous functions in Octave
%
%  Input
%  x..... Design variable vector
%  f..... Objective function handle, f(x)
%  g..... Inequality constraint vector function handle, g(x)
%
%  Output
%  obj... Objective function (scalar) value evaluated for x
%  con... Inequality constraint vector values evaluated for x

if nargin<1
   disp('usage: [obj,con,ceq]=fghx(x,f,g,h)')
   return
end
obj = f(x);    % objective function evaluation
if nargin>2
   con = g(x); % inequality constraint evluation
else
   con = -Inf;
end
end