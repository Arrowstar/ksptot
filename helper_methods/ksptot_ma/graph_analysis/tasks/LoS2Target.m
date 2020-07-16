function LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, station)
    %https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    
    eBodyRad = eclipseBodyInfo.radius;

    time = stateLogEntry(1);
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(stateLogEntry(2:4),stateLogEntry(5:7),bodyInfo.gm);
    meanA = computeMeanFromTrueAnom(tru, ecc);
    inputOrbit = [sma, ecc, inc, raan, arg, meanA, time];
    scBodyInfo = getBodyInfoStructFromOrbit(inputOrbit);
    scBodyInfo.parent = bodyInfo.name;
    [rVectBodySCwrtSun, ~] = getPositOfBodyWRTSun(time, scBodyInfo, celBodyData);
       
    [rVectTargetwrtSun, ~] = getPositOfBodyWRTSun(time, targetBodyInfo, celBodyData);
    
    rVectEclipseBodyBodywrtSun = getPositOfBodyWRTSun(time, eclipseBodyInfo, celBodyData);
    
	if(~isempty(station))
        stnBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
        stnRVectECIRelToParent = getInertialVectFromLatLongAlt(stateLogEntry(1), station.lat, station.long, station.alt, stnBodyInfo, [NaN;NaN;NaN]);
        rVectTargetwrtSun = rVectTargetwrtSun + stnRVectECIRelToParent;
	end
    
    rVectScToTarget = rVectTargetwrtSun-rVectBodySCwrtSun;
    nHat = normVector(rVectScToTarget);
    
    aVect = rVectBodySCwrtSun;
    pVect = rVectEclipseBodyBodywrtSun;
    rVectEclipseBodyToTarget = rVectTargetwrtSun - rVectEclipseBodyBodywrtSun;
    
    dPtToLine = norm((aVect - pVect) - (dotARH((aVect - pVect),nHat))*nHat); 

    if(dPtToLine <= eBodyRad && norm(rVectScToTarget) >= norm(rVectEclipseBodyToTarget))
        LoS = 0;
    else
        LoS = 1;
    end
    
%     dist2Target = norm(rVectSC2Target);
% 
%     oMinusC = rVectBodySCwrtSun-rVectEclipseBodyBodywrtSun;
%     underSqRt = (dotARH(normVector(rVectSC2Target),oMinusC)^2 - norm(oMinusC)^2 + eBodyRad^2);
%     
%     
%     if(underSqRt <= 0)
%         LoS = 1;
%     else
%         d1 = -(dotARH(normVector(rVectSC2Target),oMinusC)) + sqrt(underSqRt);
%         d2 = -(dotARH(normVector(rVectSC2Target),oMinusC)) - sqrt(underSqRt);
%         
%         if(d1 > dist2Target && d2 > dist2Target)
%             LoS = 1;
%         else
%             LoS = 0;
%         end
%     end
end