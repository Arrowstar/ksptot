function phys = kwt_physicsGlobals(source)
%kwt_physicsGlobals Stock KSP aerodynamic globals + FloatCurve tables.
%
%   phys = kwt_physicsGlobals() returns the stock KSP 1.12.5 aerodynamic
%   constants and FloatCurve key tables transcribed from Physics.cfg
%   (drag/tip/surface/tail/overall/Cd/CdPower/pseudo-Reynolds curves and
%   the Default + BodyLift lifting-surface curve sets).
%
%   phys = kwt_physicsGlobals(physicsCfgPath) parses the given Physics.cfg
%   file instead (same schema, values override the compiled defaults).
%   phys = kwt_physicsGlobals(kspRootFolder) looks for Physics.cfg inside
%   the given KSP install root folder.
%
%   The returned PHYS struct holds:
%       .dragMultiplier, .dragCubeMultiplier, .liftMultiplier,
%       .liftDragMultiplier, .bodyLiftMultiplier  - scalars
%       .tipCurve, .surfaceCurve, .tailCurve, .overallCurve (.dragMultiplierCurve),
%       .cdCurve, .cdPowerCurve, .pseudoReynoldsCurve  - Nx4 [x y m0 m1]
%       .wingLiftCurve, .wingLiftMachCurve, .wingDragCurve, .wingDragMachCurve
%       .bodyLiftCurve, .bodyLiftMachCurve             - Nx4, Default/BodyLift sets
%       .capsuleLiftCurve, .capsuleLiftMachCurve,
%       .capsuleDragCurve, .capsuleDragMachCurve       - Nx4, CapsuleBottom set
%                     (capsule drag/dragMach are all-zero by stock)
%       .sourcePath - '' for compiled defaults, else the file parsed
%
%   Curves are evaluated with ksp_evalFloatCurve (KSP Hermite FloatCurve
%   semantics: cubic Hermite between keys, clamped to the edge values
%   outside the key range). The only deliberate deviation from KSP is the
%   DRAG_CD curve below its first key (x = 0.05): KSP clamps to 0.0025
%   while Ren0k's kOS port special-cases rawCd <= 0 to 0. This function
%   keeps the raw KSP tables; callers that need the kOS behavior apply it
%   themselves (documented in ksp_setDrag).
%
%   See also: ksp_evalFloatCurve, ksp_setDrag, kwt_aero.

    if(nargin < 1)
        source = '';
    end

    phys = compiledDefaults();
    phys.sourcePath = '';

    if(isstruct(source))
        % Passthrough of an already-built struct (validates fields).
        phys = validateStruct(source);
        return;
    end

    if(isempty(source))
        return;
    end

    cfgPath = resolveCfgPath(source);
    if(isempty(cfgPath))
        error('kwt_physicsGlobals:fileNotFound', ...
            'Physics.cfg not found for source: %s', source);
    end

    try
        parsed = parsePhysicsCfg(cfgPath);
        phys = mergeParsed(phys, parsed);
        phys.sourcePath = cfgPath;
    catch ME
        error('kwt_physicsGlobals:parseFailed', ...
            'Failed to parse Physics.cfg at %s: %s', cfgPath, ME.message);
    end
end

