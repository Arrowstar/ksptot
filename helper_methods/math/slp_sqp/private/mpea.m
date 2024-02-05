function [y,dylb,dyub,gradfy,gradgy,TR]=mpea(TR,x)
%  Multipoint Exponential Approximation Transformation
%
% Canfield, R. A. "Quadratic Multipoint Exponential Approximation:
% Surrogate Model for Large-Scale Optimization," 12th World Congress of
% Structural and Multidisciplinary Optimization (WCSMO12). Vol. Advances in
% Structural and Multidisciplinary Optimization, Springer International
% Publishing, Braunschweig, Germany, 2017, pp. 648-661.
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:         4/2/17
%  Last modified: 10/10/20
%
%--Input
%
%  lambda.... Lagrange multpliers from last iteration
%  x0........ most recent point (may be rejected)
%  xp........ previous point with gradients
%  xr........ rejected point (empty if accepted)
%  g0........ most recent constraint values (may be rejected w/o gradients)

%--Modifications
%   2/1/18 - variable trust ratios govern exponent instead of statistics
%   2/2/18 - wash out memory with historical trust ratios
%   2/8/18 - refactored as mpea and qmea
%  4/19/18 - option to limit to current sensitivity
%  4/22/18 - check function matching
%  4/24/18 - dylb/ub check for crossing zero
%   5/3/18 - save internal variables instead of appending to TR
%   4/7/19 - reset P_his after slack variable from last iter
%  7/28/19 - lset used to scan P; guard against p=0
% 11/16/19 - compare to linear (p=1)
%  1/10/20 - Jacobi iteration for p-Beta
%  2/12/20 - determine linear f,g for QMA/QMEA
%  6/24/20 - p=-1 instead of p=1 for opposite derivative sign, per DAKOTA
% 10/10/20 - check x=xp for pBiter

% Previous Lagrangian sensitivity for legacy MPEA
persistent iter_mpea P_his Pmean Psigma pmask

%% Return inverse transformation 
if nargin==2 && nargout<=1 % really x=y^(-p)
   if isfield(TR,'p') && ~isempty(TR.p) && ~all(TR.p==1)
      y = x.^(1./TR.p);
   else
      y = x;
   end
   return
elseif nargin<2
   x = TR.mpea.x;
end

%% Recover state variables from sao_trust
dxlb    = TR.mpea.dxlb;
dxub    = TR.mpea.dxub;
gradf   = TR.mpea.gradfx;
gradg   = TR.mpea.gradgx;
gradfxp = TR.mpea.gradfxp;
g       = TR.mpea.g;

%% No previous iteration or not MPEA, return y=x
if isempty(gradfxp) || strcmpi(TR.MPEA,'off')
   y    = x;
   dylb = dxlb;
   dyub = dxub;
   gradfy = gradf;
   gradgy = gradg;
   if isempty(gradfxp)
      TR.p=ones(size(x));
      TR.p0 = TR.p;
      TR.pj = ones(size(gradg));
      TR.mpea.linear.f = true;          % Linear objective flag
      TR.mpea.linear.g = true(size(g)); % Linear constraints flag
      if strcmpi(TR.MPEA,'legacy')% initialize (clear) persistent variables
         iter_mpea = 0;
         P_his=[]; Pmean=[]; Psigma=[]; pmask=[];
      end
      return
   end
end

%% Identify linear constraints
[ndv,ncon] = size(gradg);
x0      = TR.mpea.x0;
xp      = TR.mpea.xp;
xr      = TR.mpea.xr;
f0      = TR.mpea.f0;
g0      = TR.mpea.g0;
fp      = TR.mpea.fp;
gp      = TR.mpea.gp;
gradgxp = TR.mpea.gradgxp;
% [mg,mj] = max(g);
if isempty(xr)
   dx = x0 - x; % Expansion from current to previous accepted point
else
   dx = xr - x; % Expansion from current to previous rejected point
   f0 = TR.mpea.fr;
   g0 = TR.mpea.gr;
end
if norm(dx)<eps, error('Last point and current are same'), end
fapx = TR.mpea.f + gradf.'*dx;
gapx = TR.mpea.g + gradg.'*dx;
TR.mpea.linear.f = abs(f0-fapx) < TR.TolFun & TR.mpea.linear.f;
TR.mpea.linear.g = abs(g0-gapx) < TR.TolCon & TR.mpea.linear.g;
if TR.mpea.linear.f && ~isempty(gradfxp)
   TR.mpea.linear.f = all( abs(gradf-gradfxp) < TR.TolFun, 1);
