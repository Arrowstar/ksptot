function [arrivalUT, departUT, dv] = findOptimalDepartArrivalFromPorkChop(arrivalUTGuess, departUTGuess, departBodyInfo, arrivalBodyInfo, gmu, quant2Opt, departTimeArr, arrivalTimeArr)
%findOptimalDepartArrival Summary of this function goes here
%   Detailed explanation goes here

%     departBodyMeanMotion = computeMeanMotion(departBodyInfo.sma, gmu);
%     arrivalBodyMeanMotion = computeMeanMotion(arrivalBodyInfo.sma, gmu);
%     synPeriod = computeSynodicPeriod(departBodyMeanMotion, arrivalBodyMeanMotion);

    preFunc = @(arrivalUT, departUT) findOptimalDepartureArrivalObjFunc(arrivalUT, departUT, departBodyInfo, arrivalBodyInfo, gmu, quant2Opt);
    objFunc = @(x) preFunc(x(1), x(2));
    x0 = [arrivalUTGuess departUTGuess];
    
%     dtUB = departUTGuess + (1/2)*synPeriod;
%     dtLB = max(departUTGuess - (1/2)*synPeriod, 0);
%     atUB = arrivalUTGuess + (1/2)*synPeriod;
%     atLB = max(arrivalUTGuess - (1/2)*synPeriod, 0);
    
    dtUB = departTimeArr(end);
    dtLB = departTimeArr(1);
    atUB = arrivalTimeArr(end);
    atLB = arrivalTimeArr(1);
    
    lb = [atLB dtLB];
    ub = [atUB dtUB];
    
	numIter = 20;
    ptmatrix1 = linspace(atLB,atUB,numIter-1);
    ptmatrix2 = linspace(dtLB,dtUB,numIter-1);
    ptmatrix3 = [arrivalUTGuess departUTGuess];
    ptmatrix = [ptmatrix1;ptmatrix2]';
    ptmatrix = [ptmatrix3;ptmatrix];
    tpoints = CustomStartPointSet(ptmatrix);
    
    switch(quant2Opt)
        case 'departDVRadioBtn'
            waitBarStr = 'Searching for optimal departure...';
        case 'arrivalDVRadioBtn'
            waitBarStr = 'Searching for optimal arrival...';
        case 'departPArrivalDVRadioBtn'
            waitBarStr = 'Searching for optimal departure/arrival...';
        otherwise
            waitBarStr = 'Searching for optimal departure/arrival...';
    end
    
    A = [-1, 1];
    b = 0;
    [x,dv] = multiStartCommonRun(waitBarStr, tpoints, objFunc, x0, A, b, lb, ub, []);
    
    arrivalUT = x(1);
    departUT = x(2);
end

