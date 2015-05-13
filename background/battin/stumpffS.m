function[S]=stumpffS(Z)
%% Description
% This program calculates the Stumpff function based on curtis page 184

%% Inputs
% Z - 

%% Outputs
% S - the stumpff function S(z)
%% Calculations
if Z>0
    S=(sqrt(Z)-sin(sqrt(Z)))/Z^(3/2);
elseif Z<0
    S=(sinh(sqrt(-Z))-sqrt(-Z))/Z^(3/2);
elseif Z==0
    S=1/6;
end