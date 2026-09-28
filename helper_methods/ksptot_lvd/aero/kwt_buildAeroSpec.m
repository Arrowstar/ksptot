function spec = kwt_buildAeroSpec(craftPathOrText, cubeDB, phys, opts)
%kwt_buildAeroSpec Builds a vessel aero spec from a KSP .craft file.
%
%   spec = kwt_buildAeroSpec(craftPathOrText, cubeDB, phys)
%   spec = kwt_buildAeroSpec(craftPathOrText, cubeDB, phys, opts)
%
%   CRAFTPATHORTEXT is a .craft file path or its raw text (via sfsParse).
%   CUBEDB is an lvd_import_cubeDB database. PHYS is a kwt_physicsGlobals
%   struct (kept for signature symmetry; only used for validation here).
%   OPTS (optional struct):
%       .noseAxis - 'Y' (default; rocket-style: craft stack axis +Y maps
%                   to the aero nose axis X) or 'Z' (plane-style: craft
%                   +Z maps to aero X). .noseSign (+1/-1, default +1)
%                   flips the nose direction for mirrored craft.
%       .allowMissingCubes - false (default): a part with no cubes is a
%                   hard error naming the part (methodology section 6.6).
%                   true: substitute a zero-area cube and record a warning.
%       .liftVectorOverrides - containers.Map baseName(lower) -> 3x1 local
%                   lift vector for lifting surfaces.
%       .shieldedIds - cellstr of instanceIDs treated as
%                   shieldedFromAirstream, unioned with automatic
%                   shielding (default {}).
%       .autoShielding - true (default): shield parts enclosed in closed
%                   fairings (ModuleProceduralFairing, always closed in
%                   VAB craft) or closed cargo bays (ModuleCargoBay with
%                   deploy animation at >= 50%%). Interior = reached
%                   through non-stack (interstage/surface) nodes; stack
%                   pass-through via top/bottom stays outside. Mod fairings
%                   with separate skin parts are a known limitation.
%       .occlusion - containers.Map instanceID -> 6x1 face-area
%                   multipliers, winning over automatic occlusion for the
%                   listed parts (default all ones).
%       .autoOcclusion - true (default): derive node-area occlusion from
%                   attN/srfN topology (see kwt_occlusionFromNodes).
%                   false: keep all occlusion maps at ones.
%       .partDB - lvd_import part database: entries' .liftingSurface
%                   coefficients fill in craft-omitted values per-field
%                   (craft keys win); also enriches warnings (optional).
%
%   The aero frame follows the LVD body convention (X = nose/long axis;
%   see kwt_inflowFromAeroAngles). Craft rotations (PART rot quaternion
%   x,y,z,w + mir mirror flags) are chained as
%   R_part2aero = M * diag(mir) * quat2dcm(rot), with M the noseAxis
%   permutation. Only the rotation is used; positions feed future
%   node-occlusion work and are stored as .posCraft.
%
%   Lifting surfaces are detected from craft PART MODULE blocks named
%   ModuleLiftingSurface / ModuleControlSurface (all aero fields read when
%   present, with GameData/partDB fallback per field, then KSP module
%   defaults). The local lift vector follows KSP's transformDir/Sign rule
%   (default +Z part-local). Control surfaces rotate that vector about
%   rotationAxis by the sweep-time pitchInput (see kwt_aero).
%
%   SPEC fields: .name, .parts (struct array, see code), .warnings,
%   .configHash (stable string stamping the swept configuration),
%   .autoShielded (cellstr of instanceIDs shielded automatically),
%   .frameM (3x3 craft->aero nose permutation, for frame mapping).
%
%   See also: lvd_import_cubeDB, kwt_physicsGlobals, kwt_aero,
%   kwt_sweepCraft, lvd_import_analyzeCraft.

    if(nargin < 4)
        opts = struct();
    end
    if(~isstruct(phys) || ~isfield(phys, 'bodyLiftMultiplier'))
        error('kwt_buildAeroSpec:badPhys', ...
            'PHYS must be a kwt_physicsGlobals struct.');
    end
    noseAxis = getOpt(opts, 'noseAxis', 'Y');
    noseSign = getOpt(opts, 'noseSign', 1);
    allowMissing = getOpt(opts, 'allowMissingCubes', false);
    shieldedIds = getOpt(opts, 'shieldedIds', {});
    if(ischar(shieldedIds))
        shieldedIds = {shieldedIds};
    end

    if(isstruct(craftPathOrText))
        craft = craftPathOrText;
    else
        craft = sfsParse(craftPathOrText);
    end
    if(~isfield(craft, 'PART'))
        error('kwt_buildAeroSpec:noParts', 'Craft file contains no PART blocks.');
    end

    M = nosePermutation(noseAxis, noseSign);

    spec = struct();
    spec.name = getStrField(craft, 'ship', 'Imported Craft');
    spec.warnings = {};
    spec.parts = struct.empty(0, 0);

    numParts = numel(craft.PART);
    for(i = 1:numParts)
        rawPart = craft.PART{i};
        instanceID = getStrField(rawPart, 'part', sprintf('PART_%d', i));
        baseName = stripFlightID(instanceID);

        R = partRotation(rawPart, M);

        cubeEntry = ksp_lookupCube(cubeDB, baseName);
        if(isempty(cubeEntry))
            msg = sprintf('Part "%s" has no drag cubes in the cube database.', baseName);
            if(allowMissing)
                spec.warnings{end+1} = [msg ' Using a zero-area cube.'];
                cube = zeroCube();
                cubeName = 'Zero';
            else
                error('kwt_buildAeroSpec:missingCube', '%s', msg);
            end
        else
            cube = cubeEntry.cubes(1);
            cubeName = cube.cubeName;
        end

        [hasLift, liftParams, liftNotes] = readLiftModule(rawPart, baseName, opts);
        spec.warnings = [spec.warnings, liftNotes];
        if(hasLift && ~isempty(cube) && ~strcmp(cubeName, 'Zero'))
            liftVec = defaultLiftVector(liftParams, baseName, opts);
        else
            liftVec = [0; 0; 0];
        end

        p = struct();
        p.instanceID = instanceID;
        p.baseName = baseName;
        p.posCraft = getVecField(rawPart, 'pos');
        p.R_part2vessel = R;
        p.cube = cube;
        p.cubeName = cubeName;
        p.hasLiftModule = hasLift;
        p.liftVector_local = liftVec;
        p.deflectionLiftCoeff = liftParams.deflectionLiftCoeff;
        p.omnidirectional = liftParams.omnidirectional;
        p.perpendicularOnly = liftParams.perpendicularOnly;
        p.isControl = liftParams.isControl;
        p.rotationAxis_local = liftParams.rotationAxis;
        p.ctrlRangeDeg = liftParams.ctrlRangeDeg;
        p.authorityLimiter = liftParams.authorityLimiter;
        p.deployAngleDeg = liftParams.deployAngleDeg;
        p.bodyLiftMultiplier = liftParams.bodyLiftMultiplier;
        p.liftCurveSet = liftParams.liftCurveSet;
        p.useInternalDragModel = liftParams.useInternalDragModel;
        p.isShielded = any(strcmp(instanceID, shieldedIds));
        p.occlusion = ones(6, 1);
        p.attachNodes = kwt_parseAttachNodes(rawPart);
        p.linkTargets = getLinkTargets(rawPart);
        [p.shieldKind, p.shieldClosed] = detectShield(rawPart);
        if(isfield(opts, 'occlusion') && isa(opts.occlusion, 'containers.Map') ...
                && isKey(opts.occlusion, instanceID))
            p.occlusion = double(opts.occlusion(instanceID));
            p.occlusion = p.occlusion(:);
            p.occlusionManual = true;
        else
            p.occlusionManual = false;
        end

        if(isempty(spec.parts))
            spec.parts = p;
        else
            spec.parts(end+1) = p;
        end
    end

    % Second pass: node-area occlusion from the attach topology (needs all
    % cubes + positions). Manual per-part overrides win over automatic.
    autoOcclusion = getOpt(opts, 'autoOcclusion', true);
    if(autoOcclusion && ~isempty(spec.parts))
        [autoOcc, occNotes] = kwt_occlusionFromNodes(spec.parts, M);
        for(p = 1:numel(spec.parts))
            if(~spec.parts(p).occlusionManual)
                spec.parts(p).occlusion = autoOcc(p, :)';
            end
        end
        spec.warnings = [spec.warnings, occNotes];
    end
    if(isfield(spec.parts, 'occlusionManual'))
        spec.parts = rmfield(spec.parts, 'occlusionManual');
    end

    % Third pass: shielding inside closed fairings / cargo bays. Walks the
    % link tree upward: entering a closed shield through a non-stack node
    % (interstage/surface) means enclosed; exiting through its top/bottom
    % stack nodes means outside. Manual shieldedIds union with automatic.
    autoShield = getOpt(opts, 'autoShielding', true);
    spec.autoShielded = {};
    if(autoShield && ~isempty(spec.parts))
        parentOf = buildParentMap(spec.parts);
        for(p = 1:numel(spec.parts))
            if(spec.parts(p).isShielded)
                continue;   % manual entry stands
            end
            if(isEnclosed(spec.parts, parentOf, p))
                spec.parts(p).isShielded = true;
                spec.autoShielded{end+1} = spec.parts(p).instanceID;
            end
        end
    end
    if(isfield(spec.parts, 'linkTargets'))
        spec.parts = rmfield(spec.parts, 'linkTargets');
    end
    if(isfield(spec.parts, 'shieldKind'))
        spec.parts = rmfield(spec.parts, 'shieldKind');
    end
    if(isfield(spec.parts, 'shieldClosed'))
        spec.parts = rmfield(spec.parts, 'shieldClosed');
    end

    spec.configHash = hashSpec(spec);
    spec.frameM = M;
