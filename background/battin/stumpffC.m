function[C]=stumpffC(Z)
%% Description
% This program calculates the Stumpff function based on curtis page 184

%% Inputs
% Z - 

%% Outputs
% C - the stumpff function C(z)
%% Calculations
if Z>0
    C=(1-cos(sqrt(Z)))/Z;
elseif Z<0
    C=(cosh(sqrt(-Z))-1)/(-Z);
elseif Z==0
    C=1/2;
end