function phys = compiledDefaults()
    phys = struct();
    phys.dragMultiplier = 8;
    phys.dragCubeMultiplier = 0.1;
    phys.liftMultiplier = 0.036;
    phys.liftDragMultiplier = 0.015;
    phys.bodyLiftMultiplier = 18;

    % Transcribed from KSP 1.12.5 Physics.cfg (key = x y m0 m1).
    phys.tipCurve = [ ...
        0        1        0          0; ...
        0.85     1.19     0.6960422  0.6960422; ...
        1.1      2.83     0.730473   0.730473; ...
        5        4        0          0];
    phys.surfaceCurve = [ ...
        0        0.02         0            0; ...
        0.85     0.02         0            0; ...
        0.9      0.0152439   -0.07942077  -0.07942077; ...
        1.1      0.0025      -0.005279571 -0.001936768; ...
        2        0.002083333 -2.314833E-05 -2.314833E-05; ...
        5        0.003333333 -0.000180556 -0.000180556; ...
        25       0.001428571 -7.14286E-05  0];
    phys.tailCurve = [ ...
        0        1        0            0; ...
        0.85     1        0            0; ...
        1.1      0.25    -0.02215106  -0.02487721; ...
        1.4      0.22    -0.03391732  -0.03391732; ...
        5        0.15    -0.001198566 -0.001198566; ...
        25       0.14     0            0];
    phys.overallCurve = [ ...
        0        0.5      0            0; ...
        0.85     0.5      0            0; ...
        1.1      1.3      0           -0.008100224; ...
        2        0.7     -0.1104858   -0.1104858; ...
        5        0.6      0            0; ...
        10       0.85     0.02198264   0.02198264; ...
        14       0.9      0.007694946  0.007694946; ...
        25       0.95     0            0];
    phys.cdCurve = [ ...
        0.05     0.0025   0.15       0.15; ...
        0.4      0.15     0.3963967  0.3963967; ...
        0.7      0.35     0.9066986  0.9066986; ...
        0.75     0.45     3.213604   3.213604; ...
        0.8      0.66     3.49833    3.49833; ...
        0.85     0.8      2.212924   2.212924; ...
        0.9      0.89     1.1        1.1; ...
        1        1        1          1];
    phys.cdPowerCurve = [ ...
        0        1        0          0.00715953; ...
        0.85     1.25     0.7780356  0.7780356; ...
        1.1      2.5      0.2492796  0.2492796; ...
        5        3        0          0];
    phys.pseudoReynoldsCurve = [ ...
        0        4        0            -2975.412; ...
        0.0001   3       -251.1479    -251.1479; ...
        0.01     2       -19.63584    -19.63584; ...
        0.1      1.2     -0.7846036   -0.7846036; ...
        1        1        0            0; ...
        100      1        0            0; ...
        200      0.82     0            0; ...
        500      0.86     0.0001932119 0.0001932119; ...
        1000     0.9      1.54299E-05  1.54299E-05; ...
        10000    0.95     0            0];

    % LIFTING_SURFACE "Default" (wings / control surfaces).
    phys.wingLiftCurve = [ ...
        0           0          0          1.965926; ...
        0.258819    0.5114774  1.990092   1.905806; ...
        0.5         0.9026583  0.7074468 -0.7074468; ...
        0.7071068   0.5926583 -2.087948  -1.990095; ...
        1           0         -2.014386  -2.014386];
    phys.wingLiftMachCurve = [ ...
        0           1          0            0; ...
        0.3         0.5       -1.671345   -0.8273422; ...
        1           0.125     -0.0005291355 -0.02625772; ...
        5           0.0625     0            0; ...
        25          0.05       0            0];
    phys.wingDragCurve = [ ...
        0           0.01       0          0; ...
        0.3420201   0.06       0.1750731  0.1750731; ...
        0.5         0.24       2.60928    2.60928; ...
        0.7071068   1.7        3.349777   3.349777; ...
        1           2.4        1.387938   0];
    phys.wingDragMachCurve = [ ...
        0           0.35       0            -0.8463008; ...
        0.15        0.125      0            0; ...
        0.9         0.275      0.541598     0.541598; ...
        1.1         0.75       0            0; ...
        1.4         0.4       -0.3626955   -0.3626955; ...
        1.6         0.35      -0.1545923   -0.1545923; ...
        2           0.3       -0.09013031  -0.09013031; ...
        5           0.22       0            0; ...
        25          0.3        0.0006807274 0];

    % LIFTING_SURFACE "BodyLift" (body-lift Mach factor; the AoA curve is
    % applied to cube-derived lift inside ksp_setDrag/kwt_aero callers via
    % the same Hermite evaluator).
    phys.bodyLiftCurve = [ ...
        0           0          0          1.975376; ...
        0.309017    0.5877852  1.565065   1.565065; ...
        0.5877852   0.9510565  0.735902   0.735902; ...
        0.7071068   1          0          0; ...
        0.8910065   0.809017  -2.70827   -2.70827; ...
        1           0         -11.06124    0];
    phys.bodyLiftMachCurve = [ ...
        0.3         0.167      0          0; ...
        0.8         0.167      0         -0.3904104; ...
        1           0.125     -0.0005291355 -0.02625772; ...
        5           0.0625     0          0; ...
        25          0.05       0          0];

    % LIFTING_SURFACE "CapsuleBottom" (auto-added capsule modules, e.g.
    % the Mk1 pod: fitted deflectionLiftCoeff ~0.35, see kwt_buildAeroSpec).
    phys.capsuleLiftCurve = [ ...
        0           0          0          1.975376; ...
        0.309017    0.5877852  1.565065   1.565065; ...
        0.5877852   0.9510565  0.735902   0.735902; ...
        0.7071068   1          0          0; ...
        0.8910065   0.809017  -2.70827   -2.70827; ...
        1           0         -11.06124    0];
    phys.capsuleLiftMachCurve = [0.3 0.0625 0 0];
    phys.capsuleDragCurve = [0 0 0 0];
    phys.capsuleDragMachCurve = [0 0 0 0];
