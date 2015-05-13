function [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, celBodyData)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    [best,I] = min(scoresC);
    x2 = populationC(scoresC==best,:);
    x2 = x2(1,:);
    [dv2, ~, ~, ~] = fitnessfcn(x2);

    tm = x2(end-(length(bodiesInfo)-2):end);
    x0 = x2(1:length(bodiesInfo));
    lb = lb(1:length(bodiesInfo));
    ub = ub(1:length(bodiesInfo));
    objfun = @(x) fitnessfcn([x,tm]);
    nonlconFMC1 = @(x) multiFlybyNonlcon([x,tm], fitnessfcn,minRadiiSingle,maxRadiiSingle);
    nonlconFMC2 = @(x) multiFlybyNonlcon(x, fitnessfcn,minRadiiSingle,maxRadiiSingle);
    optionsFMC = optimoptions('fmincon','Algorithm','interior-point','Display','none','ScaleProblem','obj-and-constr');
    [x3,dv3] = fmincon(objfun,x0,[],[],[],[],lb,ub,nonlconFMC1, optionsFMC);
    x3 = [x3,tm];

    if(dv3 < dv2)
        x = x3;
    else
        x = x2;
    end
    [dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, vInfDepart, vInfArrive] = fitnessfcn(x);
    xferOrbits = getMultiFlybyXferOrbits(x, bodiesInfo, celBodyData);
    c = nonlconFMC2(x);  
end

