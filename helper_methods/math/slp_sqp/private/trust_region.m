function TR=trust_region(TR,x,dx,vlb,vub,f0,f,gradf,g0,g,gradg,lambda)
% trust_region - determine trust ratio, move limits, binding constraints & penalties
%
%--Input/Output
%  TR.........   parameters and options for Trust Region (TR) strategy (structure)
%  .MoveLimit    Initial L-inf relative move limit for trust radius (default=0.2)
%  .MoveRelative Move limits relative to current x instead of x0
%  .Reject       Trust ratio value to reject new iterate    (default <0.1)
%  .Contract     Trust ratio value to contract trust region (default <0.2)
%  .Expand       Trust ratio value to expand   trust region (default >0.75)
%  .MoveExpand   Move Limit expansion factor              (default 2.0)
%  .MoveContract Move Limit contraction/reduction factor  (default 0.5)
%                for TrustRegion='off' apply every iter   (default 0.8)
%  .TrustRegion  Strategy options:
%                'simple' = exact L1 single penalty, mu*max(0,g) (default)
%                'merit'  = multiple-penalty parameter L1 merit function
%                'filter' = TR filter instead of merit descent function
%                'TRAM'   = TR adaptive move limit bounds (with merit)
%                'TRAM-filter'   combination
%                'simple-filter' combination
%
%--Input
%  x.......... design variable current values (vector)
%  dx......... change in design variable values from last iteration (vector)
%  vlb........ design variable lower bounds (vector)
%  vub........ design variable upper bounds (vector)
%  f0,f....... previous and current objective function values (scalar)
%  gradf...... gradient of objective function (vector)
%  g0,g....... previous and current constraint values (vector)
%  gradg...... gradients of constraints wrt design variables (matrix)
%  lambda..... Lagrange multipliers for constraints (structure)
%
%--Output
%
%  TR.delx....... bound on change in design variables (vector)
%  TR.rejected... flag for rejection or acceptance of current design iterate
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%  Created:       10/ 2/16
%  Last modified:  7/20/20

%--Modifications
%  11/ 7/16 - Handle missing or null TypicalX
%  11/ 9/16 - Trust Region Approximation Method (TRAM)
%  11/11/16 - TR filter option
%  11/14/16 - simple exact L-1 penalty merit function
%  11/22/16 - TR.options
%   4/ 9/17 - Unblock filter & defaut is filter
%   4/18/17 - MoveRelative option added
%   4/23/17 - FCD modified for reducing constraint violation
%   5/29/17 - Filter block OK for feasible
%   1/24/18 - Adjust penalty/merit after accept/reject, not before
%   2/25/18 - smarter TypicalX
%   4/21/18 - account for TR increased approximate objective, numeric g=0
%             don't allow duplicate point through the filter
%   4/24/18 - TRAM line search only if FCD satisfied
%   4/13/19 - TolXstr
%   11/3/19 - Reject if MoreViolated
%  11/10/19 - den nested sub-function
%   1/16/20 - some TR processing moved to saocrkargin.m
%   2/12/20 - Dominates last point is more stringent
%   7/20/20 - TypicalX='center'
%
% Wujek, B. A., and Renaud, J. E. "New Adaptive Move-Limit Management
% Strategy for Approximate Optimization, Part I," AIAA J. Vol. 36, No. 10,
% 1998, pp. 1911-1921
%
% Nocedal, J., and Wright, S.J. Numerical Optimization. New York: Springer, 2006.
% Algorithms 4.1 for TR & 15.1 for filter; Equation (15.4) for simple merit
%
% For the TR filter algorithm, also see 
% Fletcher, R., and Leyffer, S. 
% "Nonlinear programming without a penalty function," 
% Mathematical Programming Vol. 91, No. 2, 2002, pp. 239-269.
% doi: 10.1007/s101070100244

%% Process TR inputs and options
if isfield(TR,'TrustRegion'), TrustRegion=TR.TrustRegion; else, TrustRegion='on'; end
Filter = (strcmpi(TrustRegion,'on') ||  contains(lower(TrustRegion),'filter'))...
                                    && ~contains(lower(TrustRegion),'merit');
if TR.adapt && isempty(which('trust_adapt','in','trust_region'))
   error('trust_region:noTRAM','Trust Region Adaptive Move Limit not available, yet.')
end
MoveRelative = strcmpi(TR.MoveRelative,'on');
% Other TR fields used:
%       TR.cutoff
%       TR.SimpleTrust
%       TR.options.TolCon
%       TR.options.TolX
%       TR.options.TypicalX

%% Local variables
[mg0,mj0] = max(g0);
[mg, mj]  = max(g);
%TolXstr = [];

