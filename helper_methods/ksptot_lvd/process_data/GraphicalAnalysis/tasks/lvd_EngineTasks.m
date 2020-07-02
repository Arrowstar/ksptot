function datapt = lvd_EngineTasks(stateLogEntry, subTask, engine)
%lvd_EngineTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'active'
            engineStates = stateLogEntry.getAllEngineStates();
            engineState = engineStates([engineStates.engine] == engine);
            
            if(not(isempty(engineState)))
                engineState = engineState(1);
                datapt = double(engineState.active);
            else
                datapt = -1;
            end
    end
end