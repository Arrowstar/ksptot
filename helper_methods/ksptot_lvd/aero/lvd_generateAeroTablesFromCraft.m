function result = lvd_generateAeroTablesFromCraft(craftPath, opts)
%lvd_generateAeroTablesFromCraft End-to-end craft -> drag/lift CSV tables.
%
%   result = lvd_generateAeroTablesFromCraft(craftPath, opts)
%
%   CRAFTPATH is a KSP .craft file path. OPTS (optional struct):
%       .cubeDB - cubeDB struct (lvd_import_cubeDB) or PartDatabase.cfg /
%                 KSP-root path to build one from. REQUIRED unless
%                 .kspRoot is given.
%       .kspRoot - KSP install root (builds cubeDB + physics from it).
%       .phys - kwt_physicsGlobals struct, or a Physics.cfg path, or []
%               (default: compiled stock defaults; .kspRoot overrides).
%       .partDB - existing lvd_import part database (warning enrichment).
%       .machVec, .aoaDegVec, .sideslipDegVec, .pitchInput - sweep grid
%                 (see kwt_sweepCraft defaults).
%       .outDir - CSV folder (default: the craft file's folder).
%       .dragFileName, .liftFileName - CSV names (see kwt_sweepCraft).
%       .buildOpts - struct forwarded to kwt_buildAeroSpec
%                 (.noseAxis/.allowMissingCubes/...).
%       .quiet - suppress progress prints (default false).
%       .onProgress - function handle called as onProgress(fraction,
%                 message) at phase boundaries and once per sweep column
%                 (optional; drives the dialog progress bars).
%
%   RESULT fields: .dragCsv, .liftCsv, .tables (kwt_sweepCraft output),
%   .spec (kwt_buildAeroSpec output), .warnings (cellstr), .physUsed.
%
%   Single-configuration v1: tables describe the full-craft geometry as
%   imported; restaging (drops/asparagus) changes geometry and needs a
%   regen. Tables are baked at the stated pitchInput (default 0).
%
%   See also: kwt_buildAeroSpec, kwt_sweepCraft,
%   lvd_importAeroTableFromCraft.

    if(nargin < 2)
        opts = struct();
    end

    warnings = {};

    % Optional progress reporting for UI progress dialogs: phase-framed
    % as 0-0.05 loading, 0.05-0.1 craft analysis, 0.1-0.95 the sweep
    % (rescaled from kwt_sweepCraft's 0-1), 0.95-1 CSV writes.
    userProgress = getOpt(opts, 'onProgress', []);
    if(~isa(userProgress, 'function_handle'))
        userProgress = [];
    end
    emitProgress(userProgress, 0.02, 'Loading drag-cube database...');

    cubeDB = getOpt(opts, 'cubeDB', []);
    if(ischar(cubeDB) || (isstruct(cubeDB) && (isfield(cubeDB, 'kspRoot') || isfield(cubeDB, 'partDatabaseCfg'))))
        cubeDB = lvd_import_cubeDB(cubeDB);
    elseif(isempty(cubeDB) && isfield(opts, 'kspRoot') && ~isempty(opts.kspRoot))
        [cubeDB, cubeWarnings] = lvd_import_cubeDB(opts.kspRoot);
        warnings = [warnings, cubeWarnings];
    end
    if(isempty(cubeDB))
        error('lvd_generateAeroTablesFromCraft:noCubeDB', ...
            ['No drag-cube database supplied. Pass opts.cubeDB=ax ' ...
             '(lvd_import_cubeDB) or opts.kspRoot=<KSP install>.']);
    end

    if(isfield(opts, 'phys') && ~isempty(opts.phys))
        % kwt_physicsGlobals dispatches on type (struct, path, or root).
        phys = kwt_physicsGlobals(opts.phys);
    elseif(isfield(opts, 'kspRoot') && ~isempty(opts.kspRoot))
        phys = kwt_physicsGlobals(opts.kspRoot);
    else
        phys = kwt_physicsGlobals();
    end

    buildOpts = getOpt(opts, 'buildOpts', struct());
    if(~isfield(buildOpts, 'partDB') || isempty(buildOpts.partDB))
        % Default to the bundled stock DB: craft files omit lift
        % coefficients (e.g. basicFin, mk1pod.v2), so without a partDB
        % every lifting surface falls back to KSP's 1.5 default. The
        % bundled DB now carries live GameData lift harvests; callers
        % with a full KSP install can pass buildOpts.partDB from
        % lvd_import_getPartDatabase(<GameData>) to override.
        buildOpts.partDB = lvd_import_getPartDatabase();
    end
    emitProgress(userProgress, 0.08, 'Analyzing craft geometry...');
    spec = kwt_buildAeroSpec(craftPath, cubeDB, phys, buildOpts);
    warnings = [warnings, spec.warnings];

    sweepOpts = struct();
    forwardFields = {'machVec', 'aoaDegVec', 'sideslipDegVec', 'pitchInput', ...
        'dragFileName', 'liftFileName', 'quiet'};
    for(k = 1:numel(forwardFields))
        if(isfield(opts, forwardFields{k}))
            sweepOpts.(forwardFields{k}) = opts.(forwardFields{k});
        end
    end
    if(~isempty(userProgress))
        sweepOpts.onProgress = @(frac, msg) userProgress(0.1 + 0.85*frac, msg);
    end
    if(isfield(opts, 'outDir') && ~isempty(opts.outDir))
        sweepOpts.outDir = opts.outDir;
    else
        [craftDir, ~, ~] = fileparts(craftPath);
        if(isempty(craftDir))
            craftDir = pwd;
        end
        sweepOpts.outDir = craftDir;
    end

    [tables, files] = kwt_sweepCraft(spec, phys, sweepOpts);

    emitProgress(userProgress, 1, 'Done.');

    result = struct();
    result.dragCsv = files.dragCsv;
    result.liftCsv = files.liftCsv;
    result.tables = tables;
    result.spec = spec;
    result.warnings = warnings;
    result.physUsed = phys;
end

function v = getOpt(opts, name, defaultVal)
    if(isfield(opts, name) && ~isempty(opts.(name)))
        v = opts.(name);
    else
        v = defaultVal;
    end
end

function emitProgress(userProgress, frac, msg)
    %emitProgress Fires the optional progress callback; callback errors
    %must never break a generation the user is watching.
    if(isempty(userProgress))
        return;
    end
    try
        userProgress(frac, msg);
    catch
    end
end
