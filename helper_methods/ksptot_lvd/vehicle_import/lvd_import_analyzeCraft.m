function [spec, report] = lvd_import_analyzeCraft(craftSource, partDB)
%lvd_import_analyzeCraft Analyzes a KSP .craft file into an intermediate
%launch vehicle specification for LVD import.
%
%   [spec, report] = lvd_import_analyzeCraft(craftPathOrText, partDB)
%
%   craftSource is either a path to a .craft file or its raw text (it is
%   passed through sfsParse). partDB is a database from
%   lvd_import_getPartDatabase().
%
%   SPEC is a plain-data struct describing inferred stages, ordered from
%   first to burn:
%       .name            vessel name from the craft header
%       .stages(k)
%           .name          'Stage k'
%           .dryMass_mT    structural/deadweight mass (metric tons)
%           .engines(e)    .name/.partName/.instanceID/.vacThrust_kN/
%                          .ispVac_s/.ispSL_s/.minThrottle/.maxThrottle/
%                          .propellants
%           .tanks(t)      .name/.partName/.instanceID/.fluidTypeName/
%                          .propMass_mT/.resourceMasses_mT (struct)
%           .e2tConns(r)   struct .engineIdx/.tankIdx (indices into this
%                          stage's engines/tanks arrays)
%       .t2tConns(r)     .srcStageIdx/.srcTankIdx/.tgtStageIdx/.tgtTankIdx/
%                        .flowRate_mTs (crossfeed/asparagus via fuel lines)
%       .warnings        cellstr of inference issues
%       .stats           .glow_mT/.totalDryMass_mT/.totalPropMass_mT/
%                        .numStages/.numEngines/.numTanks
%
%   REPORT adds diagnostics detail:
%       .partInventory   struct array (.instanceID/.baseName/roles/.stage)
%       .unresolvedParts cellstr of part names missing from the database
%
%   Inference model:
%       - Parts form a tree from "link" entries. Decouplers split the tree
%         into hardware segments; a part's drop staging index (the istg of
%         the decoupler separating it) determines when it leaves the
%         vessel. Stack decouplers are carried away with the deeper side;
%         radial decouplers stay with their parent side.
%       - Engines ignite at their own istg. Stages are keyed by
%         (ignition group, drop order), sorted so earlier-burning,
%         earlier-dropping groups come first.
%       - Radial clusters feeding the core through fuelLine parts become
%         tank-to-tank crossfeed connections (asparagus staging).
%       - Stage dry mass sums part dry masses; propellant mass lives in
%         tanks.

    if(isstruct(craftSource))
        craft = craftSource;
    else
        craft = sfsParse(craftSource);
    end

    g0 = 9.80665;
    warnings = {};

    %------------------------------------------------------------------
    % 1) Collect part instances
    %------------------------------------------------------------------
    if(~isfield(craft, 'PART'))
        error('lvd_import:noParts', 'Craft file contains no PART blocks.');
    end

    numParts = numel(craft.PART);
    inst = struct.empty(0, 0);
    idToIdx = containers.Map('KeyType', 'char', 'ValueType', 'double');
    unresolved = {};

    for(i = 1:numParts)
        rawPart = craft.PART{i};

        rec = blankInstance();
        rec.instanceID = getStrField(rawPart, 'part', sprintf('PART_%d', i));
        rec.baseName = stripFlightID(rec.instanceID);

        rec.istg = getNumField(rawPart, 'istg', -1);
        rec.dstg = getNumField(rawPart, 'dstg', -1);
        rec.sepI = getNumField(rawPart, 'sepI', -1);

        key = lower(rec.baseName);
        if(isKey(partDB.parts, key))
            rec.db = partDB.parts(key);
        else
            rec.db = blankDbEntry(rec.baseName);
            unresolved{end+1} = rec.baseName; %#ok<AGROW>
            warnings{end+1} = sprintf(['Unknown part "%s" not found in the ' ...
                'part database; imported with zero mass and no functions.'], ...
                rec.baseName); %#ok<AGROW>
        end

        rec = classifyInstance(rec);
        if(rec.isJetSkipped)
            warnings{end+1} = sprintf(['Jet engine part "%s" (IntakeAir ' ...
                'propellant) imported as deadweight only.'], ...
                rec.baseName); %#ok<AGROW>
        end
        if(rec.isEngine && numel(rec.db.engines) > 1)
            warnings{end+1} = sprintf(['Part "%s" has multiple engine ' ...
                'modes; using its highest-thrust mode.'], ...
                rec.baseName); %#ok<AGROW>
        end

        if(rec.isFuelLine)
            rec.fuelLineTarget = findFuelLineTarget(rawPart);
            if(isempty(rec.fuelLineTarget))
                warnings{end+1} = sprintf(['Fuel line part "%s" has no ' ...
                    'recognizable target field; ignoring.'], ...
                    rec.instanceID); %#ok<AGROW>
            end
        end

        inst = pushStruct(inst, rec);
        idToIdx(rec.instanceID) = i;
    end

    %------------------------------------------------------------------
    % 2) Tree structure from "link" entries
    %------------------------------------------------------------------
    hasParent = false(1, numel(inst));
    parentIdx = zeros(1, numel(inst));

    for(i = 1:numel(inst))
        links = getMultiStrField(craft.PART{i}, 'link');
        for(l = 1:numel(links))
            if(~isempty(links{l}) && isKey(idToIdx, links{l}))
                childIdx = idToIdx(links{l});
                if(childIdx ~= i)
                    inst(i).childIdx(end+1) = childIdx; %#ok<AGROW>
                    hasParent(childIdx) = true;
                    parentIdx(childIdx) = i;
                end
            end
        end
    end

    rootCandidates = find(~hasParent);
    if(isempty(rootCandidates))
        error('lvd_import:noRoot', ...
            'Could not determine a root part (attachment cycle?).');
    end
    if(numel(rootCandidates) > 1)
        warnings{end+1} = sprintf(['Craft has %d disconnected sections; ' ...
            'all sections are imported as separate segments.'], ...
            numel(rootCandidates)); %#ok<AGROW>
    end

    %------------------------------------------------------------------
    % 3) Depth (segment) + drop-staging propagation from each root
    %------------------------------------------------------------------
    visited = false(1, numel(inst));
    for(r = reshape(rootCandidates, 1, []))
        [inst, visited] = assignTreeMetrics(inst, r, 0, Inf, visited);
    end

    % Anything unvisited (cycles): treat as its own root-level segment.
    for(u = reshape(find(~visited), 1, []))
        [inst, visited] = assignTreeMetrics(inst, u, 0, Inf, visited);
    end

    %------------------------------------------------------------------
    % 4) Ignition groups and stage keys
    %------------------------------------------------------------------
    engineFlags = [inst.isEngine];
    if(any(engineFlags))
        allIgnitions = unique([inst(engineFlags).igniteIstg]);
        allIgnitions = allIgnitions(allIgnitions >= 0);
    else
        allIgnitions = [];
    end

    if(any(engineFlags & [inst.igniteIstg] < 0))
        maxKnownIgnition = max([max(allIgnitions), 0]);
        for(i = find(engineFlags & [inst.igniteIstg] < 0))
            inst(i).igniteIstg = fallbackIgnition(inst(i), maxKnownIgnition);
            warnings{end+1} = sprintf(['Engine part "%s" has no staging ' ...
                'index; assigned to its section''s latest burn group.'], ...
                inst(i).baseName); %#ok<AGROW>
        end
        allIgnitions = unique([allIgnitions, ...
                               inst(engineFlags).igniteIstg]);
    end

    if(isempty(allIgnitions))
        warnings{end+1} = ['No staged engines detected; importing as a ' ...
            'single stage.']; %#ok<AGROW>
        allIgnitions = 0;
    end
    maxIgnition = max(allIgnitions);

    for(i = 1:numel(inst))
        [inst(i).keyA, inst(i).keyB] = computeStageKey( ...
            inst(i).isEngine, inst(i).igniteIstg, inst(i).dropIstg, ...
            allIgnitions, maxIgnition);
    end

    %------------------------------------------------------------------
    % 5) Group instances into ordered stages
    %------------------------------------------------------------------
    keysAB = [[inst.keyA]; [inst.keyB]]';
    uniqueKeys = unique(keysAB, 'rows');

    stageOfInst = zeros(1, numel(inst));
    stageMembers = cell(1, size(uniqueKeys, 1));

    for(s = 1:size(uniqueKeys, 1))
        kRow = uniqueKeys(s, :);
        members = find(keysAB(:, 1) == kRow(1) & keysAB(:, 2) == kRow(2));
        stageMembers{s} = members;
        stageOfInst(members) = s;
    end

    %------------------------------------------------------------------
    % 6) Fluid grouping and propellant masses per instance
    %------------------------------------------------------------------
    densities = partDB.resourceDensities;

    for(i = 1:numel(inst))
        [inst(i).fluidGroup, inst(i).propMass_mT, inst(i).resMasses_mT] = ...
            summarizeResources(inst(i).db.resources_u, densities);
    end

    %------------------------------------------------------------------
    % 7) Merge propulsion-less stages forward, then emit spec.stages
    %------------------------------------------------------------------
    [stageMembers, stageOfInst] = mergeEmptyStages(stageMembers, stageOfInst, inst);

    spec = struct();
    spec.name = getStrField(craft, 'ship', 'Imported Craft');
    spec.warnings = warnings;
    spec.stages = struct.empty(0, 0);

    unfedEngines = {};

    for(s = 1:numel(stageMembers))
        [stg, stgUnfed] = buildSpecStage(stageMembers{s}, inst);
        stg.name = sprintf('Stage %d', s);
        spec.stages = pushStruct(spec.stages, stg);
        unfedEngines = [unfedEngines, stgUnfed]; %#ok<AGROW>
    end

    if(~isempty(unfedEngines))
        spec.warnings{end+1} = sprintf(['No compatible tank found for ' ...
            'engine(s): %s. Connect tanks manually after import.'], ...
            strjoin(unique(unfedEngines), ', ')); %#ok<AGROW>
    end

    %------------------------------------------------------------------
    % 8) Fuel-line crossfeed (asparagus) connections
    %------------------------------------------------------------------
    spec.t2tConns = struct.empty(0, 0);

    for(i = 1:numel(inst))
        if(~inst(i).isFuelLine || isempty(inst(i).fuelLineTarget))
            continue;
        end

        % A fuel line runs from its parent part to its target part; both
        % must be propellant tanks for a crossfeed connection.
        srcIdx = parentIdx(i);

        tgtIdx = 0;
        if(isKey(idToIdx, inst(i).fuelLineTarget))
            tgtIdx = idToIdx(inst(i).fuelLineTarget);
        end

        if(srcIdx == 0 || tgtIdx == 0 || ...
           inst(srcIdx).propMass_mT <= 0 || inst(tgtIdx).propMass_mT <= 0)
            warnings{end+1} = sprintf(['Fuel line on "%s" could not be ' ...
                'mapped between propellant tanks; ignoring.'], ...
                inst(i).baseName); %#ok<AGROW>
            continue;
        end

        [srcStageIdx, srcTankIdx] = findTankSlot(spec, inst(srcIdx).instanceID);
        [tgtStageIdx, tgtTankIdx] = findTankSlot(spec, inst(tgtIdx).instanceID);

        if(srcTankIdx == 0 || tgtTankIdx == 0)
            continue;
        end

        conn = struct();
        conn.srcStageIdx = srcStageIdx;
        conn.srcTankIdx = srcTankIdx;
        conn.tgtStageIdx = tgtStageIdx;
        conn.tgtTankIdx = tgtTankIdx;
        conn.flowRate_mTs = estimateFlowRate(tgtIdx, inst, stageOfInst, g0);

        spec.t2tConns = pushStruct(spec.t2tConns, conn);
    end

    %------------------------------------------------------------------
    % 9) Summary statistics + report
    %------------------------------------------------------------------
    totalDry = sum([spec.stages.dryMass_mT]);
    totalProp = 0;
    numEngines = 0;
    numTanks = 0;
    for(s = 1:numel(spec.stages))
        if(numel(spec.stages(s).tanks) > 0)
            totalProp = totalProp + sum([spec.stages(s).tanks.propMass_mT]);
        end
        numEngines = numEngines + numel(spec.stages(s).engines);
        numTanks = numTanks + numel(spec.stages(s).tanks);
    end

    stats = struct();
    stats.glow_mT = totalDry + totalProp;
    stats.totalDryMass_mT = totalDry;
    stats.totalPropMass_mT = totalProp;
    stats.numStages = numel(spec.stages);
    stats.numEngines = numEngines;
    stats.numTanks = numTanks;
    spec.stats = stats;

    report = struct();
    report.unresolvedParts = unique(unresolved);

    inventory = struct.empty(0, 0);
    for(i = 1:numel(inst))
        invRec = struct();
        invRec.instanceID = inst(i).instanceID;
        invRec.baseName = inst(i).baseName;
        invRec.rolesSummary = strjoin(inst(i).db.roles, '/');
        invRec.stageNum = stageOfInst(i);
        inventory = pushStruct(inventory, invRec);
    end
    report.partInventory = inventory;