end

function targets = getLinkTargets(rawPart)
%getLinkTargets Child instanceIDs from the craft "link" entries.

    targets = {};
    if(~isfield(rawPart, 'link'))
        return;
    end
    v = rawPart.link;
    if(ischar(v))
        v = {v};
    end
    if(~iscellstr(v))
        return;
    end
    for(k = 1:numel(v))
        if(~isempty(v{k}))
            targets{end+1} = v{k}; %#ok<AGROW>
        end
    end
end

function [kind, closed] = detectShield(rawPart)
%detectShield Classifies fairing / cargo-bay shield parts from craft MODULEs.
%
%   Fairings (ModuleProceduralFairing) are always closed in VAB craft
%   files: jettison is not representable pre-flight. Cargo bays
%   (ModuleCargoBay without a procedural module on the same part) follow
%   their DeployModuleIndex-linked animation: closed unless the percent
%   reads below 50 (Dynawing evidence: hangar-closed bays save at 100).
%   Missing animation state defaults to closed.

    kind = '';
    closed = false;
    if(~isfield(rawPart, 'MODULE'))
        return;
    end
    hasFairing = false;
    hasBay = false;
    for(m = 1:numel(rawPart.MODULE))
        nm = getStrField(rawPart.MODULE{m}, 'name', '');
        if(strcmpi(nm, 'ModuleProceduralFairing'))
            hasFairing = true;
        elseif(strcmpi(nm, 'ModuleCargoBay'))
            hasBay = true;
        end
    end
    if(hasFairing)
        kind = 'fairing';
        closed = true;
    elseif(hasBay)
        kind = 'bay';
        closed = animatePercent(rawPart) >= 50;
    end
