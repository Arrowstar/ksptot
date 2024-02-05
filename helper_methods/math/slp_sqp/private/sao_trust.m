function [x,f,Converged,output,lambda]=sao_trust(Problem,Fun,Grd,...
                                                 TR,options,varargin)
% Sequential Approximate Optimization (SAO) with a Trust Region Strategy
% finds the constrained minimum of a function of several variables.
%
% Version 1.4.2
%
% Copyright (c) 2020, Robert A. Canfield. All rights reserved.
%                     See accompanying LICENSE.txt file for conditions.
%
%  Optimization Toolbox Version 1-compatible input arguments
%
%  usage: [x,f,Converged,output,lambda]=sao_trust(Fun,X0,Opts,vlb,vub,Grd,P1,P2,...)
%
%  input:   Fun     - function handle (or string) which returns the
%                     value of the objective function and a vector of
%                     constraints, i.e., [f,g]=fun(x,active,P1,P2,...) 
%                     where x is the design variable vector and active is
%                     an index/boolean vector pointing to active constraints.
%                     f is minimized such that g<=zeros(g).
%           X0      - initial vector of design variables
%           options - (optional) a structure according to optimset & fields
%                     TrustRegion: on, off, simple, merit, TRAM (string)
%                     ComplexStep: off, on (string)
%                     cutg:        active constraint cutoff value (real)
%           vlb     - (optional) vector of lower bounds on design variables
%           vub     - (optional) vector of upper bounds on design variables
%           Grd     - (optional) function handle that returns a vector of 
%                     function gradients and a matrix of constraint gradients
%                     i.e. [fp,gp]=grd(x,active,P1,P2,...) where
%                     active is an index (or boolean) vector to active g.
%           Pn      - (optional) variables directly passed to Fun and Grd
%
%           Note: optional inputs can be skipped by inputing []
%
%  output: x         - vector of design variables at the optimal solution
%          f         - final value of objective function
%          Converged - Convegence flag
%          output   - Structure of output results (iteration history)
%          lambda   - Structure of Lagrange multipliers
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:       11/8/19
%  Last modified: 9/15/20
%
% This function signature is based on the MATLAB function constr.m written
% by Andy Grace of MathWorks, 7/90, supplemented with 
% Optimization Toolbox version 2 data structures for options and output.
%
% Trust Region (TR) algorithm and filter based on: 
% Nocedal and Wright, Numerical Optimization. New York: Springer, 2006 
% Algorithms 4.1 for TR & 15.1 for filter; Equation (15.4) for simple merit
%--------------------------------------------------------------------------
% Copyright (c) 2020, Robert A. Canfield. All rights reserved.
%                     Virginia Tech
%                     bob.canfield@vt.edu
%                    <http://www.aoe.vt.edu/people/faculty/canfield.html>
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the "Software"),
% to deal with the Software without restriction, including without 
% limitation the rights to use, copy, modify, merge, publish, distribute, 
% sublicense, and/or sell copies of the Software, and to permit persons 
% to whom the Software is furnished to do so, subject to the following 
% conditions:
% 
% * Redistributions of source code must retain the above copyright notice,
%   this list of conditions and the following disclaimers.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimers in the
%   documentation and/or other materials provided with the distribution.
% 
% * Neither the names of Robert A. Canfield, Virginia Tech, 
%   Air Force Institute of Technology, nor the names of its contributors 
%   may be used to endorse or promote products derived from this Software 
%   without specific prior written permission.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
% THE USE OR OTHER DEALINGS WITH THE SOFTWARE. 
%--------------------------------------------------------------------------

%--Modifications
%   4/13/06 - Created as slp
%   5/17/07 - Created as slp_trust
%  10/30/11 - fdgrd internal function added
%   9/27/15 - active constraint strategy added
%   9/29/15 - fmincon compatibility with single input: problem structure
%   9/30/15 - fix grd -> eval grdstr
%  10/16/15 - user Fcn, Grd with or without active
%  11/12/15 - exit if checkbounds msg error, reset X0 if needed
%  12/09/15 - FinDiffRelStep not backward compatible
%   9/28/16 - gradf=gradg typo
%   10/2/16 - refine bindLM
%   11/7/16 - TR.Bound returned
%   11/8/16 - active0
%  11/12/16 - display trust region filter status string; lp optimoptions
%  11/13/16 - return all output arguments from trust_region in TR
%  11/14/16 - Active constraint set for gradients; TR.cutg
%  11/24/16 - linprog no feasible solution, find least infeasible
%  11/25/16 - R2016b optim toolbox version 7.5 optimoptions compatibility
%  12/ 8/16 - VERSION 1.2.1
%   3/21/17 - Detect user unaware of active when varargin supplied
%   4/01/17 - MPEA
%   4/ 9/17 - nac<ncon fixed
%   4/18/17 - Use Merit in Slowed only for Trust
%   4/11/17 - VERSION 1.2.2
%   5/28/17 - QMEA
%   1/24/18 - return # function & gradient evaluations in output
%   2/ 1/18 - save Lambda in TR for use in mpeaprog
%   2/ 8/18 - refactored slp_trust into sao_trust
%   2/24/18 - FunEval nested function to handle unconstrained (g=[])
%   3/ 9/18 - bound side constraints must be binding wrt objective
%   4/ 6/19 - initialize KKT infeasible first iteration
%   4 /7/19 - VERSION 1.3
%   4/28/19 - fix misplaced x0,g0 (used in mpea)
%   7/28/19 - accept infeasible linprog only less violated
%   11/3/19 - interior-point-legacy for b<0; terminate slowed rejected
%--
%   11/9/19 - Refactored to sao_trust with saocrkargin pre-processor
%  11/24/19 - remove ObjCon; varargin always a cell
%   1/10/20 - pass dxlb/ub, Problem to qmeaprog
%   3/10/20 - lower/upper LM in guessLM (for Octave)
%   5/23/20 - options.OutputFcn to store/plot iteration history
%    6/8/20 - unconstrained handled better
%   7/12/20 - least-squares Lagrange multipliers
%   7/18/20 - Solve QMEA after infeasible LP
%   7/21/20 - Schittkowski KTO alternative criteron
%   7/23/20 - renamed private/Octave/linprog -> lpOctave
%   9/15/20 - OutputFcn initialized with structure input
%--

