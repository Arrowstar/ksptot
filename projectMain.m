clc; clear variables; format long g; close all;

%Include matlabrc, hopefully
%#function matlabrc

%set pathes if not deployed
if(~isdeployed) 
    addpath(genpath('helper_methods'));
    addpath(genpath('formsGUIs'));
    addpath(genpath('kspTOT_RTS'));
    addpath(genpath('kspTOT_MissionArchitect'));
    addpath(genpath('kspTOT_LaunchVehicleDesigner'));
    addpath(genpath('kspTOT_VehicleSizer'));
    addpath(genpath('kspTOT_SingleUIs'));
    addpath(genpath('images'));
    addpath(genpath('kos_scripts'));
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

%Turn off class destructor warnings.  These pop up a lot for App Designer
%UIs when closing while using uiwait().
warning('off','MATLAB:class:DestructorError');

%Turn off java component being removed warnings.  User doesn't need to see
%that and I already know.
warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved');

%Turn off warning for up axis when rotating camera.
warning('off','MATLAB:Axes:UpVector');

%Turn off warning for recursive close
warning('off','MATLAB:Figure:RecursionOnClose');

%Populate initial ksptot log file
writeKsptotLogFileHeaderToConsole();

%display splashscreen
hS = splashScreenGUI_App(); drawnow;
t = tic;

%Initialize KSPTOT options
appOptions = getAppOptionsFromFile();

%Initalize KSP celestial body data
if(isprop(appOptions.ksptot,'bodiesinifile') && ~isempty(appOptions.ksptot.bodiesinifile) && exist(appOptions.ksptot.bodiesinifile,'file'))
    [celBodyDataFromINI,~,~] = inifile(appOptions.ksptot.bodiesinifile,'readall');
else
    [celBodyDataFromINI,~,~] = inifile('bodies.ini','readall');
end
celBodyData = processINIBodyInfo(celBodyDataFromINI, false, 'bodyInfo');
celBodyData = CelestialBodyData(celBodyData);
[goodTF, celBodyWarnMsgs] = verifyCelBodyData(celBodyData);  
bodyNames = fieldnames(celBodyData);

if(not(goodTF))
    msg = {sprintf('Potential issues were found with the loaded celestial body information: \n')};
    for(i=1:length(celBodyWarnMsgs)) %#ok<*NO4LP> 
        msg{end+1} = sprintf('\t%s\n', celBodyWarnMsgs{i}); %#ok<SAGROW>
    end
    
    msgbox(msg,'Celestial Body Data Warnings','warn');
end

%Pause for some time to show the splash screen
while(toc(t) < 1)
    pause(0.1);
end

%Set up the GUI for use
% mainGUIHandle = mainGUI(celBodyData, bodyNames, hS, appOptions);
mainGUIHandle = mainGUI_App(celBodyData, bodyNames, hS, appOptions);
if(isvalid(hS))
    delete(hS);
end