function entries = lvd_getValidationPropagationEntries(lvdData, evt)
    entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
    numActions = evt.getNumberOfActions();

    if(isempty(entries) || numActions == 0)
        return;
    end

    if(numel(entries) <= numActions)
        entries = LaunchVehicleStateLogEntry.empty(1,0);
        return;
    end

    switch evt.execActionsNode
        case ActionExecNodeEnum.BeforeProp
            entries = entries(numActions+1:end);
        case ActionExecNodeEnum.AfterProp
            entries = entries(1:end-numActions);
        otherwise
            entries = LaunchVehicleStateLogEntry.empty(1,0);
    end
end
