function lvdData = lvd_importCraft(lvdData, craftPath, partDBPath)
%lvd_importCraft Imports a KSP .craft file into LVD case data (console
%entry point).
%
%   lvdData = lvd_importCraft(lvdData, craftPath)
%   lvdData = lvd_importCraft(lvdData, craftPath, partDBPath)
%
%   Analyzes the craft file against the bundled mini stock-parts database
%   (or the database at PARTDBPATH), builds a LaunchVehicle, installs it
%   into LVDDATA, regenerates initial states, and prints the resulting
%   vehicle summary. For an interactive review first, use
%   lvd_ImportCraftGUI_App.launch(lvdData) instead.
%
%   Warnings from the analysis stage are printed to the command window.

    if(nargin < 3)
        partDBPath = '';
    end

    partDB = lvd_import_getPartDatabase(partDBPath);

    [spec, ~] = lvd_import_analyzeCraft(craftPath, partDB);

    for(i = 1:numel(spec.warnings))
        fprintf('Warning: %s\n', spec.warnings{i});
    end

    newLv = lvd_import_createLaunchVehicle(lvdData, spec);
    lvdData = lvd_import_applyToLvdData(lvdData, newLv);

    fprintf('Imported "%s": %d stage(s), %d engine(s), %d tank(s), GLOW = %.3f mT.\n', ...
        spec.name, spec.stats.numStages, spec.stats.numEngines, ...
        spec.stats.numTanks, spec.stats.glow_mT);

    disp(newLv.getLvSummaryStr());

end
