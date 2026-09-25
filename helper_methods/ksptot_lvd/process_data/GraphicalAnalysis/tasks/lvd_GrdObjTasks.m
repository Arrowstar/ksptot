function [datapt, unitStr] = lvd_GrdObjTasks(stateLogEntry, subTask, grdObj, inFrame)
%lvd_GrdObjTasks Summary of this function goes here
%   Detailed explanation goes here

    origCentralBody = stateLogEntry.centralBody;
    stateLogEntry = stateLogEntry.deepCopy();
    cartElem = stateLogEntry.getCartesianElementSetRepresentation().convertToFrame(inFrame);
    stateLogEntry.setCartesianElementSet(cartElem);

    switch subTask
        case 'azimuth'
            [az, ~, ~] = getAzElRngOfScFromGrdObj(stateLogEntry, grdObj);
            
            datapt = rad2deg(az);
            unitStr = 'deg';
            
        case 'elevation'
            [~, elev, ~] = getAzElRngOfScFromGrdObj(stateLogEntry, grdObj);
            
            datapt = rad2deg(elev);
            unitStr = 'deg';
            
        case 'range'
            [~, ~, r] = getAzElRngOfScFromGrdObj(stateLogEntry, grdObj);
            
            datapt = r;
            unitStr = 'km';
            
        case 'LoS'
            maStateLogEntry = stateLogEntry.getMAFormattedStateLogMatrix(false);
            bodyInfo = stateLogEntry.centralBody;
            celBodyData = bodyInfo.celBodyData;
            
            targetBodyInfo = grdObj.centralBodyInfo;
            
            allBodyInfo = celBodyData.getAllBodyInfo();
            hasLoSAll = true;
            for(j=1:length(allBodyInfo))
                eclipseBodyInfo = allBodyInfo(j);
                
                hasLoS = LoS2Target(maStateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, grdObj);
                
                if(hasLoS == 0)
                    hasLoSAll = false;
                    break;
                end
            end
            
            datapt = double(hasLoSAll);
            unitStr = '';
            
        case 'rangeRate'
            [rhoVect, rhoDotVect] = getScStationRelStateInStationInertialFrame(stateLogEntry, grdObj);
            rng = norm(rhoVect);
            
            if(rng > 0)
                datapt = dot(rhoVect, rhoDotVect)/rng;
            else
                datapt = NaN;
            end
            unitStr = 'km/s';
            
        case 'elevRate'
            [rhoVect, rhoDotVect] = getScStationRelStateInStationInertialFrame(stateLogEntry, grdObj);
            
            time = stateLogEntry.time;
            grdObjBodyInfo = grdObj.centralBodyInfo;
            stnCartInert = getStationCartInStationInertialFrame(grdObj, time);
            R_ned_2_inert = computeNedFrame(time, stnCartInert.rVect, grdObjBodyInfo);
            
            %The NED axes rotate with the planet (plus station motion over
            %the surface): d(R')/dt contributes -R'*skew(omega).  The
            %planetary term is included exactly below; on fast rotators
            %(Kerbin: ~0.017 deg/s) it is NOT negligible.  Waypoint-motion
            %turn of the NED frame is neglected (second order for
            %station-keeping ground objects).
            omegaInert = getBodySpinVectInertial(grdObjBodyInfo, time);
            rhoNed = R_ned_2_inert' * rhoVect(:);
            rhoDotNed = R_ned_2_inert' * (rhoDotVect(:) - cross(omegaInert, rhoVect(:)));
            
            u = -rhoNed(3);
            h = hypot(rhoNed(1), rhoNed(2));
            uDot = -rhoDotNed(3);
            if(h > 0)
                hDot = (rhoNed(1)*rhoDotNed(1) + rhoNed(2)*rhoDotNed(2))/h;
            else
                hDot = hypot(rhoDotNed(1), rhoDotNed(2));
            end
            
            denom = u^2 + h^2;
            if(denom > 0)
                datapt = rad2deg((uDot*h - u*hDot)/denom);
            else
                datapt = NaN;
            end
            unitStr = 'deg/s';
            
        case 'downrange'
            %Downrange is only defined when the station sits on the body
            %the vehicle is orbiting.  origCentralBody is captured before
            %the frame conversion above, which re-roots centralBody at the
            %task frame's origin body.
            bodyInfo = origCentralBody;

            if(grdObj.centralBodyInfo ~= bodyInfo)
                datapt = NaN;
                unitStr = 'km';
            else
                time = stateLogEntry.time;
                [scLat, scLon] = getLatLongAltFromInertialVect(time, stateLogEntry.position, bodyInfo, stateLogEntry.velocity);
                
                stnElemSet = grdObj.getStateAtTime(time);
                if(isempty(stnElemSet))
                    datapt = NaN;
                else
                    centralAngle = distance(scLat, scLon, stnElemSet.lat, stnElemSet.long, 'radians');
                    datapt = centralAngle * bodyInfo.radius;
                end
                unitStr = 'km';
            end
            
        otherwise
            error('Unknown sub task string: %s', subTask);
    end
end

function [az, elev, r] = getAzElRngOfScFromGrdObj(stateLogEntry, grdObj)
    time = stateLogEntry.time;
    scCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    grdObjElemSet = grdObj.getStateAtTime(time);
    
    grdObjBodyInfo = grdObj.centralBodyInfo;
    grdObjParentBodyInertialFrame = grdObj.centralBodyInfo.getBodyCenteredInertialFrame();
    scCartElemStnFrame = scCartElem.convertToFrame(grdObjParentBodyInertialFrame).convertToCartesianElementSet();
    
    grdObjElemSetInertialFrame = grdObjElemSet.convertToFrame(grdObjParentBodyInertialFrame).convertToCartesianElementSet();
    
    rVectScToTarget = grdObjElemSetInertialFrame.rVect - scCartElemStnFrame.rVect;
    stnRVectECIRelToParent = grdObjElemSetInertialFrame.rVect;
    
    R_ned_2_inert = computeNedFrame(time, stnRVectECIRelToParent, grdObjBodyInfo);
    rVectTargetToSc = -rVectScToTarget;
    rVectTargetToScNed = R_ned_2_inert' * rVectTargetToSc;
    [az, elev, r] = getAzElRngFromNedPosition(rVectTargetToScNed);
end

function stnCartInert = getStationCartInStationInertialFrame(grdObj, time)%getStationCartInStationInertialFrame Ground-station Cartesian state in its
%parent body's inertial frame (NaN state when the waypoint schedule is
%empty at that time).
    stnElemSet = grdObj.getStateAtTime(time);

    if(isempty(stnElemSet))
        stnCartInert = CartesianElementSet(time, [NaN;NaN;NaN], [NaN;NaN;NaN], ...
            grdObj.centralBodyInfo.getBodyCenteredInertialFrame());
        return;
    end

    parentInertial = grdObj.centralBodyInfo.getBodyCenteredInertialFrame();
    stnCartInert = stnElemSet.convertToCartesianElementSet().convertToFrame(parentInertial).convertToCartesianElementSet();