end

function pct = animatePercent(rawPart)
%animatePercent Deployment percent of the first animation-state MODULE
%(ModuleAnimateGeneric: deployPercent, else 100*animTime). Absent -> 100.

    pct = 100;
    if(~isfield(rawPart, 'MODULE'))
        return;
    end
    for(m = 1:numel(rawPart.MODULE))
        mod = rawPart.MODULE{m};
        if(isfield(mod, 'deployPercent'))
            pct = getNumField(mod, 'deployPercent', 100);
            return;
        end
        if(isfield(mod, 'animTime'))
            pct = 100 * getNumField(mod, 'animTime', 1);
            return;
        end
    end
end

function parentOf = buildParentMap(parts)
%buildParentMap First-wins child->parent indices from link targets.

    idToIdx = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for(i = 1:numel(parts))
        if(~isKey(idToIdx, parts(i).instanceID))
            idToIdx(parts(i).instanceID) = i;
        end
    end
    parentOf = zeros(1, numel(parts));
    for(i = 1:numel(parts))
        if(~isfield(parts(i), 'linkTargets'))
            continue;
        end
        for(t = 1:numel(parts(i).linkTargets))
            tgt = parts(i).linkTargets{t};
            if(isKey(idToIdx, tgt))
                c = idToIdx(tgt);
                if(c ~= i && parentOf(c) == 0)
                    parentOf(c) = i;
                end
            end
        end
    end
