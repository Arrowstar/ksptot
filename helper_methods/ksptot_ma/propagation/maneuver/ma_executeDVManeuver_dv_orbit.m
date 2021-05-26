function eventLog = ma_executeDVManeuver_dv_orbit(dVVectNTW, thruster, initialState, eventNum)
%ma_executeDVManeuver_dv_orbit Summary of this function goes here
%   Detailed explanation goes here

    [dVVectECI] = getNTW2ECIdvVect(dVVectNTW, initialState(2:4)', initialState(5:7)');
    eventLog = ma_executeDVManeuver_dv_inertial(dVVectECI, thruster, initialState, eventNum);
end

