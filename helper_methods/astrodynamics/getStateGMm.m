function [rVect, vVect] = getStateGMm(bodyInfo, time, celBodyData)

% Here we are looking for Kepler elements of the body for a given time with
% G(M+m) factor
%     sma = bodyInfo.sma;
%     ecc = bodyInfo.ecc;
%     inc = AngleZero2Pi(deg2rad(bodyInfo.inc));
%     raan = AngleZero2Pi(deg2rad(bodyInfo.raan));
%     argp = AngleZero2Pi(deg2rad(bodyInfo.arg));
%     M0 = deg2rad(bodyInfo.mean); 
%        
%     n = computeMeanMotion(sma,bodyInfo.gm+parentbodyInfo.gm);
%     deltaT = time - bodyInfo.epoch;
%     M = M0 + n.*deltaT;
%     tru = computeTrueAnomFromMean(M, ecc);
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);

    [rVectB, vVectB] = getStateAtTime(bodyInfo, time, getParentGM(bodyInfo, celBodyData));
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVectB, vVectB, getParentGM(bodyInfo, celBodyData));
    
% Here we are calculating position and velocity for these parameters, but
% with GM factor
    [rVect,vVect]=getStatefromKepler(sma, ecc, inc, raan, arg, tru, parentBodyInfo.gm, true);
end