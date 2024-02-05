%% runBeamGVslp
% Script to Run Gary Vanderplaats cantilever Beam with slp_trust. 
% N beam segments and 2N design variables, taken from 
% Vanderplaats (1984) Example 5-1, pp. 147-150.
%
%  Trust Region (TR) Strategy follows
%  Nocedal, J., and Wright, S.J. Numerical Optimization. 
%  New York: Springer, 2006.
%  Algorithm  4.1 for TR and
%  Algorithm 15.1 for filter; and 
%  Equation (15.4) for the simple L1 merit function
%
% TR Approximate Model (TRAM) for adaptive move limits roughly follows 
% Wujek, B. A., and Renaud, J. E. "New Adaptive Move-Limit Management
% Strategy for Approximate Optimization, Part I," AIAA J. Vol. 36, No. 10,
% 1998, pp. 1911-1921 
% except that quadratic approximations are used for objective and
% constraints and a linear approximation for the merit penalty function
% (instead of TANA for the merit function)
% during the "line search" that determines the trust region radius.
% Also, a custom TR algorithm is used for multi-penalty L1 merit function. 

%% Initialize variables
clear; 
N = 10;%[5 10 20 40 50 100 200]; % number of beam segments
x0 = [5*ones(1,N), 40*ones(1,N)];
xlb = [ ones(1,N),  5*ones(1,N)];
dv_ans = [
  3.19816490
  3.08376316
  2.95741262
  2.81884951
  2.66757801
  2.49525923
  2.29425084
  2.05390625
  1.74975701
  1.38878306
 63.96329803
 61.67526322
 59.14825242
 56.37699020
 53.35156029
 49.90518453
 45.88501685
 41.07812501
 34.99514024
 27.77566121];

%% SLP Trust
%  TrustRegion='filter' (default)
options.Display = 'Iter';
options.TolX = .5;
options.TolFun = 0.5;
options.TolOpt = 1.0;
options.TolCon = 1e-4;
options.MoveLimit = 0.2;
options.MaxIter = 40;
% default options for simple merit function TR algorithm
[dv,f,sta,out,lambda] = slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV);
regression_check( dv, dv_ans, 'BeamGV_SLP', 0.1, @fbeamGV );

%% other SLP TR methods - simple merit descent function
%  Exact L1 single penalty, mu*max(0,g) (default)
options.TrustRegion = 'simple';
options.Contract = 0.2;
dv1=slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV);
regression_check( dv1, dv_ans, 'BeamBV_SLP', 0.1, @fbeamGV );

%% TrustRegion='merit' - multiple-penalty parameter L1 merit function
options.TrustRegion = 'merit';
dv=slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV);
regression_check( dv, dv_ans, 'BeamGV_SLP', 2e-2, @fbeamGV );

%% TrustRegion='TRAM' - TR adaptive move limit bounds (with merit)
if ~exist('../private/trust_adapt','file')
   return
end
options.TrustRegion = 'TRAM';
dv=slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV);
regression_check( dv, dv_ans, 'BeamGV_SLP_TRAM', 0.1, @fbeamGV );

%% TrustRegion='TRAM-filter' combination
options.TrustRegion = 'TRAMfilter';
dv=slp_trust(@fbeamGV,x0,options,xlb,[],@gbeamGV);
regression_check( dv, dv_ans, 'BeamGV_SLP_TRAM', 0.2, @fbeamGV );