end

%==========================================================================
% Instance helpers
%==========================================================================

function rec = blankInstance()
    rec = struct();
    rec.instanceID = '';
    rec.baseName = '';
    rec.istg = -1;
    rec.dstg = -1;
    rec.sepI = -1;
    rec.db = [];
    rec.isEngine = false;
    rec.engineSpec = [];
    rec.engineModeCount = 0;
    rec.isJetSkipped = false;
    rec.isStackDec = false;
    rec.isRadialDec = false;
    rec.isFuelLine = false;
    rec.fuelLineTarget = '';
    rec.childIdx = [];
    rec.depth = 0;
    rec.dropIstg = Inf;
    rec.igniteIstg = -1;
    rec.keyA = 0;
    rec.keyB = 0;
    rec.fluidGroup = '';
    rec.propMass_mT = 0;
    rec.resMasses_mT = struct();
end

function entry = blankDbEntry(name)
    entry = struct();
    entry.name = name;
    entry.title = name;
    entry.mass_t = 0;
    entry.roles = {'unknown'};
    entry.resources_u = struct();
    entry.engines = struct.empty(0, 0);
end

function rec = classifyInstance(rec)
%classifyInstance Marks role flags based on database roles/engines.
% NOTE: rec is a value struct; callers must reassign the result.

    roles = lower(rec.db.roles);

    engines = rec.db.engines;
    rec.engineModeCount = numel(engines);

    intakeAirMask = false(1, numel(engines));
    for(e = 1:numel(engines))
        intakeAirMask(e) = any(strcmpi(engines(e).propellants, 'IntakeAir'));
    end

    usableEngines = engines(~intakeAirMask);

    if(~isempty(usableEngines))
        rec.isEngine = true;
        [~, bestInd] = max([usableEngines.maxThrust_kN]);
        rec.engineSpec = usableEngines(bestInd);
        rec.igniteIstg = rec.istg;
    elseif(numel(engines) > 0)
        rec.isJetSkipped = true;
    end

    rec.isStackDec = any(strcmpi(roles, 'decoupler')) || ...
                     any(strcmpi(roles, 'separator'));
    rec.isRadialDec = any(strcmpi(roles, 'radialDecoupler'));
    rec.isFuelLine = any(strcmpi(roles, 'fuelLine'));