%% Local variables
x0  = Problem.x0;
vlb = Problem.lb;
vub = Problem.ub;
ndv = length(x0); % number of design variables
fd_gradients = isempty(Grd);
MaxIter= options.MaxIter;
TolFun = options.TolFun;
TolCon = options.TolCon;
TolX   = options.TolX;
TolOpt = options.TolOpt;
Tolvb  = options.Tolvb;
MPEA = isfield(TR,'MPEA') && ~isempty(TR.MPEA) && ~strcmpi(TR.MPEA,'off');
QMEA = isfield(TR,'QMEA') && ~isempty(TR.QMEA) && ~strcmpi(TR.QMEA,'off');
BFGS = isfield(options,'BFGS') && ~isempty(options.BFGS) && options.BFGS;
UserHessian=isfield(options,'HessianFcn') && ~isempty(options.HessianFcn);
OutputFcn=isfield(options,'OutputFcn') && isa(options.OutputFcn,'function_handle');
PlotFcn  =isfield(options,'PlotFcns')  && ~isempty(options.PlotFcns);
if OutputFcn,        options.OutputFcn([],[],'init'); end
if PlotFcn, plotFcns(options.PlotFcns, [],[],'init'); end
optQP = [];

%% Set up function and gradient calls
if all(size(x0)==size(Problem.X0)) % allow for user x0 as matrix instead of vector
   xshape = @(x) x;
else
   xshape = @(x) reshape(x(:),size(Problem.X0));
end
unconstrained = nargout(Fun)<2;
UserOptionalInp = nargin>5 && ~isempty(varargin);
UserKnowsActive = nargin(Fun) > 1+numel(varargin);
if UserKnowsActive && UserOptionalInp
   fun = @(x,active) Fun(xshape(x),active,varargin{:});
elseif UserKnowsActive
   fun = @(x,active) Fun(xshape(x),active);
elseif UserOptionalInp % user has optional inputs
   fun = @(x) Fun(xshape(x),varargin{:});
else % user does not have optional inputs and does not recognize active set
   fun = @(x) Fun(xshape(x));
end
if fd_gradients
   grdstr = 'fdgrd(fun,x,f,g,h,options,active)';
elseif ~isempty(varargin)
   if nargin(Grd) > 1+numel(varargin)
      grdstr = 'Grd(xshape(x),active,varargin{:})';
   elseif nargin(Grd) == 1+numel(varargin{:})
      grdstr = 'Grd(xshape(x),varargin{:})';
   end
else
   grdstr = 'Grd(xshape(x))';
end
active  = [];
nfuneval = 0;
ngrdeval = 0;

%% Initial function and gradient evaluations
Iter=0;
TR.stat=0;
TR.radius=0;
lambda=[];
Lagrangian = NaN;
[f,g,h,mcon,mc] = FunEval(x0); 
ng   = length(g);
nh   = length(h);
ncon = ng + nh;
if nh>0,    error('Nonlinear equality constraints h TBD'), end
if UserKnowsActive  % User aware of active constraints
   nretain = 2*ndv; % Retain more active constraints than design variables
else
   nretain = ncon;
end

[gradf,gradg,gradh,active,cutoff] = GradEval(x0,[],nretain);

if length(gradf) ~= ndv
   error('sao_trust:gradf','Objective gradient length does not match # design variables')
elseif ~isempty(g) && size(gradg,1) ~= ndv
   error('sao_trust:gradg','# rows of gradg should be # design variables')
% elseif size(gradg,2) ~= ncon % but maybe nretain,nac<ncon
%    error('sao_trust:nac','# columns of gradg should be # constraints')
elseif ~isempty(h) && size(gradh,1) ~= ndv
   error('sao_trust:gradh','# rows of gradh should be # design variables')
end

