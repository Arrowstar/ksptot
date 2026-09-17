function numRows = lvd_exportEphemeris(stateLog, frame, filePath, opts)
%LVD_EXPORTEPHEMERIS Writes an LVD state log as a Cartesian ephemeris file.
%
%   numRows = lvd_exportEphemeris(stateLog, frame, filePath, opts) converts
%   every entry of the LaunchVehicleStateLog to the given reference frame
%   (the same CartesianElementSet.convertToFrame path the state readout
%   uses) and writes it to filePath.  Returns the number of data rows
%   written.
%
%   opts is an optional struct with fields (all optional):
%       format      - 'csv' (default) or 'oem'
%       stepSize    - resampling step in seconds.  Empty (default) writes
%                     the raw state-log epochs; a positive value writes a
%                     uniform grid from the first to the last epoch (the
%                     final epoch is always included), spline-interpolated
%                     inside each continuous segment.
%       includeMass - logical (default false).  CSV only: appends a total
%                     vehicle mass column (mT).
%       objectName  - OEM OBJECT_NAME (default 'LVD Vehicle')
%       bodyName    - OEM CENTER_NAME (default: the frame's origin body)
%
%   Segments: the log is split wherever the event changes or the time does
%   not advance (an action, restart, or backward-propagated event), so
%   interpolation never bridges a discontinuity.  In raw mode consecutive
%   rows that repeat the epoch and agree in state to round-off (the
%   integrator re-initialising after an action or event boundary) are
%   collapsed to one, the later segment's row winning at a boundary; rows
%   that share an epoch but differ in state (a real discontinuity) are both
%   kept.  In resampled mode a grid epoch that sits exactly on a segment
%   boundary likewise takes the state from the later segment.
%
%   CSV columns: UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms[,mass_mT],event_num
%   OEM: a minimal CCSDS OEM 2.0 style text file.  KSP has no calendar, so
%   START_TIME/STOP_TIME and the data epochs are raw UT seconds.

    arguments
        stateLog(1,1) LaunchVehicleStateLog
        frame(1,1) AbstractReferenceFrame
        filePath(1,:) char
        opts(1,1) struct = struct()
    end

    opts = applyDefaults(opts, frame);

    entries = stateLog.getAllEntries();
    chunks = buildChunks(entries, frame);

    if(isempty(opts.stepSize))
        rows = rawRows(chunks);
    else
        rows = resampledRows(chunks, opts.stepSize);
    end

    numRows = size(rows, 2);

    switch lower(opts.format)
        case 'csv'
            writeCsv(filePath, rows, opts.includeMass);

        case 'oem'
            writeOem(filePath, rows, frame, opts);

        otherwise
            error('lvd_exportEphemeris:badFormat', 'Unknown ephemeris format "%s".  Use ''csv'' or ''oem''.', opts.format);
    end
end

function opts = applyDefaults(opts, frame)
    if(not(isfield(opts, 'format')) || isempty(opts.format))
        opts.format = 'csv';
    end

    if(not(isfield(opts, 'stepSize')))
        opts.stepSize = [];
    elseif(not(isempty(opts.stepSize)))
        if(not(isscalar(opts.stepSize)) || not(isfinite(opts.stepSize)) || opts.stepSize <= 0)
            error('lvd_exportEphemeris:badStep', 'stepSize must be empty or a positive finite scalar.');
        end
    end

    if(not(isfield(opts, 'includeMass')) || isempty(opts.includeMass))
        opts.includeMass = false;
    end

    if(not(isfield(opts, 'objectName')) || isempty(opts.objectName))
        opts.objectName = 'LVD Vehicle';
    end

    if(not(isfield(opts, 'bodyName')) || isempty(opts.bodyName))
        opts.bodyName = '';
        try
            originBody = frame.getOriginBody();
            if(not(isempty(originBody)))
                opts.bodyName = originBody.name;
            end
        catch
            %frame has no single origin body; leave blank
        end

        if(isempty(opts.bodyName))
            opts.bodyName = 'UNKNOWN';
        end
    end
end

function chunks = buildChunks(entries, frame)
%buildChunks Splits the log into continuous segments and converts each to
%the output frame.  Each chunk: t (1xN), rv (6xN), mass (1xN), evtNum.
    chunks = struct('t', {}, 'rv', {}, 'mass', {}, 'evtNum', {});

    if(isempty(entries))
        return;
    end

    numEntries = numel(entries);
    startInds = 1;
    dirSign = 0;
    for(i=2:numEntries) %#ok<*NO4LP>
        dt = entries(i).time - entries(i-1).time;
        sameEvt = isSameEvent(entries(i).event, entries(i-1).event);

        newChunk = not(sameEvt) || dt == 0 || (dirSign ~= 0 && sign(dt) ~= dirSign);
        if(newChunk)
            startInds(end+1) = i; %#ok<AGROW>
            dirSign = 0;
        elseif(dirSign == 0)
            dirSign = sign(dt);
        end
    end
    endInds = [startInds(2:end) - 1, numEntries];

    for(k=1:numel(startInds))
        chunkEntries = entries(startInds(k):endInds(k));

        [t, rv, mass] = convertEntries(chunkEntries, frame);

        evtNum = NaN;
        try
            evtNum = chunkEntries(1).event.getEventNum();
            if(isempty(evtNum))
                evtNum = NaN;
            end
        catch
            %no resolvable event; keep NaN
        end

        %Sort so backward-propagated segments are still increasing in time.
        [t, I] = sort(t);
        rv = rv(:,I);
        mass = mass(I);

        chunks(end+1) = struct('t', t, 'rv', rv, 'mass', mass, 'evtNum', evtNum); %#ok<AGROW>
    end
end

function tf = isSameEvent(evtA, evtB)
    if(isempty(evtA) || isempty(evtB))
        tf = isempty(evtA) && isempty(evtB);
    else
        tf = evtA == evtB;
    end
end

function [t, rv, mass] = convertEntries(chunkEntries, frame)
%convertEntries Frame-converts a run of entries, grouping consecutive
%entries that share a central body so convertToFrame sees one source frame
%per call (it requires uniform frames within an array).
    numEntries = numel(chunkEntries);
    t = zeros(1, numEntries);
    rv = zeros(6, numEntries);
    mass = zeros(1, numEntries);

    i = 1;
    while(i <= numEntries)
        j = i;
        while(j < numEntries && chunkEntries(j+1).centralBody == chunkEntries(i).centralBody)
            j = j + 1;
        end

        groupEntries = chunkEntries(i:j);
        ce = groupEntries.getCartesianElementSetRepresentation();
        ce = ce.convertToFrame(frame);

        t(i:j) = [ce.time];
        rv(1:3, i:j) = [ce.rVect];
        rv(4:6, i:j) = [ce.vVect];

        for(m=i:j)
            mass(m) = chunkEntries(m).getTotalVehicleMass();
        end

        i = j + 1;
    end
end

function rows = rawRows(chunks)
%rawRows Concatenates chunk samples, collapsing repeated states.
%   Consecutive rows at the same epoch whose states agree to round-off
%   (see sameEpochAndState) are the integrator re-initialising after an
%   action or event boundary, not a discontinuity, so only one is kept.
%   Inside a segment the first is kept; across a segment boundary the later
%   segment's row wins so the event number flips at the boundary, matching
%   the resampled-mode rule.
    rows = zeros(9, 0);

    for(k=1:numel(chunks))
        c = chunks(k);
        chunkRows = [c.t; c.rv; c.mass; repmat(c.evtNum, 1, numel(c.t))];

        keep = true(1, size(chunkRows, 2));
        for(i=2:size(chunkRows, 2))
            keep(i) = not(sameEpochAndState(chunkRows(:, i), chunkRows(:, i-1)));
        end
        chunkRows = chunkRows(:, keep);

        if(not(isempty(rows)) && not(isempty(chunkRows)) && sameEpochAndState(rows(:, end), chunkRows(:, 1)))
            rows(:, end) = [];
        end

        rows = [rows, chunkRows]; %#ok<AGROW>
    end
end

function tf = sameEpochAndState(rowA, rowB)
%sameEpochAndState True when two rows share an epoch exactly and their
%position/velocity/mass agree to a relative round-off tolerance.
    relTol = 1E-9;

    tf = rowA(1) == rowB(1) && ...
         norm(rowA(2:7) - rowB(2:7)) <= relTol * max(1, norm(rowA(2:7))) && ...
         abs(rowA(8) - rowB(8)) <= relTol * max(1, abs(rowA(8)));
end

function rows = resampledRows(chunks, stepSize)
%resampledRows Samples a uniform grid, interpolating within each chunk only.
    rows = zeros(9, 0);

    if(isempty(chunks))
        return;
    end

    allT = [chunks.t];
    t0 = min(allT);
    tEnd = max(allT);

    grid = t0:stepSize:tEnd;
    if(isempty(grid) || grid(end) < tEnd - 1E-9*max(1, abs(tEnd)))
        grid(end+1) = tEnd;
    end

    chunkInd = zeros(size(grid));
    for(k=1:numel(chunks))
        tMin = chunks(k).t(1);
        tMax = chunks(k).t(end);
        bool = grid >= tMin & grid <= tMax;
        chunkInd(bool) = k; %later chunks win at shared boundaries
    end

    for(k=1:numel(chunks))
        tq = grid(chunkInd == k);
        if(isempty(tq))
            continue;
        end

        c = chunks(k);
        data = [c.rv; c.mass];

        if(isscalar(c.t))
            vals = repmat(data, 1, numel(tq));
        else
            vals = interp1(c.t', data', tq', 'spline')';
        end

        rows = [rows, [tq; vals; repmat(c.evtNum, 1, numel(tq))]]; %#ok<AGROW>
    end

    [~, I] = sort(rows(1,:));
    rows = rows(:, I);
end

function writeCsv(filePath, rows, includeMass)
    fid = fopen(filePath, 'w');
    if(fid < 0)
        error('lvd_exportEphemeris:cannotOpen', 'Could not open "%s" for writing.', filePath);
    end
    cleanup = onCleanup(@() fclose(fid));

    if(includeMass)
        fprintf(fid, 'UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms,mass_mT,event_num\n');
        fmt = [repmat('%.17g,', 1, 8), '%s\n'];
        dataInds = 1:8;
    else
        fprintf(fid, 'UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms,event_num\n');
        fmt = [repmat('%.17g,', 1, 7), '%s\n'];
        dataInds = 1:7;
    end

    for(i=1:size(rows, 2))
        fprintf(fid, fmt, rows(dataInds, i), eventNumStr(rows(9, i)));
    end
end

function writeOem(filePath, rows, frame, opts)
    fid = fopen(filePath, 'w');
    if(fid < 0)
        error('lvd_exportEphemeris:cannotOpen', 'Could not open "%s" for writing.', filePath);
    end
    cleanup = onCleanup(@() fclose(fid));

    if(isempty(rows))
        startTime = 0;
        stopTime = 0;
    else
        startTime = rows(1, 1);
        stopTime = rows(1, end);
    end

    fprintf(fid, 'CCSDS_OEM_VERS = 2.0\n');
    fprintf(fid, 'CREATION_DATE = %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss')));
    fprintf(fid, 'ORIGINATOR = KSPTOT Launch Vehicle Designer\n');
    fprintf(fid, '\n');
    fprintf(fid, 'META_START\n');
    fprintf(fid, 'OBJECT_NAME = %s\n', opts.objectName);
    fprintf(fid, 'OBJECT_ID = UNKNOWN\n');
    fprintf(fid, 'CENTER_NAME = %s\n', opts.bodyName);
    fprintf(fid, 'REF_FRAME = %s\n', frame.getNameStr());
    fprintf(fid, 'TIME_SYSTEM = UT\n');
    fprintf(fid, 'START_TIME = %.17g\n', startTime);
    fprintf(fid, 'STOP_TIME = %.17g\n', stopTime);
    fprintf(fid, 'META_STOP\n');
    fprintf(fid, '\n');
    fprintf(fid, 'COMMENT Epochs are KSP universal time in seconds.  Units: km, km/s.\n');

    for(i=1:size(rows, 2))
        fprintf(fid, '%.17g %.17g %.17g %.17g %.17g %.17g %.17g\n', rows(1:7, i));
    end
end

function str = eventNumStr(evtNum)
    if(isnan(evtNum))
        str = 'NaN';
    else
        str = sprintf('%d', round(evtNum));
    end
end
