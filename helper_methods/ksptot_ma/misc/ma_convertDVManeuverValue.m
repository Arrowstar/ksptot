function returnValue = ma_convertDVManeuverValue(stateRowPreEvent, stateRowEvent, convertTo)
%ma_convertDVManeuverValue Summary of this function goes here
%   Detailed explanation goes here
    rVect1 = stateRowPreEvent(2:4);
    vVect1 = stateRowPreEvent(5:7);
    
    vVect2 = stateRowEvent(5:7);

    switch(convertTo)
        case 'Proscribed Delta-V (Inertial Vector)'
            returnValue = (vVect2 - vVect1)*1000;
        case 'Proscribed Delta-V (Orbital Vector)'
            inertialDV = vVect2 - vVect1;
            returnValue = getNTWdvVect(inertialDV', rVect1', vVect1')*1000;
        case 'Proscribed Delta-V (Inertial Spherical)' 
            inertialDV = vVect2 - vVect1;
            [azimuth,elevation,r] = cart2sph(inertialDV(1),inertialDV(2),inertialDV(3));
            returnValue = [rad2deg(azimuth), rad2deg(elevation), r*1000];
        case 'Proscribed Delta-V (Orbital Spherical)'
            inertialDV = vVect2 - vVect1;
            ntwDV = getNTWdvVect(inertialDV', rVect1', vVect1');
            
            [azimuth,elevation,r] = getAzElMagFromNTW(ntwDV);
            returnValue = [rad2deg(azimuth), rad2deg(elevation), r*1000];
        otherwise
            returnValue = [];
    end
end

