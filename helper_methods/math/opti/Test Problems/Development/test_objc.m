%% Test constant objective

%% LP
clc
% Linear Objective & Bias
f = -[6 5]';
objbias = 5;
% Linear Constraints
A = ([1,4; 6,4; 2, -5]); 
b = [16;28;6];    
lb = [0;0]; ub = [10;10];
%Build Object
Opt = opti('f',f,'objbias',objbias,'ineq',A,b,'bounds',lb,ub)
%Build & Solve
[x,fval,exitflag,info] = solve(Opt)  
%Plot
plot(Opt)


%% QP
P = coinRead('testQP.qps')

O = opti(P,optiset('solver','scip','display','iter'))
[x,f] = solve(O)
plot(O)

%% MILP2
clc
%Objective & Constraints
f = -[1 2 3 1]'; 
A = [-1 1 1 10; 1 -3 1 0]; 
b = [20;30];  
Aeq = [0 1 0 -3.5];
beq = 0;
%Setup Options
opts = optiset('solver','cbc','display','iter');
%Build & Solve
Opt = opti('grad',f,'ineq',A,b,'eq',Aeq,beq,'bounds',[0 0 0 2]',[40 inf inf 3]','int','CCCI','options',opts,'objbias',10)
[x,fval,exitflag,info] = solve(Opt)
plot(Opt)

%% QCQP 1
clc
%Objective & Constraints
H = [33 6    0;
     6  22   11.5;
     0  11.5 11];
f = [-1;-2;-3];
A = [-1 1 1; 1 -3 1];
b = [20;30];
Q = eye(3);
l = [2;2;2];
r = 0.5;
lb = [0;0;0];
ub = [40;inf;inf];
%Build & Solve
Opt = opti('H',H,'f',f,'ineq',A,b,'qc',Q,l,r,'bounds',lb,ub,'objbias',10,'options',optiset('display','iter','solver','ipopt'))
[x,fval,exitflag,info] = solve(Opt)