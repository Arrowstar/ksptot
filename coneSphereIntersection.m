clc; clear variables; format long g; close all;
% addpath(genpath('C:\Users\Adam\Dropbox\Documents\MATLAB\gptoolbox-master'));

%Initalize KSP celestial body data
[celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
celBodyData = processINIBodyInfo(celBodyDataFromINI, false, 'bodyInfo');
celBodyData = CelestialBodyData(celBodyData);

t=tic;
% profile off; profile on;

%planet sphere
x0 = 0;
y0 = 0;
z0 = 0;
r = 600;

%sensor cone
x0C = -2000;
y0C = 0;
z0C = 0;
scOrigin = [x0C, y0C, z0C]';

sensorRange = 5000;
sensAng = deg2rad(10);

%Compute Occluding Mesh
[sV, sF] = sphereMesh([x0,y0,z0,r], 'nTheta', 16, 'nPhi', 16);

%define sensor
sensor = ConicalSensor(sensAng, sensorRange);

%define targets
target1 = BodyFixedLatLongGridTargetModel(celBodyData.kerbin, 0, deg2rad(90), 2*pi, deg2rad(-90), 30, 30, 100);

frame = celBodyData.kerbin.getBodyCenteredInertialFrame();
lvdData = LvdData.getDefaultLvdData(celBodyData);
point = FixedPointInFrame([-1000;0;0], frame, 'Point 1', lvdData);
target2 = PointSensorTargetModel(point);

point = FixedPointInFrame([1000;0;0], frame, 'Point 2', lvdData);
target3 = PointSensorTargetModel(point);

targets = [target1, target2, target3];

%Compute results
scElem = CartesianElementSet(0, [x0C;y0C;z0C], [0;0;0], frame);
bodyInfos = [celBodyData.kerbin, celBodyData.mun, celBodyData.minmus];
tt=tic;[results, V3, F3] = sensor.evaluateSensorTargets(targets, scElem, bodyInfos, frame);toc(tt);
[bool, sVPts] = getTargetResultsInFrame(results, frame);

%% Plotting
hAx = axes(figure());
hold on;
drawMesh(hAx, sV, sF, 'FaceAlpha',1.0,'LineStyle','none');
% drawMesh(hAx, Vobs, Fobs, 'FaceAlpha',1.0, 'FaceColor','b');
drawMesh(hAx, V3, F3, 'FaceColor','g','FaceAlpha',0.3, 'LineStyle','none');
% plot3(hAx, V3(:,1), V3(:,2), V3(:,3),'b.');
plot3(hAx, scOrigin(1), scOrigin(2), scOrigin(3), 'd', 'MarkerFaceColor','k', 'MarkerEdgeColor','r');
plot3(hAx, sVPts(bool,1), sVPts(bool,2), sVPts(bool,3), 'o', 'MarkerFaceColor','g', 'MarkerEdgeColor','k', 'MarkerSize',3);
plot3(hAx, sVPts(~bool,1), sVPts(~bool,2), sVPts(~bool,3), 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k', 'MarkerSize',3);
grid(hAx, 'minor');
axis(hAx, 'equal');
% camproj(hAx, 'perspective')
% campos(hAx,[x0C, y0C, z0C])
hold off;

% profile viewer; 
toc(t);