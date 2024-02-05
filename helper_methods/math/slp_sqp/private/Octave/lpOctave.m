function [x,f,exitflag,output,lambda] = lpOctave(c,A,b,Aeq,beq,lb,ub,x0,opts)
% Wrapper for Octave linprog that first traps no feasible solution. 
% Octave optim package linprog does not return lambda. Use this substitute.
%
%  Written by:    Robert A. Canfield
%  Inspired by:   Blake van Winkle
%  Created:       11/9/19
%  Last modified: 7/21/20 - change name to avoid lp copy of linprog
%                 7/24/20 - detect infeasible; start qp from lp solution

if nargin<9
   options=x0; % New algorithms omit x0 (only active-set uses it)
   x0=[];
else
   options=opts;
end
options=optimset(optimset('fminsearch'),options);
if isfield(options,'TolCon') && ~isempty(options.TolCon)
   TolCon = options.TolCon;
else
   TolCon = min(options.TolFun,optimget(optimset('fminsearch'),'TolFun'));
end

% Check for a feasible solution
if isempty(x0) 
   if ~isempty(lb) && ~isempty(ub) && ~any(isinf([lb;ub]))
      xi = (lb + ub)/2;
   else
      xi = zeros(size(c));
   end
else
   xi = x0;
end
if isempty(A),   A1=0; b1=0; else, A1=A;   b1=b;   end
if isempty(Aeq), Aq=0; bq=0; else, Aq=Aeq; bq=beq; end
if isempty(lb), xlb=-inf*x0; else, xlb=lb; end
if isempty(ub), xub= inf*x0; else, xub=ub; end
viol = @(x) max( [A1*x-b1; x-xub; xlb-x; abs(Aq*x-bq)] );
feas = @(x) viol(x) <= TolCon;
feasible = feas(xi) || feas(xlb) || feas(xub);
nx = length( c );
if ~feasible % minimize a slack variable
   d = [zeros(nx,1); 1];
   [xf,delta]=linprog(d,[A,b],b,[Aeq,beq],beq,[lb;0],[ub;1]);
   x = xf(1:end-1);
   f = c(:)'*x;
   feasible = delta < TolCon;
   if ~feasible
      output.constrviolation = viol( x );
      output.message = 'No feasible LP solution.';
      exitflag = -1; lambda=[];
      return
   end
end

% Call Octave's simplex solver [formerly renamed linprog->lp]
if isfield(options,'manyDV') && ~isempty(options.manyDV)
   many_dv = options.manyDV;
else
   many_dv = 500;
end
if nx<=many_dv
   [x1,f1]=linprog(c,A,b,Aeq,beq,lb,ub);
else % Octave's simplex inefficient for large #var
   x1=x0;
   f1=[];
end

% Call quadprog get Lagrange multipliers, lambda, starting from lp solution
H = eye(nx);
[x2,f2,exitflag,output,lambda]=quadprog(H,c,A,b,Aeq,beq,lb,ub,x1,options);

% Return best solution from lp or qp
if ~isempty(f1) && any(x2) && output.iterations>0 % assume a feasible solution
   x1 = max( lb, min( ub, x1 ) );
   x2 = max( lb, min( ub, x2 ) );
   % Return best solution
   if f2<f1 && viol(x2) <= max(TolCon,viol(x1))
      x = x2;
      f = f2;
   else
      x = x1;
      f = f1;
   end
else
   x = x2;
   f = f2;
end
x = max( xlb, min( xub, x ) );
output.constrviolation = viol( x );
end