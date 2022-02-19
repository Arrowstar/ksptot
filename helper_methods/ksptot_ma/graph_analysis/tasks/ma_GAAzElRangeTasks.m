function datapt = ma_GAAzElRangeTasks(stateLogEntry, subTask, station, celBodyData)
%ma_GADistToRefStationTask Summary of this function goes here
%   Detailed explanation goes here
      
    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

    if(isempty(station))
        datapt = -1;
        return;
    end
    
	switch subTask
        case 'Elevation'
            dVect = getAbsPositBetweenSpacecraftAndStation(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, station, celBodyData);
            staBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
            rSta = getInertialVectFromLatLongAlt(stateLogEntry(1), station.lat, station.long, station.alt, staBodyInfo, [NaN;NaN;NaN]);
            datapt = -(90 - rad2deg(dang(rSta,dVect)));
	end