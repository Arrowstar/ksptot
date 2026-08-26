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

    % Prioritize NOMAD v4.6 over older versions (v4.4, v3.9) to ensure new MEX is used.
    % Both win64 and linux contain nomadOpt MEX with same name but different NOMAD_ versions;
    % Windows must load the DLLs from the same folder as the MEX, so the MEX's folder must be first.
    % This also fixes DLL hell where v4.4 and v4.6 have same DLL names (nomadAlgos.dll etc.).
    try
        v46Win = fullfile(root, 'helper_methods','math','nomad','v4.6','win64');
        v46Lin = fullfile(root, 'helper_methods','math','nomad','v4.6','linux');
        if ispc && isfolder(v46Win)
            addpath(v46Win, '-begin');
            % Also ensure old versions are after, not before
            v44 = fullfile(root, 'helper_methods','math','nomad','v4.4');
            if isfolder(v44)
                rmpath(genpath(v44));
                addpath(genpath(v44), '-end');
            end
        elseif isunix && isfolder(v46Lin)
            addpath(v46Lin, '-begin');
            v44 = fullfile(root, 'helper_methods','math','nomad','v4.4');
            if isfolder(v44)
                rmpath(genpath(v44));
                addpath(genpath(v44), '-end');
            end
        elseif isfolder(v46Win)
            addpath(v46Win, '-begin');
        elseif isfolder(v46Lin)
            addpath(v46Lin, '-begin');
        end
    catch
        % Non-critical; tests will catch if prioritization fails
    end

    alreadyAdded = true;
end
