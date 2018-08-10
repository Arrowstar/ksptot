function eventLog = ma_executeMassDump(massDumpEvent, initialState, eventNum)
%ma_executeMassDump Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do the mass dump according to its sub-type
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    type = massDumpEvent.subType;
    switch type
        case 'basic'
            eventLog = ma_executeBasicMassDump(massDumpEvent, initialState, eventNum);
        case 'delta-v'
            eventLog = ma_executeDVMassDump(massDumpEvent, initialState, eventNum);
        otherwise
            error(['Did not recongize mass dump of type ', type]);
    end
end

