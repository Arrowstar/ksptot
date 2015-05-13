function eventLog = ma_executeCoast_goto_tru(truTarget, initialState, eventNum, considerSoITransitions, refBody, celBodyData)
%ma_executeCoast_goto_tru Summary of this function goes here
%   Detailed explanation goes here    
    bodyID = initialState(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';
    
    [sma, ecc, ~, ~, ~, truINI] = getKeplerFromState(rVect,vVect,gmu);
%     meanINI = computeMeanFromTrueAnom(truINI, ecc);
    meanMotion = computeMeanMotion(sma, gmu);
    
    if(isempty(refBody))
        refBody.id = -1;
    end
    
    if((abs(truTarget-truINI) < 1E-7 || abs(abs(truTarget-truINI)-2*pi) < 1E-7) && refBody.id==bodyInfo.id)
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    if(ecc < 1.0)
        if(abs(truTarget-2*pi) < 1E-7)
            truTarget = 2*pi;
        else
            truTarget = AngleZero2Pi(truTarget);
        end
        
        if(abs(truINI-2*pi) < 1E-7)
            if(truINI - 2*pi >= 0 || truINI==2*pi)
                truINI = 0;
            else
                truINI = 0;
            end
        else
            truINI = AngleZero2Pi(truINI);
        end
    else
        truINI = angleNegPiToPi(truINI);
        truTarget = angleNegPiToPi(truTarget);
    end
    
    if(abs(AngleZero2Pi(truTarget)-AngleZero2Pi(truINI)) <1E-6)
        truTarget = truINI;
    end
        
    if(ecc >= 1.0)
        parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
        if(~isempty(parentBodyInfo))
            rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
        else
            rSOI = Inf;
        end
        iniOrbit = [sma, ecc];
        iniHyTruMax = AngleZero2Pi(computeTrueAFromRadiusEcc(rSOI, iniOrbit(1), iniOrbit(2)));
        meanMotion = computeMeanMotion(iniOrbit(1), bodyInfo.gm);
        lbTA = -iniHyTruMax;
        ubTA = iniHyTruMax;
        
        bool1 = (ecc >= 1.0 && (truTarget)<(truINI));
        bool2 = (ecc >= 1.0 && truTarget>ubTA);
        bool3 = (ecc >= 1.0 && truTarget<lbTA);
        
        if(bool1 || bool2 || bool3)
            soITrans = findSoITransitions(initialState, Inf, celBodyData);
            if(~isempty(soITrans))
                SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, Inf, celBodyData, soITrans);
                goToUTEventLog = ma_executeCoast_goto_tru(truTarget, SoITransEventLog(end,:), eventNum, true, refBody, celBodyData);
                eventLog = [SoITransEventLog; goToUTEventLog];
                return;
            else
                warnStr = ['Cannot go to target true anomaly (', num2str(rad2deg(truTarget)), ' deg).  Could not find an SoI transition, skipping.'];
                addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
                eventLog = initialState;
                eventLog(:,13) = eventNum;
                return;
            end
        end
    end
    
    if(considerSoITransitions)
        if(refBody.id == bodyID || refBody.id == -1)
            dt = getDtToTru(truTarget, sma, ecc, truINI, gmu);
            utTru = initialState(1) + dt;
        else
            utTru = Inf;
        end
        
        soITrans = findSoITransitions(initialState, utTru, celBodyData);
        SoITransEventLog = [];
        if(~isempty(soITrans) && min(soITrans(:,2)) < utTru)            
            SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, utTru, celBodyData, soITrans);
            goToUTEventLog = ma_executeCoast_goto_tru(truTarget, SoITransEventLog(end,:), eventNum, true, refBody, celBodyData);
        else 
            goToUTEventLog = ma_executeCoast_goto_tru(truTarget, initialState, eventNum, false, refBody, celBodyData);
        end
        eventLog = [SoITransEventLog; goToUTEventLog];
        return;
    end
        
    if(truTarget >= truINI)
        meanINI = computeMeanFromTrueAnom(truINI, ecc);
        if(abs(truTarget) < 1E-8)
            meanTarget = 0;
        elseif(abs(truTarget-2*pi) < 1E-8)
            meanTarget = 2*pi;
            if(meanINI < 0)
                meanINI = meanINI + 2*pi;
            end
        else
            meanTarget = computeMeanFromTrueAnom(truTarget, ecc);
        end
                
        dM = meanTarget-meanINI;
        dt = dM/meanMotion;
        
        eventLog = ma_executeCoast_goto_dt(dt, initialState, eventNum, considerSoITransitions, celBodyData);
    else
        eventLog1 = ma_executeCoast_goto_tru(2*pi, initialState, eventNum, considerSoITransitions, refBody, celBodyData);

        bodyID = eventLog1(end,8);
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        gmu = bodyInfo.gm;
        [sma, ecc, inc, raan, arg, ~] = getKeplerFromState(eventLog1(end,2:4),eventLog1(end,5:7),gmu);
        
        if(truTarget>=1E-6)
            newTruINI = 1E-6;
            [rVect,vVect]=getStatefromKepler(sma, ecc, inc, raan, arg, newTruINI, gmu); %set true anomaly to 0 to avoid having issues w/ infinite recursion
            eventLog1(end,2:4) = reshape(rVect,1,3);
            eventLog1(end,5:7) = reshape(vVect,1,3);
            
            eventLog2 = ma_executeCoast_goto_tru(truTarget, eventLog1(end,:), eventNum, considerSoITransitions, refBody, celBodyData); 
        else
            eventLog2 = [];
        end
        
        eventLog = [eventLog1; eventLog2];
    end
end
