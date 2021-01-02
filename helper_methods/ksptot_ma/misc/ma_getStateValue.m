function [value] = ma_getStateValue(state, type, celBodyData)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
        
    bodyID = state(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utSec = state(1);
    rVect = state(2:4)';
    vVect = state(5:7)';

    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    [lat, long, ~] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo, vVect);
    [rAp, rPe] = computeApogeePerigee(sma, ecc);

    switch type
        case 'Semi-major Axis'
            value = sma;
        case 'Eccentricity'
            value = ecc;
        case 'Inclination'
            value = rad2deg(inc);
        case 'Right Asc. of the Asc. Node'
            value = rad2deg(raan);
        case 'Argument of Periapsis'
            value = rad2deg(arg);
        case 'True Anomaly'
            value = rad2deg(tru);
        case 'Radius of Apoapsis'
            value = rAp;
        case 'Radius of Periapsis'
            value = rPe;
        case 'Longitude (East)'
            value = rad2deg(long);
        case 'Latitude (North)'
            value = rad2deg(lat);
        case 'Central Body ID'
            value = bodyID;
        otherwise
            error('Undefined state type in ma_getStateValue()');
    end
end

