% runExtRosenbrock.m - script to minimize extended Rosenbrock function
%                      for increasing number of design variables
%
% Goldberg, D. E. (1989) Genetic algorithms in search, optimization and
% machine learning. Reading, Massachusetts: Addison-Wesley
%
% Kok, Schalk, and Carl Sandrock (2009) "Locating and Characterizing the
% Stationary Points of the Extended Rosenbrock Function," Evolutionary
% Computation, No. 17 (3):437-453, doi: 10.1162/evco.2009.17.3.437
%
%  Written by: Robert A. Canfield
%  Created:    2/24/18
%  Modified:   2/24/18

clear; clc
options.Display = 'iter';
options.TolX = 1e-4;
options.TolFun = 1e-5;
options.TolOpt = 1e-5;
options.TrustRegion = 'TRAM-filter';

for N = [2 10 100]% 1000 1e4] % number of design variables
   %% set optimizer variables
   disp(['N = ',num2str(N)])
   options.MaxIter = max( 100, 25*N );
   options.MaxFunEvals = 4*options.MaxIter;
   if N==2
      x0 = [-1.9; 2.0];
   else
      x0 = zeros(N,1);
   end
   xlb = repmat(-2.048, size(x0));
   xub = repmat( 2.048, size(x0));
   
   %% SQP
   tic
   [~,outsqp]=sqp(@fextRosenbrock,x0,options,xlb,xub,@gextRosenbrock); toc
   disp(outsqp)
   
   %% fmincon IP
   opts=optimoptions(@fmincon,'Display','iter','TolFun',1e-5,'GradObj','on',...
      'MaxIterations', options.MaxIter,...
      'MaxFunctionEvaluations',10*options.MaxIter);
   tic
   [~,outip]=fmincon(@objextRosenbrock,x0,[],[],[],[],xlb,xub,[],opts); toc
   disp(outip)
   
%    %% SLP Trust
%    disp(' '), disp('SLP')
%    [~,outslp]=slp_trust(@fextRosenbrock,x0,options,xlb,xub,@gextRosenbrock);
%    disp(outslp)
%    
   %% MPEA
   disp(' '), disp('MPEA')
   options.MPEA='on'; options.QMEA='off';
   [~,outmpea]=slp_trust(@fextRosenbrock,x0,options,xlb,xub,@gextRosenbrock);
   disp(outmpea)

   %% QMEA
   disp(' '), disp('QMEA')
   options.MPEA='on'; options.QMEA='on'; %options.TrustRegion='TRAM-filter';
   x00  = repmat(1e-4, N,1);
   xlb0 = repmat(1e-4,size(x0));
   tic
   [~,outqmea]=sqp_trust(@fextRosenbrock,x00,options,xlb0,xub,@gextRosenbrock); toc
   disp(outqmea)
end
