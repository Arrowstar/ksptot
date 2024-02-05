function [dx,dy,TR,out,lambda]=qmeaprog(f,g,gradfy,gradgy,dy,x1,TR)
%  Quadratic Multipoint Exponential Approximation Program
%
%  Written by:    Robert A. Canfield
%  e-mail:        bob.canfield@vt.edu
%
%  Created:       2/13/18
%  Last modified: 7/18/20

%--Input
%
%  f,g..... Function and constraint values at expansion (current) point
%  x1...... LPP point (no function or gradient evaluations)

%--Modifications
%   4/21/18 - use fmincon for any beta<0
%   4/26/18 - iterate between y and beta
%   11/8/19 - Pass Aineq,bineq,Aeqlin,beqlin
%   1/16/20 - search in sub-space
%   2/23/20 - analytic gradients and Hessian for sqp
%   6/ 7/20 - qmeapx_sub w/lam Ab
%   7/ 7/20 - qmeapx_H better posdef H
%   7/18/20 - slack for QMEA when infeasible LP

%% QMEA 2nd-order coefficients
TR = qmea(TR,TR.mpea.x,f,g,gradfy,gradgy,x1);
x0 = TR.mpea.x;
y0 = x0.^TR.p;
dx = x1-x0;
TR.qmea.QPP=[];

