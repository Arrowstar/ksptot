if(~isdeployed)
    clc;  clear variables; format long g;  close all;
end

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
    % Prioritize NOMAD v4.6 (see tests/helpers/ksptotAddProjectPaths.m:29 for rationale)
    try
        if ispc && isfolder('helper_methods/math/nomad/v4.6/win64')
            addpath('helper_methods/math/nomad/v4.6/win64', '-begin');
        elseif isunix && isfolder('helper_methods/math/nomad/v4.6/linux')
            addpath('helper_methods/math/nomad/v4.6/linux', '-begin');
        end
    catch
    end
end

% %set look and feel if deployed
% if(isdeployed)
%     if(ispc)
%         javax.swing.UIManager.setLookAndFeel(com.sun.java.swing.plaf.windows.WindowsLookAndFeel);
%     elseif(isunix)
%         javax.swing.UIManager.setLookAndFeel(com.jgoodies.looks.plastic.Plastic3DLookAndFeel);
%     elseif(ismac)
%         javax.swing.UIManager.setLookAndFeel(com.apple.laf.AquaLookAndFeel);
%     end
% end

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

%Turn off warning for "unable to save App Designer object"
warning('off','MATLAB:appdesigner:appdesigner:SaveObjWarning');

%Turn off warning for "tcpip" class going to be removed.
warning('off','instrument:tcpip:ClassToBeRemoved');

%Populate initial ksptot log file
writeKsptotLogFileHeaderToConsole();

%display splashscreen
hS = splashScreenGUI_App(); 
drawnow;
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

%Initialize KSPTOT time system
global ksptot_TimeSystem options_UseEarthTimeSystem; %#ok<GVMIS>
ksptot_TimeSystem = getTimeSystemFromConfig(appOptions, celBodyDataFromINI);
options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system,'earth_stock');

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
newMainGUI_App(celBodyData);

if(isvalid(hS))
    delete(hS);
end