function datapt = lvd_StageTasks(stateLogEntry, subTask, stage)
%lvd_StageTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'dryMass'            
            datapt = stage.dryMass;   
            
        case 'active'
            stgStates = stateLogEntry.stageStates;
            stageState = stgStates([stgStates.stage] == stage);
                        
            if(not(isempty(stageState)))
                stageState = stageState(1);
                datapt = double(stageState.active);
            else
                datapt = -1;
            end
    end
end