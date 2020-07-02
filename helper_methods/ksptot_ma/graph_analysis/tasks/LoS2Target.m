function LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, station)
    %https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection
    
    eBodyRad = eclipseBodyInfo.radius;
%     rVectSC2EBody = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
%                         bodyInfo, eclipseBodyInfo, celBodyData);
%     rVectSC2Target = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
%                         bodyInfo, targetBodyInfo, celBodyData);

    time = stateLogEntry(1);
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(stateLogEntry(2:4),stateLogEntry(5:7),bodyInfo.gm);
    meanA = computeMeanFromTrueAnom(tru, ecc);
    inputOrbit = [sma, ecc, inc, raan, arg, meanA, time];
    scBodyInfo = getBodyInfoStructFromOrbit(inputOrbit);
    scBodyInfo.parent = bodyInfo.name;
    [rVectBodySCwrtSun, ~] = getPositOfBodyWRTSun(time, scBodyInfo, celBodyData);
          
    rVectEclipseBodyBodywrtSun = getPositOfBodyWRTSun(time, eclipseBodyInfo, celBodyData);
    rVectTargetBodywrtSun = getPositOfBodyWRTSun(time, targetBodyInfo, celBodyData);
    
	if(~isempty(station))
        stnBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
        stnRVectECIRelToParent = getInertialVectFromLatLongAlt(stateLogEntry(1), station.lat, station.long, station.alt, stnBodyInfo, [NaN;NaN;NaN]);
        rVectTargetBodywrtSun = rVectTargetBodywrtSun + stnRVectECIRelToParent;
	end
    
%     rVectSC2Target = rVectTargetBodywrtSun - rVectBodySCwrtSun;
    nVect = normVector(rVectBodySCwrtSun);
    
    aVect = rVectBodySCwrtSun;
    pVect = rVectEclipseBodyBodywrtSun;
    
    dPtToLine = norm((aVect - pVect) - (dotARH((aVect - pVect),nVect))*nVect); 
    
    if(dPtToLine <= eBodyRad && norm(rVectBodySCwrtSun) >= norm(rVectEclipseBodyBodywrtSun))
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