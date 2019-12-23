function [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, celBodyData)
%findSaneTraj Summary of this function goes here
%   Detailed explanation goes here
    [best,~] = min(scoresC);
    x2 = populationC(scoresC==best,:);
    x2 = x2(1,:);
    [dv2, ~, ~, ~] = fitnessfcn(x2);

    flybyBodies = bodiesInfo(2:end-1);
    numFB = length(flybyBodies);
    numREVS = length(bodiesInfo) - 1;
    
    tm = x2(:,end-numREVS-numFB:end-numREVS);
    numRevInds = x2(:,end-numREVS+1:end);
    
    for(i=1:size(numRevInds,2)) %#ok<*NO4LP>
        numRevInd = numRevInds(:,i);
        numRev(i) = numRevsArr{i}(numRevInd); %#ok<AGROW>
    end
    
    x0 = x2(1:length(bodiesInfo));
    lb = lb(1:length(bodiesInfo));
    ub = ub(1:length(bodiesInfo));
    objfun = @(x) fitnessfcn([x,tm,numRevInds]);
    nonlconFMC1 = @(x) multiFlybyNonlcon([x,tm,numRevInds], fitnessfcn,minRadiiSingle,maxRadiiSingle, minXferRad, maxDepartVInf, maxArriveVInf);
    nonlconFMC2 = @(x) multiFlybyNonlcon(x, fitnessfcn,minRadiiSingle,maxRadiiSingle, minXferRad, maxDepartVInf, maxArriveVInf);
    optionsFMC = optimoptions('fmincon','Algorithm','interior-point','Display','none','ScaleProblem','obj-and-constr');
    try
        [x3,dv3] = fmincon(objfun,x0,[],[],[],[],lb,ub,nonlconFMC1, optionsFMC);
    catch ME %#ok<NASGU>
        x3 = x2;
        dv3 = dv2;
    end
    x3 = [x3,tm,numRevInds];

    if(dv3 < dv2)
        x = x3;
    else
        x = x2;
    end
    
%     numRev = zeros(1,(length(bodiesInfo)-1));
%     for(i=1:length(bodiesInfo)-1) %#ok<*NO4LP>
%         if(bodiesInfo{i}.id == bodiesInfo{i+1}.id)
%             numRev(i) = 1; 
%         else
%             numRev(i) = 0;
%         end
%     end
    
    [dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, vInfDepart, vInfArrive, ~, r1B, r2B, v1, v2] = fitnessfcn(x);
    xferOrbits = getMultiFlybyXferOrbits(x, numRev, r1B, r2B, v1, v2, bodiesInfo, celBodyData);
    c = nonlconFMC2(x);  
end

