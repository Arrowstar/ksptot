function tf = lvd_import_isLocalizationCfg(cfgPath)
%lvd_import_isLocalizationCfg True for KSP localization dictionary files.
%
%   Dictionaries live in a folder named "Localization" (Squad and most
%   mods) or are named after a language tag / "dictionary". They contain no
%   PART definitions, so the part scanner skips them.

    tf = false;

    [folder, baseName, ext] = fileparts(cfgPath);
    if(~strcmpi(ext, '.cfg'))
        return;
    end

    [~, leafFolder] = fileparts(folder);
    if(strcmpi(leafFolder, 'Localization'))
        tf = true;
        return;
    end

    if(any(strcmpi(baseName, {'dictionary', 'localization'})))
        tf = true;
        return;
    end

    % Language-tag file names such as en-us.cfg / en_us.cfg.
    if(~isempty(regexpi(baseName, '^[a-z]{2}[-_][a-z]{2}$', 'once')))
        tf = true;
    end

end
