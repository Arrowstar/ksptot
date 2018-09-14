clc; format long g; close all;

%Set Up Data
lvdData = LvdData.getDefaultLvdData(celBodyData);

%Execute Script
% profile on -history;
tic;
lvdData.script.executeScript();
toc;
% profile viewer;

%%Plotting 
bodyInfo = celBodyData.kerbin;
matStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();

hFig = figure(123);
hAxes = axes(hFig);

ma_initOrbPlot(hFig, hAxes, bodyInfo);

hold on;
plot3(matStateLog(:,2), matStateLog(:,3), matStateLog(:,4))

grid on;
axis equal;

xlabel('X');
ylabel('Y');
zlabel('Z');

hold off;

figure(124);
plot(matStateLog(:,1),sum(matStateLog(:,9:12), 2))
grid on;

figure(125);
pos = matStateLog(:,2:4);
radius = sqrt(sum(pos.^2,2));
altitude = radius - bodyInfo.radius;
plot(matStateLog(:,1),altitude);
grid on;

figure(126);
pitchAngles = NaN(length(lvdData.stateLog.entries),1);
for(i=1:length(lvdData.stateLog.entries)) %#ok<*NO4LP>
    dcm = lvdData.stateLog.entries(i).attitude.dcm;
    rVect = lvdData.stateLog.entries(i).position;
    vVect = lvdData.stateLog.entries(i).velocity;
    [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(rVect, vVect, dcm(:,1), dcm(:,2), dcm(:,3));
    
    pitchAngles(i) = rad2deg(pitchAngle);
end
plot(matStateLog(:,1),pitchAngles);
grid on;