end
if ~isempty(gradgxp) && any(TR.mpea.linear.g)
   TR.mpea.linear.g = all( abs(gradg-gradgxp) < TR.TolCon, 1).' & ...
   TR.mpea.linear.g;
end

if strcmpi(TR.MPEA,'off'), return, end

%% Lagrange Multipliers before and after current iteration
lambda = TR.mpea.lambda;
if isfield(TR,'Lambda')
   LM = max( lambda.ineqlin, TR.Lambda );
else
   LM = lambda.ineqlin;
end

%% Identify p=1 exponents
a_lin  = TR.mpea.linear.g & LM > TR.TolCon & max(gp,g0) > -TR.TolCon; % active linear g
x_lin  = any(gradg(:,a_lin).*gradf(:,ones(1,sum(a_lin)))<0,2);
x_same = abs(dx) < eps;
i_bnd  = TR.bound & x_same ...
   & (lambda.lower | lambda.upper); % x_i at bound
i_fix = i_bnd | x_lin ... % p=1 if bound or active linear constraint
   | x.*(x+dxlb) < 0 ...  % sign change of x not allowed
   | x.*x0       < 0;     % or sign changed

%% Update exponents if last point accepted
if TR.rejected % No new gradient to update p
   p   = TR.p;
   p(i_fix) = 1;
else % accepted point
   % Constraint gradient sensitivity
   g_crit = max(TR.mpea.g(LM>=TR.TolCon));
   if ~isempty(g_crit) && max(g) > g_crit ...
         && (isfield(TR,'qmea') && ~isfield(TR.qmea,'Beta')...
         || ~isfield(TR,'qmea'))
      disp('mpea:     Maximum constraint w/o Lagrange multiplier added')
