clc; clear all; format long g; close all;

addpath(genpath('examples'));
addpath(genpath('helper_methods'));
addpath(genpath('formsGUIs'));
addpath(genpath('kspTOT_RTS'));
addpath(genpath('kspTOT_MissionArchitect'));
addpath(genpath('kspTOT_LaunchVehicleDesigner'));
addpath(genpath('kspTOT_VehicleSizer'));
addpath(genpath('kspTOT_SingleUIs'));
addpath(genpath('images'));
addpath(genpath('kos_scripts'));

%%
% load('C:\Users\Adam\Desktop\JoolTourLVD2.mat')
load('lvdExample_TwoStageToOrbit.mat');

%%
for(i=1:length(lvdData.script.evts))
    lvdData.script.evts(i).integratorObj.options.AbsTol = 1E-6;
    lvdData.script.evts(i).integratorObj.options.RelTol = 1E-6;
end

%%
tic; 
profile off; profile on;
for(i=1:15) %#ok<*NO4LP> 
stateLog = lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false); 
end
profile viewer;
toc;