end

function [rhoVect, rhoDotVect] = getScStationRelStateInStationInertialFrame(stateLogEntry, grdObj)
%getScStationRelStateInStationInertialFrame S/C-minus-station position
%(km) and velocity (km/s) in the station parent body's inertial frame.
%The station's inertial velocity comes from a central difference of its
%waypoint schedule (dt = 0.5 s), so moving waypoints are captured and no
%frame-transport assumption is needed.  NaN when the schedule is empty.
    time = stateLogEntry.time;

    parentInertial = grdObj.centralBodyInfo.getBodyCenteredInertialFrame();
    scCartElem = stateLogEntry.getCartesianElementSetRepresentation();
    scInert = scCartElem.convertToFrame(parentInertial).convertToCartesianElementSet();

    stnInert = getStationCartInStationInertialFrame(grdObj, time);

    dtStn = 0.5;
    stnPlus = getStationCartInStationInertialFrame(grdObj, time + dtStn);
    stnMinus = getStationCartInStationInertialFrame(grdObj, time - dtStn);
    stnVel = (stnPlus.rVect(:) - stnMinus.rVect(:)) / (2*dtStn);

    rhoVect = scInert.rVect(:) - stnInert.rVect(:);
    rhoDotVect = scInert.vVect(:) - stnVel;
end

function omegaInert = getBodySpinVectInertial(bodyInfo, time)
%getBodySpinVectInertial Planetary spin angular-velocity vector (rad/s) in
%the body-centered inertial frame: spin rate about the body-fixed Z axis
%(same convention as BodyFixedFrame.getAngVelWrtOriginAndRotMatToInertial).
    spinRate = 2*pi / bodyInfo.rotperiod;

    if(not(isfinite(spinRate)))
        spinRate = 0;
    end

    bff = bodyInfo.getBodyFixedFrame();
    R_ecef_to_inert = bff.getRotMatToInertialAtTime(time, [], []);
    omegaInert = spinRate * R_ecef_to_inert(:,3);
end