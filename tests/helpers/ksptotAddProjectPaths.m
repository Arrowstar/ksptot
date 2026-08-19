function ksptotAddProjectPaths()
% ksptotAddProjectPaths Adds the KSPTOT source folders to the MATLAB path.
%
% Deliberately uses addpath() rather than restoredefaultpath() so that
% tooling already on the path (test runners, MCP helpers, etc.) survives.

    persistent alreadyAdded
    if(~isempty(alreadyAdded) && alreadyAdded)
        return;
    end

    root = ksptotTestRoot();

    srcFolders = {'helper_methods', 'formsGUIs', 'kspTOT_RTS', ...
                  'kspTOT_MissionArchitect', 'kspTOT_LaunchVehicleDesigner', ...
                  'kspTOT_VehicleSizer', 'kspTOT_SingleUIs', 'images', ...
                  'kos_scripts'};

    for(i = 1:numel(srcFolders)) %#ok<*NO4LP>
        thisFolder = fullfile(root, srcFolders{i});
        if(isfolder(thisFolder))
            addpath(genpath(thisFolder));
        end
    end

    addpath(genpath(fullfile(root, 'tests')));

    alreadyAdded = true;
end
