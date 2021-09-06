clc; clear variables; format long g; close all;
% addpath(genpath('C:\Users\Adam\Dropbox\Documents\MATLAB\gptoolbox-master'));

%Initalize KSP celestial body data
[celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
celBodyData = processINIBodyInfo(celBodyDataFromINI, false, 'bodyInfo');
celBodyData = CelestialBodyData(celBodyData);

tic;
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
hC = 5000;

%occulding cylinder
v = [x0 - x0C, y0 - y0C, z0 - z0C];
v = v / norm(v);
v = 2*hC*v;

%Compute Occluding Mesh
[sV, sF] = sphereMesh([x0,y0,z0,r], 'nTheta', 16, 'nPhi', 16);
[sVPts, sFPTs] = sphereMesh([x0,y0,z0,r+0.001*r], 'nTheta', 30, 'nPhi', 30);
% [cV, cF] = cylinderMesh([x0 y0 z0, x0+v(1), y0+v(2), z0+v(3), r]);
% [sV2, sF2] = sphereMesh([x0+v(1), y0+v(2), z0+v(3),r]);
% [V,~] = concatenateMeshes(sV,sF,cV,cF);
% F = convhull(V);

%Compute Rays
numAngles = 50;
numIntAngles = 2;

scOrigin = [x0C, y0C, z0C]';
sensAng = deg2rad(10);
sensorRange = hC;

% boreDir = [x0 - x0C, y0 - y0C, z0 - z0C + 500]';
% boreDir = boreDir / norm(boreDir);
% borePlaneV0 = [0;1;0];
% borePlaneV1 = cross(boreDir,borePlaneV0);
% borePlaneV2 = cross(boreDir,borePlaneV1);
% 
% theta = linspace(0,2*pi,numAngles);
% sensorOutlineCenter = scOrigin + sensorRange*boreDir;
% sensAngPlusIteriorAngles = linspace(0,sensAng,numIntAngles);
% r = sensorRange*(sin(sensAngPlusIteriorAngles) ./ sin(pi/2 - sensAngPlusIteriorAngles));
% 
% sensorOutlinePtsRaw = [];
% for(i=1:length(r))
%     sensorOutlinePtsRaw = [sensorOutlinePtsRaw, sensorOutlineCenter + r(i)*borePlaneV1*cos(theta) + r(i)*borePlaneV2*sin(theta)]; %#ok<AGROW>
% end

% V2 = vertcat(scOrigin', sensorOutlinePtsRaw');
% F2 = convhull(V2);

% [V3,F3] = mesh_boolean(V2,F2,V,F,'minus');
% MESHES = splitMesh(V3, F3);

% if(length(MESHES) > 1)
%     for(i=1:length(MESHES))
%         mesh = MESHES(i);
%         centroid = mean(MESHES(i).vertices,1);
%         dist(i) = norm(centroid - scOrigin); %#ok<SAGROW>
%     end
% 
%     [~,meshInd] = min(dist);
%     coneMesh = MESHES(meshInd);
% else
%     coneMesh = MESHES;
% end
% [V3,F3] = meshVertexClustering(coneMesh,0.1);

sensor = ConicalSensor(sensAng, sensorRange);
frame = celBodyData.kerbin.getBodyCenteredInertialFrame();
scElem = CartesianElementSet(0, [x0C;y0C;z0C], [0;0;0], frame);
bodyInfos = [celBodyData.kerbin, celBodyData.mun, celBodyData.minmus];
tic;[V3,F3, Vobs,Fobs] = sensor.getObscuredSensorMesh(scElem, bodyInfos, frame);toc;
% toc;

bool = isPointInMesh(sVPts, V3, F3);
% toc;

hAx = axes(figure());
hold on;
drawMesh(hAx, sV, sF, 'FaceAlpha',1.0,'LineStyle','none');
% drawMesh(hAx, Vobs, Fobs, 'FaceAlpha',1.0, 'FaceColor','b');
drawMesh(hAx, V3, F3, 'FaceColor','g','FaceAlpha',0.3, 'LineStyle','none');
plot3(hAx, V3(:,1), V3(:,2), V3(:,3),'b.');
plot3(hAx, scOrigin(1), scOrigin(2), scOrigin(3), 'd', 'MarkerFaceColor','k', 'MarkerEdgeColor','r');
plot3(hAx, sVPts(bool,1), sVPts(bool,2), sVPts(bool,3), 'g.');
plot3(hAx, sVPts(~bool,1), sVPts(~bool,2), sVPts(~bool,3), 'k.');
grid(hAx, 'minor');
axis(hAx, 'equal');
% camproj(hAx, 'perspective')
% campos(hAx,[x0C, y0C, z0C])
hold off;

% profile viewer; 
% toc;