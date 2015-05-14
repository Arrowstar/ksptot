function soITrans = findSoITransitions(initialState, maxSearchUT, celBodyData)
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
    global num_SoI_search_revs;
    
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
    parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
    if(~isempty(parentBodyInfo))
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        if(ecc < 1)
            [rAp, ~] = computeApogeePerigee(sma, ecc);
        else
            rAp = Inf;
        end

        if(ecc >= 1 || rAp > soiRadius) %definite SoI transition upwards exists!
            if(norm(rVect) >= soiRadius)
%                 error(['Searching for SoI transition failed: initial state is already outside central body SoI.  Body: ', bodyInfo.name, ' - SoI Radius: ', num2str(soiRadius), ' - rNorm: ', num2str(norm(rVect)), ' - GM: ', num2str(gmu)]);
                truSoI = truINI;
                tempEventLog = initialState;
            else
                truSoI = computeTrueAFromRadiusEcc(soiRadius, sma, ecc);
                tempEventLog = ma_executeCoast_goto_tru(truSoI, initialState, -1, false, [], celBodyData);
            end
            
%             truSoI = computeTrueAFromRadiusEcc(soiRadius, sma, ecc);
%             tempEventLog = ma_executeCoast_goto_tru(truSoI, initialState, -1, false, [], celBodyData);
            upSoITransUT = tempEventLog(end,1);
            
            if(upSoITransUT <= maxSearchUT)
                [rVectUp, vVectUp] = convertRVVectOnUpwardsSoITransition(bodyInfo, parentBodyInfo, upSoITransUT, tempEventLog(end,2:4), tempEventLog(end,5:7));

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
    parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
    [childBodies] = getChildrenOfParentInfo(celBodyData, lower(bodyInfo.name));
    downSoITrans = [];
    for(child = childBodies)
        childBodyInfo = child{1};
        soiRadius = getSOIRadius(childBodyInfo, bodyInfo);
        if(~isempty(parentBodyInfo))
            soiRadiusParent = getSOIRadius(bodyInfo, parentBodyInfo);
        else
            soiRadiusParent = Inf;
        end
        
        [rAp, rPe] = computeApogeePerigee(sma, ecc);
        if(ecc > 1)
            rAp = Inf;
        end
                
        [rApBody, rPeBody] = computeApogeePerigee(childBodyInfo.sma, childBodyInfo.ecc);
        
        %%%%%%%%%%%
        %These are the two cases in which an SoI transition downwards is
        %impossible:
        % 1) S/C apogee is less than the child body perigee minus the SoI
        %    radius (we don't get up the child body).
        % 2) S/C perigee is greater than the child body apogee plus the SoI
        %    radius (we don't get down to the child body).
        % 3) Position vectors at the asc/desc nodes must be within some
        %    small number of SoI radii.
        %%%%%%%%%%%
        if(rAp < rPeBody-soiRadius)
            continue;
        end
        if(rPe > rApBody+soiRadius)
            continue;
        end
        
        hma_MainGUI = findobj('Tag','ma_MainGUI');
        if(~isempty(hma_MainGUI))
            maData = getappdata(hma_MainGUI,'ma_data');
            
            if(maData.settings.strictSoISearch)
                sma1=sma;
                ecc1=ecc;
                inc1=inc;
                raan1=raan;
                arg1=arg;

                sma2=childBodyInfo.sma;
                ecc2=childBodyInfo.ecc;
                inc2=deg2rad(childBodyInfo.inc);
                raan2=deg2rad(childBodyInfo.raan);
                arg2=deg2rad(childBodyInfo.arg);

                [TF] = intersectCheck(sma1, ecc1, inc1, raan1, arg1,...
                                      sma2, ecc2, inc2, raan2, arg2,...
                                      gmu, soiRadius);

                if(TF == false)
                    continue;
                end
            end
        end

        n1 = computeMeanMotion(sma, gmu);
        n2 = computeMeanMotion(childBodyInfo.sma, gmu);
        maxSearchRadius = min(rApBody+soiRadius,rAp);
        minSearchRadius = max(rPeBody-soiRadius,rPe);
        if(ecc < 1)             
            sPeriod = computeSynodicPeriod(n1, n2);
            oPeriod = computePeriod(sma,gmu);
            if(sPeriod / oPeriod > 3)
                sPeriod = 3*computePeriod(sma,gmu);
            end
            numPeriods = ceil(sPeriod/oPeriod);
            numPeriods = num_SoI_search_revs;
            
            truMax1=real(computeTrueAFromRadiusEcc(maxSearchRadius, sma, ecc));
            truMin1=real(computeTrueAFromRadiusEcc(minSearchRadius, sma, ecc));
            
            truMax2 = 2*pi-truMin1;
            truMin2 = 2*pi-truMax1;
            
            %%%%%%%%%Set 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MA1 = computeMeanFromTrueAnom(truMin1, ecc);
            MA2 = computeMeanFromTrueAnom(truMax1, ecc);
            
            dt = (MA1 - meanINI)/n1;
            if(dt < 0)
                if(meanINI>=MA1 && meanINI<=MA2)
                    dt = 0;
                else
                    dt = (2*pi-meanINI+MA1)/n1;
                end
            end
            
            minT = ut+dt-100;
            if(minT < ut)
                minT = ut;
            end
            
            dMA = MA2-MA1;
            sPeriod = dMA/n1;
            tArr = [];
            for(i=1:numPeriods)
                t1 = minT + (i-1)*oPeriod;
                t2 = minT + (i-1)*oPeriod + sPeriod + 100;
                
                if(t1 <= maxSearchUT && t2 <= maxSearchUT)
                    tArr(end+1) = t1;
                    tArr(end+1) = t2;
                elseif(t1 <= maxSearchUT && t2 > maxSearchUT)
                    tArr(end+1) = t1;
                    tArr(end+1) = maxSearchUT; %we don't want to exceed maxSearchUT
                else
                    continue; %both t1 and t2 are greater than maxSearchUT, don't add them
                end
            end  
            
            if(truINI >= truMin1 && truINI <= truMax1)
                tArr(end+1) = ut;
                tArr(end+1) = minT;
            end
            
            %%%%%%%%%Set 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MA1 = computeMeanFromTrueAnom(truMin2, ecc);
            MA2 = computeMeanFromTrueAnom(truMax2, ecc);
            
            dt = (MA1 - meanINI)/n1;
            if(dt < 0)
                dt = 0;
                dt = (2*pi-meanINI+MA1)/n1;
            end
            
            minT = ut+dt-100;
            if(minT < ut)
                minT = ut;
            end
            
            dMA = MA2-MA1;
            sPeriod = dMA/n1;
            for(i=1:numPeriods)
                tArr(end+1) = minT + (i-1)*oPeriod;
                tArr(end+1) = minT + (i-1)*oPeriod + sPeriod + 100;
            end  
            
            if(truINI >= truMin2 && truINI <= truMax2)
                tArr(end+1) = ut;
                tArr(end+1) = minT;
            end
            
        else
            iniHyTruMax1 = AngleZero2Pi(real(computeTrueAFromRadiusEcc(maxSearchRadius, sma, ecc)));
            iniHyTruMin1 = AngleZero2Pi(real(computeTrueAFromRadiusEcc(minSearchRadius, sma, ecc))); 
            
            iniHyTruMax2 = -iniHyTruMin1;
            iniHyTruMin2 = -iniHyTruMax1;
          
            %%%%%%%%%Set 1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MA1 = computeMeanFromTrueAnom(iniHyTruMin1, ecc);
            MA2 = computeMeanFromTrueAnom(iniHyTruMax1, ecc);
            
            dt = (MA1 - meanINI)/n1;
            if(dt < 0)
                dt = 0;
            end
            
            dMA = MA2-MA1;
            sPeriod = dMA/n1;
            
            minT = ut+dt-100;
            if(minT < ut)
                minT = ut;
            end
            tArr = linspace(minT, ut+dt+sPeriod+100, 2);
            
            %%%%%%%%%Set 2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            MA1 = computeMeanFromTrueAnom(iniHyTruMin2, ecc);
            MA2 = computeMeanFromTrueAnom(iniHyTruMax2, ecc);
            
            dt = (MA1 - meanINI)/n1;
            if(dt < 0)
                dt = 0;
            end
            
            dMA = MA2-MA1;
            sPeriod = dMA/n1;
            
            minT = ut+dt-100;
            if(minT < ut)
                minT = ut;
            end
            
            tArrTmp = linspace(minT, ut+dt+sPeriod+100, 2);
            tArr(end+1) = min(tArrTmp);
            tArr(end+1) = max(tArrTmp);
        end
        
