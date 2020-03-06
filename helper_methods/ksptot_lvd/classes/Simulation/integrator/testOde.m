clc; clear all; format long g; close all;

tspan = 0:0.5:20;
y0 = [2 0];
odefun = @vdp1;
options = odeset();

% tspan = 0:0.5:15;
% y0 = [20 20]';
% odefun = @lotka;
% options = odeset('Events',@events);

% tspan = 0:1:30;
% y0 = [0; 20];
% odefun = @f;
% options = odeset('Events',@events);

tic;
[tOde45,yOde45]= ode113(odefun,tspan,y0,options);
toc;

int = ODE5Integrator();
tic;
[tMyOde,yMyOde]= int.integrate(odefun,tspan,y0,options);
toc;

hF = figure();
hold on;
plot(tOde45,yOde45(:,1),'b');
plot(tMyOde, yMyOde(:,1), 'c--');

plot(tOde45,yOde45(:,2),'r');
plot(tMyOde, yMyOde(:,2), 'y--');
grid minor;


function dydt = f(t,y)
    dydt = [y(2); -9.8];
end

% --------------------------------------------------------------------------

function [value,isterminal,direction] = events(t,y)
% Locate the time when height passes through zero in a decreasing direction
% and stop integration.
    value = y(1);     % detect height = 0
    isterminal = 1;   % stop the integration
    direction = -1;   % negative direction
end