function [cubeDB, warnings] = lvd_import_cubeDB(source)
%lvd_import_cubeDB Loads KSP drag-cube data for the aero sweep pipeline.
%
%   [cubeDB, warnings] = lvd_import_cubeDB(source)
%
%   SOURCE selects the input (first match wins):
%       - path to a PartDatabase.cfg file (KSP root folder artifact that
%         holds one PART { url, DRAG_CUBE { cube = ... } } block per
%         part variant/state),
%       - path to a KSP install root folder (expects PartDatabase.cfg
%         directly inside, as KSP writes it),
%       - struct with optional fields .partDatabaseCfg (file path) or
%         .kspRoot (install root folder),
%       - omitted/empty: looks for PartDatabase.cfg next to the bundled
%         stock parts database, else errors with a helpful message.
%
%   CUBEDB struct fields:
%       .sourcePath - resolved PartDatabase.cfg path ('' if none parsed)
%       .cubes      - containers.Map, lower-cased lookup key -> cube entry.
%                     Keys are registered for the full url, the url tail
%                     after the last '/' (usually the part name), and
%                     dot/underscore swapped variants of the tail, so both
%                     craft-style ('engine3.v2') and cfg-style
%                     ('engine3_v2') lookups resolve.
%                     Each value is a struct with:
%                       .url   - full url string from the cfg
%                       .name  - tail name
%                       .cubes - struct array, one per 'cube = ...' line:
%                           .cubeName  - variant/state name (Default, ...)
%                           .faces     - 6x3 [area, baseDrag, depth] in
%                                        face order +X,-X,+Y,-Y,+Z,-Z
%                           .center    - 1x3 cube center (part local, m)
%                           .size      - 1x3 cube size (part local, m)
%       .numParts   - number of distinct urls parsed
%
%   Use ksp_lookupCube(cubeDB, partName) or the map directly to fetch the
%   cube entry for a part; use entry.cubes(1) ('Default' when present) for
%   the v1 sweep. Parts without any DRAG_CUBE block are absent from the
%   map -- callers error naming the part rather than substituting.
%
%   Procedural parts (fairings) need RenderProceduralDragCube fallback;
%   v1 treats them as missing with a warning (see KWT_Lift_Methodology
%   section 6.6).
%
%   See also: ksp_setDrag, kwt_buildAeroSpec, kwt_aero.

    warnings = {};

    cfgPath = resolveCubeSource(source);

    cubeDB = struct();
    cubeDB.sourcePath = '';
    cubeDB.cubes = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cubeDB.urls = {};
    cubeDB.numParts = 0;

    if(isempty(cfgPath))
        if(nargin < 1 || isempty(source))
            error('lvd_import_cubeDB:noSource', ...
                ['No PartDatabase.cfg found. Pass the path to PartDatabase.cfg ' ...
                 'from a KSP 1.12 install (KSP root folder), e.g. ' ...
                 'lvd_import_cubeDB(''C:\\KSP_win64'').']);
        else
            error('lvd_import_cubeDB:fileNotFound', ...
                'Drag-cube source not found: %s', stringifySource(source));
        end
    end

    try
        txt = fileread(cfgPath);
        root = sfsParse(txt);
    catch ME
        error('lvd_import_cubeDB:parseFailed', ...
            'Failed to parse %s: %s', cfgPath, ME.message);
    end

    if(~isfield(root, 'PART'))
        warnings{end+1} = sprintf('No PART blocks found in %s.', cfgPath);
        return;
    end

    numNoCube = 0;
    for(i = 1:numel(root.PART))
        node = root.PART{i};
        url = getStr(node, 'url');
        if(isempty(url))
            continue;
        end
        if(~isfield(node, 'DRAG_CUBE'))
            numNoCube = numNoCube + 1;
            continue;
        end
        entry = buildEntry(url, node);
        if(isempty(entry))
            numNoCube = numNoCube + 1;
            continue;
        end
        registerEntry(cubeDB.cubes, entry);
        if(~any(strcmp(cubeDB.urls, entry.url)))
            cubeDB.urls{end+1} = entry.url;
        end
    end

    cubeDB.sourcePath = cfgPath;
    cubeDB.numParts = double(numel(cubeDB.urls));

    if(cubeDB.numParts == 0)
        warnings{end+1} = sprintf(['No drag cubes parsed from %s. The file may be a ' ...
            'part-config database rather than the KSP-generated PartDatabase.cfg cache.'], cfgPath);
    elseif(numNoCube > 0)
        warnings{end+1} = sprintf('%d PART blocks had no usable DRAG_CUBE and were skipped.', numNoCube);
    end
