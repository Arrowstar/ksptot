%% runSvanbergSQP.m script to run SQP for Svanberg's 5-segment beam. 
% Svanberg, Krister, "The Method of Moving Asymptotes--A New Method for
% Structural Optimization," Intl. J. Num. Meth. Vol. 24, 1987, pp. 359-373.

%% Initialize Variables & options
Nsegments=5;
Xinitial=5;
X0=repmat(Xinitial,Nsegments,1); vlb=zeros(Nsegments,1);
options=optimset('fmincon');
options.Display='iter';
options.MaxIter=30;
options.TolX=0.1;
options.TolFun=0.001;
options.TolCon=0.001;
options.TypicalX=[]; % move limit relative to x0, instead of ones

%% Schittkowski SQP with line search
[x,output]=sqp(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam);
disp('Final Design Variables, X')
disp(x)

%% SLP with Trust Region
[x1,~,~,output1]=slp_trust(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam) %#ok<NOPTS>

%% MPEA
options.MPEA='on';
[xM,~,~,outputM]=slp_trust(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam) %#ok<NOPTS>

%% QMEA in sub-space
options.QMEA='on';
options.TolOpt=0.001;
[xQ,~,~,outputQ]=sqp_trust(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam) %#ok<NOPTS>

%% SQP QMA with Trust Region
options.MPEA='off';
options.QMEA='on';
[x2,~,~,output2]=sqp_trust(@fSvanbergBeam,X0,options,vlb,[],@gSvanbergBeam) %#ok<NOPTS>