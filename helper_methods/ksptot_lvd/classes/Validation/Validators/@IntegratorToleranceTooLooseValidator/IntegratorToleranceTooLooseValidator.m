classdef IntegratorToleranceTooLooseValidator < AbstractLaunchVehicleDataValidator
    %IntegratorToleranceTooLooseValidator Warns when an event's integrator
    %tolerances are too loose for the distances that event actually reaches.
    %
    %The variable-step integrators control LOCAL error per step against
    %max(AbsTol, RelTol*|state|).  RelTol is therefore a *relative* budget:
    %the same 1E-7 that buys sub-meter steps in LEO buys tens of meters at
    %lunar distance, and that error accumulates over thousands of steps.
    %The stock defaults are fine for the orbits LVD was originally used for
    %and quietly wrong for a translunar trajectory, so rather than change
    %the defaults (which would silently alter every existing mission) this
    %reports the mismatch against the radii the mission actually flew.

    properties
        lvdData LvdData
    end

    properties(Constant)
        %Per-step position error, in km, above which the tolerances are
        %called too loose.  One meter: small enough that accumulation over
        %a long propagation stays well inside typical constraint
        %tolerances, large enough not to fire on ordinary LEO work.
        ToleranceWarnThresholdKm(1,1) double = 1E-3;
    end

    methods
        function obj = IntegratorToleranceTooLooseValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            warnEvtNums = [];
            worstErrKm = 0;
            suggestedRelTol = Inf;

            evts = obj.lvdData.script.evts;
            for(i=1:length(evts)) %#ok<*NO4LP>
                evt = evts(i);

                if(isempty(evt.integratorObj))
                    continue;
                end

                options = evt.integratorObj.getOptions();
                if(not(isa(options, 'BuiltInIntegratorOptions')))
                    %Fixed step integrators have no tolerances to be loose.
                    continue;
                end

                stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);

                maxRadiusKm = 0;
                for(j=1:length(stateLogEntries))
                    maxRadiusKm = max(maxRadiusKm, norm(stateLogEntries(j).position));
                end

                if(maxRadiusKm <= 0)
                    continue;
                end

                estErrKm = max(options.AbsTol, options.RelTol * maxRadiusKm);

                if(estErrKm > obj.ToleranceWarnThresholdKm)
                    warnEvtNums(end+1) = evt.getEventNum(); %#ok<AGROW>
                    worstErrKm = max(worstErrKm, estErrKm);
                    suggestedRelTol = min(suggestedRelTol, obj.ToleranceWarnThresholdKm / maxRadiusKm);
                end
            end

            if(not(isempty(warnEvtNums)))
                eventStr = makeEventsStr(unique(warnEvtNums));
                str = sprintf(['Integrator tolerances are loose for the distances flown: up to %.3g m of error per step. ', ...
                               'Consider RelTol/AbsTol of %.0e or tighter. (Events: %s)'], ...
                              worstErrKm*1000, suggestedRelTol, eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end