end

function target = findFuelLineTarget(rawPart)
%findFuelLineTarget Scans a fuel-line part block for a plausible target
%key holding another part's full instance ID.

    target = '';

    candidates = {'target', 'trf', 'targetID', 'srcUid'};
    fieldNames = fieldnames(rawPart);

    for(f = 1:numel(fieldNames))
        if(any(strcmpi(fieldNames{f}, candidates)))
            val = getRawField(rawPart, fieldNames{f});
            if(~isempty(val))
                target = val;
                return;
            end
        end
    end

end

function [inst, visited] = assignTreeMetrics(inst, rootIdx, startDepth, ...
                                             startDropIstg, visited)
%assignTreeMetrics Iterative DFS assigning depth and dropIstg.
%
% Decoupler handling:
%   - both decoupler kinds keep their PARENT-side drop index themselves
%     (they stay attached to the keeping side), while everything beyond
%     them is one segment deeper and drops at the decoupler's istg
% A decoupler whose istg < 0 never fires in staging, so it does not set a
% new drop index (parts beyond it inherit the upstream drop index).

    stackIdx = rootIdx;
    stackDepth = startDepth;
    stackDrop = startDropIstg;

    while(~isempty(stackIdx))
        idx = stackIdx(end);
        depth = stackDepth(end);
        drop = stackDrop(end);
        stackIdx(end) = [];
        stackDepth(end) = [];
        stackDrop(end) = [];

        if(visited(idx))
            continue;
        end
        visited(idx) = true;

        inst(idx).depth = depth;
        inst(idx).dropIstg = drop;

        nextDepth = depth;
        nextDrop = drop;

        if(inst(idx).isStackDec || inst(idx).isRadialDec)
            nextDepth = depth + 1;
            if(inst(idx).istg >= 0)
                nextDrop = inst(idx).istg;
            end
        end

        for(c = reshape(inst(idx).childIdx, 1, []))
            stackIdx(end+1) = c; %#ok<AGROW>
            stackDepth(end+1) = nextDepth; %#ok<AGROW>
            stackDrop(end+1) = nextDrop; %#ok<AGROW>
        end
    end

