function [c,ceq]=nonlcon(x,g,h)
% Enabling function to use optimtool with anonymous functions
%
%  Input
%  x..... Design variable vector
%  g..... Inequality constraint vector function handle, g(x)
%  h..... Equality   constraint vector function handle, h(x)
%
%  noOutput
%  c..... Inequality constraint vector values evaluated for x
%  ceq... Equality   constraint vector values evaluated for x
if nargin<1
   disp('usage: [c,ceq]=nonlcon(x,g,h)')
   return
elseif nargin>2
   ceq = h(x);
else
   ceq = [];
end
c = g(x);
end