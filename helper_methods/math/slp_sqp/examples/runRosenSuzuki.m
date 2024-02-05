%% Rosen-Suzuki four-variable constrained optimization problem
% Hock W., Schittkowski K. (1981): 
% Test Examples for Nonlinear Programming Codes, 
% Willi Hock, Klaus Schittkowski, 
% Springer, Lecture Notes in Economics and Mathematical Systems, Vol. 187

%% Initialize variables
clear;
disp(' ')
disp('Rosen-Suzuki problem from Hock & Schittkowski test suite')

ndv = 4;
x0  = (2:5)';
xlb = repmat(-100,ndv,1);
xub = repmat( 100,ndv,1);
xans= [0; 1; 2; -1];

options.Display='iter';
options.MaxIter= 50;
options.TolFun = 5e-5;
options.TolX   = 1e-3;

%% Sequential Linear Programming with Trust Region Strategy
disp('SLP')
options.TrustRegion='merit'; % performs better than default 'simple'
if isOctave, options.MaxIter=4; end % Octave linprog bug
[xopt,fopt]=slp_trust(@fRosenSuzuki,x0,options,xlb,xub,@gRosenSuzuki)
[fopt,gopt]=fRosenSuzuki(xopt) %#ok<*ASGLU,*NOPTS>
regression_check(xopt, xans, 'RosenSuzuki_SLP',2e-4,@fRosenSuzuki);
options.MaxIter= 50;

%% Schittkowski's SQP coded in MATLAB by Spillman & Canfield
disp('Schittkowski''s SQP with complex step gradients')
options.ComplexStep = 'on';
options.DerivativeCheck='on';
xopt = sqp(@fRosenSuzuki,x0,options,xlb,xub);%,@gRosenSuzuki) complex step
[fopt,gopt]=fRosenSuzuki(xopt) %#ok<*ASGLU,*NOPTS>
regression_check(xopt, xans, 'RosenSuzuki_SQP',1e-4,@fRosenSuzuki);

%% Spillman & Canfield SQP with fmincon data structure
disp('Schittkowski''s SQP with fmincon problem structure')
options.ComplexStep = 'off';
options.DerivativeCheck='off';
prob.objective=@objRosenSuzuki;
prob.nonlcon=@cRosenSuzuki;
prob.x0=x0;
prob.lb=xlb; 
prob.ub=xub;
prob.options=options;
prob.solver='fmincon';
[xopt,fopt]=sqp(prob)
regression_check(xopt, xans, 'RosenSuzuki_SQP',1e-4,@fRosenSuzuki);

%% fmincon algorithms
if ~isOctave
options = optimset(options,'GradObj','on', 'GradConstr','on');
Algorithm = {'active-set','interior-point','sqp'};
for n=1:length(Algorithm)
   options = optimset(options,'Algorithm',Algorithm{n});
   disp(Algorithm{n})
   [xopt,fval]=fmincon(@objRosenSuzuki,x0,[],[],[],[],xlb,xub,@cRosenSuzuki,options)
   [fopt,gopt]=fRosenSuzuki(xopt)
end
end

%% Quadratic Objective function, Linear constraints, 4-DV
type fRosenSuzuki