%% Initialize Trust Region (TR) data structure fields
if UserKnowsActive % user aware of active constraints
   TR.cutoff = cutoff;
   nretain = ndv; % Subsequently retain at least ndv active constraints
else
   options.cutg = Inf;
   TR.cutoff    = Inf;
end
TR.qmea.QPP = [];
if nargout>3 || QMEA
   TR.output.f(1) = f;
   TR.output.g(:,1) = g;
   TR.output.rejected(1)=false;
   TR.qmea.LP = false;
   if QMEA ||(MPEA && strcmpi(TR.MPEA,'best')), TR.X=x0; end
end
TR = trust_region(TR,x0,[],vlb,vub,f,f,gradf,g(active),g(active),gradg);

%% SAO loop
%  ------------------------------------------------------------------------
Converged=false; KKT=false; Slowed=false;
f0=f; g0=g; x=x0; if unconstrained, mcon=-inf; mc=[]; end
% empty gradfxp is key for mpea to return y=x
TR.mpea = struct('xp',[],'fp',[],'gp',[],'xr',[],...
                 'gradfxp',[],'gradgxp',[],'gradhxp',[],...
                 'gradfx', [],'gradgx', [],'gradhx', []);
% headers
indent=blanks(9);
if TR.adapt
   indent = [indent,'TRAM '];
end
if QMEA
   if MPEA
      SAO = 'QMEA';
   else
      SAO = 'QMA';
   end
   indent=[indent,'Sequential ',SAO,' Optimization'];
elseif MPEA
   SAO = 'MPEA';
   indent=[indent,'Sequential MPEA Optimization'];
elseif BFGS || UserHessian
   SAO = 'SQP';
   indent=[indent,'Sequential Quadratic Programming (SQP)'];
else
   SAO = 'SLP';
   indent=[indent,'Sequential Linear Programming (SLP)'];
end
if strcmpi(options.Display,'iter')
   disp(' ')
   disp([indent, ' Iteration History'])
   disp('Iteration      Objective MaxConstraint  Index   Step-size   Merit      MoveLimit  TrustRatio')
   fprintf('%9.0f %14.5g  %12.4g  %5.0f  %10.4g  %10.4g\n',Iter,f,mcon,mc,0,TR.Merit)
end

while ~Converged && Iter<options.MaxIter
   Iter = Iter + 1;
   lp_inf_str = [];

   % Move Limit side constraints
   dxlb = max( vlb-x, -TR.delx );
   dxub = min( vub-x,  TR.delx );

   % Solve approximate optimization program
   [dx,TR,out,lambda]=saoprog(TR,lambda);

   % save old values before resetting as new
   x0 = x;
   f0 = f;
   g0 = g;
   mc0 = mcon;
   active0 = active;
   MoveLimit0 = TR.MoveLimit;

   % Evaluate functions
   x  = x0 + dx;
   [f,g,h,mcon,mc] = FunEval(x);

%% Update trust region move limits.
   TR = trust_region(TR,x,dx,vlb,vub,f0,f,gradf,g0(active),g(active),gradg,lambda);
   active1 = TR.bindLM;

   % Check convergence.
   Feasible = mcon <= TolCon;
   Slowed   = abs(f-f0) < TolFun&& max(abs(dx)) < TolX ...
           && abs(max(g)-max(g0)) < TolCon;
   if TR.trust && ~TR.filter.flag % merit function & not filter
      Slowed = Slowed && abs(f-TR.Merit) < TolFun;
   end
   if TR.rejected
      newactive = ~ismember(active1,active0);
      if any(newactive)
         active = active1(newactive);
         [~,gradg] = GradEval(x,active);
         active = union(active0,active1); %#ok<*NASGU>
      end
      Lagrangian = NaN;
      KTO = false;
      KTT = false;
      TR.mpea.xr=x;
      TR.mpea.fr=f;
      TR.mpea.gr=g;
   else % new point accepted
      if MPEA || BFGS || QMEA % store previous and current gradients
         TR.mpea.xp = x0;
         TR.mpea.fp = f0;
         TR.mpea.gp = g0;
         TR.mpea.gradfxp = gradf;
         TR.mpea.gradgxp = gradg;
         TR.mpea.gradhxp = gradh;
      end
      TR.mpea.xr=[];
      TR.mpea.lambda = lambda;

      [gradf,gradg,gradh] = GradEval(x,active,nretain); % gradients

      % Locate active binding side constraints, not from move limits
      bound = ((x<vlb+Tolvb | (x<vlb+TolX & lambda.lower>Tolvb)) & gradf>0)...
            | ((x>vub-Tolvb | (x>vub-TolX & lambda.upper>Tolvb)) & gradf<0);   

      if ~Feasible && all(bound)
         warning('sao_trust:bound','Infeasible design, all variables bound')
         break
      elseif isempty(TR.bindLM) % unconstrained (except for bounds)
         Lambda = 0;
         Lagrangian = gradf(:);
      else % binding approximate constraints exist
         if max(g) < -TolCon && isempty(h) % unconstrained
         	Lambda = zeros(size(TR.bindLM(:)));
         elseif Feasible % active constraints exist