%% Solve QMEA surrogate
if strcmpi(TR.QMEA,'on') || contains(TR.QMEA,'sub')
   A = TR.Problem.Aineq;
   b = TR.Problem.bineq;
   TR.qmea.LP = strcmpi(TR.MPEA,'off'); % never use LP for MPEA
   if TR.qmea.LP % turn off LP for QMA for non-zero Beta
      TR.qmea.LP = ~any(TR.qmea.Beta.f);
      for j=TR.qmea.Beta.gJ(:)'
         TR.qmea.LP = TR.qmea.LP && ~any(TR.qmea.Beta.g{j});
      end
   end
   [f1,g1]= qmeapx_sub( TR.qmea.basis'*dx );
   TR.qmea.LP = TR.qmea.LP || ...
      (f1-TR.fapx<TR.TolFun && all(g1<=max(TR.gapx,eps)));
   if TR.qmea.LP
      out = [];
      lambda = TR.mpea.lambda;
      return
   end
   if all(size(TR.qmea.basis)==1) % no reduced sub-space
      dlb = TR.mpea.dxlb;
      dub = TR.mpea.dxub;
      d0  = max( dlb, min( dub, x1-TR.mpea.x ) );
      nd = length(d0);
   else % search in reduced sub-space
      d0 = TR.qmea.basis.'*(x1-TR.mpea.x);
      nd = length(d0);
      dlb = [];
      dub = [];
      if ~isempty(A) && ~isempty(b)
         ncon = length(g);
         % retain nd most active linear constraints
         [~,j] = sort(TR.mpea.lambda.ineqlin(ncon+1:end),'descend');
         A = TR.Problem.Aineq(:,j(1:nd))*TR.qmea.basis;
         b = TR.Problem.bineq(  j(1:nd))*TR.qmea.basis;
      end
      % add side constraints as linear sub-space constraints
      % retain ndv most active bounds
      [~,il] = sort(TR.mpea.lambda.lower,'descend'); il = il(1:nd);
      [~,iu] = sort(TR.mpea.lambda.upper,'descend'); iu = iu(1:nd);
      A = [A; -TR.qmea.basis(il,:); TR.qmea.basis(iu,:)];
      b = [b; -TR.mpea.dxlb( il );  TR.mpea.dxub( iu )];
%       try
%          [A,b] = noredund(AA,bb);
%       catch
%          A = AA;
%          b = bb;
%       end
   end
   if TR.debug  % Revisit previous points to verify accuracy
      print_xpfg
   end
   % Solve QMA/QMEA in reduced space
   dz = zeros(size(d0));
   opts.Display='off';
   opts.MaxIter=10*max(50,nd);
   opts.Termination=2; % allows Slowed
   if strcmpi(TR.MPEA,'off')
      grdfcn = @qmeapx_grd;
      grdfcn1= @qmeapx_grd1;
      lamAb = TR.mpea.lambda;
      lamAb.ineq = lamAb.ineqlin;
      [~,~,~,lamAb] = qmeapx_sub( d0, lamAb );
      opts.HessFun = @qmeapx_H;
      opts.MaxFunEvals = 10*opts.MaxIter;
      opts.LagrangeMultipliers = lamAb.ineqlin;
%     opts.DerivativeCheck = 'on';
   else
      grdfcn=[]; grdfcn1=[];
      opts.ComplexStep='on';
      opts.MaxFunEvals = 10*(nd+1)*opts.MaxIter;
   end
   warnStruct=warning;
   warning('backtrace','off')
   if max(TR.gapx)<=TR.TolCon % if LP was feasible
      dz1 = [];
      [d,opt,lambda,~,out] = sqp(@qmeapx_sub, dz, opts, dlb, dub, grdfcn);
      if out==-6 && opt.constrviolation < TR.TolCon % line search term.
         out = abs(out); % accept this feasible solution
      end
   end
   if max(TR.gapx)>TR.TolCon || out<0 % infeas LP or failed/infeas QP
      dz1  = [dz;0];
      dlb1 = [dlb;0];
      dub1 = [dub;1];
      [d,opt,lambda,~,out] = sqp(@qmeapx_sub1,dz1,opts,dlb1,dub1,grdfcn1);
      d = d(1:end-1);
      TR.qmea.QPP = ' slack_sqp';
   end
   warning(warnStruct)
   [TR.fapx,gapx,x2,lambda] = qmeapx_sub( d, lambda );
   if out<1
      disp(opt.status)
      [mg,mj]=max(gapx);
      fprintf('   f,gapx=%14.5g  %12.4g  %5.0f',TR.fapx,mg,mj)
      fprintf('  sqp failed in qmeaprog\n')
      x2 = max(TR.Problem.lb, min(TR.Problem.ub, x2));
   end
   TR.gapx = gapx(1:numel(g));
   lambda.ineqlin = lambda.ineq; % remove Ax-b LM
   dx = x2-x0;
   dy = x2.^TR.p-y0;
   
%% Matrix-vector product Hessian
elseif contains(TR.QMEA,'fmincon') || any(TR.qmea.Beta.L < 0)
   optQP = optimoptions(@fmincon,'Algorithm','interior-point','Display','off',...
      'SpecifyObjectiveGradient',true,'SpecifyConstraintGradient',true,...
      'SubproblemAlgorithm','cg','HessianMultiplyFcn',@hmfun);
   [dy,~,TR.stat,out,lambda]=fmincon(@qmeapx,dy,gradgy',-g,[],[],dylb,dyub,[],optQP);

%% TR.QMEA=='Lagrangian'
else
   % sparse Hessian with reduced space as auxiliary design variables
   optQP = optimoptions(@quadprog,'Algorithm','interior-point-convex','Display','off');
   m = length(g);
   [ndv,n] = size(TR.qmea.basis);
   Aeq = [-TR.qmea.basis.', eye(n),TR.Problem.Aeq]; % only good for p==1
   beq = [ zeros(n,1),             TR.Problem.beq];
   %v0 = [dy; TR.qmea.basis.'*(dy(:))];
   vlb = [dylb; -Inf(n,1)];
   vub = [dyub;  Inf(n,1)];
   c = [gradfy;   zeros(n,1)];
   A = [gradgy.', zeros(m,n), Aineq];
   b = [-g,                   bineq];
   N = length(c);
   i = (N-n+1:N);
   H = sparse(i,i,TR.qmea.Beta.L,N,N);
   [v,~,TR.stat,out,lambda2]=quadprog(H,c,A,b,Aeq,beq,vlb,vub,[],optQP);
   if TR.stat < 0
      warning('mpeaprog:qpinfeas','quadprog failed for QMEA, return LP solution')
      lambda = TR.mpea.lambda;
   else
      dy = v(1:ndv);
      lambda.ineqlin = lambda2.ineqlin;
      lambda.lower   = lambda2.lower(1:ndv);
      lambda.upper   = lambda2.upper(1:ndv);
      [TR.Lapx] = qmeapx(dy);
   end
end

%% Matrix-vector multiply nested sub-function
   function W=hmfun(~,~,Y)
      W = TR.qmea.basis*(diag(TR.qmea.Beta.L)*(TR.qmea.basis.'*Y));
   end

%% QMEA surrogate nested sub-function
   function [fQapx,fQgrd]=qmeapx(dy)
      if TR.qmea.Beta.pBiter
         y = y0 + dy;
         x  = mpea(TR,y);
         dx = x - x0;
         dxdy = y.^(1./TR.p-1) ./ TR.p;
         d = TR.qmea.basis.'*(dx);
      else
         dxdy = 1;
         d = TR.qmea.basis.'*(dy(:));
      end
      fQapx = f + gradfy.'*dy + (d.^2).'*TR.qmea.Beta.L/2;
      fQgrd = gradfy + TR.qmea.basis*(TR.qmea.Beta.L.*d).*dxdy;
   end

%% QMEA sub-space function evaluation nested sub-function
   function [f,g,x,lambda] = qmeapx_sub( d1, lambda )
      dx1 = TR.qmea.basis*d1;
      if any(imag(dx1)) % allow for complex-step derivatives
         x = TR.mpea.x + max(real(dx1),TR.mpea.dxlb) + 1i*imag(dx1);
      else
%        x = TR.mpea.x + max(dx1,TR.mpea.dxlb);
         x = TR.mpea.x + dx1;
      end
      x = max( x, TR.Problem.lb );
      x = min( x, TR.Problem.ub );
      if length(TR.qmea.gradf) < length(TR.mpea.x)
         y1 = d1; % reduced gradient
      else
         y1 = x.^TR.p0;
      end
      dB = TR.qmea.basisB.'*d1; % Further reduce subspace to previous points
      f  = TR.qmea.f0 + TR.qmea.gradf.'*y1 + sum(TR.qmea.Beta.f.'*dB.^2)/2;
      [nd,ncon] = size(TR.qmea.gradg);
      if nd < length(x0) % reduced gradients for each constraint
         y1 = repmat(d1,1,ncon); % subspace with x1
      else % intermediate variable for each constraint
         y1 = repmat(x,1,ncon).^TR.pj;
      end
      g = TR.qmea.g0 + sum(TR.qmea.gradg.*y1).';
      if any(TR.qmea.Beta.gJ) && isfield(TR.qmea.Beta,'g')
         for jg=TR.qmea.Beta.gJ(:)'
            if any(TR.qmea.Beta.g{jg}>0)
               g(jg) = g(jg) + sum([TR.qmea.Beta.g{jg}].*dB.^2)/2;
            end
         end
      end
      if ~isempty(A) && ~isempty(b) % Add side constraints
         g = [g; A*d1-b];
      end
      if nargin>1 && nargout>3 % Lagrange multpliers for variable bounds
         lambda.ineq = lambda.ineq(1:length(TR.qmea.g0)); % remove Ax-b
         lambda.ineqlin = [lambda.ineq; zeros(size(b))]; % initial Ax-b
         lambda.lower = double( dx1 < TR.mpea.dxlb + TR.TolX );
         lambda.upper = double( dx1 > TR.mpea.dxub - TR.TolX );
      end
   end

   function [fsub,gsub]=qmeapx_sub1( dd )
      delta = dd(end);
      fnorm = max(1,abs(TR.Merit));
      [fsub,gsub] = qmeapx_sub( dd(1:end-1) );
      penalt = zeros(size(gsub)); % include A*d1-b linear constraints
      penalt(1:ncon) = TR.penalty;
      penalt(real(gsub)<0) = 0; % for complex step instead of max(0,g)
      fsub = (fsub + penalt.'*gsub)/fnorm + delta.^2/2;
      gsub(1:ncon) = gsub(1:ncon)-delta*max(0,g1);
   end

%% QMEA gradient evaluation nested sub-function
   function [grdf,grdg] = qmeapx_grd( d1 )
      dB   = TR.qmea.basisB.'*d1; % Further reduce subspace to previous points
      grdf = TR.qmea.gradf + TR.qmea.basisB*(TR.qmea.Beta.f.*dB);
      grdg = TR.qmea.gradg;
      if any(TR.qmea.Beta.gJ) && isfield(TR.qmea.Beta,'g')
         for jg=TR.qmea.Beta.gJ(:)'
            if any(TR.qmea.Beta.g{jg}>0)
               grdg(:,jg) = grdg(:,jg) ...
                          + TR.qmea.basisB*([TR.qmea.Beta.g{jg}].*dB);
            end
         end
      end
      grdg = [grdg, A'];
   end

   function [grdf,grdg] = qmeapx_grd1( dd )
      fnorm = max(1,abs(TR.Merit));
      [grdf,grdg] = qmeapx_grd( dd(1:end-1) );
      [~,   gsub] = qmeapx_sub( dd(1:end-1) );
      ng   = numel(gsub);
      gsub = gsub(1:ncon);
      grdf = [(grdf + grdg(:,1:ncon)*(TR.penalty.*max(0,sign(gsub))))/fnorm; dd(end)];
      grdg = [grdg; [-max(0,g1).', zeros(1,ng-ncon)]];
   end

%% QMEA Hessian evaluation nested sub-function
   function H = qmeapx_H( ~, lam )
      if any(TR.qmea.Beta.f>0)
         H  = sparse(diag(TR.qmea.Beta.f));
      else
         nB = size(TR.qmea.basisB,2);
         H  = sparse(nB,nB);
      end
      if any(TR.qmea.Beta.gJ) && isfield(TR.qmea.Beta,'g')
         for jg=TR.qmea.Beta.gJ(:)'
            if any(TR.qmea.Beta.g{jg}>0)
               H = H + sparse(lam(jg)*diag(TR.qmea.Beta.g{jg}));
            end
         end
      end
      if norm(H(:),inf)==0 % || ...
%        (~TR.psd && abs(min(H(:))) > abs(max(H(:))))
         nB = size(TR.qmea.basisB,2);
         H = speye(nB);
      elseif min(diag(H))/max(abs(diag(H))) < eps
         if TR.psd || abs(min(diag(H))) > max(diag(H))/10
            H(H<0) = eps*max(1,norm(H(:),inf)); % pd H
         else
            ep = abs(min(min(diag(H)),0)) + eps*max(abs(H(:)));
            H  = ep*speye(size(H)) + H; % pd H
         end
      end
      H = full(TR.qmea.basisB*sqrt(H)); % expanded square root of H
      H = H*H.';
%       if size(TR.qmea.basisB,1)>size(TR.qmea.basisB,2) || rcond(H) < eps
%          maxeig = max(diag(H));
%          H = H + eps*maxeig*eye(size(H));
%       end
      if ~isempty(dz1)
         n1 = length(H);
         H1 = eye(n1+1);
         H1(1:n1,1:n1)=H;
         H = H1;
      end
   end

%% Verification print sub-function
   function print_xpfg
      id = TR.dbgfid;
      [ndv,nX] = size(TR.X);
      fprintf(id,'\nIter=%3.f\n',nX);
%     d1 = TR.qmea.basis.'*(x1-TR.mpea.x0);
%     [f1,g1,x1] = qmeapx_sub( d1 ) %#ok<ASGLU,NOPRT>
      fprintf(id,'Func#    p\n%5.0f',0);
      fprintf(id,'%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f\n',TR.p0);
      if mod(length(TR.p0),10), fprintf(id,'\n'); end
      for jp=1:size(TR.pj,2)
         fprintf(id,'%5.0f',jp);
         fprintf(id,'%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f%5.1f\n',...
                 TR.pj(:,jp));
         if mod(ndv,10)>0, fprintf(id,'\n'); end
      end
      fprintf(id,'Prev             f        f_qmea   j            g        g_qmea\n');
      for prev=max(1,nX-ndv):nX
         dp = TR.qmea.basis.'*(TR.X(:,prev)-TR.mpea.x);
         [fa,ga,xa] = qmeapx_sub( dp );
         ga = ga(1:size(TR.output.g,1)); % remove linear constraints
         fprintf(id,'%4.0f  %12.4g  %12.4g\n',prev-1,TR.output.f(prev),fa);
         fprintf(id,'%36.0f %12.4g  %12.4g\n',[(1:numel(ga));TR.output.g(:,prev)';ga']);
         fprintf(id,'    x=');
         fprintf(id,'%12.4g%12.4g%12.4g%12.4g%12.4g\n      ', xa);
         fprintf(id,'\n');
      end
      fprintf(id,'   x0=');
      fprintf(id,'%12.4g%12.4g%12.4g%12.4g%12.4g\n      ', TR.mpea.x);
      fprintf(id,'\n');
      fprintf(id,'   x1=');
      fprintf(id,'%12.4g%12.4g%12.4g%12.4g%12.4g\n      ', x1);
      fprintf(id,'\n\n\n');
   end
end