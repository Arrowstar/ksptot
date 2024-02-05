%% Script to solve Haftka Exercise 6.3.1 using SLP
% Haftka, R. T. and Z. Gurdal (1992), Elements of Structural Optimization, 
% Kluwer Academic Publishers

%% Initialize guess for design variables and move limit bounds
clear;
x0  = [ 1; 1];
xlb = [ 0; 0];
xub = [10; 10];

%% Initialize termination criteria tolerances
options=optimset('Display','iter');
options.TolX   = 0.01;
options.TolCon = 1e-3;
options.MoveLimit=0.5;
tolreg = 1e-4;

disp(' ')
disp('Haftka Exercise 6.3.1')

%% Sequential Linear Programming with Trust Region Strategy
options.TrustRegion='merit';
[xopt,fval] = slp_trust(@fHaftka6p3p1,x0,options,xlb,xub,@gHaftka6p3p1) %#ok<*NOPTS>
regression_check(xopt, [4; 3], 'Haftka 6.3.1 SLP merit',tolreg,@fHaftka6p3p1);

%% Sequential Linear Programming with Trust Region Strategy Filter
options.TrustRegion='filter';
[xopt2,fval2] = slp_trust(@fHaftka6p3p1,x0,options,xlb,xub,@gHaftka6p3p1) %#ok<*NOPTS>
regression_check(xopt, [4; 3], 'Haftka 6.3.1 SLP filter',tolreg,@fHaftka6p3p1);

%% SLP Trust Region with Adaptive Move Limits
if exist('../private/trust_adapt','file')
   options.TrustRegion='TRAM';
   [xopt3,fval3] = slp_trust(@fHaftka6p3p1,x0,options,xlb,xub,@gHaftka6p3p1)
   regression_check(xopt2, [4; 3], 'Haftka 6.3.1 SLP TRAM',tolreg,@fHaftka6p3p1);
end

%% Linear Objective function, Quadratic Constraints, 2-DV
type fHaftka6p3p1
type gHaftka6p3p1