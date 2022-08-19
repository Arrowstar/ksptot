%% GERAD VERSION TESTING
%Note xtype has been dropped as per Christophe's MEX file

%% PROBLEM 1
% why the large difference in results for same mesh tolerance?
clc
fun = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
x0 = [-2 1]';
lb = [-Inf;-1.5];
ub = [100;100];
opts1 = nomadset('min_mesh_size','1e-007','direction_type','ortho n+1 quad');
opts2 = nomadset('min_mesh_size','1e-007','direction_type','ortho 2n');

%New Search
[x,fval] = nomad(fun,x0,lb,ub,opts1)
%Old Search
[x2,fval2] = nomad(fun,x0,lb,ub,opts2)

%% PROBLEM 2
% Gets stuck in v3.6.0 ..... (use ctrl-c to exit)
clc
% Blackbox Function
bb = @(x) [29.4*x(1) + 18*x(2);
           -(x(1) - 0.2458*x(1)^2/x(2)) + 6];
% Bounds      
lb = [0;1e-5];
ub = [115.8;30];
% Starting Guess
x0 = [0;1e-5];
% Options
opts = nomadset('display_degree',2,'bb_output_type','OBJ PB');

[x,fval,ef,iter] = nomad(bb,x0,lb,ub,opts)

%% PROBLEM 3
% When specified as ortho n+1, ortho n+1 NEG is used? [direction  : (  1  0 ) Ortho-MADS n+1 NEG ]
clc
% Blackbox Function
bb = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
% Starting Guess
x0 = [0 0]';
opts = []; %not no nomadset just to keep user options
opts.display_degree = 3;
opts.direction_type = 'ortho n+1';
opts.max_bb_eval = 2;
% Solve
[x,fval,ef,iter] = nomad(bb,x0,[],[],opts)

%% PROBLEM 4 [fval = -2.5]
% Fixed parameter error??
clc
fun = @(x)   [-x(1) - x(2) - x(3);
              (x(2) - 1./2.)*(x(2) - 1./2.) + (x(3) - 1./2.)*(x(3) - 1./2.) - 1/4;
                x(1) - x(2);
                x(1) + x(3) + x(4) - 2];          
ub = [1;10;10;5];
lb = [0;0;0;0];
x0 = [0;0;0;0];

opts = []; %not no nomadset just to keep user options
opts.display_degree = 2;
opts.bb_output_type = 'OBJ PB PB PB';
opts.bb_input_type = '[B R R I]';

[xr,fval,ef,iter] = nomad(fun,x0,lb,ub,opts)


%% REMAINDER OF PROBLEMS OK

%% Rosenbrock [x = 1,1, fval = 0]
clc
% Blackbox Function
bb = @(x) (1-x(1))^2 + 100 *(x(2)-x(1)^2)^2;
% Starting Guess
x0 = [0 0]';
% Solve
[x,fval,ef,iter] = nomad(bb,x0)

%% St_e01 [x = 6,0.6667, fval = -6.6667]
clc
% Blackbox Function
bb = @(x) [-x(1) - x(2);
           x(1)*x(2) - 4];
% Bounds
lb = [0;0];
ub = [6;4];
% Starting Guess
x0 = [1,1]';
% Options
opts = nomadset('display_degree',2,'bb_output_type','OBJ PB');
% Solve
[x,fval,ef,iter] = nomad(bb,x0,lb,ub,opts)

%% St_e08 [x = 0.1294, 0.4830, fval = 0.7418]
clc
% Blackbox Function
bb = @(x) [2*x(1)+x(2);
           -16*x(1)*x(2) + 1; 
           (-4*x(1)^2) - 4*x(2)^2 + 1];
% Bounds       
lb = [0;0];
ub = [1;1];
% Starting Guess
x0 = [0;0];
% Options
opts = nomadset('display_degree',2,'bb_output_type','OBJ PB PB');

[x,fval,ef,iter] = nomad(bb,x0,lb,ub,opts)

%% Wolfram problem (multiple global minima fval = 0)
clc
% Fitting Function
obj = @(x) [x(1) - sin(2*x(1) + 3*x(2)) - cos(3*x(1) - 5*x(2));
          x(2) - sin(x(1) - 2*x(2)) + cos(x(1) + 3*x(2))];      
% Blackbox Function      
bb = @(x) norm(obj(x));

% Bounds
lb = [-4;-4];
ub = [4;4];
% Starting Guess
x0 = [0;-3];
% Options
opts = nomadset('display_degree',2,'vns_search',0.9,'f_target',1e-6);

[x,fval,ef,iter] = nomad(bb,x0,lb,ub,opts)

%% MINLP 1 [fval = -5]
clc
fun = @(x) [ (x(1) - 5)^2 + x(2)^2 - 25;
              x(1)^2 - x(2) + 0.5 ];
x0 = [0;0];
opts = nomadset('display_degree',2,'bb_input_type','[I I]','bb_output_type','OBJ PB');
[xr,fval,ef,iter] = nomad(fun,x0,[],[],opts)

%% Bi-Objective (NOMAD Example)
clc
% Blackbox Function
bb = @(x) [x(5); 
           sum((x-1).^2)-25;
           25-sum((x+1).^2)];   
% Bounds       
lb = [-6;-6;-6;-6;-6];
ub = [5;6;7;Inf;Inf];
% Starting Guess
x0 = [0;0;0;0;0];
% Options
% note the setting of bb_output_type in order to specify two objectives
opts = nomadset('display_degree',2,'multi_overall_bb_eval',100,'bb_output_type','obj obj eb');

[xr,fval,ef,iter] = nomad(bb,x0,lb,ub,opts)

%% TEST SURROGATE
% wasn't sure on remainder of parameters for this function...
clc
x0 = [1;1];
opts = nomadset('display_degree',2,'bb_output_type','OBJ EB','has_sgte',1)
[x,fval] = nomad(@bbsur,x0,[-10;-10],[10;10],opts)

% function eval = bbsur(x,sur)
% if (nargin==1), sur=false; end
% if (sur)
%     eval=[9.9*(x(2)-x(1)^2); 1 - x(1)];
% else
%     eval=[10*(x(2)-x(1)^2); 1 - x(1)];
% end