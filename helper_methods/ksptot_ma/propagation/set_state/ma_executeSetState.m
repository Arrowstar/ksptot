function eventLog = ma_executeSetState(setStateEvent, initialState, eventNum, celBodyData)
%ma_executeSetState Summary of this function goes here
%   Detailed explanation goes here
    
    event = setStateEvent;
    
    if(strcmpi(event.subType,'setState'))
        eventLog = [event.epoch, ...
                    event.rVect(1), event.rVect(2), event.rVect(3), ...
                    event.vVect(1), event.vVect(2), event.vVect(3), ...
                    event.centralBody.id, ...
                    event.dryMass, event.fuelOxMass, event.monoMass, event.xenonMass, ...
                    eventNum];
    elseif(strcmpi(event.subType,'estLaunch'))
        eventLog = ma_executeLaunch(initialState, event.launch, celBodyData);
        
        eventLog(:,8) = event.centralBody.id;
        eventLog(:,9) = event.dryMass;
        eventLog(:,10) = event.fuelOxMass;
        eventLog(:,11) = event.monoMass;
        eventLog(:,12) = event.xenonMass;
        eventLog(:,13) = eventNum;
        
%         if(isempty(initialState))
%             eventLog(:,8) = event.centralBody.id;
%             eventLog(:,9) = event.dryMass;
%             eventLog(:,10) = event.fuelOxMass;
%             eventLog(:,11) = event.monoMass;
%             eventLog(:,12) = event.xenonMass;
%             eventLog(:,13) = eventNum;
%         else
%             eventLog(:,8) = initialState(8);
%             eventLog(:,9) = initialState(9);
%             eventLog(:,10) = initialState(10);
%             eventLog(:,11) = initialState(11);
%             eventLog(:,12) = initialState(12);
%             eventLog(:,13) = eventNum;
%         end
    end
end

