function [depVarValue, depVarUnit, cumVals] = lvd_CumulativeDeltaVTasks(entryInd, subLog)
%lvd_CumulativeDeltaVTasks Cumulative finite-burn + impulsive Delta-V in km/s.
%   Integrates propulsive Delta-V from subLog(1) up to subLog(entryInd):
%     * forward propagation steps (dt > 0) contribute the finite-burn
%       increment g0*Isp*ln(m1/m2), exactly the per-segment computation in
%       EventDeltaVExpendedConstraint (same throttle, pressure and
%       mass-flow evaluation);
%     * same-time steps (dt == 0, produced by AddDeltaVAction entries)
%       contribute norm(v2 - v1), i.e. the impulsive magnitude (0 when the
%       action did not change velocity, e.g. staging or engine toggles).
%   Per the F2 decision this includes impulsive Delta-V.  Per-event or
%   per-stage splits are intentionally NOT separate tasks: use a
%   GenericMAConstraint on this quantity with StateComparison mode.
%
%   Sequential-access memo: GraphicalAnalysis loops call with increasing
%   entryInd on the same array, so each call costs one segment.  Random
%   access (constraints) recomputes the prefix.  Backward propagation is
%   not counted (finite segments require increasing time, as in
%   EventDeltaVExpendedConstraint); non-sequential-event impulses that do
%   not produce same-time log entries are not counted either.
%
%   cumVals is the whole prefix, cumVals(k) for k = 1..entryInd, for
%   callers that need every value along the log in one pass.
    arguments
        entryInd(1,1) double
        subLog(1,:) LaunchVehicleStateLogEntry
    end

    persistent cachedEntries cachedCum

    depVarUnit = 'km/s';

    if(entryInd < 1 || entryInd > numel(subLog))
        depVarValue = 0;
        cumVals = zeros(1,0);
        return;
    end

    useCache = not(isempty(cachedEntries)) && numel(cachedEntries) <= numel(subLog);
    if(useCache)
        nCached = numel(cachedEntries);
        try
            useCache = all(cachedEntries == subLog(1:nCached));
        catch
            useCache = false;
        end
    end

    if(useCache && entryInd <= numel(cachedCum))
        depVarValue = cachedCum(entryInd);
        cumVals = cachedCum(1:entryInd);
        return;
    end

    if(useCache)
        startK = numel(cachedCum) + 1;
        cumVals = cachedCum;
    else
        startK = 2;
        cumVals = zeros(1, entryInd);
        cumVals(1) = 0;
    end

    if(numel(cumVals) < entryInd)
        cumVals(entryInd) = 0;
    end

    for(k=max(startK,2):entryInd) %#ok<NO4LP>
        cumVals(k) = cumVals(k-1) + lvd_deltaVSegmentIncrement(subLog(k-1), subLog(k));
    end

    cachedEntries = subLog(1:entryInd);
    cachedCum = cumVals(1:entryInd);

    cumVals = cumVals(1:entryInd);
    depVarValue = cumVals(entryInd);
end