end

function [keyA, keyB] = computeStageKey(isEngine, igniteIstg, dropIstg, ...
                                        allIgnitions, maxIgnition)
%computeStageKey Assigns the (ignition group, drop order) sort key.
% Higher keyA/keyB sorts earlier (burns first, drops first).

    if(isEngine)
        keyA = -igniteIstg;
    else
        % Staging events fire in DESCENDING istg order, so a part takes
        % part in every burn ignited strictly before its own separation
        % event; it rides along with the EARLIEST-burning of those groups
        % (payload that never separates ends up in the final stage).
        attached = allIgnitions(isinf(dropIstg) | allIgnitions > dropIstg);
        if(isempty(attached))
            keyA = -maxIgnition;
        else
            keyA = -min(attached);
        end
    end

    if(isinf(dropIstg))
        keyB = realmax;
    else
        keyB = -dropIstg;
    end

end

function ignite = fallbackIgnition(rec, maxIgnition)
    if(isfinite(rec.dropIstg) && rec.dropIstg >= 0)
        ignite = min(rec.dropIstg, maxIgnition);
    else
        ignite = maxIgnition;
    end
end

function [fluidGroup, propMass, breakdown] = summarizeResources(resourcesU, densities)
%summarizeResources Maps a part's stored resources onto one LVD fluid
%group (mixed-resource parts resolve to their heaviest group).

    fluidGroup = '';
    propMass = 0;
    breakdown = struct();

    resFields = fieldnames(resourcesU);
    groupNames = {};
    groupMasses = [];

    for(f = 1:numel(resFields))
        resName = resFields{f};
        units = resourcesU.(resName);

        dens = 0;
        if(isKey(densities, resName))
            dens = densities(resName);
        end

        mass = units * dens;
        breakdown.(resName) = mass;

        if(mass <= 0)
            continue;
        end

        grp = fluidGroupForResource(resName);
        grpInd = find(strcmp(groupNames, grp), 1);
        if(isempty(grpInd))
            groupNames{end+1} = grp; %#ok<AGROW>
            groupMasses(end+1) = mass; %#ok<AGROW>
        else
            groupMasses(grpInd) = groupMasses(grpInd) + mass;
        end
    end

    if(isempty(groupNames))
        return;
    end

    [~, bestGrp] = max(groupMasses);
    fluidGroup = groupNames{bestGrp};
    propMass = groupMasses(bestGrp);

    % Zero-out resources outside the chosen group to prevent downstream
    % double counting.
    for(f = 1:numel(resFields))
        resName = resFields{f};
        if(breakdown.(resName) > 0 && ...
           ~strcmp(fluidGroupForResource(resName), fluidGroup))
            propMass = propMass - breakdown.(resName);
            breakdown.(resName) = 0;
        end
    end

