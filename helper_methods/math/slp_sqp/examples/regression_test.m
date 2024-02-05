%% Regression_test script to run slp_trust and sqp examples

%% Log file
clear; clc; close all; format compact
delete regression_test.txt
diary  regression_test.txt
warning('backtrace','off')
disp(version)
disp(date)
disp(' ')

%% Octave package
if exist ('OCTAVE_VERSION','builtin')
   % Tested with Octave versions 4.4.1 and 5.1.0 on Mac OSX 10.13.16
   % isOctave used by private/qp.m, sqpcrkopts.m
   % Manually move checkbounds.m to private directory
   MSGID = 'Octave:possible-matlab-short-circuit-operator';
   warning('off',MSGID);
   % source this script examples/regression_Octave.m from slp_sqp directory
   % or specify full directory path in addpath
   pkg load optim
   addpath('examples:private:private/Octave')
   
   % OutputFcn specific to Octave
   history_slp = OutputPlotFcnsExampleOctave('slp') %#ok<NOPTS>
   history_sqp = OutputPlotFcnsExampleOctave('sqp') %#ok<NOPTS>
   
else
   disp('OutputPlotFcnsExample')
   runOutputFcnExample
end

%% Run scripts
disp(' ')
disp('run2barFox')
run2barFox % sqp
regression_check( xf, [1.87835663, 20.23690725], 'Fox2bar' );

Ricciardi_cs_test
runSimple
runBarnes
runHaftka4p2p1
runHaftka6p3p1slp
runRosenSuzuki
runSpringExampleTrust

runSvanbergSLP
xSvanberg = [
   6.01858007
   5.30292693
   4.49935286
   3.50102575
   2.15179983];
regression_check( x, xSvanberg, 'Svanberg_SLP', 0.03 );

runSvanbergSQP
xSvanberg = [
   6.01858007
   5.30292693
   4.49935286
   3.50102575
   2.15179983];
regression_check( x, xSvanberg, 'Svanberg_SQP', 0.06 );

try
  runBeamGVslp
  runBeamGV
catch
  disp(lasterr) %#ok<LERR>
end
diary off

tsuite

diary regression_test.txt
fprintf('\n\n\n----- tsuite -----\n\n\n')
type tsuite.log
diary off