function[Phi_o_Phip]=Phi_o_Phip(x_mt,sig,N)
%% Description
% This function performs a subprocess required for the Lambert Der-Sun
% process for multi-rev. It is used in a newtons iteration to solve for x
% Based on the Paper "The Superior Lambert Algorithm" By Gim J. Der (page 15)
% This is basically half of a newton's iteration.

%% Outputs
% Phi_o_Phip = Phi(x)/Phi'(x)

%% Inputs
% x_mt from Der_Sun_Lambert.m
% sig used to change the sign on the value of y 
% N number of revolutions

%% Calculations

little_pi = @(x) acot(x/sqrt(1-x^2))-(x+x^2)*sqrt(1-x^2)/(3*x)

if sig^2~=0
    y=sign(sig)*sqrt((1-sig^2)*(1-x^2));
elseif sig^2==1
    y=1;
end

Phi=little_pi(y)-little_pi(x_mt)-N*pi;

Phi_dot=3/2*(1-x^2)^(3/2)/x^2*(1-sig^5*x^3/abs(y)^3);

Phi_o_Phip=Phi/Phi_dot;