end

function grp = fluidGroupForResource(resName)
    switch(resName)
        case 'SolidFuel'
            grp = 'Solid Fuel';
        case 'MonoPropellant'
            grp = 'Monopropellant';
        case 'XenonGas'
            grp = 'Xenon';
        otherwise
            % LiquidFuel/Oxidizer combos (and unknowns) -> standard group
            grp = 'Liquid Fuel/Ox';
    end
end

function [stageMembers, stageOfInst] = mergeEmptyStages(stageMembers, ...
                                                        stageOfInst, inst)
%mergeEmptyStages Folds stages containing neither engines nor tanks into
%an adjacent stage so they still contribute their dry mass.

    for(s = numel(stageMembers):-1:1)
        members = reshape(stageMembers{s}, 1, []);
        hasProp = any(arrayfun(@(m) inst(m).propMass_mT > 0, members));
        hasEng = any(arrayfun(@(m) inst(m).isEngine, members));

        if(hasProp || hasEng || numel(stageMembers) == 1)
            continue;
        end

        if(s < numel(stageMembers))
            targetS = s + 1;
        else
            targetS = s - 1;
        end

        stageMembers{targetS} = [reshape(stageMembers{targetS}, 1, []), ...
                                 members];
        stageOfInst(members) = targetS;

        stageMembers(s) = [];
        stageOfInst(stageOfInst > s) = stageOfInst(stageOfInst > s) - 1;
    end

