function [evtNum, varLocType, ownerEvt] = getEventNumberForVar(var, lvdData)
    %getEventNumberForVar Resolves an optimization variable to where it lives.
    %
    %   evtNum     - the sequential event number owning the variable, or []
    %                when it is not owned by a sequential event.  It stays
    %                EMPTY for a non-sequential event: those have no
    %                sequential number (getEventNum returns NaN), so there
    %                is no honest value to put here, and filling one in
    %                would only make callers that compare against
    %                evt.getEventNum() silently never match.
    %   varLocType - a human-readable location for display.
    %   ownerEvt   - the owning LaunchVehicleEvent handle, sequential or
    %                not, or empty.  Callers that need identity (rather
    %                than a number) should use this.

    evtNum = [];
    varLocType = '';
    ownerEvt = LaunchVehicleEvent.empty(1,0);

    numEvents = lvdData.script.getTotalNumOfEvents();
    for(i=1:numEvents)
        event = lvdData.script.getEventForInd(i);

        [~, eVars] = event.hasActiveOptVars();

        for(j=1:length(eVars)) %#ok<*NO4LP>
            eVar = eVars(j);

            if(strcmpi(class(var), class(eVar)) && var == eVar)
                evtNum = i;
                varLocType = 'Event';
                ownerEvt = event;
                return;
            end
        end
    end

    nonSeqEvts = lvdData.script.nonSeqEvts.evts;
    for(i=1:length(nonSeqEvts))
        nonSeqEvt = nonSeqEvts(i);

        [~, eVars] = nonSeqEvt.hasActiveOptVars();

        for(j=1:length(eVars))
            eVar = eVars(j);

            if(strcmpi(class(var), class(eVar)) && var == eVar)
                varLocType = sprintf('Nonsequential Event %u', i);
                ownerEvt = nonSeqEvt;
                return;
            end
        end
    end

    if(lvdData.initStateModel.isVarFromInitialState(var))
        varLocType = 'Initial State';

    elseif(lvdData.launchVehicle.isVarFromLaunchVehicle(var))
        varLocType = 'Launch Vehicle';

    elseif(lvdData.pluginVars.isVarAPluginVar(var))
        varLocType = 'Plugins';

    else
        varLocType = '';
    end
end
