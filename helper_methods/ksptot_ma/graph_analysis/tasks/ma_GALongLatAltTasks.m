function datapt = ma_GALongLatAltTasks(stateLogEntry, subTask, celBodyData)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    utSec = stateLogEntry(1);
    rVect = stateLogEntry(2:4)';
    
    [lat, long, alt] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo);
    
    switch subTask
        case 'long'
            datapt = rad2deg(long);
        case 'lat'
            datapt = rad2deg(lat);
        case 'alt'
            datapt = alt;
    end
end

