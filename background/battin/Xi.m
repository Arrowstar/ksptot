function[Xi_x]=Xi(x)
%% Description
% This function calculates Xi_x based on the function described by vallado
% page 492 and also in the program seebatt.m from vallado (which is
% HORRIBLY written :)
% Validated against seebatt.m 6/2/2012 -EH

%% Inputs
% x - given by the Batton_Lambert.m code

%% Output
% Xi_x - the solution to the problem

%% Calculations

% intermediate variable
N=x/(sqrt(1+x)+1)^2;


% Setup C matrix
c(1:3)=0;
c(4)=16/63;
c(5)=25/99;
c(6)=36/143;
c(7)=49/195;
c(8)=68/225;
c(9)=81/323;
c(10)=100/399;
c(11)=121/483;
c(12)=144/575;
c(13)=169/675;
c(14)=196/783;
c(15)=225/899;
c(16)=256/1023;
c(17)=289/1155;
c(18)=324/1295;
c(19)=361/1443;
c(20)=400/1599;

% here we are adding up all the denominators one at a time because the loop
% structure vallado used in his method was impossible for reasonable peopel
% to understand
Z(1)=1+c(20)*N;
Z(2)=1+c(19)*N/Z(1);
Z(3)=1+c(18)*N/Z(2);
Z(4)=1+c(17)*N/Z(3);
Z(5)=1+c(16)*N/Z(4);
Z(6)=1+c(15)*N/Z(5);
Z(7)=1+c(14)*N/Z(6);
Z(8)=1+c(13)*N/Z(7);
Z(9)=1+c(12)*N/Z(8);
Z(10)=1+c(11)*N/Z(9);
Z(11)=1+c(10)*N/Z(10);
Z(12)=1+c(9)*N/Z(11);
Z(13)=1+c(8)*N/Z(12);
Z(14)=1+c(7)*N/Z(13);
Z(15)=1+c(6)*N/Z(14);
Z(16)=1+c(5)*N/Z(15);
Z(17)=1+c(4)*N/Z(16);
Z(18)=1+16/63*N/Z(17);
Z(19)=5+N+9/7*N/Z(18);
Z(20)=3+1/Z(19);

Xi_x=8*(sqrt(1+x)+1)/Z(20);





