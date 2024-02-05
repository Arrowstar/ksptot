function TR = qmea(TR,x0,f0,g0,gradfy,gradgy,x1)
% Quadratic Multipoint Exponential Approximation
%
% Assumes transformation to expenontial variable already done by mpea.
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:        4/2/17
%  Last modified: 9/23/20
%
%--Input
%
%  TR........ Trust Ratio structure with iteration history
%  TR.p...... Intermediate variable exponsent p for y=x.^p
%  TR.mpea.... structure with state variables from sao_trust
%  lambda.... Structure of Lagrange multipliers from linprog or quadprog
%  gradfy.... Gradient of objective function,f, wrt y
%  gradgy.... Gradient of constraint fuunctions, g, wrt y
%  x1........ LPP point (no function or gradient evaluations)
%
%--Output
%
%  TR.qmea.Beta... Vector of quadratic coefficients in reduced subspace
%                  (m-by-1 where m=min(ndv,nprev))

%--Modifications
%   2/ 8/18 - refactored into mpea and qmea
%   4/21/18 - non-positive-semi-definite option
%   4/26/18 - return g_match; limit eq_lp to all pos
%   4/28/18 - current is not last if last was rejected
%    5/3/18 - reduced basis wrt dX instead of dY
%    4/6/19 - initialize TR.qmea.Beta in case nonpsd
%    4/7/19 - abort if last two points rejected
%   10/5/19 - unitialized TR.pj
%  11/18/19 - Refactor as qmea_beta_iter for each function
%   1/16/20 - beta for every f,g; LPP point in basis
%   2/ 9/20 - beta varies with p0,pj exponents
%   3/ 9/20 - avoid fully constrained beta becomes negative
%   6/ 5/20 - pinv for rank deficient D2T
%   6/ 7/20 - nonpsd comes from TR.psd
%   6/26/20 - derivative wrt p
%   7/ 1/20 - keep nBeta instead of Prev
%   7/11/20 - more prev points to increase rank of basis
%   7/20/20 - non-square D2Td
%   9/23/20 - guess lambda for rejected first point
%
%--Local variables
%
%  D........ matrix of reduced space coefficients at prev points
%  Prev.... index to previous points of TR.X in D
%  k........ index to current (last accepted) point in TR.X

%% Reduced basis design-variable sub-space
[ndv,nprev]=size(TR.X);
mprev = min(ndv,nprev-1);
ncon = length(g0);
k = find( ~TR.output.rejected, 1, 'last' ); % current point is last accepted
if max(abs(TR.X(:,k)-x0))>0
   error('qmea:x0','x0 ~= current x')
end
Prev = setdiff(1:nprev, k); %        previous points
k1 = length(Prev)-mprev+1;  %  first previous point to use
keep = Prev(k1:end);        % recent previous points
if isfield(TR,'p')
   p  = TR.p;
   if any(any( TR.X(:,Prev) <=0 & repmat(p,1,numel(Prev)) <=0 ))
      error('qmea:negp','Negative exponent for nonpositive previous X not allowed')
   end
else
   p  = 1;
end
dX = TR.X(:,Prev)    - x0;
dY = TR.X(:,Prev).^p - x0.^p;
xBeta  =  strcmpi(TR.QMEA,'on') || contains(TR.QMEA,'sub');
dbasis = nprev < ndv; % && ndv > TR.manyDV;
if xBeta % reduced basis in X-space
   if dbasis
      TR.qmea.basis  = orth([dX, x1-x0]);
      Dx = TR.qmea.basis.'*dX;
      TR.qmea.basisB = orth(Dx);
      D = TR.qmea.basisB.'*Dx;
   else
      TR.qmea.basis = 1;
      TR.qmea.basisB = orth(dX);
      D = TR.qmea.basisB.'*dX;
   end