end

function enclosed = isEnclosed(parts, parentOf, startIdx)
%isEnclosed Walks the link tree upward: entering a closed shield through
%a non-stack (interstage/surface) node means enclosed; crossing one of
%its top/bottom stack nodes means outside. Missing node records are
%conservative (outside). Cycle-guarded.

    enclosed = false;
    visited = false(1, numel(parts));
    cur = startIdx;
    while(true)
        if(cur < 1 || cur > numel(parts) || visited(cur))
            return;
        end
        visited(cur) = true;
        s = parentOf(cur);
        if(s == 0)
            return;
        end
        if(isClosedShield(parts(s)))
            nodeId = edgeNodeId(parts, s, cur);
            if(isempty(nodeId))
                % No record (e.g. strut): conservative = outside.
                cur = s;
                continue;
            end
            if(isStackNode(nodeId))
                cur = s;   % through the stack: outside this shield
                continue;
            end
            enclosed = true;   % entered the interior
            return;
        end
        cur = s;
    end
end

function tf = isClosedShield(part)
    tf = isfield(part, 'shieldKind') && ~isempty(part.shieldKind) ...
        && isfield(part, 'shieldClosed') && part.shieldClosed;
end

function nodeId = edgeNodeId(parts, shieldIdx, childIdx)
%edgeNodeId The shield-side node attaching the child: the shield's stack
%node targeting the child, else the child's srf node targeting the shield
%reported as interior ('srf').

    nodeId = '';
    childID = parts(childIdx).instanceID;
    shieldID = parts(shieldIdx).instanceID;
    if(isfield(parts(shieldIdx), 'attachNodes'))
        for(n = parts(shieldIdx).attachNodes.stack)
            if(strcmp(n.target, childID))
                nodeId = n.id;
                return;
            end
        end
    end
    if(isfield(parts(childIdx), 'attachNodes'))
        for(n = parts(childIdx).attachNodes.srf)
            if(strcmp(n.target, shieldID))
                nodeId = 'srf';
                return;
            end
        end
    end
end

function tf = isStackNode(nodeId)
    l = lower(nodeId);
    tf = contains(l, 'top') || contains(l, 'bottom');
end

function M = nosePermutation(noseAxis, noseSign)
    if(strcmpi(noseAxis, 'Z'))
        % Plane-style: craft +Z -> aero +X, craft +X -> aero +Y,
        % craft +Y -> aero +Z (cyclic, det +1).
        M = [0 0 1; 1 0 0; 0 1 0];
    else
        % Rocket-style: craft +Y -> aero +X, craft +X -> aero +Y,
        % craft -Z -> aero +Z (det +1).
        M = [0 1 0; 1 0 0; 0 0 -1];
    end
    if(noseSign < 0)
        M(1, :) = -M(1, :);
    end
end

function R = partRotation(rawPart, M)
    q = getVecField(rawPart, 'rot', [0 0 0 1]);
    Rq = quat2dcm(q);
    mir = getVecField(rawPart, 'mir', [1 1 1]);
    mir = sign(mir);
    mir(mir == 0) = 1;
    R = M * diag(mir) * Rq;
    % Re-orthogonalize against float drift (mir flips keep det +1 by
    % construction of M, but numerical noise accumulates).
    [U, ~, V] = svd(R);
    R = U * V';
    if(det(R) < 0)
        R(:, 3) = -R(:, 3);
    end
end

