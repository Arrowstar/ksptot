function [K_U]=Kay(U)
%% Description
% Caluclates the values of K_U given the input variable U. Based on Vallado
% page 493. Used to calculate the intermediate variable K_U to solve
% lambert's problem via Batton's Method
% Impossible to validate against Vallado's code because his kbatt.m
% function is broken

%% Inputs
% U - from Batton_Lambert.m code

%% Outputs
% K_U - used by Batton_Lambert.m 

%% Calculations

% setup the C variable
c(1)=4/27;   %@n=0
c(2)=8/27; %@n=1
c(3)=208/891; %n=2
c(4)=340/1287; %@n=3
c(5)=700/2907;
c(6)=928/3591;
c(7)=296/1215;
c(8)=1804/7047;
c(9)=2548/10395;
c(10)=2968/11655;
c(11)=3904/15867;
c(12)=884/3483;
c(13)=5548/22491;
c(14)=6160/24327;
c(15)=7480/30267;
c(16)=8188/32391;
c(17)=1940/7839;
c(18)=10504/41607;
c(19)=12208/49275;
c(20)=13108/51975;

% sum up all the intermediate variables
Z=1+c(20)*U;
Z=1+c(19)*U/Z;
Z=1+c(18)*U/Z;
Z=1+c(17)*U/Z;
Z=1+c(16)*U/Z;
Z=1+c(15)*U/Z;
Z=1+c(14)*U/Z;
Z=1+c(13)*U/Z;
Z=1+c(12)*U/Z;
Z=1+c(11)*U/Z;
Z=1+c(10)*U/Z;
Z=1+c(9)*U/Z;
Z=1+c(8)*U/Z;
Z=1+c(7)*U/Z;
Z=1+c(6)*U/Z;
Z=1+c(5)*U/Z;
Z=1+c(4)*U/Z;
Z=1+c(3)*U/Z;
Z=1+c(2)*U/Z;
Z=1+c(1)*U/Z;

K_U=1/(3*Z);




