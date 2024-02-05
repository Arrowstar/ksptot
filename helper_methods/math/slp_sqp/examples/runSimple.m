%% run Simple explict example

%% Initialize variables
clear; 
options.Display = 'iter';
options.MaxIter = 50;
options.TolX   = 0.001;
options.TolFun = 0.001;
options.TolCon = 1e-4;
options.OptimalityTolerance = 0.01;
options.MoveLimit = 0.2;
options.ComplexStep = 'on';
options.psd = 'off';

x0 = ones(1,3);
xlb = 0.1*x0;
xub =  10*x0;
x_opt = [0.1, 0.1, 7.9047]';

disp(' ')
disp('runSimple')

%% SLP Trust
[x1,f1,stat1,outslp,LMslp] = slp_trust(@fsimple,x0,options,xlb,xub);
regression_check( x1, x_opt, 'runSimple', 0.0001 );

%% QMA Trust
options.debug='on';
[x2,f2,stat2,outqma,LMqma] = sqp_trust(@fsimple,x0,options,xlb,xub);
regression_check( x2, x_opt, 'runSimple', 0.0001 );
options.debug='off';

%% MPEA legacy
options.TrustRegion='filter'; options.MPEA='legacy'; options.QMEA='off';
[x3,~,~,outmpea] = slp_trust(@fsimple,x0,options,xlb,xub) %#ok<ASGLU,*NOPTS>

%% MPEA Trust
options.TrustRegion='filter'; options.MPEA='on'; options.QMEA='off';
[x3,f3,stat3,outmpea] = slp_trust(@fsimple,x0,options,xlb,xub);
regression_check( x3, x_opt, 'runSimple', 0.0001 );

%% QMEA Trust (quadprog)
options.MPEA='on'; options.QMEA='on'; options.debug='on';
[x4,f4,stat4,outqmea] = sqp_trust(@fsimple,x0,options,xlb,xub);
regression_check( x4, x_opt, 'runSimple', 0.0001 );
options.debug='off';

%% SQP
x0(3)=5;
options.TolFun = 0.0001;
[x,f,stat,outsqp,LMsqp] = sqp(@fsimple,x0,options,xlb,xub);
regression_check( x, x_opt', 'runSimple', 0.0001 );