end

function phys = validateStruct(phys)
    required = {'dragMultiplier','dragCubeMultiplier','liftMultiplier', ...
        'liftDragMultiplier','bodyLiftMultiplier','tipCurve','surfaceCurve', ...
        'tailCurve','overallCurve','cdCurve','cdPowerCurve', ...
        'pseudoReynoldsCurve','wingLiftCurve','wingLiftMachCurve', ...
        'wingDragCurve','wingDragMachCurve','bodyLiftCurve','bodyLiftMachCurve', ...
        'capsuleLiftCurve','capsuleLiftMachCurve','capsuleDragCurve','capsuleDragMachCurve'};
    for(i = 1:numel(required))
        if(~isfield(phys, required{i}))
            error('kwt_physicsGlobals:invalidStruct', ...
                'Physics struct is missing required field "%s".', required{i});
        end
    end
    if(~isfield(phys, 'sourcePath'))
        phys.sourcePath = '';
    end
end

function cfgPath = resolveCfgPath(source)
    cfgPath = '';
    if(~ischar(source))
        return;
    end
    if(isfolder(source))
        candidate = fullfile(source, 'Physics.cfg');
        if(isfile(candidate))
            cfgPath = candidate;
        end
        return;
    end
    if(isfile(source))
        cfgPath = source;
    end
end

function parsed = parsePhysicsCfg(cfgPath)
    txt = fileread(cfgPath);
    root = sfsParse(txt);

    parsed = struct();
    parsed.scalars = struct();
    scalarNames = {'dragMultiplier','dragCubeMultiplier','angularDragMultiplier', ...
        'liftMultiplier','liftDragMultiplier','bodyLiftMultiplier'};
    for(i = 1:numel(scalarNames))
        v = getScalar(root, scalarNames{i});
        if(~isnan(v))
            parsed.scalars.(scalarNames{i}) = v;
        end
    end

    % Top-level DRAG_* blocks each hold repeated "key = x y m0 m1" lines.
    parsed.tipCurve = getCurveKeys(root, 'DRAG_TIP');
    parsed.surfaceCurve = getCurveKeys(root, 'DRAG_SURFACE');
    parsed.tailCurve = getCurveKeys(root, 'DRAG_TAIL');
    parsed.overallCurve = getCurveKeys(root, 'DRAG_MULTIPLIER');
    parsed.cdCurve = getCurveKeys(root, 'DRAG_CD');
    parsed.cdPowerCurve = getCurveKeys(root, 'DRAG_CD_POWER');
    parsed.pseudoReynoldsCurve = getCurveKeys(root, 'DRAG_PSEUDOREYNOLDS');

    % Lifting-surface sets live under LIFTING_SURFACE_CURVES.
    sets = struct('Default', [], 'BodyLift', [], 'CapsuleBottom', []);
    if(isfield(root, 'LIFTING_SURFACE_CURVES'))
        lsc = root.LIFTING_SURFACE_CURVES{1};
        if(isfield(lsc, 'LIFTING_SURFACE'))
            for(k = 1:numel(lsc.LIFTING_SURFACE))
                node = lsc.LIFTING_SURFACE{k};
                nm = getStr(node, 'name');
                if(strcmpi(nm, 'Default') || strcmpi(nm, 'BodyLift') || ...
                   strcmpi(nm, 'CapsuleBottom'))
                    sets.(nm).lift = getCurveKeys(node, 'lift');
                    sets.(nm).liftMach = getCurveKeys(node, 'liftMach');
                    sets.(nm).drag = getCurveKeys(node, 'drag');
                    sets.(nm).dragMach = getCurveKeys(node, 'dragMach');
                end
            end
        end
    end
    parsed.sets = sets;
