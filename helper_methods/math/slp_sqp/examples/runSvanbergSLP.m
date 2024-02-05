%% runSvanbergSLP.m script to run SLP for Svanberg's 5-segment beam.
% Svanberg, Krister, "The Method of Moving Asymptotes--A New Method for
% Structural Optimization," Intl. J. Num. Meth. Vol. 24, 1987, pp. 359-373.

%% Initialize Variables & options
clear; 
Nsegments=5;
Xinitial=5;
X0=repmat(Xinitial,Nsegments,1); vlb=zeros(Nsegments,1);
options.Display='iter';
options.MaxIter=30;
options.TolX=0.1;
options.TolFun=0.001;
options.TolCon=0.0001;
options.DerivativeCheck='on';
options.CompexStep='on';
%options.MoveLimit=1; % relative to X0; absolute, if options.TypicalX=1
%options.MoveReduction=0.8;
%options.TrustRegion='off';

%% SLP
options.TrustRegion='merit';
[x,f,exitflag,output]=slp_trust(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam);
disp(' ')
disp('Final Design Variables, X')
disp(x)

%% Plot iteration history
figure
iter=(0:output.iterations);
[AX,H1,H2]=plotyy(iter,output.f,iter,abs(max(output.g,[],1)),'plot','semilogy'); %#ok<PLOTYY>
set(get(AX(1),'Ylabel'),'String','Objective, f(X)');
set(get(AX(2),'Ylabel'),'String','Constraint, g(X)');
set(H1,'LineStyle','-','LineWidth',1,'Marker','o');
set(H2,'LineStyle','-.','LineWidth',1,'Marker','x');
xlabel('Iteration #');
title('Svanberg Beam SLP Iteration History');
