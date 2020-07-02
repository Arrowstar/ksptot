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
        x3 = x2(1:length(bodiesInfo));
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
    
    [dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, ~, ~, ~, r1B, r2B, v1, v2] = fitnessfcn(x);
    
    times = cumsum(x3(1:length(bodiesInfo)));
    parentBodyFrame = bodiesInfo{1}.getParBodyInfo().getBodyCenteredInertialFrame();
    for(i=1:size(orbitsIn,1))
        time = times(1+i);
        bodyFrame = flybyBodies{i}.getBodyCenteredInertialFrame();
        
        cartStateParent = CartesianElementSet(time, r1B(:,i+1), v1(:,i+1), parentBodyFrame);
        vInfOut = cartStateParent.convertToFrame(bodyFrame).vVect;
        
        cartStateParent = CartesianElementSet(time, r2B(:,i), v2(:,i), parentBodyFrame);
        vInfIn = cartStateParent.convertToFrame(bodyFrame).vVect;
        
        [smaIn, eIn, hHat, sHat, smaOut, eOut, oHat] = computeMultiFlyByParameters(vInfIn, vInfOut, flybyBodies{i}.gm);
        [hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, ~, ~, ~] = computeHyperOrbitFromMultiFlybyParams(smaIn, eIn, hHat, sHat, true);
        [hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, ~, ~, ~] = computeHyperOrbitFromMultiFlybyParams(smaOut, eOut, hHat, oHat, false);
        
        orbitsIn(i,:) = [hSMAIn', hEccIn', hIncIn', hRAANIn', hArgIn', zeros(size(hSMAIn')), ((1-eIn).*smaIn)'];
        orbitsOut(i,:) = [hSMAOut', hEccOut', hIncOut', hRAANOut', hArgOut', zeros(size(hSMAOut')), ((1-eOut).*smaOut)'];
        
        inOrbitKepState = KeplerianElementSet(time, hSMAIn', hEccIn', hIncIn', hRAANIn', hArgIn', 0, bodyFrame);
        outOrbitKepState = KeplerianElementSet(time, hSMAOut', hEccOut', hIncOut', hRAANOut', hArgOut', 0, bodyFrame);
        
        deltaVVect(:,1) = outOrbitKepState.convertToCartesianElementSet().vVect - inOrbitKepState.convertToCartesianElementSet().vVect;
    end
    
    cartStateParent = CartesianElementSet(times(1), r1B(:,1), v1(:,1), parentBodyFrame);
    vInfDepart = cartStateParent.convertToFrame(bodiesInfo{1}.getBodyCenteredInertialFrame()).vVect;
    
    cartStateParent = CartesianElementSet(times(end), r1B(:,end), v2(:,end), parentBodyFrame);
    vInfArrive = cartStateParent.convertToFrame(bodiesInfo{end}.getBodyCenteredInertialFrame()).vVect;
    
    xferOrbits = getMultiFlybyXferOrbits(x, numRev, r1B, r2B, v1, v2, bodiesInfo, celBodyData);
    c = nonlconFMC2(x);  
end