end

function [stg, unfedEngineNames] = buildSpecStage(members, inst)
%buildSpecStage Emits one spec stage: engines, tanks, dry mass, E2T conns.

    stg = struct();
    stg.engines = struct.empty(0, 0);
    stg.tanks = struct.empty(0, 0);
    stg.e2tConns = struct.empty(0, 0);
    unfedEngineNames = {};

    engineInstIndices = [];

    % Count duplicate part titles for unique engine/tank naming.
    titleCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for(m = reshape(members, 1, []))
        rec = inst(m);
        if(rec.isEngine || rec.propMass_mT > 0)
            t = lower(strtrim(rec.db.title));
            if(isKey(titleCounts, t))
                titleCounts(t) = titleCounts(t) + 1;
            else
                titleCounts(t) = 1;
            end
        end
    end

    seenTitles = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for(m = reshape(members, 1, []))
        rec = inst(m);
        baseTitle = strtrim(rec.db.title);

        if(rec.isEngine || rec.propMass_mT > 0)
            t = lower(baseTitle);
            if(isKey(seenTitles, t))
                seenTitles(t) = seenTitles(t) + 1;
            else
                seenTitles(t) = 1;
            end
            seenCount = seenTitles(t);

            if(titleCounts(t) > 1)
                itemTitle = sprintf('%s (%d)', baseTitle, seenCount);
            else
                itemTitle = baseTitle;
            end
        else
            itemTitle = baseTitle;
        end

        if(rec.isEngine)
            e = struct();
            e.name = itemTitle;
            e.partName = rec.baseName;
            e.instanceID = rec.instanceID;
            e.vacThrust_kN = rec.engineSpec.maxThrust_kN;
            e.ispVac_s = rec.engineSpec.ispVac_s;
            e.ispSL_s = rec.engineSpec.ispSL_s;
            e.minThrottle = rec.engineSpec.minThrottle;
            e.maxThrottle = rec.engineSpec.maxThrottle;
            e.propellants = rec.engineSpec.propellants;

            stg.engines = pushStruct(stg.engines, e);
            engineInstIndices(end+1) = m; %#ok<AGROW>
        end

        if(rec.propMass_mT > 0)
            t = struct();
            t.name = itemTitle;
            t.partName = rec.baseName;
            t.instanceID = rec.instanceID;
            t.fluidTypeName = rec.fluidGroup;
            t.propMass_mT = rec.propMass_mT;
            t.resourceMasses_mT = rec.resMasses_mT;

            stg.tanks = pushStruct(stg.tanks, t);
        end
    end

    % Dry mass: every part in the stage contributes its dry mass.
    dryMass = 0;
    for(m = reshape(members, 1, []))
        dryMass = dryMass + inst(m).db.mass_t;
    end
    stg.dryMass_mT = dryMass;

    % Engine-to-tank connections within the stage. An engine whose own
    % part also stores propellant (e.g., solid boosters) connects only to
    % that part's tank; otherwise it connects to every same-stage tank of
    % a compatible fluid group.
    for(e = 1:numel(engineInstIndices))
        engineRec = inst(engineInstIndices(e));
        wantedGroups = requiredFluidGroups(engineRec.engineSpec.propellants);

        selfTankIdx = 0;
        for(t = 1:numel(stg.tanks))
            if(strcmp(stg.tanks(t).instanceID, engineRec.instanceID) && ...
               any(strcmp(wantedGroups, stg.tanks(t).fluidTypeName)))
                selfTankIdx = t;
                break;
            end
        end

        if(selfTankIdx > 0)
            conn = struct();
            conn.engineIdx = e;
            conn.tankIdx = selfTankIdx;
            stg.e2tConns = pushStruct(stg.e2tConns, conn);
            continue;
        end

        connectedAny = false;
        for(t = 1:numel(stg.tanks))
            if(any(strcmp(wantedGroups, stg.tanks(t).fluidTypeName)))
                conn = struct();
                conn.engineIdx = e;
                conn.tankIdx = t;
                stg.e2tConns = pushStruct(stg.e2tConns, conn);
                connectedAny = true;
            end
        end

        if(~connectedAny && ~isempty(wantedGroups))
            unfedEngineNames{end+1} = sprintf('%s (%s)', ...
                strtrim(engineRec.db.title), engineRec.baseName); %#ok<AGROW>
        end
    end