else % reduced basis in Y-space
   if dbasis
      TR.qmea.basis  = orth([dY, (x1.^p-x0.^p)]);
      TR.qmea.gradf = TR.qmea.basis.'*gradfy;
      TR.qmea.gradg = TR.qmea.basis.'*gradgy;
      Dy = TR.qmea.basis.'*dY;
      TR.qmea.basisB = orth(Dy);
      D = TR.qmea.basisB.'*Dy;
   else
      TR.qmea.basis = 1;
      TR.qmea.basisB = orth(dY);
      D = TR.qmea.basisB.'*dY;
   end
end
dX = dX(:,end-mprev+1:end);
dY = dY(:,end-mprev+1:end);
Dk = D(:, end-mprev+1:end);
D2T = Dk.'.^2/2;
nBeta = min(size(D));
mBeta = rank(D2T);
Wdis = sparse(diag(norm(dX(:,end)).^2./(sum(dX(:,1:end).^2,1))));
if length(D2T)==1
   D2Td = D2T;
else % decomposed D2T
   if mBeta < mprev
      D2TdW = decomposition(Wdis*(Dk(1:mBeta,:).'.^2)/2,'cod');
      D2Td  = decomposition(     (Dk(1:mBeta,:).'.^2)/2,'cod');
   else
      D2Td = decomposition(D2T);
   end
end

% iterate on p and Beta
MPEA   = ~strcmp(TR.MPEA,'off');
pBiter = (strcmpi(TR.QMEA,'on') || contains(TR.QMEA,'iter')) && ...
         (strcmpi(TR.MPEA,'on') || strcmpi(TR.MPEA,'current'));
nonpsd = ~TR.psd;
if isfield(TR,'Lambda')
   lambda = max( TR.mpea.lambda.ineqlin, TR.Lambda );
elseif isfield(TR.mpea,'lambda') && ~isempty(TR.mpea.lambda)
   lambda = TR.mpea.lambda.ineqlin;
else
   lambda = guessLM(g0,gradfy,gradgy);
end
if isempty(TR.mpea.lambda0)
   lambda0 = zeros(size(lambda));
else
   lambda0 = TR.mpea.lambda0.ineqlin;
end
L = TR.output.f + lambda.'*max(0,TR.output.g);
ptol    = 1e-3;
lam_tol = 1e-8*max(max(lambda0,lambda));
J       = max(TR.mpea.g0, g0) > -TR.TolCon | ...
          max(lambda0,lambda) >  lam_tol; % current active g
[fapx,gapx,Lapx,f_match,g_match,L_match] = apxmatch(dX,dY);
% TR.qmea.Beta.gJ = unique([TR.bindLM; ...
%                   find(J & any(~g_match,2))]);
TR.qmea.Beta.gJ = find(J & any(~g_match,2));
TR.qmea.Prev = keep;
itermax = 50;
iter    =  0;
iterf   =  0;
iterL   =  0;
iterg   = zeros(size(g0));
Beta_L  =  0;
Beta_f  =  0;
Beta_g  = zeros(nBeta,ncon);
Lstop   = all(L_match);
fstop   = TR.mpea.linear.f | all(f_match);
gstop0  = TR.mpea.linear.g | all(g_match,2) | ~J;
converged = Lstop && fstop && all(gstop0);
while ~converged && iter <= itermax
   iter = iter + 1;
   if ~fstop && any(~f_match)
      [Beta_f, fstop] = qmea_beta( TR.output.f, fapx, Beta_f );
      TR.qmea.Beta.f = Beta_f;
      iterf=iter;
   end
   if ~Lstop && any(~L_match) && ~xBeta
      [Beta_L, Lstop] = qmea_beta( L, Lapx, Beta_L );
      iterL=iter;
   end
   gstop = gstop0;
   for j=find(J')
      if ~isempty(j) && any(~g_match(j,:)) && ~gstop(j)
         [Beta_g(:,j), gstop(j)] = qmea_beta(TR.output.g(j,:),...
            gapx(j,:), Beta_g(:,j));
         TR.qmea.Beta.g{j} = Beta_g(:,j);
         iterg(j)=iter;
      end
   end
   % Update exponents, p, p0, pj. Jacobian wrt p-derivtaives. 
   if pBiter
      p0 = TR.p0;
      pj = TR.pj;
      [TR.qmea.Beta.gradpf,TR.qmea.Beta.gradpg] = apxmatch(dX,dY);
      [~,~,~,gradfy,gradgy,TR] = mpea(TR,x0);
      Lstop = Lstop   || max(abs(p -TR.p) ) < ptol;
      fstop = fstop   && max(abs(p0-TR.p0)) < ptol;
      gstop = gstop(:) & (max(abs(pj-TR.pj),[],1)' < ptol ...
                       | TR.mpea.gJnorm<1e-10);
      [fapx,gapx,Lapx,f_match,g_match] = apxmatch(dX,dY);
   else
      iterf=-1; iterg=-ones(size(g0)); % iterl=-1;
   end
   converged = ~pBiter || (~xBeta && Lstop) ...
                       || ( xBeta && fstop && all(gstop) );
end
% Verify and store in Beta coefficients and their p-derivatives in TR.qmea
if any(Beta_L)
   qmea_beta( L, Lapx, Beta_L, 'L', iterL );
   TR.qmea.Beta.L = Beta_L;
else
   TR.qmea.Beta.L = 0;
end
if any(Beta_f)
   if TR.debug, qmea_beta(TR.output.f, fapx, Beta_f,'f',iterf); end
else
   TR.qmea.Beta.f = 0;
end
for j = TR.qmea.Beta.gJ(:)'
   if any(Beta_g(:,j))
      if TR.debug
         glabl = ['g',num2str(j)];
         qmea_beta(TR.output.g(j,:),gapx(j,:),Beta_g(:,j),glabl,iterg(j));
      end
   else
      TR.qmea.Beta.g{j} = 0;
   end
end

% Sub-space gradients
dbasis = dbasis && nBeta+1 < ndv;
if xBeta % Beta coefficients in X-space for all f and g
   ng = size(TR.mpea.gradgx,2);
   if MPEA % chain rule
      [TR.qmea.gradf,~,y0] = transf_x2y(TR.p0,TR.mpea.gradfx,0,x0);
      dxdy = repmat( x0, 1,ng ).^(1-TR.pj)./TR.pj;
      TR.qmea.gradg = TR.mpea.gradgx.*dxdy;
   else
      TR.qmea.gradf = TR.mpea.gradfx;
      TR.qmea.gradg = TR.mpea.gradgx;
      y0 = x0;
   end
   if dbasis && all(TR.p0==1) % reduce gradient if no MPEA
      TR.qmea.f0    = TR.mpea.f;
      TR.qmea.gradf = TR.qmea.basis.'*TR.mpea.gradfx;
   else
      TR.qmea.f0    = TR.mpea.f - TR.qmea.gradf.'*y0;
   end
   if dbasis && all(TR.pj(:)==1)  % reduce gradients if no MPEA
      TR.qmea.g0    = TR.mpea.g;
      TR.qmea.gradg = TR.qmea.basis.'*TR.mpea.gradgx;
   else
      TR.qmea.g0 = TR.mpea.g ...
                 - sum(TR.qmea.gradg.*repmat(x0,1,ng).^TR.pj).';
   end
end

% %% Determine p and beta simultaneously from least-squares optimization
% if strcmpi(TR.QMEA,'best')
%    p(i_fix) = 1;
%    p0  = p(~i_fix);
%    pub = repmat(4,size(p0));
%    plb = -pub;
%    nprev = size(TR.X,2)-1;
%    options = optimoptions(@lsqnonlin,'Display','off',...
%       'SpecifyObjectiveGradient',true);
%    if QMEA
%       [gradfy,gradgy]=transf_x2y(p,gradf,gradg,x);
%       TR=qmea(TR,LM,p,gradfy,gradgy);
%       BetaNorm = max(1,TR.qmea.Beta);
%       v0  = [p0; TR.qmea.Beta./BetaNorm];
%       vlb = [plb; zeros(size(TR.qmea.Beta))];
%       vub = [pub;   Inf(size(TR.qmea.Beta))];
%       v = lsqnonlin(@TrustRatios,v0,vlb,vub,options);
%       p(~i_fix) = v(1:numel(p0));
%       TR.qmea.Beta = v(numel(p0)+1:end);
%    elseif ~all(i_fix)
%       v = lsqnonlin(@TrustRatios,p0,plb,pub,options);
%       p(~i_fix) = v(1:numel(p0));
%    end
%    TR.p = p;
% end
%
% %% Trust Ratios nested function
%    function [F,J]=TrustRatios(v)
%       nv = numel(p0);
%       p = ones(size(i_fix));
%       p(~i_fix) = v(1:nv);
%       [gradfdy,gradgdy,yk]=transf_x2y(p,gradf,gradg,x);
%       DY = TR.X(:,1:nprev).^repmat(p,1,nprev) - repmat(yk,1,nprev);
%       fapxy = f + gradfdy.'*DY;
%       gapxy = g + gradgdy.'*DY;
%       % append Lagrangian trust ratio
%       beta = BetaNorm.*v(nv+1:end);
%       D = TR.qmea.basis.'*(DY);
%       Q = ((D.').^2)*beta/2; % quadratic term for each previous point
%       Lapxy = fapxy + (max(0,gapxy).'*LM + Q).';
%       Lprev = TR.output.f(1:end-1) + (max(0,TR.output.g(:,1:end-1)).'*LM).';
%       L     = f + max(0,g).'*LM;
%       w = sum((TR.X(:,1:end-1)-TR.X(:,end)).^2,1); % distance to previous points
%       w = sqrt(min(w) ./ w); % normalize relative to closest point
%       gprev = TR.output.g(:,1:end-1);
%       lm    = LM.*(any(gprev>-TR.TolCon,2));
%       trust = (gprev - g)./(gapxy - g); % unweighted trust_g
%       trust( isinf(trust) | isnan(trust) | abs(trust) <= eps ) = 1;
% %     F = 1./trust - 1; 
%       F = repmat(lm,1,nprev).*(trust-1).*repmat(w,ncon,1);   % weighted F
%       F = [F(:); (((Lapxy - L)./(Lprev - L) - 1).*w).']; % append Lagrangian trust
%       if nargout>1
%          mF  = numel(F);
%          nv = numel(v);
%          J = zeros(mF,nv);
%          v0r=v;
%          for n=1:nv
%             v=v0r;
%             v(n)=v0r(n)+1i*eps;
%             dF = TrustRatios(v);
%             J(:,n) = imag(dF)/eps;
%          end
%       end
%    end

%% Nested sub-functon for matching previous points to first order
   function [fapx,gapx,Lapx,f_match,g_match,L_match] = apxmatch(dX,dY)
      if nargout>3
         fapx = f0 + gradfy.'*dY;
         gapx = g0 + gradgy.'*dY;
         Lapx = fapx + lambda.'*max(0,gapx);
         if TR.mpea.linear.f || all(TR.p0==1) || ~isfield(TR,'p0')
            dY = dX;
            gradf = TR.mpea.gradfx;
         else
            dY = TR.X(:,keep).^TR.p0 - x0.^TR.p0;
            gradf = transf_x2y(TR.p0,TR.mpea.gradfx,0,x0);
         end
         fapx = f0 + gradf.'*dY;
         for jg = 1:length(g0)
            if TR.mpea.linear.g(jg) || ~isfield(TR,'pj') || all(TR.pj(:,jg)==1)
               dY = dX;
               gradg = TR.mpea.gradgx(:,jg);
            else
               dY = TR.X(:,keep).^TR.pj(:,jg) - x0.^TR.pj(:,jg);
               [~,gradg]=transf_x2y(TR.pj(:,jg),0,TR.mpea.gradgx(:,jg),x0);
            end
            gapx(jg,:) = g0(jg) + gradg.'*dY;
         end
         f_match = abs(TR.output.f(  keep)-fapx)<TR.TolFun;
         g_match = abs(TR.output.g(:,keep)-gapx)<TR.TolCon;
         L_match = (L(keep)-Lapx)<TR.TolFun;
         if ~MPEA
            if TR.mpea.linear.f && ~all(f_match)
               error('mpea:fmatch','linear f should match')
            end
            if any(TR.mpea.linear.g & ~all(g_match,2))
               error('mpea:gmatch','linear g should match')
            end
         end
%        % Conservative match, i.e., apx >= prev
%        f_match = (TR.output.f(  Prev)-fapx)<TR.TolFun;
%        g_match = (TR.output.g(:,Prev)-gapx)<TR.TolCon;
      else
         % Complex-step derivatives of fapx,gapx wrt p
         [np,npp]=size(dX);
         fapx = zeros(np,nBeta);
         fpx  = zeros(np,npp);
         gapx = cell(numel(TR.qmea.Beta.gJ),1);
         gpx  = cell(numel(TR.qmea.Beta.gJ),1);
         for jg=TR.qmea.Beta.gJ(:)'
            gapx{jg} = zeros(np,nBeta);
            gpx{jg}  = zeros(np,npp);
         end
         for n=1:np
            pc = TR.p0;
            pc(n) = pc(n) + 1i*eps;
            dY = TR.X(:,keep).^pc - x0.^pc;
            gradf = transf_x2y(pc,TR.mpea.gradfx,0,x0);
            fpx(n,:) = imag( f0 + gradf.'*dY ) / eps;
            if nargout>1
               for jg = 1:ncon
                  pc = TR.pj(:,jg);
                  pc(n) = pc(n) + 1i*eps;
                  dY = TR.X(:,keep).^pc - x0.^pc;
                  [~,gradg]=transf_x2y(TR.pj(:,jg),0,TR.mpea.gradgx(:,jg),x0);
                  gpx{jg}(n,:) = imag( g0(jg) + gradg.'*dY ) / eps;
               end
            end
         end
         fapx(:,1:mBeta) = (-D2Td \ fpx.').';
         for jg=TR.qmea.Beta.gJ(:)'
            gapx{jg}(:,1:mBeta) = (-D2Td \ gpx{jg}.').';
         end
      end
  end

%% Nested sub-function to compute Beta
function [Beta,Bstop,L_err] = qmea_beta( L, Lapx, Beta0, labl, iters )
   if nargin<4 || isempty(labl),   labl='TBD';  end
   if nargin<5, iters=[]; end
   L0   = L(keep);
   Ldel = L0 - Lapx; % current point k has Ldel=0
   Btol = 0.01;
   stat = 0;
   marker = 'psd';
   % Solve for reduced second-order coefficients
   % % Avoid changing curvature from negative to positive
   % neg = Lgrd_err <= 0 & (-Lgrd_err/2 <= Ldel.'-TR.TolCon);
   % mid = Lgrd_err <= 0 & (-Lgrd_err/2  > Ldel.'-TR.TolCon);
   % Aeq = DD2(neg,:); % equality constraint for zero curvature
   % beq = Ldel(neg);
   % A = [-DD2(~neg,:);  % lower bound where curvature is positive
   %       DD2(mid, :)]; % upper bound where curvature is negative
   % b = [-Ldel(~neg);
   %       Ldel(mid)];
%    Ldel = Ldel(keep);
%    Lapx = Lapx(keep);
%    L0   = L0(keep);
   pos = Ldel >= 0;
   Ldel= Ldel(:);
   
   % Solve for unrestricted sign Beta
   if mBeta < mprev
      Beta = D2TdW \ (Wdis*Ldel);
   else
      Beta = D2Td \ Ldel;
   end
   if ~nonpsd && any(Beta<0) && any(pos)
      D2Tpos  = Wdis(pos,pos)*(Dk(1:mBeta,pos).'.^2)/2;
      Ldelpos = Wdis(pos,pos)*Ldel(pos);
      if ~all(pos)
         Beta = D2Tpos \ Ldelpos;
      end
   end
   
   % Solve for non-negative Beta
   %   nonpsd = contains(lower(TR.QMEA),'nonpsd');
   if  nonpsd
      marker = 'non-psd';
   elseif ~nonpsd && ~any(pos) 
      Beta = zeros(size(Beta0));
   elseif any( Beta < 0 )
      c   = sum(D2Tpos,1); % coefficient to weight min of Beta
      Aeq = D2Tpos;
      beq = Ldelpos;
      vlb = zeros(mBeta,1);
      % Determine upper bound as single-beta function match
      vub = min(1e10,max(1,max(repmat(beq,1,mBeta)./Aeq)));
      % Scale beta to unit magnitude
      S = diag(vub);
      c = c*S;
      Aeq = Aeq*S;
      ub = ones(size(vub));
      optLP = optimoptions(@linprog,'Display','off');
      % underconstrained
      if length( beq ) < nBeta
         [beta,~,stat,out1] = linprog(c,[],[],Aeq,beq,vlb,ub,optLP);
         marker = 'eq_lp_simplex';
         if stat<0 || any( beta < 0 ) 
            optLP = optimoptions(optLP,'Algorithm','interior-point');
            [beta,~,stat,out2] = linprog(c,[],[],Aeq,beq,vlb,ub,optLP);
            marker = 'eq_lp_ip';
         end
      end
      if length(beq)>=nBeta || stat<=0
         optLP = optimoptions(@lsqlin,'Display','off');
         [Beta,~,~,stat,out3]=lsqlin(D2Tpos,Ldelpos,[],[],[],[],vlb,vub,[],optLP);
          marker = 'lsq_ip';
      else
         Beta = S*beta;
      end
      if stat<0
         optLP = optimoptions(optLP,'Algorithm','trust-region-reflexive');
         [Beta,~,~,stat,out4]=lsqlin(D2Tpos,Ldelpos,[],[],[],[],vlb,vub,beta,optLP);
         marker = 'lsq_trr';
      end
      if stat<0
         disp(out1)
         disp(out2)
         disp(out3)
         disp(out4)
         error('qmea:beta','linprog & lsqlin failed to find beta in qmea')
      end
   end
   if mBeta < nBeta
      Beta = [Beta; zeros(nBeta-mBeta,1)];
   end
   Bstop = ~any(Beta) || ...
           all( abs(Beta-Beta0) ./ max(abs(Beta0),1.e-8) < Btol);

   % Verify
   Lquad = (D2T*Beta).';
   Lqmea = Lapx + Lquad;
   L_err = Lqmea - L0;
   if TR.debug && nargin>3
      id = TR.dbgfid;
      if ~any(pos)
         marker = [marker,' Ldel<=0'];
      elseif stat<0
         marker = 'failed';
      end
      if iters<0
         fprintf(id,'QMA,  #Prev=%3.0f, %14s\n',numel(keep),marker);
      else
         fprintf(id,'QMEA, #Prev=%3.0f, %14s      iters=%2.0f\n',...
            numel(keep),marker,iters);
      end
      beta = NaN(size(Lquad));
      beta(1:length(Beta)) = Beta.';
      hdrfmt='        %4s_0      %4s_apx     %4s_qmea  %4s_err     %4s_quad          beta\n';
      fprintf(id,hdrfmt, labl,labl,labl,labl,labl);
      fprintf(id,'%14.6g%14.6g%14.6g %9.4f%14.6g%14.6g\n',[L0;Lapx;Lqmea;L_err;Lquad;beta]);
      if any(pos) && stat<0
         fprintf(id,'qmea failed: stat=%4.0f\n',num2str(stat));
      end
   end
   if any( Beta < 0 ) && ~nonpsd
      if abs(min(Beta))/max(Beta) < TR.Tolvb
         Beta(Beta<0) = 0;
      else
         disp( Beta )
         error('qmea:negBeta','Beta should be non-negative')
      end
   end
end

end