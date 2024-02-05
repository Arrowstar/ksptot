%% runBeamGV
% Script to Run Gary Vanderplaats cantilever Beam with SQP and SLP. 
% N beam segments and 2N design variables, taken from 
% Vanderplaats (1984) Example 5-1, pp. 147-150.

%% Initialize variables
clear; 
options.Display = 'iter';
options.MaxIter = 40;
options.TolX   = 0.1;
options.TolFun = 0.5; TolFun=options.TolFun;
options.TolCon = 1e-4;
options.MoveLimit = 0.2;
options.psd = 'on';

%% Small and Large-Scale number of variables
for N = [5 50] % number of beam segments
   x0 = [5*ones(1,N), 40*ones(1,N)];
   xlb = [ ones(1,N),  5*ones(1,N)];
   options.TypicalX = x0;
   options.TolOpt = 2.0;
   disp(' ')
   disp(['N=',num2str(N),' beam segments'])

%% SQP with BFGS
   disp('SQP with BFGS'), tic
   [dv2,out2,lam2] = sqp(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
   if~isOctave, disp(out2), end

%% SQP with Exact Hessian
   disp('SQP with exact Hessians')
   options.HessFun=@HbeamGV; tic
   [dv3,out3,lam3,H3] = sqp(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
   if ~isOctave, disp(out3), end
   options=rmfield(options,'HessFun');

   %% SQP Trust Region with Exact Hessian
   disp('SQP Trust Region with exact Hessian')
   options.HessianFcn=@HbeamGV;
   options.TolOpt = 0.5; tic
   [~,~,stat3,out3] = sqp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
   if ~isOctave, disp(out3), end
   options.TolOpt = 2.0;
   options=rmfield(options,'HessianFcn');

%% SLP Trust
%  with and without active set strategy
   if N>=50 && ~isOctave
      disp('SLP with TRAM filter and active set')
      options.TrustRegion='TRAMfilter';
      tic
      [~,fa,stat,outa] = slp_trust(@fbeamGVa,x0,options,xlb,[],@gbeamGVa); toc
   else
      disp('SLP filter')
      options.TrustRegion='filter'; tic
      [~,f1,sta1,out1] = slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
      if ~isOctave, disp(out1), end
%       %% SQP Trust
%       disp('SQP TR - BFGS')
%       options.HessianApproximation = 'BFGS'; tic
%       [~,~,statq,outq] = sqp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
%       disp(outq)
%       options=rmfield(options,'HessianApproximation');
   end
   
%% MPEA
   if N<50
      disp('MPEA')
      options.Algorithm='MPEA';
      options.TrustRegion='filter'; tic
      [~,~,statm,outm] = slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
      if ~isOctave, disp(outm), end
   end
% %% MPEA Legacy
%    disp('MPEA Legacy')
%    options=rmfield(options,'Algorithm');
%    options.MPEA='legacy'; tic
%    [~,~,statl,outl] = slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
%    if ~isOctave, disp(outl), end
%    options=rmfield(options,'MPEA');
   
%% QMA
   disp('QMA')
   options.Algorithm='QMA'; 
   options.TrustRegion='filter';
   options.TolFun = 0.1;           tic
   if N<20, options.debug='on'; end
   [~,~,statq,outq] = sqp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
   if ~isOctave, disp(outq), end
   options.TolFun=TolFun;
   
%% QMEA
   disp('QMEA')
   options.Algorithm='QMEA'; tic
   [~,~,statqe,outqe] = sqp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV); toc
   if ~isOctave, disp(outqe), end
   options = rmfield(options,'Algorithm');
   if isfield(options,'debug'), options=rmfield(options,'debug'); end
   
%% fmincon with analytic gradients
   if ~isOctave
   A = [diag(-20.*ones(N,1)),diag(ones(N,1))]; % Linear Constraints
   b_U     = zeros(N,1);                       % Bound on linear constraints
   disp(' ')
   disp('fmincon fails with looser tolerances used for SQP and SLP_Trust')
   Options=optimoptions(@fmincon,'Display','iter','GradObj','on','GradConstr','on',...
                                 'TolX',0.5,'TolFun',0.5,'TolCon',1e-4);
   [~,~,flag,out]=fmincon(@GVbeam_obj,x0,A,b_U,[],[],xlb,[],...
                          @GVbeam_nlcon,Options) %#ok<*ASGLU,*NOPTS>
   
   Options=optimoptions(Options,'Algorithm','sqp');
   [~,~,flag,out]=fmincon(@GVbeam_obj,x0,A,b_U,[],[],xlb,[],...
                          @GVbeam_nlcon,Options)

 %% fmincon, tight tolerances
    disp('fmincon with tighter default tolerances')
    Options=optimoptions(@fmincon,'Display','iter','GradObj','on','GradConstr','on');
    tic
    [~,~,flag,out]=fmincon(@GVbeam_obj,x0,A,b_U,[],[],xlb,[],...
       @GVbeam_nlcon,Options), toc
%     disp('fmincon treating all constraints as nonlinear')
%     tic
%     [~,~,flag,out]=fmincon(@GVbeam_obj,x0,[],[],[],[],xlb,[],...
%        @GVbeam_con,Options);
%     toc
    Options=optimoptions(Options,'Algorithm','sqp'); tic
    [~,~,flag,out]=fmincon(@GVbeam_obj,x0,A,b_U,[],[],xlb,[],...
                           @GVbeam_nlcon,Options), toc
   end
end