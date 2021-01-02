function eventLog = ma_executeBasicMassDump(massDumpEvent, initialState, eventNum)
%ma_executeMassDump Summary of this function goes here
%   Detailed explanation goes here

    ut = initialState(1);
    rVectUT = initialState(2:4);
    vVectUT = initialState(5:7);
    bodyID = initialState(8);
    
    dmasses = massDumpEvent.dumpValue;
    masses = initialState(9:12) - dmasses;
    
    eventLog(1,:) = [ut, rVectUT, vVectUT, bodyID, masses, eventNum];
end