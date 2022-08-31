function eventLog = ma_executeStaging(stagingEvent, initialState, eventNum)
%ma_executeStaging Summary of this function goes here
%   Detailed explanation goes here

    ut = initialState(1);
    rVectUT = initialState(2:4);
    vVectUT = initialState(5:7);
    bodyID = initialState(8);
    
    newMasses = reshape(stagingEvent.stagingValue,1,4);
    masses = newMasses;
    
    eventLog(1,:) = [ut, rVectUT, vVectUT, bodyID, masses, eventNum];
end