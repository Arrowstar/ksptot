function eventLog = ma_executeDVManeuver_dv_inertial(dvVectInertial, thruster, initialState, eventNum)
%ma_executeDVManeuver_dv_inertial Summary of this function goes here
%   Detailed explanation goes here
    dvVectInertial = reshape(dvVectInertial, 1,3);

    ut = initialState(1);
    rVectUT = initialState(2:4);
    vVectUT = initialState(5:7) + dvVectInertial; %<--- application of DV here!
    bodyID = initialState(8);
    
    Isp = thruster.isp;
    propType = thruster.propType;
    
    masses = initialState(9:12);
    dmasses = computeDMFromDV(masses, norm(dvVectInertial), Isp, propType);
    
    eventLog(1,:) = [ut, rVectUT, vVectUT, bodyID, dmasses, eventNum];
end