function [targetMissDist, dVNorm, hOrbit, dVVect, dVVectNTW, eRVect, xferOrbit, departUT, timeSOI] = departureTargetMissDistance(x, dVVectNTW, eOrbit, departBodyInfo, arriveBodyInfo, parentBodyInfo, departUT, arrivalUT)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    eTru = x(1);
    progradeDV = x(2);
    dVVectNTW(1) = progradeDV;
    
    eSMA = eOrbit(1);
    eEcc = eOrbit(2);
    eInc = eOrbit(3);
    eRAAN = eOrbit(4);
    eArg = eOrbit(5);
%     eTru = eOrbit(6);
    
    eTruAtDepartUT = eOrbit(6);
    eMeanMotion = computeMeanMotion(eSMA, departBodyInfo.gm);
    
    eMean = computeMeanFromTrueAnom(eTru, eEcc);
    eMeanAtDepartUT = computeMeanFromTrueAnom(eTruAtDepartUT, eEcc);
    departDeltaTBurnPosAdjust = (eMean-eMeanAtDepartUT)/eMeanMotion;
    departUT = departUT + departDeltaTBurnPosAdjust;

    [eRVect,eVvect] = getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTru, departBodyInfo.gm);
    tHat = eVvect/norm(eVvect);
    wHat = cross(eRVect,eVvect)/norm(cross(eRVect,eVvect));
    nHat = cross(tHat,wHat)/norm(cross(tHat,wHat));
    ECI2TWNRotMat = [tHat,wHat,nHat];
    dVVect = ECI2TWNRotMat * dVVectNTW;
    dVNorm = norm(dVVect);
    
    hRVect = eRVect;
    hVVect = eVvect + dVVect;
    [hSMA, hECC, hINC, hRAAN, hARG, hTRU] = getKeplerFromState(hRVect,hVVect,departBodyInfo.gm);
    hOrbit = [hSMA, hECC, hINC, hRAAN, hARG, hTRU];
    
    rSOI = getSOIRadius(departBodyInfo, parentBodyInfo);

    hTruSOI = computeTrueAFromRadiusEcc(rSOI, hOrbit(1), hOrbit(2));
    [rVectSOI,vVectSOI]=getStatefromKepler(hOrbit(1), hOrbit(2), hOrbit(3), hOrbit(4), hOrbit(5), hTruSOI, departBodyInfo.gm);
    hOrbit(7) = hTruSOI;
    
    meanDepartTime = computeMeanFromTrueAnom(hOrbit(6), hOrbit(2));
    meanSOITime = computeMeanFromTrueAnom(hTruSOI, hOrbit(2));
    hMeanMotion = computeMeanMotion(hOrbit(1), departBodyInfo.gm);
    deltaT2SOI = (meanSOITime-meanDepartTime)/hMeanMotion; 
    
    timeSOI = departUT - deltaT2SOI; %may be a + sign here
    [departBodyRVect, departBodyVVect] = getStateAtTime(departBodyInfo, timeSOI, parentBodyInfo.gm);
    scInParentOrbitRVect = departBodyRVect + rVectSOI;
    scInParentOrbitVVect = departBodyVVect + vVectSOI;
    [smaXAct, eccXAct, incXAct, raanXAct, argXAct, truDXAct] = getKeplerFromState(scInParentOrbitRVect,scInParentOrbitVVect,parentBodyInfo.gm);
    xferOrbit = [smaXAct, eccXAct, incXAct, raanXAct, argXAct, truDXAct];    
    
    bodyInfoXAct.sma = smaXAct;
    bodyInfoXAct.ecc = eccXAct;
    bodyInfoXAct.inc = rad2deg(incXAct);
    bodyInfoXAct.raan = rad2deg(raanXAct);
    bodyInfoXAct.arg = rad2deg(argXAct);
    bodyInfoXAct.mean = computeMeanFromTrueAnom(truDXAct, eccXAct);
    bodyInfoXAct.epoch = timeSOI;
    
    [rVectXAct, vVectXAct] = getStateAtTime(bodyInfoXAct, arrivalUT, parentBodyInfo.gm);
    [~, ~, ~, ~, ~, truAXAct] = getKeplerFromState(rVectXAct,vVectXAct,parentBodyInfo.gm);
    xferOrbit(7) = truAXAct;
    [rVectArriveBody, ~] = getStateAtTime(arriveBodyInfo, arrivalUT, parentBodyInfo.gm);
    targetMissDist = norm(rVectArriveBody-rVectXAct);
end

