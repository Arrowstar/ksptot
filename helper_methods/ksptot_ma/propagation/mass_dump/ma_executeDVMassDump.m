function eventLog = ma_executeDVMassDump(massDumpEvent, initialState, eventNum)
%ma_executeBasicMassDump Summary of this function goes here
%   Detailed explanation goes here

    ut = initialState(1);
    rVectUT = initialState(2:4);
    vVectUT = initialState(5:7);
    bodyID = initialState(8);
    
    dv = massDumpEvent.dumpValue / 1000;
    thruster = massDumpEvent.thruster;
    masses = initialState(9:12);
    dmasses = computeDMFromDV(masses, dv, thruster.isp, thruster.propType);
    
    eventLog(1,:) = [ut, rVectUT, vVectUT, bodyID, dmasses, eventNum];
end

