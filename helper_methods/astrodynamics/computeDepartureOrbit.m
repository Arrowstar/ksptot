function [dVVect, dVVectNTW, eRVect, hOrbit, eTA] = computeDepartureOrbit(eSMA, eEcc, eInc, eRAAN, eArg, eMA, eEpoch, gmuDepartBody, hVInf, departUT, arrivalUT, departPlotNumOptIters, x0, iniLB, iniUB, departBody, arrivalBody, numRevs, parentBodyInfo, celBodyData)
%computeDepartureOrbit Summary of this function goes here
%   Detailed explanation goes here
    ePeriod = computePeriod(eSMA, gmuDepartBody);
    meanMotion = computeMeanMotion(eSMA, gmuDepartBody);
    if(not(isempty(eMA) && isempty(eEpoch)))
        curMean = AngleZero2Pi(meanMotion*(departUT-eEpoch)+eMA);
    else
        curMean = eMA;
    end

    deltaT = 1;
    cnt = 0;
    while(cnt<1 || (abs(deltaT) > 1 && cnt < 10))
        cnt = cnt + 1;
        
        %Optimization set up
        fun = @(x) computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, x, gmuDepartBody, hVInf);
        nonlcon = @(x) hyperOrbitExcessVelConst(eSMA, eEcc, eInc, eRAAN, eArg, x, gmuDepartBody, hVInf, 1);
        
        %Optimization run
        [eTA,~] = multiStartCommonRun('Searching for departure orbit...',...
                                       departPlotNumOptIters,...
                                       fun, x0, [], [], iniLB, iniUB, []);
        
        if(isempty(eMA) && isempty(eEpoch))
            deltaT=0;
        else
            meanIdeal = AngleZero2Pi(computeMeanFromTrueAnom(eTA, eEcc));            
            deltaT = (meanIdeal - curMean)/meanMotion;
            curMean = AngleZero2Pi(curMean + meanMotion*deltaT);
            departUT = departUT + deltaT;
            if(deltaT < 0 && (departUT < eEpoch))
                departUT = departUT + ePeriod;
            end
            
            departBodyInfo = celBodyData.(lower(departBody));
            arrivalBodyInfo = celBodyData.(lower(arrivalBody));
            
            [~, hVInf] = findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, arrivalBodyInfo, getParentGM(departBodyInfo, celBodyData), 'departPArrivalDVRadioBtn', numRevs);
        end
        
        disp(deltaT);
    end
          
    %Using Optimization results
    [~, dVVect, dVVectNTW, eRVect, hOrbit] = computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmuDepartBody, hVInf);
end