%     disp('g_crit, g_max=')
%     disp([g_crit, max(g)])
%     disp('Lagrange multipliers')
%     disp([LM(g==g_crit), LM(g==max(g))])
      LM(g>g_crit) = TR.penalty(g>g_crit);
   end
   p = ones(size(x));
   P = repmat(LM',numel(x),1).*gradg;
   if isempty(P_his) || length(P_his)~=length(gradf)
      P_his = zeros(size(gradf));
      TR.Pj = zeros(size(gradf));
      Pmean = zeros(size(gradf));
      Psigma = zeros(size(gradf));
   elseif any(a_lin) % Critical linear constraints
      i=x_lin;
      m=size(P,2);
      [P_his(i),TR.Pj(i)] = max( P(i,:).*(-sign(repmat(gradf(i),1,m))), [], 2 );
   end
   
   switch lower(TR.MPEA)
      case {'on','current'}
      %% Current Lagrangian sensitivity only
      % P_gc = abs(gradg) > TR.Tolvb & repmat((TR.mpea.g >= g_crit)',ndv,1);
      % P = repmat(LM',numel(x),1).*gradg;
      % lset  = ((abs(P) > TR.TolFun) | P_gc) & gradg.*gradgxp>0 ...
      lset  = gradg.*gradgxp>0 ...
            & repmat(xp~=x,1,ncon) ...
            & repmat(~i_fix,1,ncon);
%           & repmat( gradf,1,ncon).*gradg < 0 ...
      dx = xp - x;
      pi0 = ones(size(gradf));
      pij = ones(size(gradg));
      pi0(x_same) = TR.p0(x_same);
      pij(x_same) = TR.pj(x_same);
      pBiter = isfield(TR,'qmea') && isfield(TR.qmea,'Beta');
      if pBiter
         basis = TR.qmea.basis*TR.qmea.basisB;
      end
      
      % Objective exponents
      if ~TR.mpea.linear.f
      i = ~i_fix & x~=xp & ... 
         gradf.*gradfxp>eps; % consistent sign of objective derivative
      if any(i)
         pi0(i) = 1 + log(max(eps,gradfxp(i) ./ gradf(i))) ...
                  ./ (log(xp(i)./x(i)));
         pi0=min(4,max(-4,pi0));
      end
      % p=-1 for lower deriv error when inconsistent deriv sign
      k = ~i_fix & gradf.*gradfxp<0 & x.*xp>0 & x./xp<1;
      if any(k), pi0(k)=-1; end
      j = i & ~k;
      if pBiter && any(j) && isfield(TR.qmea.Beta,'f') && any(TR.qmea.Beta.f)
         phi = @(i,B) 1 + log(max(eps,...
               (gradfxp(i)-basis(i,:)*(B.*(basis'*dx))) ./ ...
                gradf(i))) ./ (log(xp(i)./x(i)));
         [pi0,TR.mpea.fJnorm] = fix_point_iter(pi0,j,phi,...
                                               TR.qmea.Beta.f,...
                                               TR.qmea.Beta.gradpf);
      else
         TR.mpea.fJnorm=0;
      end
      % Is MPEA better than linear for objective?
      if ~pBiter || TR.mpea.fJnorm>1
         [gradfy,~,y]=transf_x2y(pi0,gradf,gradg,x);
         dy = x0.^pi0 - y;
         fapxy = TR.mpea.f + gradfy.'*dy;
         if abs(fapx-fp)<=abs(fapxy-fp)
            pi0(:) = 1;
         end
      end
      end
      
      % Constraint exponents
      XbyX = repmat(log(xp./x),1,ncon);
      pij(lset) = 1 + log(max(eps,gradgxp(lset)./gradg(lset)))./XbyX(lset);
      clear XbyX
      lset = lset & abs(pij)<4;
      pij = min(4,max(-4,pij));
      TR.mpea.gJnorm = zeros(ncon,1);
      % p=-1 for lower deriv error when inconsistent deriv sign
      k = repmat(~i_fix & x.*xp>0 & x./xp<1, 1,ncon) & gradg.*gradgxp<0;
      if any(k(:)), pij(k) = -1; end
      if pBiter && any(TR.qmea.Beta.gJ) && isfield(TR.qmea.Beta,'g')
         for j=TR.qmea.Beta.gJ(:)'
            if any(lset(:,j))
            phi = @(i,B) 1 + log(max(eps,...
                  (gradgxp(i,j)-basis(i,:)*(B.*(basis'*dx)))...
                   ./gradg(i,j)))./log(xp(i)./x(i));
            [pij(:,j),TR.mpea.gJnorm(j)] ...
                     =fix_point_iter(pij(:,j),lset(:,j),phi,...
                                     TR.qmea.Beta.g{j},...
                                     TR.qmea.Beta.gradpg{j});
            end
         end
      end
      % Is MPEA better than linear for constraints?
      for j=1:ncon
         if ~pBiter || TR.mpea.gJnorm(j)>1 % ...
%                   || isempty(intersect(j,TR.qmea.Beta.gJ))
            [~,gradgy,y]=transf_x2y(pij(j),gradf,gradg(:,j),x);
            dy = x0.^pij(j) - y;
            lin_gj = abs(gapx(j)-g0(j)) < abs(g(j)+gradgy.'*dy-g0(j));
            if lin_gj
               pij(:,j) = 1;
               lset(:,j)=lset(:,j) & ~lin_gj;
            end
         end
      end
      
      % Lagrangian sensitivity determines exponent
      % weight gradf by # active constraints per DV
      j_active = max(1, sum( abs(P) > TR.TolFun, 2 ));
      [~,i] = max( abs([gradf(:)./j_active, P]), [], 2 );
      p(i==1) = pi0(i==1);
      j = i(i>1)-1;
      p(i>1)    = pij(sub2ind(size(pij), find(i>1),j));
      % Re-use p exponent from last iteration, if dx_i=0 this iteration
      p(x_same) = TR.p(x_same);

      case  'beta' % beta-development trial version
      %% Weight Lagrangian sensitivities by trust ratios
      %  Recreate MPEA using current gradients and previous exponents
      [gradfy,gradgy,y]=transf_x2y(TR.p,gradf,gradg,x);
      dy = x0.^TR.p - y;
      fapx0 = TR.mpea.f + gradfy.'*dy;
      gapx0 = TR.mpea.g + gradgy.'*dy;
   
      % Wash out prior Lagrangian sensitivity with latest trust ratios
      i = TR.Pj==0;
      TR.P(i) = max(0,min(1,TR.Ratio_f)) * TR.P(i);
      i = TR.Pj>0;
      j = TR.Pj(i);
      TR.P(i)  = max(0,min(1,TR.Ratio_g(j))) .* TR.P(i);

      % Trust ratio for each intermediate variable in objective approximation
      fapxi = fapx0 + gradfy(i).*((x0(i).^p(i)-x(i).^p(i)) - dy(i));
      tr_f = zeros(size(gradf));
      tr_f(i) = max(0, min(1, (fp - f) ./ (fapxi - f)));
      P = abs(tr_f.*gradf); % objective sensitivity weighted by trust ratio
      i = i & P > P_his;
      P_his(i) = P(i); % replace Lagrangian sensitivity with larger weighted obj sens.
      TR.p(i) = p(i);
      TR.Pj(i) = 0;
      i_lin = any(gradg(:,a_lin),2);
      [~,TR.Pj(i_lin)]=max( abs(gradg(i_lin,:)), [], 2 );
      
      % Dominant constraint derivatives determine exponent
      lset = gradg.*gradgxp>0; % & repmat(gradf,1,size(gradg,2)).*gradg < 0;
      lset(i_fix,:) = false;
      lset(:,g < -TR.TolCon) = false;
      XbyX = repmat(log(x0./x),1,ncon);
      pij = zeros(size(gradg));
      pij(lset) = 1 + log(gradgxp(lset) ./ gradg(lset))./XbyX(lset);
      
      % Trust ratio for each intermediate variable in constraint approximation
      DY0 = repmat(dy,1,ncon);
      DY  = repmat(x0,1,ncon).^pij - repmat(x, 1,ncon).^pij;
      gapxi = repmat(gapx0.',ndv,1) + gradgy.*(DY - DY0);
      tr_g = max(0, min(1, repmat((gp - g)',ndv,1) ./ (gapxi - repmat(g',ndv,1))));
      LMgradg = abs(repmat(LM',ndv,1).*gradg);
      P = zeros(size(gradg));
      P(lset) = abs(tr_g(lset).*LMgradg(lset));
      [P,j] = max(P,[],2); % collapse matrix of Lagrangian sensitivity to one per var.
      i = find( P > P_his );
      P_his(i) = P(i); % replace Lagrangian sensitivity with larger weighted sens.
      TR.p(i) = pij( sub2ind(size(pij), i, j(i)) ); % update associated exponents
      TR.Pj(i) = j(i);
      p = TR.p;
      clear dy DY DY0 fapxi gapxi LMgradg
      
   case  'legacy'
      %%  Scan Lagrangian sensitivity table to determine exponent
      % Objective gradient governs exponent if constraint gradients won't
      i = ~i_fix & gradf.*gradfxp  > eps; % consistent sign of objective derivative
      p(i) = 1 + log(gradfxp(i)./gradf(i)) ./ (log(x0(i)./x(i)));
      P = abs(gradf);
      i = i & P > P_his;
      P_his(i) = P(i); % replace Lagrangian sensitivity with larger weighted obj sens.
      TR.p(i) = p(i); % store variable exponent
      TR.Pj(i) = 0;   % record that objective (0 index) governed choice of p
      n = ~i & ~i_fix;
      p(n) = TR.p(n); % recover previous exponents for other variables
      
      % Constraint gradient sensitivity
      P = repmat(LM',numel(x),1).*gradg;
      Pmean  = mean(P,2);
      lastP = iter_mpea>1; % !!! iter_mpea never incremented!!!
      if lastP
         Pmean  = ((iter_mpea-1)*Pmean +Pmean)/iter_mpea;
         Psigma = std([(iter_mpea-1)*P, Pmean]/iter_mpea,0,2);
      else
         Psigma = std(P,0,2);
         pmask = false(size(p));
      end
      Pupper = min(P, Pmean + Psigma);
      Plower = max(P, Pmean - Psigma);
      lset = (P >= Pupper | P <= Plower) & abs(P) > TR.TolFun...
         & gradg.*gradgxp>0 & repmat(gradf,1,size(gradg,2)).*gradg < 0;
    
      % All constraint gradients in Lagrangian used if no dominant constraints
      i = ~i_fix & gradg.*gradgxp*LM > eps & ~any(lset,2);
      p(i) = 1 + log(gradg(i,:)*LM./(gradgxp(i,:)*LM))...
         ./ (log(x(i)./xp(i)));
      
      % Dominant nonlinear constraint
      XbyX = repmat(log(xp./x),1,ncon);
      pij = inf(size(gradg));
      pij(lset) = 1 + log(gradgxp(lset) ./ gradg(lset))./XbyX(lset);
      for i=find(~i_fix & any(lset,2))'
         if ~any( P(i,a_lin) ) % Leave critical linear constraints p=1
            if pmask(i)            % include previous p, if set by dominant P
               pijk = [pij(i,lset(i,:)), TR.p(i)];
               lsetj = [find(lset(i,:)), TR.Pj(i)];
            else
               pijk = pij(i,lset(i,:));
               lsetj = find(lset(i,:));
            end
            [pm1,km1]=min(abs(pijk+1)); % closest to p = +1
            [pp1,kp1]=min(abs(pijk-1)); % closest to p = -1
            if pp1 < pm1 % choose exponent closest to |p|=1
               p(i) = pijk(kp1);
               TR.Pj(i) = lsetj(kp1); % record governing constraint index
            else
               p(i) = pijk(km1);
               TR.Pj(i) = lsetj(km1); % record governing constraint index
            end
            % 	      [~,j]=max(abs(P(i,:)));
            % 	      p(i) = pij(i,j);
            pmask(i)=true; % an exponent was chosen by constraint
         end
      end
   otherwise
      disp(TR.MPEA)
      error('TR.MPEA not recognized')
   end

   if any(isnan(p(:)) | isinf(p(:)))
      disp('mpea: p=NaN or inf reset to p=+/-4')
   elseif any(p(i_fix)~=1)
      warning('mpea:i_fix','Fixed variables has p~=1')
      p(i_fix) = 1;
   end
   p=min(4,max(-4,p));
   if any(p==0), warning('mpea:pzero','intermediate variable exponent=0'), end
   p(p==0)=1;
end % accepted point

%% MPEA variable transformation
[gradfy,gradgy,y,dylb,dyub]=transf_x2y(p,gradf,gradg,x,dxlb,dxub,TR.TolX);
TR.p  = p;
if TR.rejected
   return
elseif strcmpi(TR.MPEA,'current') || strcmpi(TR.MPEA,'on')
   update = abs(pi0)<=4;
   TR.p0(update) = pi0(update);
   update = abs(pij)<=4;
   TR.pj(update) = pij(update);
end

%% Save current iterate data for trust ratio and next iteration
%  if not iterating on beta
if ~isfield(TR,'QMEA') || ~isfield(TR,'qmea') || ~isfield(TR.qmea,'Beta')
   % Save latest grad for p-beta iteration
   if isfield(TR,'QMEA') && ~strcmpi(TR.QMEA,'off')
      TR.gradfyp=gradfy;
      TR.gradgyp=gradgy;
   end
end
end % mpea function



%% Jacobi Fixed-Point Iteration for p-Beta sub-function
function [p_exp,Jnorm] = fix_point_iter(p_exp0, mask, phi, Beta, dBetadp)
p_exp = p_exp0;
p_exp(mask) = phi(mask,Beta);
% Check stability of recursive exponent eq.
m  = size(mask,1);
nB = numel(Beta);
dphidBeta = zeros(m,nB);
% Complex-step derivative of phi wrt Beta
p_cs = p_exp;
cs_err = false;
for iB=1:nB
   Beta_cs = Beta;
   if Beta_cs(iB)~=0
      Beta_cs(iB) = Beta_cs(iB) + 1i*eps;
   end
   p_cs(mask) = phi(mask,Beta_cs);
   if max(abs(real(p_cs)-p_exp))>1e-9
      cs_err = true;
   end
   dphidBeta(:,iB) = imag( p_cs(:) ) / eps;
end
% Jacobian is derivative of phi wrt p via chain rule
J = dphidBeta*dBetadp.';
Jnorm = norm(J);
if isinf(Jnorm) || (Jnorm > 1 && max(abs(eig(J))) > 1)
%    disp('J, Eigenvalues of J')
%    disp(J)
%    disp(eig(J))
% %  p_exp(mask) = phi(mask,0*Beta);
   p_exp(:) = 1;
else
   if cs_err
      warning('mpea:fpi','phi wrt beta complex-step error')
   end
   mask = mask & abs(p_exp)<4;
   p_exp(~mask) = p_exp0(~mask);
   p_exp=min(4,max(-4,p_exp));
end
end