clc; clear variables; format long g; close all;

%Initalize KSP celestial body data
[celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
celBodyData = processINIBodyInfo(celBodyDataFromINI, false, 'bodyInfo');
celBodyData = CelestialBodyData(celBodyData);

lvdData = LvdData.getDefaultLvdData(celBodyData);

% profile off; profile on;

%planet sphere
bodyInfo = celBodyData.kerbin;
frame = bodyInfo.getBodyCenteredInertialFrame();
state = convertToFrame(bodyInfo.getElementSetsForTimes(0), frame);

x0 = state.rVect(1);
y0 = state.rVect(2);
z0 = state.rVect(3);
r = bodyInfo.radius;

%sensor cone
sensorOriginRVect = [-2000;0;0];
sensorOriginPt = FixedPointInFrame(sensorOriginRVect, frame, 'Sensor Origin', lvdData);
lvdData.geometry.points.addPoint(sensorOriginPt);

steeringCoordSys = ParallelToFrameCoordSystem(frame, 'Kerbin Inertial', lvdData);
lvdData.geometry.coordSyses.addCoordSys(steeringCoordSys);
steeringModel = FixedInCoordSysSensorSteeringModel(deg2rad(0), deg2rad(0), deg2rad(10), steeringCoordSys, lvdData);

sensorRange = 3000;
sensAzAng = deg2rad(90);
sensElAng = deg2rad(45);

sensor = ConicalSensor('Demo Conical Sensor', sensAzAng, sensorRange, sensorOriginPt, steeringModel, lvdData);
sensorState = sensor.getInitialState();

%Compute Occluding Mesh
[sV, sF] = sphereMesh([x0,y0,z0,r], 'nTheta', 16, 'nPhi', 16);

%define targets
target1 = BodyFixedLatLongGridTargetModel('Test 1', celBodyData.kerbin, deg2rad(-180), deg2rad(90), deg2rad(180), deg2rad(-90), 10, 10, 1, lvdData);

frame = celBodyData.kerbin.getBodyCenteredInertialFrame();
point = FixedPointInFrame([-1000;0;0], frame, 'Point 1', lvdData);
target2 = PointSensorTargetModel('Test 2', point, lvdData);

point = FixedPointInFrame([1000;0;0], frame, 'Point 2', lvdData);
target3 = PointSensorTargetModel('Test 3', point, lvdData);

target4 = BodyFixedCircleGridTargetModel('Test 4', celBodyData.kerbin, deg2rad(90), deg2rad(-10), deg2rad(30), deg2rad(270), deg2rad(30), 10, 10, 1, lvdData);

targets = [target1, target2, target3, target4];

%Compute results
scElem = CartesianElementSet(0, sensorOriginRVect, [0;0;0], frame);
bodyInfos = [celBodyData.kerbin, celBodyData.mun, celBodyData.minmus];
tt=tic;[results, V3, F3] = sensor.evaluateSensorTargets(sensorState, targets, scElem, eye(3), bodyInfos, frame);toc(tt);
[bool, sVPts] = getTargetResultsInFrame(results, frame);

%% Plotting
hAx = axes(figure());
hold on;
drawMesh(hAx, sV, sF, 'FaceAlpha',1.0,'LineStyle','-');
% drawMesh(hAx, Vobs, Fobs, 'FaceAlpha',1.0, 'FaceColor','b');
drawMesh(hAx, V3, F3, 'FaceColor','g','FaceAlpha',0.3, 'LineStyle','-', 'EdgeAlpha',0.3);
% plot3(hAx, V3(:,1), V3(:,2), V3(:,3),'b.');
plot3(hAx, sensorOriginRVect(1), sensorOriginRVect(2), sensorOriginRVect(3), 'd', 'MarkerFaceColor','k', 'MarkerEdgeColor','r');
plot3(hAx, sVPts(bool,1), sVPts(bool,2), sVPts(bool,3), 'o', 'MarkerFaceColor','g', 'MarkerEdgeColor','k', 'MarkerSize',3);
plot3(hAx, sVPts(~bool,1), sVPts(~bool,2), sVPts(~bool,3), 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k', 'MarkerSize',3);
grid(hAx, 'minor');
axis(hAx, 'equal');
axis(hAx, 'tight');
% camproj(hAx, 'perspective')
% campos(hAx,sensorOriginRVect)
hold off;

% profile viewer; 
% disp(getCoverageFraction(results));