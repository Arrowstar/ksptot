function [tables, files] = kwt_sweepCraft(spec, phys, opts)
%kwt_sweepCraft Sweeps (Mach, AoA, sideslip) and writes LVD table CSVs.
%
%   [tables, files] = kwt_sweepCraft(spec, phys)
%   [tables, files] = kwt_sweepCraft(spec, phys, opts)
%
%   SPEC is a kwt_buildAeroSpec struct, PHYS a kwt_physicsGlobals struct.
%   OPTS (optional struct):
%       .machVec      - Mach grid (default transonic-clustered
%                       [0 0.2 0.4 0.6 0.8 0.85 0.9 1 1.1 1.4 2 3 5])
%       .aoaDegVec    - AoA grid in deg (default -30:5:30)
%       .sideslipDegVec - sideslip grid in deg (default -15:5:15)
%       .pitchInput   - baked control deflection [-1,1] (default 0;
%                       stamped into the table; regen per trim)
%       .outDir       - folder for CSV output (default '' = no files)
%       .dragFileName - drag CSV name (default '<spec>_KwtDrag.csv')
%       .liftFileName - lift CSV name (default '<spec>_KwtLift.csv')
%%       .quiet        - true to suppress progress prints (default false)
%       .onProgress   - function handle called as onProgress(fraction,
%                       message) with fraction in [0,1] after every
%                       (AoA, sideslip) sweep column (optional; UI
%                       progress dialogs). Errors inside the callback are
%                       ignored.
%
%   TABLES holds .mach/.aoaDeg/.sideslipDeg grid vectors, .ClS,
%   .dragCubeCdA, .otherDragCdA (nMach x nAoa x nSs), .configHash,
%   .pitchInput, .craftName. Coefficients use Q = 1 kPa implicitly and
%   exclude the Reynolds correction (applied at runtime by
%   KosDragCoeffientModel), matching the existing CSV dialects:
%       drag: mach,aoa_deg,sideslip_deg,dragCubeCdA,otherDragCdA
%       lift: mach,aoa_deg,sideslip_deg,ClS_m2
%   Rows are emitted sideslip-major / AoA-middle / Mach-inner, the exact
%   order createGriddedInterpFromFile's sortrows+reshape expects, so the
%   files load into KosDragCoeffientModel / UserTabulatedLiftModel
%   without reordering surprises.
%
%   Grid cost is nMach*nAoa*nSs vessel evaluations (each a per-part curve
%   evaluation, no meshing); the default 13*13*7 = 1183 points run in
%   seconds. Mach carries the shocks -- spend resolution there (grid
%   strategy per KWT_Lift_Methodology section 7.3; roll axis deferred to
%   the 4D follow-up).
%
%   See also: kwt_aero, kwt_inflowFromAeroAngles,
%   lvd_generateAeroTablesFromCraft.

    if(nargin < 3)
        opts = struct();
    end
    machVec = getOpt(opts, 'machVec', ...
        [0 0.2 0.4 0.6 0.8 0.85 0.9 1 1.1 1.4 2 3 5]);
    aoaDeg = getOpt(opts, 'aoaDegVec', -30:5:30);
    ssDeg = getOpt(opts, 'sideslipDegVec', -15:5:15);
    pitchInput = getOpt(opts, 'pitchInput', 0);
    outDir = getOpt(opts, 'outDir', '');
    quiet = getOpt(opts, 'quiet', false);
    onProgress = getOpt(opts, 'onProgress', []);
    if(~isa(onProgress, 'function_handle'))
        onProgress = [];
    end
    reportProgress = @(frac, msg) report(onProgress, frac, msg);

    machVec = unique(double(machVec(:)'));
    aoaDeg = unique(double(aoaDeg(:)'));
    ssDeg = unique(double(ssDeg(:)'));

    nM = numel(machVec);
    nA = numel(aoaDeg);
    nS = numel(ssDeg);

    ClS = zeros(nM, nA, nS);
    cubeA = zeros(nM, nA, nS);
    otherA = zeros(nM, nA, nS);

    totalCols = nA * nS;
    for(s = 1:nS)
        for(a = 1:nA)
            vHat = kwt_inflowFromAeroAngles(deg2rad(aoaDeg(a)), deg2rad(ssDeg(s)));
            for(m = 1:nM)
                out = kwt_aero(spec, phys, vHat, machVec(m), 1, 1, pitchInput);
                ClS(m, a, s) = out.ClS;
                cubeA(m, a, s) = out.dragCubeCdA;
                otherA(m, a, s) = out.otherDragCdA;
            end
            reportProgress(((s-1)*nA + a)/totalCols, ...
                sprintf('Swept AoA %d/%d, sideslip %d/%d.', a, nA, s, nS));
        end
        if(~quiet)
            fprintf('kwt_sweepCraft: sideslip %g/%d complete.\n', s, nS);
        end
    end

    tables = struct();
    tables.mach = machVec(:);
    tables.aoaDeg = aoaDeg(:);
    tables.sideslipDeg = ssDeg(:);
    tables.ClS = ClS;
    tables.dragCubeCdA = cubeA;
    tables.otherDragCdA = otherA;
    if(isfield(spec, 'configHash'))
        tables.configHash = spec.configHash;
    else
        tables.configHash = '';
    end
    tables.pitchInput = pitchInput;
    if(isfield(spec, 'name'))
        tables.craftName = spec.name;
    else
        tables.craftName = '';
    end

    files = struct('dragCsv', '', 'liftCsv', '');
    if(~isempty(outDir))
        if(~isfolder(outDir))
            mkdir(outDir);
        end
        base = sanitizeFilename(tables.craftName);
        if(isempty(base))
            base = 'craft';
        end
        dragName = getOpt(opts, 'dragFileName', sprintf('%s_KwtDrag.csv', base));
        liftName = getOpt(opts, 'liftFileName', sprintf('%s_KwtLift.csv', base));
        files.dragCsv = fullfile(outDir, dragName);
        files.liftCsv = fullfile(outDir, liftName);
        writeDragCsv(files.dragCsv, tables);
        writeLiftCsv(files.liftCsv, tables);
    end
end

function writeDragCsv(path, t)
    nM = numel(t.mach); nA = numel(t.aoaDeg); nS = numel(t.sideslipDeg);
    rows = zeros(nM * nA * nS, 5);
    r = 0;
    for(s = 1:nS)
        for(a = 1:nA)
            for(m = 1:nM)
                r = r + 1;
                rows(r, :) = [t.mach(m), t.aoaDeg(a), t.sideslipDeg(s), ...
                    t.dragCubeCdA(m, a, s), t.otherDragCdA(m, a, s)];
            end
        end
    end
    writematrix(rows, path);
end

function writeLiftCsv(path, t)
    nM = numel(t.mach); nA = numel(t.aoaDeg); nS = numel(t.sideslipDeg);
    rows = zeros(nM * nA * nS, 4);
    r = 0;
    for(s = 1:nS)
        for(a = 1:nA)
            for(m = 1:nM)
                r = r + 1;
                rows(r, :) = [t.mach(m), t.aoaDeg(a), t.sideslipDeg(s), ...
                    t.ClS(m, a, s)];
            end
        end
    end
    writematrix(rows, path);
end

function v = getOpt(opts, name, defaultVal)
    if(isfield(opts, name) && ~isempty(opts.(name)))
        v = opts.(name);
    else
        v = defaultVal;
    end
end

function report(onProgress, frac, msg)
    %report Fires the optional progress callback; callback errors must
    %never break a sweep the user is watching.
    if(isempty(onProgress))
        return;
    end
    try
        onProgress(min(max(frac, 0), 1), msg);
    catch
    end
end

function s = sanitizeFilename(name)
    s = regexprep(name, '[^\w\-\. ]', '');
    s = strtrim(s);
    s = strrep(s, ' ', '_');
    if(numel(s) > 80)
        s = s(1:80);
    end
end
