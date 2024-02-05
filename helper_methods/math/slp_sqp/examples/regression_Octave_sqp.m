%% Regression_test script to run slp_trust and sqp examples

%% Log file
clear; clc; close all; format compact
delete regression_Octave.txt
diary  regression_Octave.txt
disp(version)
disp(date)
if exist ('OCTAVE_VERSION','builtin')
   % Tested with Octave version 4.4.1 on Mac OSX 10.13.16
   % isOctave used by private/qp.m, sqpcrkopts.m
   % Manually move checkbounds.m to private directory
   MSGID = 'Octave:possible-matlab-short-circuit-operator';
   warning('off',MSGID);
   % source this script examples/regression_Octave.m from slp_sqp directory
   % or specify full directory path in addpath
   pkg load optim
   addpath('examples:private:private/Octave')
end

%% Run scripts
run2barFox
regression_check( xf, [1.87835663, 20.23690725], 'Fox2bar' );

Ricciardi_cs_test

runSvanbergSQP
xSvanberg = [
   6.01858007
   5.30292693
   4.49935286
   3.50102575
   2.15179983];
regression_check( x, xSvanberg, 'Svanberg_SQP', 0.06 );

%% runSpringExampleTrust.m
% Example problem taken from Vanderplaats textbook, example 3-1. 
% Unconstrained potential energy minimization of two springs.
% Complex-step gradient.
%
% Initialize tolerances
clear; 
options.ComplexStep = 'on';
options.Display = 'iter';
options.MaxIter = 50;
options.TypicalX = [5;5];
options.TolFun  = 0.001; % 0.0001 for SLP slow termination criterion
options.TolX    = 0.1;
xans = [8.6329432, 4.5299463];

[x,out]=sqp(      @fVanderplaatsSpringEx3d1,[5 5],options) %#ok<*NOPTS>
regression_check( x, xans, 'GV Spring Ex 3.1' );

%% runSimple
options.Display = 'iter';
options.MaxIter = 50;
x0 = ones(1,3);
xlb = 0.1*x0;
xub =  10*x0;
[x,f,stat,outsqp,LMsqp] = sqp(@fsimple,x0,options,xlb,xub); %#ok<ASGLU>
x %#ok<*NOPTS>
x0(3)=5; % start closer
[x,f,stat,outsqp,LMsqp] = sqp(@fsimple,x0,options,xlb,xub);
x

%% sqp regression test suite
diary off
tsuite