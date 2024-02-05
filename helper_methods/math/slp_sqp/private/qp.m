function [s,u,status]=qp(H,fp,A,b,vlb,vub,x0,neq,nomsg)
% QP converts old optimization toolbox qp calling sequence to new quadprog
% calling sequence in version 2 and later of the optimization toolbox.
%
% *If using version 1 optimization toolbox, remove this function.*

%--Modifications
%   5/12/06 - Structure options
%    4/4/07 - Increase MaxIter
%    5/6/13 - If A is null, then neq=0
%   9/30/15 - Default quadprog alogorithm instead of deprecated active-set
%  10/15/15 - default quadprog fails for nonconvex--revert to   active-set
%  11/16/15 - default quadprog no "s" for infeasible--revert to active-set
%  11/25/16 - active-set algorithm removed for R2016b
%		10/17 - modified to allow for Octave use, Blake van Wingkle (BVW)
%   11/3/19 - incorporated BVW Octave with local variables, not global
%  11/24/19 - shift H eval instead of call fmincon
%    3/8/20 - Marquardt shift for Octave
%   7/23/20 - call lpOctave

%% Initialize local variables
[nc,nx]=size(A);
neq=min(neq,nc);
% Rows of A are partitioned into equality and inequality constraints: p1, p2
p1=1:neq;
p2=neq+1:nc;
% No displayed output (nomsg = -1)
msg={'off','final','iter'};

%%  MOSEK %%%%%
%   path('c:\mosek\4\toolbox\r14sp3',path)
%   options=optimset('Display',msg{nomsg+2},'MaxIter',5000);
%%% NORMAL %%%%%

%% use OCTAVE optim package
if isOctave
   MaxIter=max(500,50*min(nx,100));
   opts = optimset('Display','off','MaxIter',MaxIter);
	if isempty(H)
% %     [s,f]=linprog(fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0);
%       H = eye(nx);
%       [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0,opts);
      [s,f,exitflag,output,LAMBDA]=lpOctave(fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0,opts);
   else
      [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0,opts);
      if exitflag<1
         eigH = eig(H);
         pertb=min(eigH);
         ndv = length(fp);
         if pertb<0
            H = H - diag(repmat(1.01*pertb,ndv,1));% Marquardt modification
         else
            H = eye(ndv)*max(eigH)/ndv;
         end
         [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),...
          A(p1,:),b(p1),vlb,vub,x0,opts);
      end
	end

%% Mathworks optimization toolbox linprog, quadprog
else
   if isempty(H) || ~any(H(:))
      options=optimset('linprog');
      MaxIter = max(max(200,10*min(nx,100)), optimget(options,'MaxIter'));
      options=optimset(options,'Display',msg{nomsg+2},'MaxIter',MaxIter);
      [s,f,exitflag,output,LAMBDA]=linprog(fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0,options); %#ok<*ASGLU>
   else
      options=optimset('quadprog');
      MaxIter = max(max(200,10*min(nx,100)), optimget(options,'MaxIter'));
      if verLessThan('optim','7.0')
         options=optimset(options,'Display',msg{nomsg+2},'LargeScale','off',...
            'Algorithm','active-set','MaxIter',MaxIter);
      else
         options=optimset(options,'Display',msg{nomsg+2},'MaxIter',MaxIter);
      end
      [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),A(p1,:),b(p1),vlb,vub,x0,options);
      if exitflag<0 && verLessThan('optim','7.5')
         warning('off','optim:quadprog:WillBeRemoved');
         options=optimset(options,'Algorithm','active-set');
         [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),...
            A(p1,:),b(p1),vlb,vub,x0,options);
      elseif exitflag==-6
         ndv = length(fp);
         % Marquardt modification
         H = H - diag(repmat(1.01*min(eig(H)),ndv,1));
         [s,f,exitflag,output,LAMBDA]=quadprog(H,fp,A(p2,:),b(p2),...
                                                    A(p1,:),b(p1),...
                                               vlb,vub,x0,options);
%          if isempty(s), s=zeros(size(fp)); end
%          HessianFcn = @(x,lambda) H;
%          options = optimoptions(@fmincon,'SpecifyObjectiveGradient', true,...
%             'HessianFcn',HessianFcn,...
%             'Display','off');
%          [s,f,exitflag,output,LAMBDA]=fmincon(@qobj,s,A(p2,:),b(p2),...
%             A(p1,:),b(p1),vlb,vub,[],options);
      end
   end
end

%% Exit return
if exitflag>0
   status='ok';
elseif exitflag==0
   status='maximum number of iterations exceeded';
elseif exitflag<0
   status='infeasible, unbounded, or unconverged';
end
u=[];
%if (isOctave==1 && exitflag > 0) || (isOctave==0 && exitflag>=0)
if exitflag>0 || (exitflag==0 && ~isOctave)
   if ~isempty(LAMBDA.eqlin),   u=[u;LAMBDA.eqlin(:)]; end
   if ~isempty(LAMBDA.ineqlin), u=[u;LAMBDA.ineqlin(:)]; end
   if ~isempty(vlb),            u=[u;LAMBDA.lower(1:length(vlb))]; end
   if ~isempty(vub),            u=[u;LAMBDA.upper(1:length(vub))]; end
end

%% Added -1 conditions to handle MOSEK exitflags
%  if exitflag==-1
%     status='ok';
%  end
% %%%%%MOSEK%%%%%%%
%  rmpath('c:\mosek\4\toolbox\r14sp3')
%  u = [LAMBDA.eqlin(:); LAMBDA.ineqlin(:); ...
%       LAMBDA.lower(1:length(vlb)); LAMBDA.upper(1:length(vub))];

% %% Quadratic objective function for QP search direction subproblem
%    function [f,gradf]=qobj(x)
%       f     = fp'*x + x'*H*x/2;
%       gradf = fp    +    H*x;
%    end
end
