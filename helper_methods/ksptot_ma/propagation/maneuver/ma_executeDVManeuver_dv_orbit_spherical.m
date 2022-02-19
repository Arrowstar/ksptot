function eventLog = ma_executeDVManeuver_dv_orbit_spherical(dVVectNTWSpherical, thruster, initialState, eventNum)
%ma_executeDVManeuver_dv_orbit_spherical Summary of this function goes here
%   Detailed explanation goes here

    azimuth = dVVectNTWSpherical(1);
    elevation = dVVectNTWSpherical(2);
    r = dVVectNTWSpherical(3);

    dVVectNTW = getNTWFromAzElMag(azimuth,elevation,r);

    eventLog = ma_executeDVManeuver_dv_orbit(dVVectNTW, thruster, initialState, eventNum);
end