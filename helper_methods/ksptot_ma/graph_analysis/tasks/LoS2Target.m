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
%         rVectSC2Target = rVectSC2Target + stnRVectECIRelToParent;
        rVectTargetBodywrtSun = rVectTargetBodywrtSun + stnRVectECIRelToParent;
	end
    
    rVectSC2Target = rVectTargetBodywrtSun - rVectBodySCwrtSun;
    dist2Target = norm(rVectSC2Target);
%     if(all(rVectSC2EBody==rVectSC2Target)) %eclipse body and target body are the same, eclipse not possible
%         LoS = 1;
%         return;
%     end
% 
%     rVectDAng = dang(rVectSC2EBody,rVectSC2Target);                
%     angleSizeOfEBody = atan(eBodyRad/norm(rVectSC2EBody));
% 
%     if(rVectDAng <= angleSizeOfEBody && norm(rVectSC2Target) > norm(rVectSC2EBody))
%         LoS = 0; %we're in eclipse or we can't see the target
%     else
%         LoS = 1;
%     end

    oMinusC = rVectBodySCwrtSun-rVectEclipseBodyBodywrtSun;
    underSqRt = (dotARH(normVector(rVectSC2Target),oMinusC)^2 - norm(oMinusC)^2 + eBodyRad^2);
    
%     if(strcmpi(eclipseBodyInfo.name,'kerbin'))
%         disp(underSqRt);
%     end
    
    if(underSqRt <= 0)
        LoS = 1;
    else
        d1 = -(dotARH(normVector(rVectSC2Target),oMinusC)) + sqrt(underSqRt);
        d2 = -(dotARH(normVector(rVectSC2Target),oMinusC)) - sqrt(underSqRt);
        
        if(d1 > dist2Target && d2 > dist2Target)
            LoS = 1;
        else
            LoS = 0;
        end
    end
end