function value = lvd_cumulativeDeltaVAtEntry(entry)
%lvd_cumulativeDeltaVAtEntry Cumulative Delta-V Expended (km/s) at a lone
%state log entry, recovering the history from the mission's state log.
%   For callers that hold one entry rather than the log: action
%   conditionals and plugin-variable actions evaluated during propagation.
%   Evaluated over the lone entry the task is a path integral of nothing
%   and reads 0.
%
%   Everything before the entry comes from entry.lvdData.stateLog.  During
%   propagation the entry is either not in the log yet (actions after
%   propagation work on a copy) or is its LAST element and still being
%   mutated by the actions running on it (actions before propagation).
%   Either way its own segment is added here with
%   lvd_deltaVSegmentIncrement and never enters the lvd_CumulativeDeltaVTasks
%   memo, which keys on handles and would otherwise hold a value for an
%   entry whose velocity is about to change.
%
%   A sparse log gives a sparse answer; scripts with such a reader refuse
%   sparse output (see LaunchVehicleScript.canUseSparseOutput).
    value = 0;

    lvdData = entry.lvdData;
    if(isempty(lvdData) || isempty(lvdData.stateLog))
        return;
    end

    entries = lvdData.stateLog.getAllEntries();
    ind = find(entries == entry, 1, 'first');

    if(not(isempty(ind)))
        if(ind < numel(entries))
            %Already followed by later entries, so it is final.
            value = lvd_CumulativeDeltaVTasks(ind, entries);
            return;
        end

        entries = entries(1:ind-1);
    end

    if(isempty(entries))
        return;
    end

    value = lvd_CumulativeDeltaVTasks(numel(entries), entries) + lvd_deltaVSegmentIncrement(entries(end), entry);
end
