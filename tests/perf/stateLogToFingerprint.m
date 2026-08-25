function fp = stateLogToFingerprint(stateLog)
%STATETOLOGTOFINGERPRINT Extracts a pure-numeric fingerprint of an LVD state log.
%
%   fp = stateLogToFingerprint(stateLog) summarizes every entry of the
%   given LaunchVehicleStateLog as a row in a plain double matrix.  The
%   intent is bitwise comparison (isequaln) of trajectories produced by
%   different code versions or different execution paths (full propagation
%   vs. incremental resume), so only raw stored numerics are captured:
%
%      [time, position(1:3), velocity(1:3), eventNum, integrationGroup, ...
%       allTankMassesByStage..., allPowerStorageSoCsByStage..., ...
%       stopwatchValues..., extremaValues...]
%
%   Tank and power storage values are extracted from entry.stageStates in
%   fixed stage/tank order (including inactive stages), so the matrix has
%   a constant width per mission script even when staging changes which
%   tanks are active mid-flight.
%
%   Object handles, random ids, and derived interpolants (e.g. calculus
%   object states) are deliberately excluded: handles do not serialize
%   stably across sessions and derived data is a pure function of the
%   captured numerics.
%
%   The returned struct has fields:
%       fp.matrix - [numEntries x numCols] double matrix
%       fp.numEntries - number of state log entries summarized
%       fp.numCols - width of the fingerprint matrix
%
%   Compare fingerprints with isequaln so NaNs compare equal to
%   themselves.  Note this treats +0/-0 as equal and NaN payloads as
%   insignificant, which is acceptable for trajectory data.

    entries = stateLog.entries;

    fp = struct();
    fp.numEntries = length(entries);

    rows = cell(1, fp.numEntries);

    for(i = 1:fp.numEntries)
        entry = entries(i);

        evtNum = NaN;
        try
            evtNum = entry.event.getEventNum();
            if(isempty(evtNum))
                evtNum = NaN;
            end
        catch
            %event not resolvable; keep NaN
        end

        intGrpNum = NaN;
        try
            intGrpNum = entry.integrationGroup.integrationGroupNum;
        catch
            %no integration group; keep NaN
        end

        tankVals = [];
        socVals = [];
        for(j = 1:length(entry.stageStates))
            stageState = entry.stageStates(j);

            for(m = 1:length(stageState.tankStates))
                tankVals(end+1) = stageState.tankStates(m).getTankMass(); %#ok<AGROW>
            end

            for(m = 1:length(stageState.powerStorageStates))
                socVals(end+1) = stageState.powerStorageStates(m).getStateOfCharge(); %#ok<AGROW>
            end
        end

        stopwatchVals = [];
        try
            stopwatchVals = [entry.stopwatchStates.value];
        catch
            %no stopwatches; keep empty
        end

        extremaVals = [];
        try
            extremaVals = [entry.extremaStates.value];
        catch
            %no extrema recorders; keep empty
        end

        rows{i} = [entry.time, ...
                   entry.position(:).', ...
                   entry.velocity(:).', ...
                   evtNum, intGrpNum, tankVals, socVals, stopwatchVals, extremaVals]; %#ok<AGROW>
    end

    if(fp.numEntries == 0)
        fp.matrix = zeros(0, 9);
    else
        fp.matrix = vertcat(rows{:});
    end

    fp.numCols = size(fp.matrix, 2);
end
