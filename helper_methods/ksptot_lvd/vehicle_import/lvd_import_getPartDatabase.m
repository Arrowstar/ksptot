function [partDB, warnings] = lvd_import_getPartDatabase(source)
%lvd_import_getPartDatabase Loads a part database for craft-file import.
%
%   partDB = lvd_import_getPartDatabase() loads the bundled mini stock
%   parts database shipped with KSPTOT (no KSP installation required).
%
%   partDB = lvd_import_getPartDatabase(source) loads from:
%       - char path to a .json or .mat part database file
%       - struct with optional fields:
%           .filePath  - path to a database file (as above)
%           .kspRoot   - KSP install root; reserved for future
%                        partdatabase.cfg/GameData providers, currently
%                        errors with guidance to use a database file.
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

    if(isstruct(source))
        filePath = getFieldOrDefault(source, 'filePath', '');
        kspRoot = getFieldOrDefault(source, 'kspRoot', '');

        if(~isempty(kspRoot) && isempty(filePath))
            error('lvd_import:gameDataNotSupported', ...
                ['Parsing a KSP install (%s) is not supported yet. ' ...
                 'Provide a .json/.mat part database file instead.'], ...
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

    if(~isfile(source))
        error('lvd_import:fileNotFound', 'Part database file not found: %s', source);
    end

    [~,~,ext] = fileparts(source);
    switch(lower(ext))
        case '.json'
            [partDB, loadWarnings] = loadJsonDatabase(source);
        case '.mat'
            [partDB, loadWarnings] = loadMatDatabase(source);
        otherwise
            error('lvd_import:unsupportedExtension', ...
                'Unsupported part database extension "%s" (use .json or .mat).', ext);
    end

    warnings = [warnings, loadWarnings]; %#ok<AGROW>

end

function [partDB, warnings] = loadBundledDatabase()
    dbPath = fullfile(fileparts(mfilename('fullpath')), 'resources', ...
                      'ksp_stock_parts_112.json');
    [partDB, warnings] = loadJsonDatabase(dbPath);

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

function val = getFieldOrDefault(structIn, fieldName, defaultVal)
    val = defaultVal;
    if(isstruct(structIn) && isfield(structIn, fieldName))
        val = structIn.(fieldName);
    end
end
