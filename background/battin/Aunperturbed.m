function[Ro,Vo]=Aunperturbed(Ri,Vi,t0,tf,mu)
%% description (Advanced Unpurturbed Propagagor)
% this function takes in a position and velocity and a t0 at that position
% and velocity and propagates it to time tf which can be positive or
% negative (aka we can propagate backwards in time!)

%% Inputs
% Ri (km) the nominal position of satellite in IJK at time t based on
% averaging atleast two angles only gauss observations requiring 6 points
% of data (probably) but maybe as little as 4.
% Vi (km/s) the nominal velocity of the satellite
% t0 (sec) the time that R_nom and V_nom were taken
% tf (sec) the time which we want to propagate to

%% Outputs
% Ro (km) final position
% Vo (km/s) final velocity
%% Calculations
sys_con;
options = odeset('RelTol',1e-6,'AbsTol',10^-9);

if t0>tf %use this if we are going backwards in time from t5
    [t1,f1]=ode45(@unperturbed,[tf:t0],[Ri,-Vi],options,mu);
    Ro=f1(length(f1),1:3);
    Vo=-f1(length(f1),4:6);
elseif t0<tf % use this if we are going forwards in time from t5
    [t1,f1]=ode45(@unperturbed,[t0:tf],[Ri,Vi],options,mu);
    Ro=f1(length(f1),1:3);
    Vo=f1(length(f1),4:6);
elseif t0==tf %only happens when t=t5;
    Ro=Ri;
    Vo=Vi;  
end