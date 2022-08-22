clc; clear variables; format long g; close all;

%Include matlabrc, hopefully
%#function matlabrc

%set pathes if not deployed
if(~isdeployed) 
    addpath(genpath('helper_methods'));
    addpath(genpath('formsGUIs'));
    addpath(genpath('kspTOT_RTS'));
    addpath(genpath('kspTOT_MissionArchitect'));
%     addpath('zArchive');
end

%set look and feel if deployed
if(isdeployed)
    if(ispc)
        javax.swing.UIManager.setLookAndFeel(com.sun.java.swing.plaf.windows.WindowsLookAndFeel);
    elseif(isunix)
        javax.swing.UIManager.setLookAndFeel(com.jgoodies.looks.plastic.Plastic3DLookAndFeel);
    elseif(ismac)
        javax.swing.UIManager.setLookAndFeel(com.apple.laf.AquaLookAndFeel);
    end
end

doesAppOptionsFileExist = exist('appOptions.ini','file');
if(doesAppOptionsFileExist)
    [appOptionsFromINI,~,~] = inifile('appOptions.ini','readall');
    appOptionsFromINI = addMissingAppOptionsRows(appOptionsFromINI);
else
    appOptionsFromINI = createDefaultKsptotOptions();
    inifile('appOptions.ini','write',appOptionsFromINI);
end
appOptions = processINIBodyInfo(appOptionsFromINI, false, 'appOptions'); %turns out this function works for other ini files too lol!

%Initalize celestial body data
if(isprop(appOptions.ksptot,'bodiesinifile') && ~isempty(appOptions.ksptot.bodiesinifile) && exist(appOptions.ksptot.bodiesinifile,'file'))
    [celBodyDataFromINI,~,~] = inifile(appOptions.ksptot.bodiesinifile,'readall');
else
    [celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
end
celBodyData = processINIBodyInfo(celBodyDataFromINI, false, 'bodyInfo');

multiFlyByManeuverSequencer(celBodyData);