end

function phys = mergeParsed(phys, parsed)
    f = fieldnames(parsed.scalars);
    for(i = 1:numel(f))
        phys.(f{i}) = parsed.scalars.(f{i});
    end
    % angularDragMultiplier is parsed but not part of the v1 aero model.
    if(isfield(parsed.scalars, 'angularDragMultiplier'))
        phys.angularDragMultiplier = parsed.scalars.angularDragMultiplier;
    end
    map = {'tipCurve','surfaceCurve','tailCurve','overallCurve','cdCurve', ...
        'cdPowerCurve','pseudoReynoldsCurve'};
    for(i = 1:numel(map))
        if(isfield(parsed, map{i}) && ~isempty(parsed.(map{i})))
            phys.(map{i}) = parsed.(map{i});
        end
    end
    if(isfield(parsed, 'sets'))
        if(~isempty(parsed.sets.Default))
            s = parsed.sets.Default;
            if(~isempty(s.lift)),     phys.wingLiftCurve = s.lift; end
            if(~isempty(s.liftMach)), phys.wingLiftMachCurve = s.liftMach; end
            if(~isempty(s.drag)),     phys.wingDragCurve = s.drag; end
            if(~isempty(s.dragMach)), phys.wingDragMachCurve = s.dragMach; end
        end
        if(~isempty(parsed.sets.BodyLift))
            s = parsed.sets.BodyLift;
            if(~isempty(s.lift)),     phys.bodyLiftCurve = s.lift; end
            if(~isempty(s.liftMach)), phys.bodyLiftMachCurve = s.liftMach; end
        end
        if(isfield(parsed.sets, 'CapsuleBottom') && ~isempty(parsed.sets.CapsuleBottom))
            s = parsed.sets.CapsuleBottom;
            if(~isempty(s.lift)),     phys.capsuleLiftCurve = s.lift; end
            if(~isempty(s.liftMach)), phys.capsuleLiftMachCurve = s.liftMach; end
            if(~isempty(s.drag)),     phys.capsuleDragCurve = s.drag; end
            if(~isempty(s.dragMach)), phys.capsuleDragMachCurve = s.dragMach; end
        end
    end
end

function v = getScalar(root, name)
    v = NaN;
    if(~isfield(root, name))
        return;
    end
    raw = root.(name);
    if(iscell(raw))
        raw = raw{1};
    end
    if(ischar(raw))
        tok = strsplit(strtrim(raw));
        v = str2double(tok{1});
    elseif(isnumeric(raw))
        v = double(raw);
    end
end

function keys = getCurveKeys(node, blockName)
    keys = [];
    if(~isfield(node, blockName))
        return;
    end
    blk = node.(blockName){1};
    if(~isfield(blk, 'key'))
        return;
    end
    rawKeys = blk.key;
    if(ischar(rawKeys))
        rawKeys = {rawKeys};
    end
    rows = zeros(numel(rawKeys), 4);
    n = 0;
    for(i = 1:numel(rawKeys))
        vals = sscanf(rawKeys{i}, '%f %f %f %f');
        if(numel(vals) == 4)
            n = n + 1;
            rows(n, :) = vals';
        end
    end
    keys = rows(1:n, :);
end

function s = getStr(node, field)
    s = '';
    if(~isfield(node, field))
        return;
    end
    raw = node.(field);
    if(iscell(raw))
        raw = raw{1};
    end
    if(ischar(raw))
        s = strtrim(raw);
    end
end
