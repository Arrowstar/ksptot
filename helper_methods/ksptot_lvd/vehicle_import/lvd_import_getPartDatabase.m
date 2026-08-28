function [partDB, warnings] = lvd_import_getPartDatabase(source)
%lvd_import_getPartDatabase Loads a part database for craft-file import.
%
%   partDB = lvd_import_getPartDatabase() loads the bundled mini stock
%   parts database shipped with KSPTOT (no KSP installation required).
%
%   partDB = lvd_import_getPartDatabase(source) loads from:
%       - char path to a .json/.mat database file, a single .cfg part
%         file, or a GameData/KSP root folder (recursively scans
%         GameData/**/*.cfg via sfsParse)
%       - struct with optional fields:
%           .filePath      - path to a database file (as above)
%           .kspRoot       - KSP install root (expects GameData inside)
%           .gameDataPath  - direct GameData folder path
%           .language      - localization tag for part titles ('en-us')
%
%   When scanning GameData, part titles given as localization tags
%   (title = #autoLOC_500439) are resolved against the KSP localization
%   dictionaries under GameData/**/Localization/*.cfg, falling back to the
%   "//#autoLOC_500439 = ..." comment KSP writes beside the tag, and
%   finally to the internal part name.
%
%   The returned PARTDB struct contains:
%       .schemaVersion  - database schema version (1)
%       .databaseName   - descriptive name
%       .sourcePath     - where the data came from ('' for bundled)
%       .parts          - containers.Map keyed by lower-cased part name;
%                         each value is a struct with fields:
%           .name        - canonical part name
%           .title       - human-readable title
%           .mass_t      - dry mass in metric tons
%           .roles       - cellstr of roles (engine, tank, decoupler,
%                          radialDecoupler, fuelLine, pod, rcs, parachute,
%                          antenna, fin, noseCone, utility)
%           .resources_u - struct of resource name -> units stored
%           .engines     - struct array with fields maxThrust_kN, ispVac_s,
%                          ispSL_s, minThrottle, maxThrottle, propellants
%
%   [partDB, warnings] = ... also returns cellstr of non-fatal loading
%   issues (e.g., malformed entries that were skipped).

    warnings = {};

    if(nargin < 1)
        source = '';
    end

    language = 'en-us';

    if(isstruct(source))
        filePath = getFieldOrDefault(source, 'filePath', '');
        kspRoot = getFieldOrDefault(source, 'kspRoot', '');
        gameDataPath = getFieldOrDefault(source, 'gameDataPath', '');
        language = getFieldOrDefault(source, 'language', language);

        if(~isempty(gameDataPath) && isfolder(gameDataPath))
            [partDB, loadWarnings] = loadGameDataDatabase(gameDataPath, language);
            warnings = [warnings, loadWarnings]; %#ok<AGROW>
            return;
        end

        if(~isempty(kspRoot))
            candidate = kspRoot;
            if(isfolder(fullfile(kspRoot, 'GameData')))
                candidate = fullfile(kspRoot, 'GameData');
            end
            if(isfolder(candidate))
                [partDB, loadWarnings] = loadGameDataDatabase(candidate, language);
                warnings = [warnings, loadWarnings]; %#ok<AGROW>
                return;
            end
        end

        if(~isempty(kspRoot) && isempty(filePath))
            error('lvd_import:gameDataNotSupported', ...
                ['GameData folder not found under KSP root (%s). ' ...
                 'Provide a .json/.mat database or a valid GameData path.'], ...
                kspRoot);
        end

        source = filePath;
    end

    if(isempty(source))
        [partDB, loadWarnings] = loadBundledDatabase();
        warnings = [warnings, loadWarnings]; %#ok<AGROW>
        return;
    end

    if(~ischar(source))
        error('lvd_import:invalidSource', ...
            'source must be omitted, a file path char, or an options struct.');
    end

    if(isfolder(source))
        gameDataPath = source;
        if(isfolder(fullfile(source, 'GameData')))
            gameDataPath = fullfile(source, 'GameData');
        end
        [partDB, loadWarnings] = loadGameDataDatabase(gameDataPath, language);
        warnings = [warnings, loadWarnings]; %#ok<AGROW>
        return;
    end

    if(~isfile(source))
        error('lvd_import:fileNotFound', 'Part database file not found: %s', source);
    end

    [~,~,ext] = fileparts(source);
    switch(lower(ext))
        case '.json'
            [partDB, loadWarnings] = loadJsonDatabase(source);
        case '.mat'
            [partDB, loadWarnings] = loadMatDatabase(source);
        case '.cfg'
            [partDB, loadWarnings] = loadSingleCfgDatabase(source);
        otherwise
            error('lvd_import:unsupportedExtension', ...
                'Unsupported part database extension "%s" (use .json, .mat, or .cfg).', ext);
    end

    warnings = [warnings, loadWarnings]; %#ok<AGROW>

end

function [partDB, warnings] = loadBundledDatabase()
    % Robust lookup that survives MATLAB Compiler deployment (ctfroot)
    dbPath = getBundledDbPath();
    [partDB, warnings] = loadJsonDatabase(dbPath);

end

function dbPath = getBundledDbPath()
%getBundledDbPath Returns the full path to the bundled stock database,
% handling both development and deployed (isdeployed/ctfroot) layouts.

    baseName = 'partsDatabaseStockKSP.json';

    % 1) Alongside this m-file (development layout)
    cand1 = fullfile(fileparts(mfilename('fullpath')), 'resources', baseName);
    if(isfile(cand1))
        dbPath = cand1;
        return;
    end

    % 2) Deployed CTF layout
    if(isdeployed)
        cand2 = fullfile(ctfroot, 'helper_methods', 'ksptot_lvd', 'vehicle_import', 'resources', baseName);
        if(isfile(cand2))
            dbPath = cand2;
            return;
        end
    end

    % 3) Search on MATLAB path (additional files)
    cand3 = which(baseName);
    if(~isempty(cand3) && isfile(cand3))
        dbPath = cand3;
        return;
    end

    % Fallback to cand1 (will error with file-not-found downstream if missing)
    dbPath = cand1;

end

function [partDB, warnings] = loadJsonDatabase(filePath)
    warnings = {};

    raw = fileread(filePath);
    decoded = jsondecode(raw);

    schemaVersion = getFieldOrDefault(decoded, 'schemaVersion', 0);
    if(schemaVersion ~= 1)
        warning('lvd_import:schemaVersion', ...
            'Unexpected part DB schema version %d in %s (expected 1).', ...
            schemaVersion, filePath);
    end

    densities = lvd_import_resourceDensities();

    partsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    rawParts = [];
    if(isfield(decoded, 'parts'))
        rawParts = decoded.parts;
    else
        warnings{end+1} = 'Database contains no "parts" array.'; %#ok<AGROW>
    end

    if(isstruct(rawParts))
        for(i = 1:numel(rawParts))
            [entry, entryWarnings] = normalizePartEntry(rawParts(i), densities);
            warnings = [warnings, entryWarnings]; %#ok<AGROW>

            if(~isempty(entry))
                key = lower(entry.name);
                if(isKey(partsMap, key))
                    warnings{end+1} = sprintf( ...
                        'Duplicate part name "%s"; keeping first occurrence.', ...
                        entry.name); %#ok<AGROW>
                else
                    partsMap(key) = entry;
                end
            end
        end
    end

    partDB = struct();
    partDB.schemaVersion = schemaVersion;
    partDB.databaseName = getFieldOrDefault(decoded, 'databaseName', '');
    partDB.sourcePath = filePath;
    partDB.resourceDensities = densities;
    partDB.parts = partsMap;

end

function [partDB, warnings] = loadMatDatabase(filePath) %#ok<STIN>
    loaded = load(filePath);

    candidate = [];
    fieldNames = fieldnames(loaded);
    for(i = 1:numel(fieldNames))
        val = loaded.(fieldNames{i});
        if(isstruct(val) && isfield(val, 'parts') && isa(val.parts, 'containers.Map'))
            candidate = val;
            break;
        end
    end

    if(isempty(candidate))
        error('lvd_import:badMatDatabase', ...
            '%s does not contain a saved part database struct.', filePath);
    end

    partDB = candidate;
    partDB.sourcePath = filePath;

    if(~isfield(partDB, 'resourceDensities'))
        partDB.resourceDensities = lvd_import_resourceDensities();
    end

    warnings = {};

end

function [entry, warnings] = normalizePartEntry(rawPart, densities)
%normalizePartEntry Validates and coerces one decoded JSON part object.
% Returns empty entry when the part is unusable.

    warnings = {};
    entry = [];

    name = getFieldOrDefault(rawPart, 'name', '');
    if(isempty(name))
        warnings{end+1} = 'Skipping part entry missing "name".'; %#ok<AGROW>
        return;
    end

    massT = getFieldOrDefault(rawPart, 'mass_t', NaN);
    if(~isscalar(massT) || ~isfinite(massT) || massT < 0)
        warnings{end+1} = sprintf( ...
            'Part "%s" has invalid mass_t; defaulting to 0.', name); %#ok<AGROW>
        massT = 0;
    end

    roles = getFieldOrDefault(rawPart, 'roles', {});
    if(ischar(roles))
        roles = {roles};
    elseif(~iscellstr(roles))
        roles = {};
    end

    resourcesU = getFieldOrDefault(rawPart, 'resources_u', struct());
    if(~isstruct(resourcesU))
        resourcesU = struct();
    end
    resourcesU = coerceResourcesStruct(resourcesU, name, densities, warnings);

    engines = parseEngineEntries(rawPart, name, warnings);

    entry = struct();
    entry.name = name;
    entry.title = getFieldOrDefault(rawPart, 'title', name);
    entry.mass_t = massT;
    entry.roles = roles;
    entry.resources_u = resourcesU;
    entry.engines = engines;

end

function engines = parseEngineEntries(rawPart, partName, warnings)
%parseEngineEntries Extracts and validates the engines struct array.

    enginesRaw = getFieldOrDefault(rawPart, 'engines', []);
    engines = struct.empty(0, 0);

    if(isempty(enginesRaw))
        return;
    end

    if(isstruct(enginesRaw) && numel(enginesRaw) == 1 && ~isfield(enginesRaw, 'maxThrust_kN'))
        enginesRaw = struct.empty(0, 0);
    end

    if(~isstruct(enginesRaw))
        warnings{end+1} = sprintf( ...
            'Part "%s" has malformed "engines"; ignoring.', partName); %#ok<AGROW>
        return;
    end

    for(i = 1:numel(enginesRaw))
        eng = enginesRaw(i);

        thrust = getFieldOrDefault(eng, 'maxThrust_kN', NaN);
        ispVac = getFieldOrDefault(eng, 'ispVac_s', NaN);
        ispSL = getFieldOrDefault(eng, 'ispSL_s', 1e-6);

        if(~isscalar(thrust) || ~isfinite(thrust) || thrust <= 0 || ...
           ~isscalar(ispVac) || ~isfinite(ispVac) || ispVac <= 0)
            warnings{end+1} = sprintf( ...
                'Part "%s" engine %d has invalid thrust/Isp; skipping engine.', ...
                partName, i); %#ok<AGROW>
            continue;
        end

        newEng = struct();
        newEng.maxThrust_kN = thrust;
        newEng.ispVac_s = ispVac;
        newEng.ispSL_s = max(ispSL, 1e-6);
        newEng.minThrottle = min(max(getFieldOrDefault(eng, 'minThrottle', 0), 0), 1);
        newEng.maxThrottle = min(max(getFieldOrDefault(eng, 'maxThrottle', 1), 0), 1);
        newEng.propellants = coerceCellStr(getFieldOrDefault(eng, 'propellants', {}));

        if(isempty(engines))
            engines = newEng;
        else
            engines(end+1) = newEng; %#ok<AGROW>
        end
    end

end

function resOut = coerceResourcesStruct(resIn, partName, densities, warnings) %#ok<INUSD>
%coerceResourcesStruct Ensures resource values are finite nonneg doubles.

    resOut = struct();
    fieldNames = fieldnames(resIn);

    for(i = 1:numel(fieldNames))
        val = resIn.(fieldNames{i});
        if(~isscalar(val) || ~isfinite(val) || val < 0)
            warnings{end+1} = sprintf( ...
                'Part "%s" resource "%s" invalid; skipping.', ...
                partName, fieldNames{i}); %#ok<AGROW>
            continue;
        end
        resOut.(fieldNames{i}) = val;
    end

end

function out = coerceCellStr(in)
    if(ischar(in))
        out = {in};
    elseif(iscellstr(in))
        out = in;
    else
        out = {};
    end
end

function [partDB, warnings] = loadGameDataDatabase(gameDataPath, language)
%loadGameDataDatabase Recursively scans GameData/**/*.cfg and builds a part DB.

    warnings = {};

    if(nargin < 2 || isempty(language))
        language = 'en-us';
    end

    if(~isfolder(gameDataPath))
        error('lvd_import:gameDataNotFound', 'GameData folder not found: %s', gameDataPath);
    end

    densities = lvd_import_resourceDensities();
    partsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    cfgFiles = findCfgFilesRecursive(gameDataPath);

    if(isempty(cfgFiles))
        warnings{end+1} = sprintf('No .cfg files found under %s', gameDataPath); %#ok<AGROW>
    end

    % Localization dictionaries hold the human-readable text behind the
    % #autoLOC_* tags that part cfgs use for their titles. They never
    % contain PART nodes, so pull them out of the part scan entirely.
    isLocFile = false(1, numel(cfgFiles));
    for(i = 1:numel(cfgFiles))
        isLocFile(i) = lvd_import_isLocalizationCfg(cfgFiles{i});
    end

    [locMap, locWarnings] = lvd_import_loadLocalization(cfgFiles(isLocFile), language);
    warnings = [warnings, locWarnings]; %#ok<AGROW>

    if(locMap.Count == 0)
        warnings{end+1} = sprintf( ...
            ['No localization dictionary found under %s; part titles will ' ...
             'fall back to inline tag comments or internal part names.'], ...
            gameDataPath); %#ok<AGROW>
    end

    cfgFiles = cfgFiles(~isLocFile);

    for(i = 1:numel(cfgFiles))
        file = cfgFiles{i};
        try
            txt = fileread(file);
            if(isempty(strfind(txt, 'PART')))
                continue;
            end
            inlineMap = harvestInlineLocalization(txt);
            root = sfsParse(txt);
            if(~isfield(root, 'PART'))
                continue;
            end
            for(pIdx = 1:numel(root.PART))
                partNode = root.PART{pIdx};
                [entry, entryWarnings] = buildEntryFromCfgPart(partNode, densities, locMap, inlineMap);
                warnings = [warnings, entryWarnings]; %#ok<AGROW>
                if(isempty(entry))
                    continue;
                end
                key = lower(entry.name);
                if(isKey(partsMap, key))
                    continue;
                else
                    partsMap(key) = entry;
                end
            end
        catch ME
            warnings{end+1} = sprintf('Skipping %s: %s', file, ME.message); %#ok<AGROW>
        end
    end

    if(partsMap.Count == 0)
        warnings{end+1} = 'No PART definitions found — GameData may contain only ModuleManager patches or drag-cube cache.'; %#ok<AGROW>
    end

    % Add dot/underscore aliases so craft files using '.' (liquidEngine3.v2)
    % match GameData entries using '_' (liquidEngine3_v2) and vice versa.
    try
        initialKeys = keys(partsMap);
        for(kk = 1:numel(initialKeys))
            k = initialKeys{kk};
            entry = partsMap(k);
            a1 = strrep(k, '.', '_');
            a2 = strrep(k, '_', '.');
            if(~strcmp(a1, k) && ~isKey(partsMap, a1))
                partsMap(a1) = entry;
            end
            if(~strcmp(a2, k) && ~isKey(partsMap, a2))
                partsMap(a2) = entry;
            end
        end
    catch
    end

    % Merge bundled DB for mod parts not in GameData (e.g., KAL9000)
    try
        bundled = loadBundledDatabase();
        bKeys = keys(bundled.parts);
        for(kk = 1:numel(bKeys))
            bk = bKeys{kk};
            if(~isKey(partsMap, bk))
                partsMap(bk) = bundled.parts(bk);
            end
        end
    catch
    end

    partDB = struct();
    partDB.schemaVersion = 1;
    partDB.databaseName = 'GameData';
    partDB.sourcePath = gameDataPath;
    partDB.resourceDensities = densities;
    partDB.parts = partsMap;

end

function [partDB, warnings] = loadSingleCfgDatabase(cfgPath)
%loadSingleCfgDatabase Parses a single .cfg file (e.g., a part file or PartDatabase.cfg).

    warnings = {};

    try
        txt = fileread(cfgPath);
        root = sfsParse(txt);

        % Detect drag-cube cache (PART with url + DRAG_CUBE, no name/mass)
        hasRealParts = false;
        if(isfield(root, 'PART'))
            for(ii = 1:numel(root.PART))
                if(isfield(root.PART{ii}, 'name'))
                    hasRealParts = true;
                    break;
                end
            end
        end
        if(~hasRealParts && isfield(root, 'PART'))
            warnings{end+1} = sprintf('File %s appears to be a drag-cube cache (no PART name/mass fields) and contains no usable part definitions.', cfgPath); %#ok<AGROW>
        end

        densities = lvd_import_resourceDensities();
        partsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

        % No GameData tree to pull dictionaries from here, so localization
        % tags resolve from the inline "//#autoLOC_x = ..." comments only.
        locMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
        inlineMap = harvestInlineLocalization(txt);

        if(isfield(root, 'PART'))
            for(pIdx = 1:numel(root.PART))
                [entry, entryWarnings] = buildEntryFromCfgPart(root.PART{pIdx}, densities, locMap, inlineMap);
                warnings = [warnings, entryWarnings]; %#ok<AGROW>
                if(isempty(entry))
                    continue;
                end
                key = lower(entry.name);
                if(~isKey(partsMap, key))
                    partsMap(key) = entry;
                end
            end
        end

        partDB = struct();
        partDB.schemaVersion = 1;
        partDB.databaseName = 'SingleCfg';
        partDB.sourcePath = cfgPath;
        partDB.resourceDensities = densities;
        partDB.parts = partsMap;

        if(partsMap.Count == 0)
            warnings{end+1} = sprintf('No usable PART definitions found in %s', cfgPath); %#ok<AGROW>
        end
    catch ME
        error('lvd_import:cfgParseFailed', 'Failed to parse %s: %s', cfgPath, ME.message);
    end

end

function files = findCfgFilesRecursive(root)
%findCfgFilesRecursive Recursively finds all *.cfg files under root.

    files = {};

    entries = dir(root);
    for(i = 1:numel(entries))
        name = entries(i).name;
        if(strcmp(name, '.') || strcmp(name, '..'))
            continue;
        end
        full = fullfile(root, name);
        if(entries(i).isdir)
            sub = findCfgFilesRecursive(full);
            files = [files, sub]; %#ok<AGROW>
        else
            [~,~,ext] = fileparts(name);
            if(strcmpi(ext, '.cfg'))
                files{end+1} = full; %#ok<AGROW>
            end
        end
    end

end

function [entry, warnings] = buildEntryFromCfgPart(partNode, densities, locMap, inlineMap)
%buildEntryFromCfgPart Converts a parsed PART config node into a DB entry.
%
% locMap and inlineMap are optional containers.Map lookups from lower-cased
% localization tag to display text; see resolveLocalizedString.

    warnings = {};
    entry = [];

    if(nargin < 3)
        locMap = [];
    end
    if(nargin < 4)
        inlineMap = [];
    end

    name = getCfgStr(partNode, 'name', '');
    if(isempty(name))
        return;
    end
    if(any(name(1) == ['@','+','!','$','-']) || contains(name, '['))
        return;
    end

    title = resolveLocalizedString(getCfgStr(partNode, 'title', ''), locMap, inlineMap);
    if(isempty(title) || startsWith(title, '#'))
        title = name;
    end

    massStr = getCfgStr(partNode, 'mass', '0');
    mass = str2double(massStr);
    if(isnan(mass) || mass < 0)
        mass = 0;
        warnings{end+1} = sprintf('Part "%s" has invalid mass; defaulting to 0.', name); %#ok<AGROW>
    end

    resources_u = struct();
    if(isfield(partNode, 'RESOURCE'))
        for(rIdx = 1:numel(partNode.RESOURCE))
            resNode = partNode.RESOURCE{rIdx};
            rName = getCfgStr(resNode, 'name', '');
            if(isempty(rName))
                continue;
            end
            maxAmtStr = getCfgStr(resNode, 'maxAmount', '');
            if(isempty(maxAmtStr))
                maxAmtStr = getCfgStr(resNode, 'amount', '0');
            end
            maxAmt = str2double(maxAmtStr);
            if(isnan(maxAmt) || maxAmt < 0)
                continue;
            end
            if(maxAmt > 0)
                resources_u.(rName) = maxAmt;
            end
        end
    end

    roles = {};
    engines = struct.empty(0,0);
    hasEngine = false;

    if(isfield(partNode, 'MODULE'))
        for(mIdx = 1:numel(partNode.MODULE))
            mod = partNode.MODULE{mIdx};
            modName = getCfgStr(mod, 'name', '');
            if(strcmpi(modName, 'ModuleEngines') || strcmpi(modName, 'ModuleEnginesFX'))
                hasEngine = true;
                maxThrust = getCfgNum(mod, 'maxThrust', NaN);
                if(isnan(maxThrust) || maxThrust <= 0)
                    continue;
                end
                ispVac = NaN;
                ispSL = NaN;
                if(isfield(mod, 'atmosphereCurve'))
                    acNode = mod.atmosphereCurve{1};
                    if(isfield(acNode, 'key'))
                        keys = acNode.key;
                        if(ischar(keys))
                            keys = {keys};
                        end
                        for(kIdx = 1:numel(keys))
                            kStr = keys{kIdx};
                            toks = strsplit(strtrim(kStr));
                            if(numel(toks) >= 2)
                                k = str2double(toks{1});
                                isp = str2double(toks{2});
                                if(k == 0)
                                    ispVac = isp;
                                elseif(k == 1)
                                    ispSL = isp;
                                end
                            end
                        end
                    end
                end
                if(isnan(ispVac))
                    continue;
                end
                if(isnan(ispSL))
                    ispSL = ispVac;
                end
                propNames = {};
                if(isfield(mod, 'PROPELLANT'))
                    for(pIdx = 1:numel(mod.PROPELLANT))
                        pNode = mod.PROPELLANT{pIdx};
                        pName = getCfgStr(pNode, 'name', '');
                        if(~isempty(pName))
                            propNames{end+1} = pName; %#ok<AGROW>
                        end
                    end
                end
                if(isempty(propNames))
                    engineType = getCfgStr(mod, 'EngineType', '');
                    if(strcmpi(engineType, 'SolidBooster'))
                        propNames = {'SolidFuel'};
                    elseif(~isempty(engineType))
                        propNames = {engineType};
                    end
                end
                minThrottle = 0;
                maxThrottle = 1;
                throttleLockedStr = getCfgStr(mod, 'throttleLocked', 'False');
                if(strcmpi(throttleLockedStr, 'True'))
                    minThrottle = 1;
                else
                    minThrust = getCfgNum(mod, 'minThrust', 0);
                    if(~isnan(maxThrust) && maxThrust > 0)
                        minThrottle = max(0, min(1, minThrust / maxThrust));
                    end
                end
                newEng = struct('maxThrust_kN', maxThrust, 'ispVac_s', ispVac, 'ispSL_s', ispSL, 'minThrottle', minThrottle, 'maxThrottle', maxThrottle, 'propellants', {propNames});
                if(isempty(engines))
                    engines = newEng;
                else
                    engines(end+1) = newEng; %#ok<AGROW>
                end
                if(~any(strcmpi(roles, 'engine')))
                    roles{end+1} = 'engine'; %#ok<AGROW>
                end
            elseif(strcmpi(modName, 'ModuleDecouple'))
                if(~any(strcmpi(roles, 'decoupler')))
                    roles{end+1} = 'decoupler'; %#ok<AGROW>
                end
            elseif(strcmpi(modName, 'ModuleAnchoredDecoupler'))
                if(~any(strcmpi(roles, 'radialDecoupler')))
                    roles{end+1} = 'radialDecoupler'; %#ok<AGROW>
                end
            elseif(strcmpi(modName, 'ModuleFuelLine'))
                if(~any(strcmpi(roles, 'fuelLine')))
                    roles{end+1} = 'fuelLine'; %#ok<AGROW>
                end
            elseif(strcmpi(modName, 'ModuleParachute'))
                if(~any(strcmpi(roles, 'parachute')))
                    roles{end+1} = 'parachute'; %#ok<AGROW>
                end
            end
        end
    end

    if(contains(lower(name), 'fuelline'))
        if(~any(strcmpi(roles, 'fuelLine')))
            roles{end+1} = 'fuelLine'; %#ok<AGROW>
        end
    end

    hasFuelRes = false;
    resNames = fieldnames(resources_u);
    for(ii = 1:numel(resNames))
        rn = resNames{ii};
        if(any(strcmpi(rn, {'LiquidFuel','Oxidizer','MonoPropellant','XenonGas','SolidFuel'})) && resources_u.(rn) > 0)
            hasFuelRes = true;
            break;
        end
    end

    if(hasFuelRes && ~any(strcmpi(roles, 'tank')) && ~any(strcmpi(roles, 'decoupler')) && ~any(strcmpi(roles, 'radialDecoupler')) && ~any(strcmpi(roles, 'fuelLine')))
        if(hasEngine)
            if(isfield(resources_u, 'SolidFuel'))
                roles{end+1} = 'tank'; %#ok<AGROW>
            end
        else
            roles{end+1} = 'tank'; %#ok<AGROW>
        end
    end

    if(isempty(roles))
        category = getCfgStr(partNode, 'category', '');
        switch lower(category)
            case 'fueltank'
                roles = {'tank'};
            case 'engine'
                roles = {'engine'};
            case 'control'
                roles = {'pod'};
            otherwise
                if(hasFuelRes)
                    roles = {'tank'};
                else
                    roles = {'utility'};
                end
        end
    end

    if(hasEngine && ~any(strcmpi(roles, 'engine')))
        roles{end+1} = 'engine'; %#ok<AGROW>
    end

    roles = unique(lower(roles), 'stable');
    resources_u = coerceResourcesStruct(resources_u, name, densities, warnings);

    entry = struct();
    entry.name = name;
    entry.title = title;
    entry.mass_t = mass;
    entry.roles = roles;
    entry.resources_u = resources_u;
    entry.engines = engines;

end

function out = resolveLocalizedString(raw, locMap, inlineMap)
%resolveLocalizedString Turns a "#autoLOC_500439" tag into display text.
%
% Returns RAW unchanged when it is not a tag or when no lookup has it, so
% callers can still detect an unresolved tag by its leading '#'.

    out = strtrim(raw);
    if(isempty(out) || out(1) ~= '#')
        return;
    end

    % The value is the bare tag; guard against trailing junk after it.
    tag = out;
    sepInd = find(isspace(tag), 1, 'first');
    if(~isempty(sepInd))
        tag = tag(1:sepInd-1);
    end
    tag = lower(tag);

    resolved = '';
    if(isa(locMap, 'containers.Map') && isKey(locMap, tag))
        resolved = locMap(tag);
    elseif(isa(inlineMap, 'containers.Map') && isKey(inlineMap, tag))
        resolved = inlineMap(tag);
    end

    % Titles are shown on one line, so flatten any embedded whitespace.
    resolved = strtrim(regexprep(resolved, '\s+', ' '));

    if(~isempty(resolved) && resolved(1) ~= '#')
        out = resolved;
    end

end

function map = harvestInlineLocalization(txt)
%harvestInlineLocalization Reads the "//#autoLOC_x = ..." comments KSP
%writes next to each localization tag in a part cfg. Used as a fallback
%when no dictionary covers the tag.

    map = containers.Map('KeyType', 'char', 'ValueType', 'char');

    if(isempty(strfind(txt, '//#'))) %#ok<STREMP>
        return;
    end

    toks = regexp(txt, '//\s*(#[A-Za-z0-9_.\-]+)\s*=\s*([^\r\n]*)', 'tokens');
    for(i = 1:numel(toks))
        key = lower(strtrim(toks{i}{1}));
        val = strtrim(toks{i}{2});
        if(~isempty(val) && ~isKey(map, key))
            map(key) = val;
        end
    end

end

function val = getCfgStr(node, field, defaultVal)
    val = defaultVal;
    if(~isfield(node, field))
        return;
    end
    raw = node.(field);
    if(iscell(raw))
        if(~isempty(raw))
            val = raw{1};
        end
    elseif(ischar(raw))
        val = raw;
    end
    if(ischar(val))
        val = strtrim(val);
    end
end

function num = getCfgNum(node, field, defaultVal)
    str = getCfgStr(node, field, '');
    if(isempty(str))
        num = defaultVal;
    else
        num = str2double(str);
        if(isnan(num))
            num = defaultVal;
        end
    end
end

function val = getFieldOrDefault(structIn, fieldName, defaultVal)
    val = defaultVal;
    if(isstruct(structIn) && isfield(structIn, fieldName))
        val = structIn.(fieldName);
    end
end
