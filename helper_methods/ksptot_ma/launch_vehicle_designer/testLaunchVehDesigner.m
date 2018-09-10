clc; format long g; close all;

%%Set Up Launch Vehicle and Sim Driver
lv = LaunchVehicle.createDefaultLaunchVehicle();
bodyInfo = celBodyData.kerbin;

initStateLogEntry = LaunchVehicleStateLogEntry.getDefaultStateLogEntryForLaunchVehicle(lv, bodyInfo);
initStateLogEntry.stageStates(3).engineStates(1).active = true; %Turn on the first stage engine
initStateLogEntry.stageStates(2).engineStates(1).active = false; %Turn off the second stage engine

simMaxDur = 20000;
minAltitude = -1;
simDriver = LaunchVehicleSimulationDriver(lv, initStateLogEntry.time, simMaxDur, minAltitude, celBodyData);

%%Set Up Mission Script
script = LaunchVehicleScript();

%Event 1
evt1 = LaunchVehicleEvent(script);
evt1.name = 'Propagate 5 seconds';
evt1.termCond = EventDurationTermCondition(5);
script.addEvent(evt1);

%Event 2
evt2 = LaunchVehicleEvent(script);
evt2.name = 'Propagate to Stage One Burnout';

evt2TcTank = lv.stages(3).tanks(1);
evt2.termCond = TankMassTermCondition(evt2TcTank,0);

evt2Action1 = SetStageActiveStateAction(lv.stages(3), false);
evt2.addAction(evt2Action1);

evt2Action2Eng = lv.stages(2).engines(1);
evt2Action2 = SetEngineActiveStateAction(evt2Action2Eng, true);
evt2.addAction(evt2Action2);

script.addEvent(evt2);

%Event 3
evt3 = LaunchVehicleEvent(script);
evt3.name = 'Propagate to Stage Two Burnout';

evt3TcTank = lv.stages(2).tanks(1);
evt3.termCond = TankMassTermCondition(evt3TcTank,0);

evt3Action1 = SetStageActiveStateAction(lv.stages(2), false);
evt3.addAction(evt3Action1);

script.addEvent(evt3);

%Event 4
evt4 = LaunchVehicleEvent(script);
evt4.name = 'Propagate 1000 seconds';
evt4.termCond = EventDurationTermCondition(1000);
script.addEvent(evt4);

%Execute Script
% profile on;
stateLog = LaunchVehicleStateLog();
script.executeScript(initStateLogEntry, simDriver, stateLog);
matStateLog = stateLog.getMAFormattedStateLogMatrix();
% profile viewer;

%%Plotting 
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
plot(matStateLog(:,1),sum(matStateLog(:,9:12), 2))
grid on;
