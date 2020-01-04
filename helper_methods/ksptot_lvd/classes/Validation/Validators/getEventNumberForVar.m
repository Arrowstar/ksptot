function evtNum = getEventNumberForVar(var, lvdData)
    evtNum = [];
    
    numEvents = lvdData.script.getTotalNumOfEvents();
    for(i=1:numEvents)
        event = lvdData.script.getEventForInd(i);
        
        [~, eVars] = event.hasActiveOptVars();
        
        for(j=1:length(eVars))
            eVar = eVars(j);
            
            if(strcmpi(class(var), class(eVar)) && var == eVar)
                evtNum = i;
                break;
            end
        end
        
        if(not(isempty(evtNum)))
            break;
        end
    end
end