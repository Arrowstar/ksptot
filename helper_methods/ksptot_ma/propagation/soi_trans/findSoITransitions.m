function soITrans = findSoITransitions(initialState, maxSearchUT, soiSkipIds, massLoss, orbitDecay, celBodyData)
%findSoITransitions Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %findSoITransitions() returns a matrix of information that contains
    % data on upcoming SoI transitions for a given state.  SoI transition
    % information is given in the following format:
    %
    % [transType, transUT, fromSoI, toSoI, fromRx, fromRy, fromRz, fromVx, fromVy, fromVz, toRx, toRy, toRz, toVx, toVy, toVz]
    %
    % transType - type of SoI transition.  1 for upwards, -1 for downwards
    % transUT   - UT of the SoI transition
    % fromSoI   - ID number of the body transitioning out of
    % toSoI     - ID number of the body transitioning into
    %
    % fromRx    - The following three are the position components of the s/c prior to leaving, relative to the fromSoI body
    % fromRy
    % fromRz
    % fromVx    - The following three are the velocity components of the s/c prior to leaving, relative to the fromSoI body
    % fromVy
    % fromVz
    %
    % toRx    - The following three are the position components of the s/c after moving to new SoI, relative to the toSoI body
    % toRy
    % toRz
    % toVx    - The following three are the velocity components of the s/c after moving to new SoI, relative to the toSoI body
    % toVy
    % toVz
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    global num_SoI_search_revs strict_SoI_search use_selective_soi_search soi_search_tol num_soi_search_attempts_per_rev;
    
    ut = initialState(1);
    
    if(isempty(maxSearchUT))
        maxSearchUT = Inf;
    else
        if(maxSearchUT <= ut)
            maxSearchUT = Inf;
        end
    end
    
    bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

    gmu = bodyInfo.gm;
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';
    
    [sma, ecc, inc, raan, arg, truINI] = getKeplerFromState(rVect,vVect,gmu);
    meanINI = computeMeanFromTrueAnom(truINI, ecc);
    scBodyInfo = getBodyInfoStructFromOrbit([sma, ecc, inc, raan, arg, meanINI, ut]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %There are two cases to consider: moving up the heirarchy and moving
    % down the heirarchy.  For example:
    % Up Heirarchy: Kerbin -> Sun
    % Down Heirarchy Kerbin -> Mun
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This segment looks for SoI transitions upwards.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    upSoITrans = [];
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    if(~isempty(parentBodyInfo))
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        if(ecc < 1)
            [rAp, ~] = computeApogeePerigee(sma, ecc);
        else
            rAp = Inf;
        end

        if(ecc >= 1 || rAp > soiRadius) %definite SoI transition upwards exists!
            if(abs(norm(rVect)-soiRadius)<0.001 && dot(rVect, vVect) > 0)
                truSoI = truINI;
                tempEventLog = initialState;
            else
                truSoI = computeTrueAFromRadiusEcc(soiRadius, sma, ecc);
                tempEventLog = ma_executeCoast_goto_tru(truSoI, initialState, -1, false, soiSkipIds, [], massLoss, orbitDecay, celBodyData);
            end
            
            upSoITransUT = tempEventLog(end,1);
            
            if(upSoITransUT <= maxSearchUT)
                [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, celBodyData, upSoITransUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
                
                upSoITrans = [1, upSoITransUT, bodyInfo.id, parentBodyInfo.id, ...
                              tempEventLog(end,2:7), ...
                              rVectUp', vVectUp'];
            else
                upSoITrans = [];
            end
        else 
            upSoITrans = [];
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This segment looks for SoI transitions downwards.  This is the
    % trickier of the two algorithms.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    [childBodies] = getChildrenOfParentInfo(celBodyData, lower(bodyInfo.name));
    downSoITrans = [];
    
    searchableChildBodies = KSPTOT_BodyInfo.empty(1,0);
    childBodySoIRadii = [];
    for(child = childBodies)
        childBodyInfo = child{1};
        
        if(use_selective_soi_search && ismember(childBodyInfo.id,soiSkipIds))
            continue;
        else
            searchableChildBodies(end+1) = childBodyInfo; %#ok<AGROW>
            childBodySoIRadii(end+1) = getSOIRadius(childBodyInfo, bodyInfo);
        end
    end
    
    if(not(isempty(searchableChildBodies)))
        meanMotion = computeMeanMotion(sma, gmu);
        odefun = @(ut, mean) soiSearchOdeFun(ut, mean, meanMotion);
        
        [maxSearchUTComputed, maxStepSize] = getMaxSoISearchTime(ut, sma, ecc, truINI, bodyInfo, gmu, parentBodyInfo, num_SoI_search_revs, num_soi_search_attempts_per_rev);
        if(isempty(maxSearchUT) || not(isfinite(maxSearchUT)) || isnan(maxSearchUT))
            maxSearchUT = maxSearchUTComputed;
        end

        tspan = [ut, maxSearchUT];
        if(isempty(maxSearchUT))
            fprintf('%0.9f - %0.9f - %0.9f - %0.9f - %0.9f - %0.9f - %0.9f\n\n', ut, sma, ecc, truINI, gmu, num_SoI_search_revs, num_soi_search_attempts_per_rev);
        end
        
        meanIni = computeMeanFromTrueAnom(truINI, ecc);
        if(ecc < 1)
            meanIni = AngleZero2Pi(meanIni);
        end
        y0 = meanIni;
        
        odeEvtFcn = @(ut,mean) getSoITransitionOdeEvents(ut, mean, sma, ecc, inc, raan, arg, bodyInfo, gmu, searchableChildBodies, childBodySoIRadii, celBodyData);
        options = odeset('RelTol',soi_search_tol, 'AbsTol',soi_search_tol, 'Events',odeEvtFcn, 'MaxStep',maxStepSize, 'Refine',1, 'InitialStep',maxStepSize);
        
        [~,~,te,ye,ie] = ode113(odefun,tspan,y0,options);
        
        if(not(isempty(ie)))
            [crossingUT, I] = min(te);
            childBodyInfo = searchableChildBodies(ie(I));
            
            tempEventLog = ma_executeCoast_goto_ut(crossingUT, initialState, -1, false, soiSkipIds, massLoss,  orbitDecay, celBodyData);
            
            [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, crossingUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
            
            downSoITrans(end+1,:) = [-1, crossingUT, bodyInfo.id, childBodyInfo.id, ...
                                     tempEventLog(end,2:7), ...
                                     rVectDown', vVectDown'];
        end
    end
    
    soITrans = [upSoITrans;downSoITrans]; 
end

function [maxSearchUT, maxStep] = getMaxSoISearchTime(utINI, sma, ecc, truINI, bodyInfo, gmu, parentBodyInfo, num_SoI_search_revs, num_soi_search_attempts_per_rev)
    numStepsPer = num_soi_search_attempts_per_rev;
    
    if(ecc < 1)
        oPeriod = computePeriod(sma,gmu);
        
        maxSearchUT = utINI + num_SoI_search_revs .* oPeriod;
        
        maxStep = abs(maxSearchUT - utINI)/num_SoI_search_revs/numStepsPer;
    else
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        maxHypTru = AngleZero2Pi(real(computeTrueAFromRadiusEcc(soiRadius, sma, ecc)));

        meanMotion = computeMeanMotion(sma, gmu);
        meanIni = computeMeanFromTrueAnom(truINI, ecc);
        maxMean = computeMeanFromTrueAnom(maxHypTru, ecc);
        
        maxSearchUT = utINI + (maxMean - meanIni)./meanMotion;
        
        maxStep = abs(maxSearchUT - utINI)./numStepsPer;
    end
end

function meandot = soiSearchOdeFun(~, ~, meanMotion)
    meandot = meanMotion;
end

function [value, isterminal, direction] = getSoITransitionOdeEvents(ut, mean, sma, ecc, inc, raan, arg, bodyInfo, gmu, childBodies, searchableChildBodies, celBodyData)
    value = [];
    isterminal = [];
    direction = [];
    
    tru = computeTrueAnomFromMean(mean, ecc);
    [rVect, ~] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu, false);

    for(i=1:length(childBodies)) %#ok<*NO4LP>
        childBodyInfo = childBodies(i);

        dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVect, bodyInfo, childBodyInfo, celBodyData);
        distToChild = norm(dVect);

        rSOI = searchableChildBodies(i);

        val = distToChild - rSOI;
        
        
        value(end+1) = val; %#ok<AGROW>
        direction(end+1) = -1; %#ok<AGROW>
        isterminal(end+1) = 1; %#ok<AGROW>
    end  
end
    
%     for(child = childBodies)
%         childBodyInfo = child{1};
%         
%         if(use_selective_soi_search && ismember(childBodyInfo.id,soiSkipIds))
%             continue;
%         end
%         
%         soiRadius = getSOIRadius(childBodyInfo, bodyInfo);
%         if(~isempty(parentBodyInfo))
%             soiRadiusParent = getSOIRadius(bodyInfo, parentBodyInfo);
%         else
%             soiRadiusParent = Inf;
%         end
%         
%         [rAp, rPe] = computeApogeePerigee(sma, ecc);
%         if(ecc > 1)
%             rAp = Inf;
%         end
%                 
%         [rApBody, rPeBody] = computeApogeePerigee(childBodyInfo.sma, childBodyInfo.ecc);
%         
%         %%%%%%%%%%%
%         %These are the two cases in which an SoI transition downwards is
%         %impossible:
%         % 1) S/C apogee is less than the child body perigee minus the SoI
%         %    radius (we don't get up the child body).
%         % 2) S/C perigee is greater than the child body apogee plus the SoI
%         %    radius (we don't get down to the child body).
%         % 3) Position vectors at the asc/desc nodes must be within some
%         %    small number of SoI radii.
%         %%%%%%%%%%%
%         if(rAp < rPeBody-soiRadius)
%             continue;
%         end
%         if(rPe > rApBody+soiRadius)
%             continue;
%         end
%                    
%         if(strict_SoI_search)
%             sma1=sma;
%             ecc1=ecc;
%             inc1=inc;
%             raan1=raan;
%             arg1=arg;
% 
%             sma2=childBodyInfo.sma;
%             ecc2=childBodyInfo.ecc;
%             inc2=deg2rad(childBodyInfo.inc);
%             raan2=deg2rad(childBodyInfo.raan);
%             arg2=deg2rad(childBodyInfo.arg);
% 
%             [TF] = intersectCheck(sma1, ecc1, inc1, raan1, arg1,...
%                                   sma2, ecc2, inc2, raan2, arg2,...
%                                   gmu, soiRadius);
% 
%             if(TF == false)
%                 continue;
%             end
%         end
%         
%         soiSf = 0;
%         
%         distScChildBody = norm(getAbsPositBetweenSpacecraftAndBody(ut, rVect, scBodyInfo, childBodyInfo, celBodyData));
%         if(distScChildBody < (soiRadius-2*soiSf)) %The spacecraft starts out inside the SoI for some reason!
%                 [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, ut, initialState(end,2:4), initialState(end,5:7));
%                 if(dot(rVectDown,vVectDown) < 0) %we're already headed down, so we can transition downwards.  But if we're headed up at the SoI boundary, don't transition!  Will cause SoI dithering.
%                     downSoITrans(end+1,:) = [-1, ut, bodyInfo.id, childBodyInfo.id, ...
%                                              initialState(end,2:7), ...
%                                              rVectDown', vVectDown']; %#ok<AGROW>
%                 end
%         end
%         
%         n1 = computeMeanMotion(sma, gmu);
%         n2 = computeMeanMotion(childBodyInfo.sma, gmu);
%         maxSearchRadius = min(rApBody+soiRadius,rAp);
%         minSearchRadius = max(rPeBody-soiRadius,rPe);
%         if(ecc < 1)             
%             sPeriod = computeSynodicPeriod(n1, n2);
%             oPeriod = computePeriod(sma,gmu);
%             if(sPeriod / oPeriod > 3)
%                 sPeriod = 3*computePeriod(sma,gmu);
%             end
%             numPeriods = ceil(sPeriod/oPeriod);
%             numPeriods = num_SoI_search_revs;
%             
%             truMax1=real(computeTrueAFromRadiusEcc(maxSearchRadius, sma, ecc));
%             truMin1=real(computeTrueAFromRadiusEcc(minSearchRadius, sma, ecc));
%             
%             truMax2 = 2*pi-truMin1;
%             truMin2 = 2*pi-truMax1;
%             
%             %%%%%%%%%Set 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             MA1 = computeMeanFromTrueAnom(truMin1, ecc);
%             MA2 = computeMeanFromTrueAnom(truMax1, ecc);
%             
%             dt = (MA1 - meanINI)/n1;
%             if(dt < 0)
% %                 if(meanINI>=MA1 && meanINI<=MA2)
% %                     dt = (2*pi-meanINI+MA1)/n1;
% %                 else
% %                     dt = (2*pi-meanINI+MA1)/n1;
% %                 end
%                 dt = (2*pi-meanINI+MA1)/n1;
%             end
%             
%             minT = ut+dt-100;
%             if(minT < ut)
%                 minT = ut;
%             end
%             
%             dMA = MA2-MA1;
%             sPeriod = dMA/n1;
%             tArr = [];
%             for(i=1:numPeriods)
%                 t1 = minT + (i-1)*oPeriod;
%                 t2 = minT + (i-1)*oPeriod + sPeriod + 100;
%                 
%                 if(t1 <= maxSearchUT && t2 <= maxSearchUT)
%                     tArr(end+1) = t1;
%                     tArr(end+1) = t2;
%                 elseif(t1 <= maxSearchUT && t2 > maxSearchUT)
%                     tArr(end+1) = t1;
%                     tArr(end+1) = maxSearchUT; %we don't want to exceed maxSearchUT
%                 else
%                     continue; %both t1 and t2 are greater than maxSearchUT, don't add them
%                 end
%             end  
%             
%             if(truINI >= truMin1 && truINI <= truMax1)
%                 tArr(end+1) = ut;
%                 tArr(end+1) = minT;
%             end
%             
%             %%%%%%%%%Set 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             MA1 = computeMeanFromTrueAnom(truMin2, ecc);
%             MA2 = computeMeanFromTrueAnom(truMax2, ecc);
%             
%             dt = (MA1 - meanINI)/n1;
%             if(dt < 0)
% %                 dt = 0;
%                 dt = (2*pi-meanINI+MA1)/n1;
%             end
%             
%             minT = ut+dt-100;
%             if(minT < ut)
%                 minT = ut;
%             end
%             
%             dMA = MA2-MA1;
%             sPeriod = dMA/n1;
%             for(i=1:numPeriods)
%                 t1 = minT + (i-1)*oPeriod;
%                 t2 = minT + (i-1)*oPeriod + sPeriod + 100;
%                 
%                 if(t1 <= maxSearchUT && t2 <= maxSearchUT)
%                     tArr(end+1) = t1;
%                     tArr(end+1) = t2;
%                 elseif(t1 <= maxSearchUT && t2 > maxSearchUT)
%                     tArr(end+1) = t1;
%                     tArr(end+1) = maxSearchUT; %we don't want to exceed maxSearchUT
%                 else
%                     continue; %both t1 and t2 are greater than maxSearchUT, don't add them
%                 end
%             end  
%             
%             if(truINI >= truMin2 && truINI <= truMax2)
%                 tArr(end+1) = ut;
%                 tArr(end+1) = minT;
%             end
%             
%         else
%             iniHyTruMax1 = AngleZero2Pi(real(computeTrueAFromRadiusEcc(maxSearchRadius, sma, ecc)));
%             iniHyTruMin1 = AngleZero2Pi(real(computeTrueAFromRadiusEcc(minSearchRadius, sma, ecc))); 
%             
%             iniHyTruMax2 = -iniHyTruMin1;
%             iniHyTruMin2 = -iniHyTruMax1;
%           
%             %%%%%%%%%Set 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             MA1 = computeMeanFromTrueAnom(iniHyTruMin1, ecc);
%             MA2 = computeMeanFromTrueAnom(iniHyTruMax1, ecc);
%             
%             dt = (MA1 - meanINI)/n1;
%             if(dt < 0)
%                 dt = 0;
%             end
%             
%             dMA = MA2-MA1;
%             sPeriod = dMA/n1;
%             
%             minT = ut+dt-100;
%             if(minT < ut)
%                 minT = ut;
%             end
%             tArr = linspace(minT, ut+dt+sPeriod+100, 2);
%             
%             %%%%%%%%%Set 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             MA1 = computeMeanFromTrueAnom(iniHyTruMin2, ecc);
%             MA2 = computeMeanFromTrueAnom(iniHyTruMax2, ecc);
%             
%             dt = (MA1 - meanINI)/n1;
%             if(dt < 0)
%                 dt = 0;
%             end
%             
%             dMA = MA2-MA1;
%             sPeriod = dMA/n1;
%             
%             minT = ut+dt-100;
%             if(minT < ut)
%                 minT = ut;
%             end
%             
%             tArrTmp = linspace(minT, ut+dt+sPeriod+100, 2);
%             tArr(end+1) = min(tArrTmp);
%             tArr(end+1) = max(tArrTmp);
%         end
%         
%         %These two lines sort the SoI calculations so that they're in
%         %time-order, meaning that earlier SoI transitions will not be
%         %missed if there are multiple possible SoI transitions.
%         tArr = sortrows(reshape(tArr, [2,length(tArr)/2])', 1);
%         tArr = reshape(tArr',1,[]);
%         
%         findChildSoITransFunc = @(ut) isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius-soiSf, true, celBodyData);
%         findChildSoITransFuncNoAbs = @(ut) isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius-soiSf, false, celBodyData);
%         findChildSoITransFuncRealSoI = @(ut) isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius-10/1000, false, celBodyData);
%         
%         options = optimset('TolX',soi_search_tol);
%         tolX2 = soi_search_tol;
%         for(i=1:length(tArr)/2) %#ok<*NO4LP>
%             tInds = [2*(i-1)+1, 2*i];
%             
%             if(tArr(tInds(1)) >= tArr(tInds(2)))
%                 continue;
%             end
%             
%             %%%%%%%%%
%             %This block of code is designed to weed out extraneous calls to
%             %fminbnd by avoiding looking for SoI transitions where the
%             %child body in question is clearly off on the other side of the
%             %orbit.
%             %%%%%%%%%
%             [rVectSc1] = getStateAtTime(scBodyInfo, tArr(tInds(1)), gmu);
%             [rVectSc2] = getStateAtTime(scBodyInfo, tArr(tInds(2)), gmu);
%             
%             [rVectC1] = getStateAtTime(childBodyInfo, tArr(tInds(1)), gmu);
%             [rVectC2] = getStateAtTime(childBodyInfo, tArr(tInds(2)), gmu);
%             
%             distT1 = norm(rVectSc1-rVectC1)/childBodyInfo.sma;
%             distT2 = norm(rVectSc2-rVectC2)/childBodyInfo.sma;
%             
%             if(strict_SoI_search)
%                 smaFrac = 0.5;
%             else
%                 smaFrac = 60.0; %used to be 0.9
%             end
%             
%             if(min(distT1, distT2) > smaFrac)
%                 if(strict_SoI_search)
%                     fprintf('While propagating Mission Architect orbit, strict SoI search setting skipped over a possible SoI transition between UT = %f sec and UT = %f sec.\n', tArr(tInds(1)), tArr(tInds(2)))
%                 end
%                 continue;
%             end
%             
%             try
%                 minUT = max(tArr(tInds(1)), initialState(1));
%                 maxUT = tArr(tInds(2));
%                 
%                 if(minUT > maxUT)
%                     continue;
%                 end
%                                
%                 if(num_soi_search_attempts_per_rev > 1)
%                     startPts = linspace(minUT,maxUT,num_soi_search_attempts_per_rev+1);
%                 else
%                     startPts = [minUT,maxUT];
%                 end
%                 crossingUTs = NaN(length(startPts)-1,1);
%                 minDistFromSOI2s = crossingUTs;
%                 for(j=1:length(startPts)-1)
%                     minUT_Opt = startPts(j);
%                     maxUT_Opt = startPts(j+1);
%                                         
%                     [crossingUTs(j), ~,~,~] = fminbnd(findChildSoITransFunc,minUT_Opt,maxUT_Opt, options);
%                     minDistFromSOI2s(j) = findChildSoITransFuncRealSoI(crossingUTs(j));
%                     
%                     if(minDistFromSOI2s(j) < 1)
%                         break; %we found SoI transition, no need to keep going
%                     end
%                 end
%                 
%                 [minDistFromSOI2, minI] = min(minDistFromSOI2s);
%                 crossingUT = crossingUTs(minI);
%                 
%                 if(minDistFromSOI2 > 100)    
%                     continue;
%                 end
%             catch ME %#ok<*NASGU>
%                 continue;
%             end       
% 
%             if(abs(minDistFromSOI2) > 0)
%                 minUT = crossingUT-1200;
%                 maxUT = crossingUT+1200;
%                 unrefinedCrossingUt = crossingUT;
%                 
%                 [crossingUT,minDistFromSOI2, exitFlag] = bisection(findChildSoITransFuncNoAbs, minUT, maxUT, 0.0, tolX2);
%                 if(minDistFromSOI2 > 0.01)
%                     continue;
%                 end
%                 
%                 if(minDistFromSOI2 < 0.01 && isnan(crossingUT))
%                     options = optimset('Display','off', 'TolX',tolX2);
%                     [crossingUT,minDistFromSOI2, exitFlag] = fzero(findChildSoITransFuncNoAbs, unrefinedCrossingUt, options);
%                     
%                     if(minDistFromSOI2 > 0.01)
%                         continue;
%                     end
%                 end
%             end
%             
%             if(isempty(crossingUT) || isnan(crossingUT) || ~isreal(crossingUT) || ~isfinite(crossingUT))
%                 continue;
%             end
%             
%             if(abs(crossingUT-initialState(1)) <= 0.1)
%                 crossingUT = initialState(1);
%             elseif(abs(crossingUT-initialState(1)) > 0.1)
%                 if(crossingUT < initialState(1))
%                     continue;
%                 end
%             end
%             
%             if(abs(maxSearchUT - crossingUT) <= 0.1)
%                 crossingUT = maxSearchUT;
%             elseif(abs(maxSearchUT - crossingUT) > 0.1)
%                 if(crossingUT > maxSearchUT)
%                     continue;
%                 end
%             end
%             
%             tempEventLog = ma_executeCoast_goto_ut(crossingUT, initialState, -1, false, soiSkipIds, massLoss,  orbitDecay, celBodyData);
%             
%             [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, crossingUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
%             if(dot(rVectDown, vVectDown) > 0) %we found the outgoing part of the SoI transition                
%                 crossingUTTemp = crossingUT;
%                 
%                 [smaTd, eccTd, ~, ~, ~, truTd] = getKeplerFromState(rVectDown, vVectDown, childBodyInfo.gm);
%                 [meanTd] = computeMeanFromTrueAnom(truTd, eccTd);
%                 [meanMotionTd] = computeMeanMotion(smaTd, childBodyInfo.gm);
% %                 [~,vVectTd] = getStatefromKepler(smaTd, eccTd, incTd, raanTd, argTd, 0.0, childBodyInfo.gm);
%                 
%                 maxUT = crossingUT - meanTd/meanMotionTd+100;
%                 minUT = crossingUT - 6*meanTd/meanMotionTd;
%                 minUT = max(minUT,initialState(1));
% 
%                 if(maxUT < initialState(1))
%                     continue;
%                 end
%                 
%                 try
%                     [crossingUT, ~,~,~] = fminbnd(findChildSoITransFunc,minUT,maxUT, options);
%                     minDistFromSOI2 = findChildSoITransFuncRealSoI(crossingUT);
%                     if(minDistFromSOI2 > 100)    
%                         continue;
%                     end
%                 catch ME %#ok<*NASGU>
%                     continue;
%                 end       
% 
%                 if(minDistFromSOI2 > 0)
%                     minUT = crossingUT-1200;
%                     minUT = max(minUT,initialState(1));
%                     maxUT = crossingUT+1200;
%                     [crossingUT,minDistFromSOI2] = bisection(findChildSoITransFuncRealSoI, minUT, maxUT, 0.0, tolX2);
%                     if(minDistFromSOI2 > 0.01)
%                         continue;
%                     end
%                 end
%                 
%                 if(isempty(crossingUT) || isnan(crossingUT) || ~isreal(crossingUT) || ~isfinite(crossingUT))
%                     continue;
%                 end
%                 
%                 if(abs(crossingUT-initialState(1)) <= 1)
%                     crossingUT = initialState(1);
%                 elseif(abs(crossingUT-initialState(1)) > 1)
%                     if(crossingUT < initialState(1))
%                         continue;
%                     end
%                 end
% 
%                 if(abs(maxSearchUT - crossingUT) <= 1)
%                     crossingUT = maxSearchUT;
%                 elseif(abs(maxSearchUT - crossingUT) > 1)
%                     if(crossingUT > maxSearchUT)
%                         continue;
%                     end
%                 end
%                 
%                 tempEventLog = ma_executeCoast_goto_ut(crossingUT, initialState, -1, false, soiSkipIds, massLoss, orbitDecay, celBodyData);
%                 [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, crossingUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
%             end
% %             if(abs(norm(rVectDown) - soiRadius) >= 0.01)
% %                 continue; %something wierd happened, go around
% %             end
%             if(crossingUT <= maxSearchUT)
%                 downSoITrans(end+1,:) = [-1, crossingUT, bodyInfo.id, childBodyInfo.id, ...
%                                          tempEventLog(end,2:7), ...
%                                          rVectDown', vVectDown']; %#ok<AGROW>
%             end
%             break;
%         end
%     end
%        
%     soITrans = [upSoITrans;downSoITrans];   
% end
% 
