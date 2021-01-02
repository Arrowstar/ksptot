function [datapt, unitStr] = lvd_GrdObjTasks(stateLogEntry, subTask, grdObj)
%lvd_GrdObjTasks Summary of this function goes here
%   Detailed explanation goes here

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