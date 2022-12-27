%%% SPLINEFIT EXAMPLES


%% EXAMPLE 1: Breaks and pieces

% Data (200 points)
x = 2*pi*rand(1,200);
y = sin(x) + sin(2*x) + 0.2*randn(size(x));

% Uniform breaks
breaks = linspace(0,2*pi,41); % 41 breaks, 40 pieces
pp1 = splinefit(x,y,breaks);

% Breaks interpolated from data
pp2 = splinefit(x,y,10);  % 11 breaks, 10 pieces

% Plot
figure(1)
xx = linspace(0,2*pi,400);
y1 = ppval(pp1,xx);
y2 = ppval(pp2,xx);
plot(x,y,'.',xx,[y1;y2])
axis([0,2*pi,-2.5,2.5]), grid on
legend('data','41 breaks, 40 pieces','11 breaks, 10 pieces')
title('EXAMPLE 1: Breaks and pieces')



%% EXAMPLE 2: Spline orders

% Data (200 points)
x = 2*pi*rand(1,200);
y = sin(x) + sin(2*x) + 0.1*randn(size(x));

% Splines
pp1 = splinefit(x,y,8,1);  % Piecewise constant
pp2 = splinefit(x,y,8,2);  % Piecewise linear
pp3 = splinefit(x,y,8,3);  % Piecewise quadratic
pp4 = splinefit(x,y,8,4);  % Piecewise cubic
pp5 = splinefit(x,y,8,5);  % Etc.

% Plot
figure(2)
xx = linspace(0,2*pi,400);
y1 = ppval(pp1,xx);
y2 = ppval(pp2,xx);
y3 = ppval(pp3,xx);
y4 = ppval(pp4,xx);
y5 = ppval(pp5,xx);
plot(x,y,'.',xx,[y1;y2;y3;y4;y5]), grid on
legend('data','order 1','order 2','order 3','order 4','order 5')
title('EXAMPLE 2: Spline orders')



%% EXAMPLE 3: Periodic boundary conditions

% Data (100 points)
x = 2*pi*[0,rand(1,98),1];
y = sin(x) - cos(2*x) + 0.2*randn(size(x));

% No constraints
pp1 = splinefit(x,y,10,5);
% Periodic boundaries
pp2 = splinefit(x,y,10,5,'p');

% Plot
figure(3)
xx = linspace(0,2*pi,400);
y1 = ppval(pp1,xx);
y2 = ppval(pp2,xx);
plot(x,y,'.',xx,[y1;y2]), grid on
legend('data','no constraints','periodic')
title('EXAMPLE 3: Periodic boundary conditions')

% Check boundary conditions
y0 = ppval(pp2,[0,2*pi]);             % y
y1 = ppval(ppdiff(pp2,1),[0,2*pi]);   % y'
y2 = ppval(ppdiff(pp2,2),[0,2*pi]);   % y''
y3 = ppval(ppdiff(pp2,3),[0,2*pi]);   % y'''
disp('Endpoint derivatives:')
disp([y0;y1;y2;y3])



%% EXAMPLE 4: Endpoint conditions

% Data (200 points)
x = 2*pi*rand(1,200);
y = sin(2*x) + 0.1*randn(size(x));

% Breaks
breaks = linspace(0,2*pi,10);

% Clamped endpoints, y = y' = 0
xc = [0,0,2*pi,2*pi];
cc = [eye(2),eye(2)];
con = struct('xc',xc,'cc',cc);
pp1 = splinefit(x,y,breaks,con);

% Hinged periodic endpoints, y = 0
con = struct('xc',0);
pp2 = splinefit(x,y,breaks,con,'p');

% Plot
figure(4)
xx = linspace(0,2*pi,400);
y1 = ppval(pp1,xx);
y2 = ppval(pp2,xx);
plot(x,y,'.',xx,[y1;y2]), grid on
legend('data','clamped','hinged periodic')
title('EXAMPLE 4: Endpoint conditions')



%% EXAMPLE 5: Airfoil data

% Truncated data
x = [0,1,2,4,8,16,24,40,56,72,80]/80;
y = [0,28,39,53,70,86,90,79,55,22,2]/1000;
xy = [x;y];

% Curve length parameter
ds = sqrt(diff(x).^2 + diff(y).^2);
s = [0, cumsum(ds)];

% Constraints at s = 0: (x,y) = (0,0), (dx/ds,dy/ds) = (0,1)
con = struct('xc',[0 0],'yc',[0 0; 0 1],'cc',eye(2));

% Fit a spline with 4 pieces
pp = splinefit(s,xy,4,con);

% Plot
figure(5)
ss = linspace(0,s(end),400);
xyfit = ppval(pp,ss);
xyb = ppval(pp,pp.breaks);
plot(x,y,'.',xyfit(1,:),xyfit(2,:),'r',xyb(1,:),xyb(2,:),'ro')
legend('data','spline','breaks')
grid on, axis equal
title('EXAMPLE 5: Airfoil data')



%% EXAMPLE 6: Robust fitting

% Data
x = linspace(0,2*pi,200);
y = sin(x) + sin(2*x) + 0.05*randn(size(x));

% Add outliers
x = [x, linspace(0,2*pi,60)];
y = [y, -ones(1,60)];

% Fit splines with hinged conditions
con = struct('xc',[0,2*pi]);
pp1 = splinefit(x,y,8,con,0.25); % Robust fitting
pp2 = splinefit(x,y,8,con,0.75); % Robust fitting
pp3 = splinefit(x,y,8,con); % No robust fitting

% Plot
figure(6)
xx = linspace(0,2*pi,400);
y1 = ppval(pp1,xx);
y2 = ppval(pp2,xx);
y3 = ppval(pp3,xx);
plot(x,y,'.',xx,[y1;y2;y3]), grid on
legend('data with outliers','robust, beta = 0.25','robust, beta = 0.75',...
    'no robust fitting')
title('EXAMPLE 6: Robust fitting')


