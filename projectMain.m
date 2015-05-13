clc; clear variables; format long g; close all;

%set pathes if not deployed
if(~isdeployed) 
    addpath(genpath('helper_methods'));
    addpath(genpath('formsGUIs'));
    addpath(genpath('kspTOT_RTS'));
    addpath(genpath('kspTOT_MissionArchitect'));
    addpath('zArchive');
end

%display splashscreen
hS = splashScreenGUI(); drawnow;
t = tic;

%Initalize KSP celestial body data
[celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
celBodyData = processINIBodyInfo(celBodyDataFromINI);
bodyNames = fieldnames(celBodyData);

while(toc(t) < 2)
    pause(0.1);
end

%Set up the GUI for use
mainGUIHandle = mainGUI(celBodyData, bodyNames, hS);
close(hS);