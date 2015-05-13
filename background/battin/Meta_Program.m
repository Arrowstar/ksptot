clear all
close all 
clc 
format compact 
sys_con

% Test Case 1
R1=[22592.145603;-1599.915239;-19783.950506]
R2=[1922.067697;4054.157051;-8925.727465]
dt=36000

% Test Case 2
%R1=[7231.58074563487;218.02523761425;11.79251215952];
%R2=[7357.06485698842;253.55724281562;38.81222241557];
%dt=12300;

% Test Case 3
%R1=[2.5;0;0]*r_earth;
%R2=[1.915111;1.606969;0]*r_earth;
%dt=76*60;

mu=mu_earth
tm=-1
n_rev=0

%% Inputs
% R1 (km) position vector at time=1
% R2 (km) position vector at time=2
% mu (km^3/s^2) gravitational constant of the body the object is orbiting
% around
% dt (sec) the time 
% tm (dimensionless) +1 for prograde, -1 for retrograde

% Figure out del_nu (the angle between R1 and R2) in radians based on curtis
% page 264
r1=norm(R1);
r2=norm(R2);
check=cross(R1,R2);
if check(3)>=0
    if tm==1 %prograde
        del_nu=acos(dot(R1,R2)/(r1*r2)); %first or 3rd quadrant 
    elseif tm==-1 %retrograde
        del_nu=2*pi-acos(dot(R1,R2)/(r1*r2));
    end
elseif check(3)<0
    if tm==1 %prograde
        del_nu=2*pi-acos(dot(R1,R2)/(r1*r2)); %second or 4th quadreant
    elseif tm==-1 %retrograde
        del_nu=acos(dot(R1,R2)/(r1*r2));
    end
end


Lamberts_Analysis(R1,R2,mu,dt,n_rev,tm)





