function LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, station, varargin)
    %https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    
    eBodyRad = eclipseBodyInfo.radius;
    
    time = stateLogEntry(1);
    rVectSc = stateLogEntry(2:4);
    rVectSc = rVectSc(:);
    
    %     [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(stateLogEntry(2:4),stateLogEntry(5:7),bodyInfo.gm);
    %     meanA = computeMeanFromTrueAnom(tru, ecc);
    %     inputOrbit = [sma, ecc, inc, raan, arg, meanA, time];
    %     scBodyInfo = getBodyInfoStructFromOrbit(inputOrbit);
    %     scBodyInfo.parent = bodyInfo.name;
    %     [rVectBodySCwrtSun, ~] = getPositOfBodyWRTSun(time, scBodyInfo, celBodyData);
       
    if(length(varargin) >= 1 && not(isempty(varargin{1})))
        scElemSetSun = varargin{1};
    else
        scBodyInertialFrame = bodyInfo.getBodyCenteredInertialFrame();
        scElemSet = CartesianElementSet(time, rVectSc, [0;0;0], scBodyInertialFrame);
        
        sunBodyInfo = celBodyData.getTopLevelBody();
        sunInertialFrame = sunBodyInfo.getBodyCenteredInertialFrame();
        scElemSetSun = scElemSet.convertToFrame(sunInertialFrame);
    end
    
    rVectBodySCwrtSun = scElemSetSun.rVect;
    
    [rVectTargetwrtSun, ~] = getPositOfBodyWRTSun(time, targetBodyInfo, celBodyData);
    
    rVectEclipseBodyBodywrtSun = getPositOfBodyWRTSun(time, eclipseBodyInfo, celBodyData);
    
    if(~isempty(station))
        if(isstruct(station)) %MA ground target
            stnBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
            stnRVectECIRelToParent = getInertialVectFromLatLongAlt(stateLogEntry(1), station.lat, station.long, station.alt, stnBodyInfo, [NaN;NaN;NaN]);
            rVectTargetwrtSun = rVectTargetwrtSun + stnRVectECIRelToParent;
            
        elseif(isa(station, 'LaunchVehicleGroundObject')) %LVD ground object
%             inertialFrame = bodyInfo.getBodyCenteredInertialFrame();
            
            stnElemSet = station.getStateAtTime(time);
%             stnElemSet = stnElemSet.convertToFrame(inertialFrame).convertToCartesianElementSet();
            stnElemSet = stnElemSet.convertToFrame(sunInertialFrame).convertToCartesianElementSet();           
            rVectTargetwrtSun = stnElemSet.rVect;
            
%             stnRVectECIRelToParent = stnElemSet.rVect;
            
%             rVectTargetwrtSun = rVectTargetwrtSun + stnRVectECIRelToParent;
%             rVectTargetwrtSun = stnRVectECIRelToParent;
        else
            error('Other station types not yet supported');
        end
    end
    
    rVectScToTarget = rVectTargetwrtSun-rVectBodySCwrtSun;
    nHat = normVector(rVectScToTarget);
    distScToTarget = norm(rVectScToTarget);
    
    aVect = rVectBodySCwrtSun;
    pVect = rVectEclipseBodyBodywrtSun;
    
    points = intersectLineSphere([aVect(:)' nHat(:)'], [pVect(:)' eBodyRad]);
   
    tol=1E-6;
    if(any(not(isnan(points))))       
        LoS = 1;
        for(i=1:2)
            if(all(not(isnan(points(i,:)))))
                pt = points(i,:)';
                pt = pt(:);
                
                dist1 = norm(rVectBodySCwrtSun - pt);
                dist2 = norm(rVectTargetwrtSun - pt);
                
                if(dist1 - distScToTarget <= -tol && dist2 - distScToTarget <= -tol)
                    LoS = 0;
                    break;
                end
            end
        end
    else
        LoS = 1;
    end
    
%     if(strcmpi(bodyInfo.name,'Kerbin'))
%         R_ned_2_inert = computeNedFrame(time, stnRVectECIRelToParent, bodyInfo);
%         rVectTargetToSc = -rVectScToTarget;
%         rVectTargetToScNed = R_ned_2_inert' * rVectTargetToSc;
%         [az, elev, r] = getAzElRngFromNedPosition(rVectTargetToScNed);
%         fprintf('Az: %0.3f, El: %0.3f, Dist: %0.3f\n', rad2deg(az), rad2deg(elev), r);
%     end
    
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