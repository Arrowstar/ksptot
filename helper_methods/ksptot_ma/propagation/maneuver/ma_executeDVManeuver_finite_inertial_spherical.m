function eventLog = ma_executeDVManeuver_finite_inertial_spherical(dvVectInertialSpherical, thruster, initialState, eventNum, celBodyData)
        
    azimuth = dvVectInertialSpherical(1);
    elevation = dvVectInertialSpherical(2);
    r = dvVectInertialSpherical(3);

    [x,y,z] = sph2cart(azimuth,elevation,r);
    dvVectInertial = [x,y,z];

    eventLog = ma_executeDVManeuver_finite_inertial(dvVectInertial, thruster, initialState, eventNum, celBodyData);
end