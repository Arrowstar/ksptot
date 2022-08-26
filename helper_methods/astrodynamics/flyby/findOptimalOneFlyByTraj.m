function [dv, dvArr, flyByDVVect, flyByRp, xferOrbitIn, xferOrbitOut, flyByOrbitIn, flyByOrbitOut, departHypExVelVect, dvVectNTW] = findOptimalOneFlyByTraj(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr, quant2Opt)
%findOptimalOneFlyByTraj Summary of this function goes here
%   Detailed explanation goes here
    if(length(x)~=3)
        error('Length of x in findOptimalOneFlyByTraj must be 3');
    end
    
    departDate = x(1);
    phase1TOF = x(2);
    phase2TOF = x(3);
    
    xDates = [departDate, 
              departDate + phase1TOF,
              departDate + phase1TOF + phase2TOF];
          
    preFunc1 = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, flybyBodyInfo, gmuXfr, 'departDVRadioBtn');
    objFuncDepart = @(x) preFunc1(x(2), x(1));
    
    objFuncFlybyDV = @(x) flybyDVObjFunc(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr);
    
    preFunc2 = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, flybyBodyInfo, arrivalBodyInfo, gmuXfr, 'arrivalDVRadioBtn');
    objFuncArrival = @(x) preFunc2(x(3), x(2));
    
    [dv1, departHypExVelVect] = objFuncDepart(xDates);
    [dv2, flyByDVVect, flyByRp, xferOrbitIn, xferOrbitOut, flyByOrbitIn, flyByOrbitOut, dvVectNTW] = objFuncFlybyDV(xDates);
    dv3 = objFuncArrival(xDates);
    dvArr = [dv1, dv2, dv3];
    
    switch(quant2Opt)
        case 'departDVRadioBtn'
            dv3 = 0;
        case 'arrivalDVRadioBtn'
            dv1 = 0;
    end
    
    dv = dv1 + dv2 + dv3;
end

