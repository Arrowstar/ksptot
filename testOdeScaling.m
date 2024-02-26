clc; clear all; format long g; close all;

% profile off; profile on;
%% base ODE function
muKerbin = 3531.6; %km^3/s^2

odefun = @(t,y) baseOdeFun(t,y);
tspan = [0 50000];
y0 = [1000;
      0;
      500;
      ...
      0;
      sqrt(muKerbin/1000);
      0];

options = odeset('RelTol',5e-14, 'AbsTol',5E-14);

tic;
[t,y] = ode113(odefun,tspan,y0,options);
toc;

%% Scaled ODE function
% lStar = 10000000; %km
% tStar = sqrt(lStar^3/muKerbin);
% vStar = lStar / tStar;
% aStar = vStar / tStar;
lStar = norm(y0(1:3)); %km
vStar = norm(y0(4:6));
tStar = lStar / vStar;
aStar = vStar / tStar;

odeFunS = @(tS,yS) scaledOdeFun(tS,yS, tStar, lStar, vStar, aStar, odefun);
tspanS = tspan/tStar;
y0S = [y0(1:3)/lStar;
       y0(4:6)/vStar];

tic;
[tS,yS] = ode113(odeFunS,tspanS,y0S,options);
toc;

yUS = [yS(:,1:3)*lStar, yS(:,4:6)*vStar];

% profile viewer;

%% Plotting
hAx = axes(figure());
hold(hAx,"on");

plot3(hAx, y(:,1), y(:,2), y(:,3), 'bo');
plot3(hAx, yUS(:,1), yUS(:,2), yUS(:,3), 'ro--');
grid(hAx,'on');
axis(hAx,'equal');

function ydot = baseOdeFun(t,y)
    rx = y(1);
    ry = y(2);
    rz = y(3);
    vx = y(4);
    vy = y(5);
    vz = y(6);

    muKerbin = 3531.6; %km^3/s^2

    rVect = [rx;ry;rz];
    vVect = [vx;vy;vz];

    rMag = norm(rVect);
    aGrav = -(muKerbin/(rMag^3))*rVect;
    
    vHat = vVect / norm(vVect);
    aThrust = 0.00003 * vHat;

    aVect = aGrav + aThrust;

    ydot = [vx;
            vy;
            vz;
            aVect(:)];
end

function yDotS = scaledOdeFun(tS,yS, tStar, lStar, vStar, aStar, baseOdeFun)
    t = tS*tStar;
    y = [yS(1:3)*lStar;
         yS(4:6)*vStar];

    yDot = baseOdeFun(t,y);

    yDotS = [yDot(1:3)/vStar;
             yDot(4:6)/aStar];
end