end

function wanted = requiredFluidGroups(propellants)
%requiredFluidGroups Maps engine propellants onto tank fluid-group names.

    wanted = {};
    for(p = 1:numel(propellants))
        grp = fluidGroupForResource(propellants{p});
        if(~any(strcmp(wanted, grp)))
            wanted{end+1} = grp; %#ok<AGROW>
        end
    end

end

function [stageIdx, tankIdx] = findTankSlot(spec, instanceID)
%findTankSlot Locates a tank in the assembled spec by part instance ID.

    stageIdx = 0;
    tankIdx = 0;

    for(s = 1:numel(spec.stages))
        tanks = spec.stages(s).tanks;
        for(t = 1:numel(tanks))
            if(strcmp(tanks(t).instanceID, instanceID))
                stageIdx = s;
                tankIdx = t;
                return;
            end
        end
    end

end

function flowRate = estimateFlowRate(targetInstIdx, inst, stageOfInst, g0)
%estimateFlowRate Estimates crossfeed demand as the total vacuum mass flow
%of engines in the target tank's stage drawing the same fluid group.

    flowRate = 0;
    targetStage = stageOfInst(targetInstIdx);
    targetGroup = inst(targetInstIdx).fluidGroup;

    if(targetStage == 0 || isempty(targetGroup))
        return;
    end

    for(i = 1:numel(inst))
        if(~inst(i).isEngine || stageOfInst(i) ~= targetStage)
            continue;
        end

        wantedGroups = requiredFluidGroups(inst(i).engineSpec.propellants);
        if(~any(strcmp(wantedGroups, targetGroup)))
            continue;
        end

        isp = inst(i).engineSpec.ispVac_s;
        thrust = inst(i).engineSpec.maxThrust_kN;
        flowRate = flowRate + thrust / (g0 * isp);
    end

end

%==========================================================================
% Small utilities
%==========================================================================

function out = getStrField(nodeStruct, fieldName, defaultVal)
    out = defaultVal;
    if(isfield(nodeStruct, fieldName))
        val = nodeStruct.(fieldName);
        if(ischar(val))
            out = val;
        elseif(iscellstr(val) && ~isempty(val))
            out = val{1};
        end
    end
end

function out = getRawField(nodeStruct, fieldName)
    out = '';
    if(isfield(nodeStruct, fieldName))
        val = nodeStruct.(fieldName);
        if(ischar(val))
            out = val;
        elseif(iscellstr(val) && ~isempty(val))
            out = val{end};
        end
    end
end

function out = getMultiStrField(nodeStruct, fieldName)
    out = {''};
    if(isfield(nodeStruct, fieldName))
        val = nodeStruct.(fieldName);
        if(ischar(val))
            out = {val};
        elseif(iscellstr(val))
            out = val;
        end
    end
end

function out = getNumField(nodeStruct, fieldName, defaultVal)
    out = defaultVal;
    if(isfield(nodeStruct, fieldName))
        val = nodeStruct.(fieldName);
        if(ischar(val))
            val = str2double(val);
        end
        if(isscalar(val) && isfinite(val))
            out = double(val);
        end
    end
end


function arr = pushStruct(arr, item)
%pushStruct Appends to a possibly-empty struct array.

    if(isempty(arr))
        arr = item;
    else
        arr(end+1) = item;
    end

end

function baseName = stripFlightID(instanceID)
%stripFlightID Removes the trailing "_<flightID>" suffix KSP appends.
% Stock part internal names do not contain underscores.

    tokens = strsplit(instanceID, '_');
    if(numel(tokens) >= 2 && ~isempty(regexp(tokens{end}, '^\d+$', 'once')))
        baseName = strjoin(tokens(1:end-1), '_');
    else
        baseName = instanceID;
    end

end
