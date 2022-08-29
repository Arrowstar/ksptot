function eventLog = ma_executeDVManeuver_dv_inertial_spherical(dvVectInertialSpherical, thruster, initialState, eventNum)
%ma_executeDVManeuver_dv_inertial_spherical Summary of this function goes here
%   Detailed explanation goes here
    
    azimuth = dvVectInertialSpherical(1);
    elevation = dvVectInertialSpherical(2);
    r = dvVectInertialSpherical(3);

    [x,y,z] = sph2cart(azimuth,elevation,r);
    dvVectInertial = [x,y,z];

    eventLog = ma_executeDVManeuver_dv_inertial(dvVectInertial, thruster, initialState, eventNum);
end