function R = quat2dcm(q)
%quat2dcm Quaternion [x y z w] (KSP/Unity order) to direction-cosine matrix.
    q = double(q(:)');
    n = norm(q);
    if(n <= 0)
        R = eye(3);
        return;
    end
    x = q(1)/n; y = q(2)/n; z = q(3)/n; w = q(4)/n;
    R = [1-2*(y^2+z^2), 2*(x*y-z*w),   2*(x*z+y*w); ...
         2*(x*y+z*w),   1-2*(x^2+z^2), 2*(y*z-x*w); ...
         2*(x*z-y*w),   2*(y*z+x*w),   1-2*(x^2+y^2)];
end

function [hasLift, lp, notes] = readLiftModule(rawPart, baseName, opts)
%readLiftModule Reads wing/control-surface params with craft -> GameData ->
%KSP-default precedence (KSPDocs ModuleLiftingSurface: omnidirectional
%true, perpendicularOnly false, deflectionLiftCoeff 1.5, curve 'Default').
%Craft files usually omit deflectionLiftCoeff (stock fin craft MODULEs
%carry no aero fields), so the GameData part database (opts.partDB,
%entries' .liftingSurface) is the live source for fin/control
%coefficients. An explicit craft key always wins, even when zero.
%Falling back to the 1.5 default (stale/absent GameData) is reported in
%notes so sweeps do not silently overweight wings. The lift direction
%follows KSP's transformDir/transformSign rule (default +Z part-local);
%nodeEnabled modules resolve to zero deflection unless the named node is
%attached (e.g. the Mk1 pod's bottom-gated capsule module, whose full
%record -- 0.35/CapsuleBottom/clamped/Y/-1 -- lives in its cfg and is
%harvested like any other).

    lp = struct('deflectionLiftCoeff', 1.5, 'omnidirectional', true, ...
        'perpendicularOnly', false, 'isControl', false, ...
        'rotationAxis', [1; 0; 0], 'ctrlRangeDeg', 0, ...
        'authorityLimiter', 1, 'deployAngleDeg', 0, ...
        'bodyLiftMultiplier', 1, 'liftCurveSet', 'Default', ...
        'transformDir', 'Z', 'transformSign', 1, ...
        'nodeEnabled', false, 'attachNodeName', '', ...
        'useInternalDragModel', true);
    notes = {};
    db = dbLiftSurf(opts, baseName);
    hasLift = false;
    if(~isfield(rawPart, 'MODULE'))
        return;
    end
    warnDeflDefault = false;
    for(m = 1:numel(rawPart.MODULE))
        mod = rawPart.MODULE{m};
        nm = getStrField(mod, 'name', '');
        if(strcmpi(nm, 'ModuleLiftingSurface'))
            hasLift = true;
        elseif(strcmpi(nm, 'ModuleControlSurface'))
            hasLift = true;
            lp.isControl = true;
        else
            continue;
        end
        [lp.deflectionLiftCoeff, usedDefault] = pickNum(mod, 'deflectionLiftCoeff', db, 'deflectionLiftCoeff', 1.5);
        warnDeflDefault = usedDefault && ~isempty(baseName);
        lp.omnidirectional = pickBool(mod, 'omnidirectional', db, 'omnidirectional', true);
        lp.perpendicularOnly = pickBool(mod, 'perpendicularOnly', db, 'perpendicularOnly', false);
        lp.liftCurveSet = pickStr(mod, 'liftingSurfaceCurve', db, 'liftingSurfaceCurve', 'Default');
        lp.transformDir = pickAxis(mod, 'transformDir', db, 'transformDir', 'Z');
        lp.transformSign = pickNum(mod, 'transformSign', db, 'transformSign', 1);
        if(lp.transformSign >= 0)
            lp.transformSign = 1;
        else
            lp.transformSign = -1;
        end
        lp.nodeEnabled = pickBool(mod, 'nodeEnabled', db, 'nodeEnabled', false);
        lp.attachNodeName = pickStr(mod, 'attachNodeName', db, 'attachNodeName', '');
        lp.useInternalDragModel = pickBool(mod, 'useInternalDragModel', db, 'useInternalDragModel', true);
        lp.ctrlRangeDeg = pickNum(mod, 'ctrlSurfaceRange', db, 'ctrlSurfaceRange', 0);
        lp.authorityLimiter = pickNum(mod, 'authorityLimiter', db, 'authorityLimiter', 1);
        lp.deployAngleDeg = pickNum(mod, 'deployAngle', db, 'deployAngleDeg', 0);
        ra = getVecField(mod, 'rotationAxis', []);
        if(numel(ra) == 3 && norm(ra) > 0)
            lp.rotationAxis = ra(:) / norm(ra);
        elseif(~isempty(db) && numel(db.rotationAxis) == 3)
            lp.rotationAxis = db.rotationAxis(:) / norm(db.rotationAxis);
        end
        lp.bodyLiftMultiplier = getNumField(mod, 'bodyLiftMultiplier', lp.bodyLiftMultiplier);
        % Craft MODULE blocks may carry a stored liftVector override.
        % (Rare; the builder default covers the common case.)
        lv = getVecField(mod, 'liftVector', []);
        if(numel(lv) == 3 && norm(lv) > 0)
            lp.storedLiftVector = lv(:) / norm(lv);
        end
    end
    if(~isempty(db) && isfield(db, 'isControl') && db.isControl)
        lp.isControl = true;
    end
    if(hasLift && warnDeflDefault)
        notes{end+1} = sprintf(['No lift coefficient for "%s" in craft or part database; ' ...
            'using KSP default 1.5. Pass a GameData partDB for live values.'], baseName);
    end
    if(hasLift && lp.nodeEnabled && ~nodeAttached(rawPart, lp.attachNodeName))
        % KSP node gate: lift requires the named node attached.
        lp.deflectionLiftCoeff = 0;
        notes{end+1} = sprintf('Lifting node "%s" of "%s" is unattached; module inert.', ...
            lp.attachNodeName, baseName);
    end
end

function tf = nodeAttached(rawPart, nodeName)
%nodeAttached True when the named attach node targets a real part.

    tf = false;
    if(isempty(nodeName))
        return;
    end
    nodes = kwt_parseAttachNodes(rawPart);
    for(n = nodes.stack)
        if(strcmpi(n.id, nodeName) && ~isempty(n.target))
            tf = true;
            return;
        end
    end
end

function axis = pickAxis(mod, craftKey, db, dbField, defaultVal)
%pickAxis Craft key -> GameData X/Y/Z -> default.

    axis = defaultVal;
    if(isfield(mod, craftKey))
        raw = mod.(craftKey);
        if(iscell(raw))
            raw = raw{end};
        end
        if(ischar(raw))
            d = upper(strtrim(raw));
            if(any(strcmp(d, {'X', 'Y', 'Z'})))
                axis = d;
                return;
            end
        end
    end
    if(~isempty(db) && isfield(db, dbField) && ischar(db.(dbField)))
        d = upper(strtrim(db.(dbField)));
        if(any(strcmp(d, {'X', 'Y', 'Z'})))
            axis = d;
        end
    end
end

function [v, usedDefault] = pickNum(mod, craftKey, db, dbField, defaultVal)
%pickNum Craft key (when present) -> GameData finite value -> default.
%usedDefault is true only when defaultVal was taken.

    usedDefault = false;
    if(isfield(mod, craftKey))
        raw = mod.(craftKey);
        if(iscell(raw))
            raw = raw{end};
        end
        if(ischar(raw))
            n = str2double(strtrim(raw));
            if(isfinite(n))
                v = n;
                return;
            end
        elseif(isnumeric(raw) && isscalar(raw) && isfinite(raw))
            v = double(raw);
            return;
        end
    end
    if(~isempty(db) && isfield(db, dbField))
        n = double(db.(dbField));
        if(isscalar(n) && isfinite(n))
            v = n;
            return;
        end
    end
    v = defaultVal;
    usedDefault = true;
end

function v = pickBool(mod, craftKey, db, dbField, defaultVal)
%pickBool Craft key -> GameData finite flag -> KSP default (logical).

    if(isfield(mod, craftKey))
        raw = mod.(craftKey);
        if(iscell(raw))
            raw = raw{end};
        end
        if(ischar(raw))
            s = lower(strtrim(raw));
            if(any(strcmp(s, {'true', '1', 'yes'})))
                v = true;
                return;
            elseif(any(strcmp(s, {'false', '0', 'no'})))
                v = false;
                return;
            end
        elseif(islogical(raw) && isscalar(raw))
            v = raw;
            return;
        elseif(isnumeric(raw) && isscalar(raw))
            v = raw ~= 0;
            return;
        end
    end
    if(~isempty(db) && isfield(db, dbField))
        n = double(db.(dbField));
        if(isscalar(n) && isfinite(n))
            v = n ~= 0;
            return;
        end
    end
    v = defaultVal;
end

function s = pickStr(mod, craftKey, db, dbField, defaultVal)
%pickStr Craft key -> GameData non-empty string -> default.

    if(isfield(mod, craftKey))
        raw = mod.(craftKey);
        if(iscell(raw))
            raw = raw{end};
        end
        if(ischar(raw) && ~isempty(strtrim(raw)))
            s = strtrim(raw);
            return;
        end
    end
    if(~isempty(db) && isfield(db, dbField) && ischar(db.(dbField)) ...
            && ~isempty(strtrim(db.(dbField))))
        s = strtrim(db.(dbField));
        return;
    end
    s = defaultVal;
end

function db = dbLiftSurf(opts, baseName)
%dbLiftSurf Looks up the partDB liftingSurface record with the same
%dot/underscore-tolerant matching as lvd_import_analyzeCraft.

    db = [];
    if(~isfield(opts, 'partDB') || isempty(opts.partDB) ...
            || ~isfield(opts.partDB, 'parts'))
        return;
    end
    map = opts.partDB.parts;
    candidates = {lower(baseName), ...
        lower(strrep(baseName, '.', '_')), ...
        lower(strrep(baseName, '_', '.'))};
    for(c = 1:numel(candidates))
        if(isKey(map, candidates{c}))
            entry = map(candidates{c});
            if(isstruct(entry) && isfield(entry, 'liftingSurface'))
                db = entry.liftingSurface;
            end
            return;
        end
    end
end

function liftVec = defaultLiftVector(liftParams, baseName, opts)
    if(isfield(liftParams, 'storedLiftVector'))
        liftVec = liftParams.storedLiftVector;
        return;
    end
    if(isfield(opts, 'liftVectorOverrides') ...
            && isa(opts.liftVectorOverrides, 'containers.Map') ...
            && isKey(opts.liftVectorOverrides, lower(baseName)))
        liftVec = double(opts.liftVectorOverrides(lower(baseName)));
        liftVec = liftVec(:) / max(norm(liftVec), eps);
        return;
    end
    % KSP rule (ModuleLiftingSurface.transformDir/Sign, SetupCoefficients):
    % the part-model axis in part-local frame (default +Z). Verified
    % against the KWT fin group (transformDir default) and the pod group
    % (Y/-1 from its cfg) independently, 2026-09-26.
    axis = [0; 0; 1];
    if(isfield(liftParams, 'transformDir'))
        switch upper(liftParams.transformDir)
            case 'X'
                axis = [1; 0; 0];
            case 'Y'
                axis = [0; 1; 0];
        end
    end
    sgn = 1;
    if(isfield(liftParams, 'transformSign') && liftParams.transformSign < 0)
        sgn = -1;
    end
    liftVec = sgn * axis;
end

function cube = zeroCube()
    cube = struct('cubeName', 'Zero', 'faces', zeros(6, 3), ...
        'center', [0 0 0], 'size', [0 0 0]);
end

function h = hashSpec(spec)
    tokens = cell(1, numel(spec.parts));
    for(i = 1:numel(spec.parts))
        tokens{i} = sprintf('%s@%s', spec.parts(i).instanceID, spec.parts(i).cubeName);
    end
    h = sprintf('%s|', tokens{:});
    h = sprintf('n%d-md5na-%d', numel(tokens), sum(double(h)));
end

function v = getOpt(opts, name, defaultVal)
    if(isfield(opts, name) && ~isempty(opts.(name)))
        v = opts.(name);
    else
        v = defaultVal;
    end
end

function s = getStrField(node, field, defaultVal)
    s = defaultVal;
    if(isfield(node, field))
        v = node.(field);
        if(ischar(v))
            s = v;
        elseif(iscell(v) && ~isempty(v) && ischar(v{1}))
            s = v{1};
        end
    end
end

function v = getVecField(node, field, defaultVal)
    if(nargin < 3)
        defaultVal = [];
    end
    v = defaultVal;
    if(~isfield(node, field))
        return;
    end
    raw = node.(field);
    if(iscell(raw))
        raw = raw{end};
    end
    if(ischar(raw))
        nums = sscanf(strrep(raw, ',', ' '), '%f');
        if(~isempty(nums))
            v = nums(:)';
        end
    elseif(isnumeric(raw))
        v = double(raw(:)');
    end
end

function x = getNumField(node, field, defaultVal)
    x = defaultVal;
    if(~isfield(node, field))
        return;
    end
    raw = node.(field);
    if(iscell(raw))
        raw = raw{end};
    end
    if(ischar(raw))
        v = str2double(strtrim(raw));
        if(isfinite(v))
            x = v;
        end
    elseif(isnumeric(raw) && isscalar(raw))
        x = double(raw);
    end
end

function baseName = stripFlightID(instanceID)
    tokens = strsplit(instanceID, '_');
    if(numel(tokens) >= 2 && ~isempty(regexp(tokens{end}, '^\d+$', 'once')))
        baseName = strjoin(tokens(1:end-1), '_');
    else
        baseName = instanceID;
    end
end
