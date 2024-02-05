function [Merit,penalty]=trust_merit( f, g, penalty0, lambda, bind )
% trust_merit - exact L1 single-penalty function or vector-penalty merit function
%
%--Input
%  f......... objective function value (scalar)
%  g......... constraint values (vector)
%  penalty0.. penalty parameter (scalar or vector)
%  lambda.... Lagrange multipliers for constraints (optional structure)
%  bind...... Indices to binding constraints (vector)
%
%--Output
%
%  Merit..... Penalty function value (scalar)
%  penalty... Updated penalty parameter(s) (scalar or vector)
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:        11/13/16
%  Last modified:  11/14/16

simple  = numel(penalty0)==1;
penalty = penalty0;
%% Update penalty, if Lagrange multipliers input
if nargin>3
   if simple
      bump = 1.5; % margin to satisfy penalty > lambda
      penalty = max(penalty0, bump*max([lambda.ineqlin; lambda.lower; lambda.upper]));
   elseif any(bind)
      penalty(bind) = max( lambda.ineqlin(bind), penalty0(bind) );
   end
end

%% Merit is the penalty function
if simple % Nocedal & Wright Eq. (15.4)
   Merit = f + penalty*norm(max(0,g),1);
else
   Merit = f + penalty'*max(0,g);
end

end