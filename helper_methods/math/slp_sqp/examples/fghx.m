function [obj,con,ceq]=fghx(x,f,g,h)
% Utility function to use sqp with anonymous functions in Octave
%
%  Input
%  x..... Design variable vector
%  f..... Objective function handle, f(x)
%  g..... Inequality constraint vector function handle, g(x)
%  h..... Equality   constraint vector function handle, h(x)
%
%  Output
%  obj... Objective function (scalar) value evaluated for x
%  con... Inequality constraint vector values evaluated for x
%  ceq... Equality   constraint vector values evaluated for x

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
if nargin>3 && isa( h, 'function_handle' )
   ceq = h(x); % equality constraint evaluation
   if nargout<3
      con = [con(:); ceq(:)]; % sqp convention puts h first before g
   end
else
   ceq = [];
end
end