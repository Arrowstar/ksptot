%% runSpringExampleTrust.m
% Example problem taken from Vanderplaats textbook, example 3-1. 
% Unconstrained potential energy minimization of two springs.
% Complex-step gradient.

%% Initialize tolerances
clear;
disp(' ')
disp('Vanderplaats textbook Example 3-1')
options.ComplexStep = 'on';
options.Display = 'iter';
options.MaxIter = 50;
options.TypicalX = [5;5];
options.TolFun  = 0.001; % 0.0001 for SLP slow termination criterion
options.TolX    = 0.1;
xans = [8.6329432, 4.5299463];

%% SQP
[x,out]=sqp( @fVanderplaatsSpringEx3d1,[5 5],options )
regression_check( x, xans, 'GV Spring Ex 3.1' );

%% SLP gradually reduced move limits (no Trust Region Strategy)
options.TrustRegion = 'off';
x=slp_trust(@fVanderplaatsSpringEx3d1,[5 5],options) %#ok<*NOPTS>
regression_check( x, xans, 'GV Spring Ex 3.1', 3e-3 );

%% SLP Trust Region
options.TrustRegion = 'on';
options.MoveLimit   = 0.5;
options.OptimalityTolerance = 0.01;
[X,PE] =slp_trust(@fVanderplaatsSpringEx3d1,[5 5],options)
regression_check( X, xans, 'GV Spring Ex 3.1', 3e-3 );