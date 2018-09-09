clc; format long g; close all;

lv = LaunchVehicle.createDefaultLaunchVehicle();
bodyInfo = celBodyData.kerbin;

initStateLogEntry = LaunchVehicleStateLogEntry.getDefaultStateLogEntryForLaunchVehicle(lv, bodyInfo);

simMaxDur = 20000;
minAltitude = -1;
simDriver = LaunchVehicleSimulationDriver(lv, initStateLogEntry.time, simMaxDur, minAltitude);

profile on;
[t,y,newStateLogEntries] = simDriver.integrateOneEvent(initStateLogEntry);
profile viewer;

hFig = figure(123);
hAxes = axes(hFig);

ma_initOrbPlot(hFig, hAxes, bodyInfo);

hold on;
plot3(y(:,1), y(:,2), y(:,3))

grid on;
axis equal;

xlabel('X');
ylabel('Y');
zlabel('Z');

hold off;

figure(124);
plot(t,y(:,7:end))
grid on;
