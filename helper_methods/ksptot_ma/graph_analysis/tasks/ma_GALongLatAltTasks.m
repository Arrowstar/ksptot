function datapt = ma_GALongLatAltTasks(stateLogEntry, subTask, celBodyData)
%ma_GALongLatAltTasks Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    utSec = stateLogEntry(1);
    rVect = stateLogEntry(2:4)';
    vVect = stateLogEntry(5:7)';
    
    [lat, long, alt, vectSez, horzVel, vertVel] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo, vVect);
    
    switch subTask
        case 'long'
            datapt = rad2deg(long);
        case 'lat'
            datapt = rad2deg(lat);
        case 'alt'
            datapt = alt;
        case 'driftRate'
            [sma, ~, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,bodyInfo.gm, true);
            datapt = computeDriftRate(sma, bodyInfo) * (3600*180/pi); %convert rad/sec to deg/hr
        case 'horzVel'
            datapt = horzVel;
        case 'vertVel'
            datapt = vertVel;
    end
end