%% Initialization (before first optimization iteration)
if ~isfield(TR,'delx') || isempty(TR.delx)
   % Legacy for slp_trust -----------------------------------
   if ~isfield(TR,'TolFun'), TR.TolFun=TR.options.TolFun; end
   if ~isfield(TR,'TolCon') || isempty(TR.TolCon)
                             TR.TolCon=TR.options.TolCon; end
   if ~isfield(TR,'TolX'),   TR.TolX  =TR.options.TolX;   end
   if ~isfield(TR,'TypicalX')
      TypicalX=[];
   else
     TypicalX=TR.TypicalX;
   end
   % --------------------------------------------------------
   if ~isempty(TypicalX) && isnumeric(TypicalX)
      if length(TR.TypicalX)~=length(x)
         error('trust_region:TypicalX','TR.TypicalX not length of x')
      else
         TypicalX=TypicalX(:);
      end
   else
      if isempty(TypicalX) && all( abs(x) > TR.TolX )
         TypicalX = x(:);
      else
         CenterX = (abs(vub) + abs(vlb))/2;
         Xones = ischar(TypicalX) && contains(TypicalX,'one');
         if ~Xones && all( CenterX > TR.TolX ) && all( CenterX < 1e8 )
            TypicalX = CenterX(:);
         else
            TypicalX = ones(size(x(:)));
         end
      end
   end
   TR.delx = max(TR.TolX, TR.MoveLimit*abs(TypicalX));
   if isinf(g)
      Lambda = 0;
   else
      Lambda = norm(gradf) ./ max(eps,sqrt(diag(gradg'*gradg)));
   end
   if TR.SimpleTrust
      TR.penalty = max(Lambda);
   else
      TR.penalty = Lambda;
   end
   TR.Merit = trust_merit(f,g,TR.penalty);
   TR.bindLM = find(g>=min(0,mg)-TR.cutoff);
   TR.contracted = false;
   TR.rejected=[];
   TR.output.RadiusFraction=[];
   TR.filter.flag = Filter;
   TR.filter.f  = f0;
   TR.filter.mg = mg0;
   TR.filter.mj = mj0;
   return
else
%% Restore local variables from TR
   tol = TR.Tolvb;
   mvBound = ( (lambda.lower>tol & x>vlb+tol) ... % active move limit
             | (lambda.upper>tol & x<vub-tol) ) & (TR.delx-abs(dx))<tol;
   % Recover saved values from TR
   MoveLimit0 = TR.MoveLimit;
   Merit0     = TR.Merit;
   penalty0   = TR.penalty;
   delx0      = TR.delx;
end

%% Determine binding constraints and their penalties
TR.Bound = any( mvBound ); % move-limit-bound not at variable bounds
if TR.stat<0 % linprog did not converge; Lagrange multipliers unreliable
   bindLM=[];
else
   bindLM = find(g>=min(0,mg)-TR.TolCon ...
      | lambda.ineqlin>tol*max(lambda.ineqlin));
   TR.bindLM = bindLM;
end

%% Actual and approximate merit function values
f1 = TR.fapx;
g1 = TR.gapx;
[Merit,penalty] = trust_merit( f, g, penalty0, lambda, bindLM );
MeritApx        = trust_merit( f1,g1,penalty );
Violated     = mg > TR.TolCon;
MoreViolated = mg > mg0 && Violated;

%% Objective/Constraint-Violation Filter
tolf = tol*lambda.ineqlin(mj);
if ~TR.trust
   FilterStr = ' ';
elseif all( f < TR.filter.f & max(0,mg) <= max(0,TR.filter.mg) )
   FilterStr = '*'; % Dominates all previous designs
   NonDom = 2;
elseif any(TR.filter.f <= f+tolf & max(0,TR.filter.mg) <= max(0,mg+tol))
   FilterStr = '-'; % Dominated
   NonDom = 0;
else
   FilterStr = '+'; % Nondominated
   NonDom = 1;
end
if f>f0 && max(0,mg)>=max(0,mg0) % Dominated by last point
   NonDomLast = 0;
elseif f<f0-tolf && mg<max(tol,mg0-tol) % Dominates last point
   NonDomLast = 2;
else
   NonDomLast = 1 ;
end

%% Trust Region Strategy
if TR.trust
   % Trust Ratio
   tolg = TR.TolCon/10;
   j = unique([mj0,mj,find(g0>tolg | g>tolg)']);
   g0j = max(g0(j),0);
   g1j = max(g1(j),0);
   if f1 < f0 % approximate objective decreased (satisfies FCD wrt eps)
      TrustRatio_f = (f0-f) / max(f0-f1,eps);
   else       % approximate objective increased (maybe to make feasible)
      TrustRatio_f = (f0-f) / den(f0-f1);
   end
   TrustRatio_g = min( (g0(j)-g(j)) ./ den(g0(j)-g1(j)) );
   TrustRatio_M = (Merit0-Merit) / den(Merit0-MeritApx);
   if isfield(TR,'MPEA') && strcmpi(TR.MPEA,'beta')
      TR.Ratio_f = TrustRatio_f;
      TR.Ratio_g = zeros(size(g));
      TR.Ratio_g(j) = (g0j-g(j)) ./ den(g0j-g1j);
   end
   if Filter
      if all([g0j;g1j] <= tolg) && ~Violated
         [TR.Ratio,r] = min([TrustRatio_f, inf, TrustRatio_M]);
      else
         [TR.Ratio,r] = min([TrustRatio_f, TrustRatio_g]);
      end
      fgmstr='fgm';
      FilterStr=[fgmstr(r),' ',FilterStr];
   else
      TR.Ratio = TrustRatio_M;
   end

%% Accept or reject new design point
   if Filter
      TR.rejected = Violated && ~NonDom ... % Dominated
                             || ~NonDomLast;
   elseif TR.SimpleTrust
      TR.rejected = TR.Ratio < TR.Reject; % trust ratio too low
   else
      TR.rejected = ~NonDomLast || ... % dominated
                    (Merit > Merit0 && MoreViolated); % merit & mg too high
   end
   % Increase penalty if violation increased
   if Merit<Merit0 && MoreViolated && ~TR.SimpleTrust
     penalty(mj) = penalty(mj) + (Merit0-Merit)/mg;
     Merit = Merit0; % Reset merit to force contraction
   end

   %% Fraction of Cauchy Decrease
   mgapx = max(TR.gapx);
   FCD = MeritApx < Merit0 ... % Sufficient FCD
         || (mgapx > TR.TolCon && mgapx < mg0);
   if TR.rejected
      FCDstr=' Rejected';
      Merit = Merit0;
   else
      FCDstr=[];
   end
   if ~FCD, FCDstr=strcat(FCDstr,' ~FCD'); end

   %% Filter or Merit function determines Trust Region
   Expand = TR.Ratio > TR.Expand && ~MoreViolated && ~TR.contracted && TR.Bound;
   if Filter
%     Contract = TR.rejected  || TR.Ratio < tol || ... % removed 7/20/20
%               (NonDomLast<2 && TR.Ratio<TR.Contract);
      Contract = TR.rejected  || TR.Ratio < TR.Contract;
      Expand   = NonDom  && Expand;
      if Contract && Expand, error('Contract && Expand both true!'), end
   else
      Contract = TR.rejected || ~FCD || TR.Ratio < TR.Contract;
   end

   %% Adapt Move Limit bounds (Trust Region Approximate Model)
   MoveReduce = TR.MoveContract;
   MoveExpand = TR.MoveExpand;
   TRAMstr=[];
   if TR.adapt && FCD
      TR.Merit      = Merit;
      TR.Merit0     = Merit0;
      [R,TRAMstr] = trust_adapt(f0,f,f1,g0,g,g1,gradf,gradg,dx,penalty0,penalty,TR);
      MoveReduce = R;
      MoveExpand = R;
   end
   if MoveReduce >= 1 && Contract
      error('slp_trust:MovRed','Trust Region Strategy Move Reduction must be <1')
   end

   %% Apply Move Limit factor to design variable change (delx)
   if Contract
% %   3/10/20 - Tighten contraction of unbound point % removed 7/19/20
%       if ~any(mvBound)
%          MoveReduce = max(max(abs(dx)./TR.delx),MoveReduce)*MoveReduce;
%       end
      TR.delx      = MoveReduce*TR.delx;
      TR.radius    = MoveReduce;
      TR.MoveLimit = MoveReduce*MoveLimit0;
      if all(TR.delx < TR.TolX)
         disp('Move limits contract < TolX')
         %TolXstr = ' ML<TolX';
      end
   elseif Expand && TR.Bound
      if TR.rejected, error('Rejected should not Expand'), end
      TR.delx(mvBound) = MoveExpand*TR.delx(mvBound);
      TR.radius        = MoveExpand;
      TR.MoveLimit     = MoveExpand*min(1,MoveLimit0);
   else
      TR.radius = 1;
   end
   TR.contracted = TR.radius < 1;
   TR.filter.f(end+1)  = f;
   TR.filter.mg(end+1) = mg;
   TR.filter.mj(end+1) = mj;
   TR.filter.ftype = Merit < Merit0 && FCD;
   TR.filter.str = strcat(FilterStr,TRAMstr,FCDstr);
%  TR.filter.NonDom     = NonDom;
%  TR.filter.NonDomLast = NonDomLast;
   if (TR.rejected && ~TR.contracted),error('Rejected should Contract'),end

else
   %% No trust region strategy (ad hoc move limits)
   if TR.Bound || mg>=mg0
      if MoveRelative
         %TR.delx = max(TR.TolX, TR.MoveLimit*abs(x(:)));
         TR.delx = TR.MoveLimit*abs(x(:));
      else
         TR.delx = TR.MoveContract*TR.delx;
      end
   end
   TR.MoveLimit = TR.MoveContract*MoveLimit0;
   TR.radius = [];
   TR.Ratio  = [];
   TR.rejected=false;
   TR.filter.str = FilterStr;
%  TR.filter.NonDom = NonDomLast;
end

%% Save local variables to return for next iteration
TR.Merit      = Merit;
TR.Merit0     = Merit0;
TR.bound      = mvBound;
TR.penalty    = penalty;
if ~isempty(TR.radius)
   TR.output.RadiusFraction(end+1) = min(TR.delx./delx0)/TR.radius;
end

%% Nested sub-function
   function d=den(d)
      d( d>=0 & d< eps ) =  eps;
      d( d< 0 & d>-eps ) = -eps;
   end
end