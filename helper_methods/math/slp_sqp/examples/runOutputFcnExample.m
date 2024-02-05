%% runOutputFcnExample Script
% Illustrate use of options.OutputFcn for user to supply function
% to store and/or plot iteration history.

%% sqp
close all
history_sqp = OutputFcnSqpExample('sqp');

%% slp_trust
history_slp = OutputFcnSqpExample('slp_trust');

%% fmincon
history_ip = OutputFcnSqpExample('fmincon');