%        elseif Feasible && any(~bound) && any(lambda.ineqlin(TR.bindLM))
            % recompute Lagrange multpliers
            Lambda = -gradg(~bound,TR.bindLM) \ gradf(~bound);
            if contains(lastwarn,'Rank deficient') || ...
               any(Lambda<0) % negative multipliers
              lastwarn('');
              try
                 Lambda=lsqlin(gradg(~bound,TR.bindLM),-gradf(~bound),...
                               [],[],[],[],zeros(size(TR.bindLM)),[],...
                               lambda.ineqlin(TR.bindLM), ...
                               optimoptions(@lsqlin,'Display','off'));
               catch % revert
                  Lambda = lambda.ineqlin(TR.bindLM);
               end
            end
         elseif TR.stat>=0 % approx. sub-problem converged
            % do not recompute; use approximate sub-problem multipliers
            Lambda = lambda.ineqlin(TR.bindLM);
         else % infeasible and approx. sub-problem failed to converge
            Lambda = TR.penalty(TR.bindLM);
         end
         TR.Lambda = zeros(size(lambda.ineqlin));
         TR.Lambda(TR.bindLM) = Lambda;
         Lagrangian = gradf(:) + gradg(:,TR.bindLM)*Lambda;
      end
      Lagrangian(bound) = 0;
      SKT = abs(gradf'*dx) + abs(Lambda'*g(TR.bindLM));
      KTO = Feasible && SKT < TolOpt && any(Lambda); % constrained only
      KKT = Feasible && norm(Lagrangian,inf) < TolOpt;
   end
   Converged = KKT || KTO || (Slowed && Feasible);

   % Output current iteration
   if strcmpi(options.Display,'iter') % Print intermediate results
      if Converged || Slowed
         if TR.Bound, BoundStr=' Bound'; else, BoundStr=' Unbound'; end
         TRstatus = strcat(TR.filter.str,BoundStr);
      else
         TRstatus = TR.filter.str;
      end
      if ~isempty(lp_inf_str), TRstatus=strcat(TRstatus,lp_inf_str); end
      if ~isempty(TR.qmea.QPP),TRstatus=strcat(TRstatus,TR.qmea.QPP);end
      if QMEA && TR.qmea.LP,   TRstatus=strcat(TRstatus,' LP'); end
      if unconstrained, mcon=-inf; mc=[]; end
      fprintf('%9.0f %14.5g  %12.4g  %5.0f  %10.4g  %10.4g  %9.4g  %10.4g  %s\n',...
              Iter, f, mcon, mc, max(abs(dx)), TR.Merit, MoveLimit0,...
              TR.Ratio, TRstatus)
   end
   if nargout>3 || QMEA
      TR.output.f(end+1) = f;
      TR.output.g(:,end+1) = g;
      TR.output.rejected(end+1) = TR.rejected;
      if QMEA
         TR.X(:,end+1)=x;
         if ~Converged && isfield(TR,'qmea') && isfield(TR.qmea,'Beta')
            TR.qmea=rmfield(TR.qmea,'Beta'); % re-calculate next iter
         end
      end
   end
   if TR.rejected
      x=x0; f=f0; g=g0; mcon=mc0;  % Reset to previous point
   end
end
%  ------------------------------------------------------------------------

%% Return saved output
if OutputFcn,       options.OutputFcn(x,output,'done'); end
if PlotFcn, plotFcns(options.PlotFcns,x,output,'done'); end
if nargout>4, lambda.ineq = lambda.ineqlin; end
if nargout>3
   if all(TR.output.RadiusFraction==1)
      TR.output=rmfield(TR.output,'RadiusFraction');
   end
   if fd_gradients, nfuneval = nfuneval + ndv*ngrdeval; end
   output = TR.output;
   output.iterations = Iter;
   output.funcCount = nfuneval;
   output.gradCount = ngrdeval;
   output.message=TR.stat;
   output.TR = rmfield(TR,'output');
end

%% Print final results
if strcmpi(options.Display,'iter')
   disp('              ----------  ------------         ----------')
   fprintf('    Criteria   %9.4g  %12.4g         %10.4g\n',[TolFun TolCon TolX])
