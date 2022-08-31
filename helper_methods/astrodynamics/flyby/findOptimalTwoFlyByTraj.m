function [dv, dvArr, flyBy1DVVect, flyBy2DVVect, flyBy1Rp, flyBy2Rp, ...
          xferOrbitP1, xferOrbitP2, xferOrbitP3, flyBy1OrbitIn, flyBy1OrbitOut, ...
          flyBy2OrbitIn, flyBy2OrbitOut] = ...
          findOptimalTwoFlyByTraj(x, departBodyInfo, flyby1BodyInfo, flyby2BodyInfo, arrivalBodyInfo, gmuXfr)
%findOptimalTwoFlyByTraj Summary of this function goes here
%   Detailed explanation goes here
    if(length(x)~=4)
        error('Length of x in findOptimalTwoFlyByTraj must be 4');
    end
    
    departDate = x(1);
    phase1TOF = x(2);
    phase2TOF = x(3);
    phase3TOF = x(4);
    
    xDates = [departDate, 
              departDate + phase1TOF,
              departDate + phase1TOF + phase2TOF,
              departDate + phase1TOF + phase2TOF + phase3TOF];
          
    preFunc1 = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, flyby1BodyInfo, gmuXfr, 'departDVRadioBtn');
    objFuncDepart = @(x) preFunc1(x(2), x(1));
    
    objFuncFlyby1DV = @(x) flybyDVObjFunc([xDates(1) xDates(2) xDates(3)], departBodyInfo, flyby1BodyInfo, flyby2BodyInfo, gmuXfr);
    objFuncFlyby2DV = @(x) flybyDVObjFunc([xDates(2) xDates(3) xDates(4)], flyby1BodyInfo, flyby2BodyInfo, arrivalBodyInfo, gmuXfr);
    
    preFunc2 = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, flyby2BodyInfo, arrivalBodyInfo, gmuXfr, 'arrivalDVRadioBtn');
    objFuncArrival = @(x) preFunc2(x(4), x(3));
    
    dv1 = objFuncDepart(xDates);
    [dv2, flyBy1DVVect, flyBy1Rp, xferOrbitP1, xferOrbitP2, flyBy1OrbitIn, flyBy1OrbitOut] = objFuncFlyby1DV(xDates);
    [dv3, flyBy2DVVect, flyBy2Rp, xferOrbitP2, xferOrbitP3, flyBy2OrbitIn, flyBy2OrbitOut] = objFuncFlyby2DV(xDates);
    dv4 = objFuncArrival(xDates);
    dvArr = [dv1, dv2, dv3, dv4];
    
    dv = dv1 + dv2 + dv3 + dv4;
end