%         tArr = [initialState(1)+100, tArr(1)-100, tArr];
        
        findChildSoITransFunc = @(ut) isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius-2, true, celBodyData); %make this true again
        findChildSoITransFuncRealSoI = @(ut) isSoICrossing(ut, scBodyInfo, childBodyInfo, bodyInfo, soiRadius, false, celBodyData);
        
        for(i=1:length(tArr)/2) %#ok<*NO4LP>
            tInds = [2*(i-1)+1, 2*i];
            
            if(tArr(tInds(1)) >= tArr(tInds(2)))
                continue;
            end
            
            %%%%%%%%%
            %This block of code is designed to weed out extraneous calls to
            %fminbnd by avoiding looking for SoI transitions where the
            %child body in question is clearly off on the other side of the
            %orbit.
            %%%%%%%%%
            [rVectSc1] = getStateAtTime(scBodyInfo, tArr(tInds(1)), gmu);
            [rVectSc2] = getStateAtTime(scBodyInfo, tArr(tInds(2)), gmu);
            
            [rVectC1] = getStateAtTime(childBodyInfo, tArr(tInds(1)), gmu);
            [rVectC2] = getStateAtTime(childBodyInfo, tArr(tInds(2)), gmu);
            
            distT1 = norm(rVectSc1-rVectC1)/childBodyInfo.sma;
            distT2 = norm(rVectSc2-rVectC2)/childBodyInfo.sma;
            
            if(maData.settings.strictSoISearch)
                smaFrac = 0.5;
            else
                smaFrac = 0.9;
            end
            
            if(min(distT1, distT2) > smaFrac)
                continue;
            end
            
            try
                [crossingUT, ~,~,~] = fminbnd(findChildSoITransFunc,tArr(tInds(1)),tArr(tInds(2)));
            catch ME %#ok<*NASGU>
                continue;
            end       
            minDistFromSOI2 = findChildSoITransFuncRealSoI(crossingUT);
            
            if(minDistFromSOI2 > 10)    
                continue;
            elseif(minDistFromSOI2 <= 10 && minDistFromSOI2 > 0)
                crossingUT = bisection(findChildSoITransFuncRealSoI,crossingUT-120,crossingUT+120,[],1E-3);
                minDistFromSOI2 = findChildSoITransFuncRealSoI(crossingUT);
                if(crossingUT < ut)
                    continue;
                end
            end                
            
            if(isempty(crossingUT) || isnan(crossingUT) || ~isreal(crossingUT) || ~isfinite(crossingUT))
                continue;
            end
            
            tempEventLog = ma_executeCoast_goto_ut(crossingUT, initialState, -1, false, celBodyData);
            
            [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, bodyInfo, crossingUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
            if(dot(rVectDown, vVectDown) > 0) %we found the outgoing part of the SoI transition                
                crossingUTTemp = crossingUT;
                
                minUT = crossingUT-100-6*(soiRadius/norm(vVectDown));
                maxUT = crossingUT-(soiRadius/norm(vVectDown))+100;
                [crossingUT, ~,~,~] = fminbnd(findChildSoITransFunc,minUT,maxUT);
                if(crossingUT < ut)
                    continue;
                end
                
                minDistFromSOI2 = findChildSoITransFuncRealSoI(crossingUT);
                if(minDistFromSOI2 <= 10 && minDistFromSOI2 > 0)
                    crossingUT = bisection(findChildSoITransFuncRealSoI,crossingUT-120,crossingUT+120,[],1E-3);
                    minDistFromSOI2 = findChildSoITransFuncRealSoI(crossingUT);
                    if(crossingUT < ut)
                        continue;
                    end
                end  
                
                tempEventLog = ma_executeCoast_goto_ut(crossingUT, initialState, -1, false, celBodyData);
                [rVectDown, vVectDown] = convertRVVectOnDownwardsSoITransition(childBodyInfo, bodyInfo, crossingUT, tempEventLog(end,2:4), tempEventLog(end,5:7));
            end
            if(norm(rVectDown) - soiRadius > 1)
                continue; %something wierd happened, go around
            end
            if(crossingUT <= maxSearchUT)
                downSoITrans(end+1,:) = [-1, crossingUT, bodyInfo.id, childBodyInfo.id, ...
                                         tempEventLog(end,2:7), ...
                                         rVectDown', vVectDown']; %#ok<AGROW>
            end
            break;
        end
    end
    
    soITrans = [upSoITrans;downSoITrans];   
end