end
if ~strcmpi(options.Display,'off')
   if Converged
      if KKT || KTO
         stopped=' converged. ';
      elseif Slowed && Feasible
         stopped=' slowed.    ';
      else
         stopped='            ';
      end
      SKTstr = sprintf('%31s%14s %s','Schittkowski KTO','=',num2str(SKT));
      if KTO,        SKTstr(33)='*'; end
      if KTO && KKT, SKTstr(34)='*'; end
      disp([ SAO, stopped, 'Final objective function value = ',num2str(f)])
      disp(['               Lagrangian gradient   2-norm = ',num2str(norm(Lagrangian))])
      disp(['               Lagrangian gradient inf-norm = ',num2str(norm(Lagrangian,inf))])
      disp(SKTstr)
      disp(['               Optimality Tolerance         = ',num2str(TolOpt)])
      TolLM = sqrt(eps)*max([1;lambda.ineqlin]);
      active = find(lambda.ineqlin>TolLM);
      if strcmp(options.Display,'Iter') && numel(active)<=20
         disp( '               Lagrange Multipliers   (j)')
         if any(active)
            fprintf('%34.4g  %4.0f\n',[lambda.ineqlin(active), active]');
         end
         bound = find( lambda.lower>Tolvb | lambda.upper>Tolvb );
         if any(bound)
             disp( '               Lower    Upper         (i)')
             fprintf('%22.4g  %10.4g  %4.0f\n',...
                 [lambda.lower(bound),...
                  lambda.upper(bound), bound]')
         end
      end
   else
      disp([SAO,' did NOT converge in ',num2str(Iter),' iterations.'])
   end
   if TR.trust
      if TR.filter.flag
         merit_filter = 'filter';
      else
         merit_filter = 'Merit function';
      end
      if TR.SimpleTrust
         simple = 'simple ';
      else
         simple = '';
      end
      disp(['Trust Region Strategy uses ',simple,merit_filter])
      disp('* Dominates prior points')
      disp('+ Nondominated')
      disp('- Dominated by prior point(s)')
      if TR.adapt
         disp('! Trust Radius set by Merit function minimization')
         disp('_ Trust Radius set by target Trust Ratio')
      end
      if TR.filter.flag || TR.adapt
         disp('f/g/m Objective/Constraint/Merit governs Trust Ratio')
      end
   end
end
if TR.stat<0 && ~Converged
   warning('sao_trust:linprog',out.message)
end
if KKT || KTO
   Converged=1;
elseif Slowed
   Converged=2;
elseif Iter>=options.MaxIter
   Converged=0;
else
   Converged=-1;
end
%  ------------------------------------------------------------------------



%% Nested internal sub-functions
   function [f,g,h,mcon,mc] = FunEval( x ) % function evaluation wrapper
      if UserKnowsActive % reset fun to use current active set
         fun = @(x) Fun(xshape(x),active,varargin{:});
      end
      if abs(nargout(Fun))==2
         [f,g] = fun(x);
         h=[];
      elseif abs(nargout(Fun))==3 || ...
            contains(erase(func2str(Fun),' '),'@(x)fghx')
         [f,g,h] = fun(x);
      else
         f = fun(x);
         g = [];
         h = [];
      end
      unconstrained = unconstrained || isempty(g) || ...
                      (length(g)==1 && isinf(g));
      if unconstrained
         g = -1;
      else
         g=g(:);
      end
      nfuneval=nfuneval+1;
      [mg,mj] = max(g);
      [mh,mk] = max(abs(h));
      if isempty(h) || mg>=mh
         mcon=mg;
         mc=mj;
      else
         mcon=mh;
         mc=mj+mk;
      end
      % Call user defined outputfunction
      if OutputFcn || PlotFcn || nargout>3
         output.iteration = Iter;
         output.funcCount = nfuneval;
         output.gradCount = ngrdeval;
         output.fval      = f;
         output.constrviolation = mcon;
         output.lambda          = lambda;
         output.stepsize          = TR.radius;
         output.trustregionradius = TR.radius;
         output.firstorderopt = norm(Lagrangian,inf);
         if OutputFcn
            stop = options.OutputFcn(x,output,'iter');
            if stop, warning('sao_trust:FunEval','OutputFcn stop'), end
         end
         if PlotFcn
            plotFcns(options.PlotFcns,x,output,'iter');
         end
      end
  end

   function [gradf,gradg,gradh,active,cutoff] = GradEval(x,active,nretain)
      if nargin<2, active=[]; end
      if nargin<2 || (nargin>2 && nretain>=ncon) % evaluate all gradients
         cutoff = inf;
         active = 1:ncon; % active used in grdstr
      elseif isempty(active)
         cutoff = max([abs(options.cutg),max(mg),10*TolCon]);
         active  = find(g>=min(0,mg)-cutoff);
      else
         cutoff = abs(min(g(active)));
      end
      if nargin>2 && nretain<ncon
         [~,g_order]=sort(g,'descend');
         cutoff = max(cutoff,abs(g(g_order(nretain))));
         active  = find(g>=min(0,max(g))-cutoff);
      end
      if abs(nargout(Fun))==2
         [gradf,gradg] = eval(grdstr); gradf=gradf(:); gradh=[];
      elseif abs(nargout(Fun))==3 || ...
            contains(erase(func2str(Fun),' '),'@(x)fghx')
         [gradf,gradg,gradh] = eval(grdstr); gradf=gradf(:);
      elseif abs(nargout(Fun))==2
         [gradf,gradg] = eval(grdstr); gradf=gradf(:); gradh=[];
      else
         gradf = eval(grdstr); gradf=gradf(:); gradg=[]; gradh=[];
      end
      if isempty(gradg) % unconstrained
         gradg = zeros(size(gradf));
      elseif size(gradg,1)~=length(x)
         error('GradEval:dg','gradg is wrong size')
      end
      ngrdeval = ngrdeval + 1;
   end



function [dx,TR,out,lambda]=saoprog(TR,lambda)
   % Sequential approximate optimization program
   % solves linear or quadratic program
   % after possible intermediate variable transformation.
   persistent H % optQP initialized/shared with sao_trust to reset H
   lp = @linprog;
   if isOctave
      MaxIterations = max(500,100*(ndv+ncon+size(Problem.Aineq,1)+size(Problem.Aeq,1)));
      optLP = optimset('Display','off','MaxIter',MaxIterations,'TolFun',TR.TolCon/10);
      lp = @lpOctave;
   elseif verLessThan('optim','7.5')
      optLP = optimoptions(@linprog,'Display','off','Algorithm','active-set'); %#ok<LINPROG>
      warning('off','optim:linprog:AlgOptsWillError');
   elseif mcon>TolCon % dual-simplex won't return most feasible solution
      % interior-point-legacy will return least infeasible design
      optLP = optimoptions(@linprog,'Display','off','Algorithm','interior-point-legacy');
   elseif ndv>=options.manyDV || ... % large-scale
          all(gradg(:)==0) % dual-simplex crashes when no constraints (g<0,gradg=0)
      optLP = optimoptions(@linprog,'Display','off','Algorithm','interior-point');
      optLP.MaxIterations = 10*(ndv+ncon+size(Problem.Aineq,1)+size(Problem.Aeq,1));
   else
      optLP = optimoptions(@linprog,'Display','off','Algorithm','dual-simplex');
   end
   QPP = (UserHessian && ~MPEA) || (BFGS && Iter>1);
   LPP = ~QPP || QMEA;
   if QPP && isempty(optQP)
      optQP = optimset('Display','off');
      H = eye(ndv);
   end
   TR.mpea.x0 = x0;
   TR.mpea.f0 = f0;
   TR.mpea.g0 = g0;
   TR.mpea.x  = x;
   TR.mpea.f  = f;
   TR.mpea.g  = g;
   TR.mpea.dxlb = dxlb;
   TR.mpea.dxub = dxub;
   TR.mpea.gradfx = gradf;
   TR.mpea.gradgx = gradg;
   TR.mpea.gradhx = gradh;
   TR.mpea.lambda0 = lambda;
   
   % Transform to intermediate variables
   [y0,dylb,dyub,gradfy,gradgy,TR]=mpea(TR);
   A = [ gradgy(:,active)', Problem.Aineq];
   b = [-g(active),         Problem.bineq];
   Aeq = Problem.Aeq;
   beq = Problem.beq;
   dx = [];
   
	% Solve LPP or QPP
   if LPP || (QMEA && Iter<2)
      [dy,~,TR.stat,out,lambda]=lp(gradfy,A,b,Aeq,beq,dylb,dyub,optLP);
   elseif QPP
      if isempty(lambda)
         lambda = guessLM(g,gradfy,gradgy,gradh);
      else % use linear approximation Lagrange multipliers
         lambda.ineqnonlin = lambda.ineqlin;
         lambda.eqnonlin   = lambda.eqlin;
      end
      if ~TR.rejected % Update Hessian if last point accepted
         if UserHessian
            H = options.HessianFcn( x0, lambda );
         elseif ndv < options.manyDV % Powell's modified BFGS updated
            dx = x-x0;
            H = PmBFGS( H, dx, gradf-TR.mpea.gradfxp, ...
                               gradg-TR.mpea.gradgxp, [], ...
               lambda.ineqnonlin, lambda.eqnonlin );
         else % Limited memory BFGS
            dx = x-x0;
            H = lmBFGS( dx, gradf, gradg, gradh, lambda );
         end
      end
      [dy,~,TR.stat,out,lambda]=quadprog(H,gradfy,A,b,Aeq,beq,dylb,dyub,x0,optQP);
      if TR.stat==-6 || (TR.stat==0 && (isempty(lambda) || isOctave))
         H1 = H - diag(repmat(1.01*min(eig(H)),ndv,1));% Marquardt modif.
         [dy,~,TR.stat,out,lambda]=quadprog(H1,gradfy,A,b,Aeq,beq,dylb,dyub,x0,optQP);
      end
   end
   
   % If failed, find least infeasible solution
   if isOctave
      if isempty(lambda) % Maxiter and infeasible return no lambda
         lambda = guessLM(g,gradfy,gradgy,gradh,dy,dylb,dyub);
      end
   elseif (strcmp(optLP.Algorithm,'interior-point') && ... % linprog bug
       TR.stat==1 && out.constrviolation > TR.TolCon)
      optLP.Algorithm='interior-point-legacy';
      [dy,~,TR.stat,out,lambda]=lp(gradfy,A,b,Aeq,beq,dylb,dyub,optLP);
      lp_inf_str = ' iplegacy';
   end
   if ( TR.stat < 0 && ~isempty(dy) && ...
        max(dy-dyub)< TolX && max(dylb-dy)< TolX && ...
        max(A*dy-b) < TolCon ) % live with this solution, but notify
      warning('sao_trust:linprog',out.message)
      lambda = TR.mpea.lambda0;
      lp_inf_str = ' inf_LP';
   elseif ( TR.stat < 0 && abs(mcon) < TolCon )
      dy = zeros(size(x));
      lambda = TR.mpea.lambda0;
      lp_inf_str = ' feas_LP';
   elseif (TR.stat==-2 || TR.stat==-5) && ... % No feasible point
          (abs(mcon) > TolCon || ...
          (~isempty(dy) && (any(dy<dylb-TolX) || any (dy>dyub+TolX))))
      j  = g(active)>TolCon;                            % Add slack.
      c  = [gradfy+gradgy(:,j)*max(TR.penalty(j),1);1]; % merit fcn is obj.
      gl = g(active).*max(TR.penalty,1); % weighted linearized constraints
      A  = [(gradgy*diag(max(TR.penalty,1))).', -gl, Problem.Aineq];
      b  = [-gl, Problem.bineq];
      dy = [zeros(size(y0)); 1];
      [dy,~,TR.stat,out,lambda]=lp(c,A,b,Aeq,beq,[dylb;0],[dyub;1],dy,optLP);
      if TR.stat<0 && isempty(dy)
         error('sao_trust:inf',out.message)
      elseif TR.stat==0 && isempty(lambda) && ~isempty(dy)
         lambda = guessLM(g,c,A,Aeq,dy,[dylb;0],[dyub;1]);
      elseif isempty(lambda) || ~any(dy)
         error('sao_trust:lpOctave','No solution from linprog')
      end
      dy = dy(1:end-1);
      TR.gapx = g(active) + gradgy'*dy;
      j       = TR.gapx>TolCon;
      lambda.ineqlin(j) = lambda.ineqlin(j) + gl(j)*lambda.upper(end);
      lambda.lower      = lambda.lower(1:end-1);
      lambda.upper      = lambda.upper(1:end-1);
      lp_inf_str = ' slack_LP';
   end
      
   %  Solve QPP for QMEA
   if QMEA && Iter > 1
      x1 = mpea(TR,y0+dy); % incorporate LPP in reduced sub-space
	   TR.fapx = f         + gradfy'*dy;
	   TR.gapx = g(active) + gradgy'*dy;
      [dx,dy,TR,out2,lambda]=qmeaprog(f,g,gradfy,gradgy,dy,x1,TR);
      if ~isempty(out2), out=out2; end
      if ~TR.qmea.LP, lp_inf_str=[]; end
   end
   
   % Transform intermediate variable y back to original design variable x
   if isempty( dx )
%     dy = max(dylb, min(dyub, dy));
      y  = y0 + dy;
      x2 = mpea(TR,y);
      x2 = max(TR.Problem.lb, min(TR.Problem.ub, x2));
      dx = x2 - x;
%     dx = max( dxlb, min( dxub, x2-x ) );
	   TR.fapx = f         + gradfy'*dy;
	   TR.gapx = g(active) + gradgy'*dy;
   end
end



%% Sub-function to guess the Lagrange Multipliers
function lambda = guessLM(g,FP,GP,HP,x,lb,ub)
   if nargin<4, HP=[]; end
   if nargin>4
      il = x<=(lb+Tolvb);
      iu = x>=(ub-Tolvb);
      free = ~(il | iu);
      fp = FP(free);
      if ~isempty(GP), gp = GP(free,active); else, gp=[]; end
      if ~isempty(HP), hp = HP(free,:);      else, hp=[]; end
   end
   if nargin<5 || ~any(free)
      fp = FP;
      gp = GP(:,active);
      hp = HP;
   end
      % unconstrained problem
   if (isempty(gp) || (length(gp)==1 && gp==0)) && isempty(hp)
      lambda=[];
      lmg=[];
      lmh=[];
   else % constrained
      lmg = zeros(ng,1);
      guess = -[gp, hp] \ fp;
      if nh>0
         lmh = guess(numel(active)+1:end);
      else
         lmh = [];
      end
      if ng>0
         lmg(active) = guess(1:numel(active));
         if any(lmg<0)
            lmg   = zeros(ng,1);
            guess = zeros(numel(active),1);
            den = gp'*fp;
            if any(den==0)
               guess(den~=0) = -fp'*fp ./ den(den~=0);
            else
               guess = -fp'*fp ./ den;
            end
            for j = guess<0 % revise inequality negative LM
               guess(j) = max(-gp(:,j)./fp);
            end
            lmg(active) = guess;
            if max(g)>eps
               lmg = lmg .* exp( g/max(g) - 1 );
            else
               lmg = lmg .* exp( g - max(g) );
            end
            % positive multipliers for ineq. (zero out neg multipliers)
            lmg( lmg<0 ) = 0;
         end
      else
         lmg = [];
      end
      lambda.ineqlin = lmg;
      lambda.eqlin   = lmh;
      lambda.ineqnonlin = lmg;
      lambda.eqnonlin   = lmh;
   end
   if nargin>4
      lambda.lower = zeros(size(x));
      lambda.upper = zeros(size(x));
      if any(il)
         if any(lmg)
            lambda.lower(il) = FP(il) + GP(il,lmg>0)*lmg(lmg>0);
         else
            lambda.lower(il) = FP(il);
         end
         if any(lmh)
            lambda.lower(il) = lambda.lower(il) + HP(il,:)*lmh;
         end
         lambda.lower(il) = abs(lambda.lower(il));
      end
      if any(iu)
         if any(lmg)
            lambda.upper(iu) = -(FP(iu) + GP(iu,lmg>0)*lmg(lmg>0));
         else
            lambda.upper(iu) = - FP(iu);
         end
         if any(lmh)
            lambda.upper(iu) = lambda.lower(iu) - HP(iu,:)*lmh;
         end
         lambda.lower(iu) = abs(lambda.lower(iu));
      end
   end
end

if options.debug, fclose(TR.dbgfid); end
end
%  ------------------------------------------------------------------------



%% Finite Difference Gradient internal sub-function
function [df,dg,dh] = fdgrd( fgh, x0, f0, g0, h0, options, active ) %#ok<DEFNU>
%  FDGRD      Calculates first forward finite difference gradients
%             of objective and constraint functions.
%
%  usage:        [df,dg,dh]=fdgrd(fgh, x0, f0, g0, h0, options,sx,active)
%
%  inputs:      fgh      - function evaluation call for f,g,h
%               x0       - current design variable vector
%               f0       - objective value at x0
%               g0       - constraint values at x0
%               h0       - constraint values at x0
%               options  - data structure with fields:
%                          xmin: minimum finite difference step
%                          xmax: maximum finite difference step
%               sx       - inline function to re-shape x
%               active   - active constraint index/boolean vector
%               Pn       - optional variables directly passed to fcnstr
%
%  outputs:     df       - finite difference objective gradient vector
%               dg       - finite difference constraint gradients matrix
%
%  Written by:   Robert A. Canfield
%
%  Created:      4/14/06
%  Modified:      5/5/08
%                9/26/15 - active constraints & complex step
%                10/2/16 - handle empty FinDiffRelStep
%                2/16/18 - fd w/o active
%               11/11/19 - gradh

% Local variables
%
% dx....... Finite difference step
% f........ Perturbed objective value
% g........ Perturbed constraint values
% i........ Loop variable for current design variable perturbation

%--BEGIN
%
delx=1e-8;
if nargin<6 
   xmin=1e-8;
   xmax=1e-1;
else
   xmin=options.DiffMinChange;
   xmax=options.DiffMaxChange;
   if isfield(options,'FinDiffRelStep') && ~isempty(options.FinDiffRelStep)
      delx=options.FinDiffRelStep;
   end
end
if xmin<eps, xmin=1e-8; end
if nargin<7 || isempty(active), active=1:numel(g0); end
% Less stringent relative change in x than 1.e-8 may be 
% needed for implicit functions that require numeric evaluation.
nac = numel(g0(active)); % number of constraints
nh  = numel( h0 );
nx  = length(x0);
df = zeros(nx,1);
dg = zeros(nx,nac);
dh = zeros(nx,nh);
dx = min( max(delx*abs(x0(:)),xmin), xmax );
switch nargin(fgh)
   case 1
      fgeval = @(x,active) fgh(x);
   case 2
      fgeval = @(x,active) fgh(x,active);
   otherwise
      fgeval = @(x,active) fgh(x,active,varargin);
end

% Forward Finite Difference or Complex Step loop.
for n=1:length(x0(:))
   x = x0;
   if strcmpi(options.FinDiffType,'complex')
      x(n) = x(n) + 1i*eps;
      [f,g] = fgeval(x,active);
      df(n) = imag(f) / eps;
      if isempty(g) || (length(g)==1 && isinf(g))
         dg = [];
      elseif nac
         dg(n,:) = imag(g(:)) / eps;
      end
      if isempty(h0)
         dh = [];
      else
         dh(n) = imag(h) / eps;
      end
   else
      x(n) = x(n) + dx(n);
      [f,g] = fgeval(x,active);
      df(n) = (f - f0) / dx(n);
      if isempty(g) || (length(g)==1 && isinf(g))
         dg = [];
      elseif nac
         dg(n,:) = (g(active) - g0(active)).'/ dx(n);
      end
      if isempty(h0)
         dh = [];
      else
         dh(n) = (h - h0).' / dx(n);
      end
   end
end
end



%%  Powell's modified BFGS Update of Lagrangian Hessian
function H = PmBFGS( H, s, delgradf, delgradg, delgradh, lg, lh )
   if isempty(H),  H=diag(ones(size(s))); end
   if isempty(lg), lg=0; delgradg=0; end
   if isempty(lh), lh=0; delgradh=0; end
   ag  = lg>1e-12; % active inequality constraints
   z = H*s;
   y = delgradf + delgradg(:,ag)*lg(ag) + delgradh*lh;
   theta = 0.8*s'*z/(s'*z-s'*y);
   w = theta*y + (1-theta)*z;
   H = H + w*w'/(s'*w) - z*z'/(s'*z);
end