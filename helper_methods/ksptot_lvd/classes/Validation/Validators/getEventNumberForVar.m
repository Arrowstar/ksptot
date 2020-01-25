function [evtNum, varLocType] = getEventNumberForVar(var, lvdData)
    evtNum = [];
    varLocType = '';
    
    numEvents = lvdData.script.getTotalNumOfEvents();
    for(i=1:numEvents)
        event = lvdData.script.getEventForInd(i);
        
        [~, eVars] = event.hasActiveOptVars();
        
        for(j=1:length(eVars))
            eVar = eVars(j);
            
            if(strcmpi(class(var), class(eVar)) && var == eVar)
                evtNum = i;
                varLocType = 'Event';
                break;
            end
        end
        
        if(not(isempty(evtNum)))
            break;
        end
    end
    
    if(isempty(evtNum))
        if(lvdData.initStateModel.isVarFromInitialState(var))
            varLocType = 'Initial State';
            
        elseif(lvdData.launchVehicle.isVarFromLaunchVehicle(var))
            varLocType = 'Launch Vehicle';
            
        else
            varLocType = '';
            
        end
    end
end