end

function cfgPath = resolveCubeSource(source)
    cfgPath = '';
    if(nargin < 1 || isempty(source))
        % Next to the bundled stock parts database (usually absent -- the
        % caller is expected to pass a KSP root). Kept for symmetry with
        % lvd_import_getPartDatabase's bundled lookup.
        try
            dbDir = fileparts(mfilename('fullpath'));
            cand = fullfile(dbDir, 'resources', 'PartDatabase.cfg');
            if(isfile(cand))
                cfgPath = cand;
            end
        catch
        end
        return;
    end
    if(isstruct(source))
        if(isfield(source, 'partDatabaseCfg') && ~isempty(source.partDatabaseCfg))
            cfgPath = resolveCubeSource(source.partDatabaseCfg);
        elseif(isfield(source, 'kspRoot') && ~isempty(source.kspRoot))
            cfgPath = resolveCubeSource(source.kspRoot);
        end
        return;
    end
    if(~ischar(source))
        return;
    end
    if(isfile(source))
        cfgPath = source;
        return;
    end
    if(isfolder(source))
        cand = fullfile(source, 'PartDatabase.cfg');
        if(isfile(cand))
            cfgPath = cand;
        end
    end
end

function s = stringifySource(source)
    if(ischar(source))
        s = source;
    else
        s = '(struct source)';
    end
end

function entry = buildEntry(url, node)
    entry = [];
    cubes = struct.empty(0, 0);
    for(d = 1:numel(node.DRAG_CUBE))
        dc = node.DRAG_CUBE{d};
        if(~isfield(dc, 'cube'))
            continue;
        end
        raw = dc.cube;
        if(ischar(raw))
            raw = {raw};
        end
        for(c = 1:numel(raw))
            cube = parseCubeLine(raw{c});
            if(~isempty(cube))
                if(isempty(cubes))
                    cubes = cube;
                else
                    cubes(end+1) = cube; %#ok<AGROW>
                end
            end
        end
    end
    if(isempty(cubes))
        return;
    end
    % Prefer the 'Default' cube first so callers can use cubes(1).
    defIdx = find(strcmpi({cubes.cubeName}, 'default'), 1);
    if(~isempty(defIdx) && defIdx ~= 1)
        cubes = cubes([defIdx, setdiff(1:numel(cubes), defIdx)]);
    end
    tail = url;
    slash = find(url == '/', 1, 'last');
    if(~isempty(slash))
        tail = url(slash+1:end);
    end
    entry = struct('url', url, 'name', tail, 'cubes', cubes);
end

function cube = parseCubeLine(line)
%parseCubeLine Parses one 'cube = Name, 24 numbers' drag-cube line.
%   Layout: name, then 6 faces x (area, baseDrag, depth) in face order
%   +X,-X,+Y,-Y,+Z,-Z, then center xyz, then size xyz (all part-local m).

    cube = [];
    if(~ischar(line))
        return;
    end
    comma = find(line == ',', 1, 'first');
    if(isempty(comma))
        return;
    end
    cubeName = strtrim(line(1:comma-1));
    nums = sscanf(line(comma+1:end), '%f,');
    if(numel(nums) < 24)
        nums = sscanf(line(comma+1:end), '%f');
    end
    if(numel(nums) < 24)
        return;
    end
    nums = nums(1:24);
    faces = reshape(nums(1:18), 3, 6)';
    cube = struct('cubeName', cubeName, 'faces', faces, ...
        'center', reshape(nums(19:21), 1, 3), ...
        'size', reshape(nums(22:24), 1, 3));
end

function registerEntry(map, entry)
    keys = {lower(entry.url), lower(entry.name), ...
        lower(strrep(entry.name, '.', '_')), ...
        lower(strrep(entry.name, '_', '.'))};
    for(k = 1:numel(keys))
        if(~isKey(map, keys{k}))
            map(keys{k}) = entry;
        end
    end
    % Also register progressively shorter url suffixes (mod path prefixes
    % differ between installs, e.g. Squad/ vs SquadExpansion/).
    full = lower(entry.url);
    parts = strsplit(full, '/');
    for(s = 2:numel(parts))
        suffix = strjoin(parts(s:end), '/');
        if(~isKey(map, suffix))
            map(suffix) = entry;
        end
    end
end

function s = getStr(node, field)
    s = '';
    if(~isfield(node, field))
        return;
    end
    raw = node.(field);
    if(iscell(raw))
        if(isempty(raw))
            return;
        end
        raw = raw{1};
    end
    if(ischar(raw))
        s = strtrim(raw);
    end
end
