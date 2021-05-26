function eventLog = ma_executeDVManeuver_finite_steered_spherical(dVVectNTWSpherical, thruster, initialState, eventNum, celBodyData)

    azimuth = dVVectNTWSpherical(1);
    elevation = dVVectNTWSpherical(2);
    r = dVVectNTWSpherical(3);

    dVVectNTW = getNTWFromAzElMag(azimuth,elevation,r);
    eventLog = ma_executeDVManeuver_finite_steered(dVVectNTW, thruster, initialState, eventNum, celBodyData);
end