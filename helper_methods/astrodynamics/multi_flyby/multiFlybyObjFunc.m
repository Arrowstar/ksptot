function [dv, rp, orbitIn, orbitOut, deltaVVect, vInfDNorm, vInfDepart, vInfArrive, totDV] =  multiFlybyObjFunc(x, bodiesInfo,celBodyData)
%multiFlybyObjFunc Summary of this function goes here
%   Detailed explanation goes here
    numX = size(x,1);
    
    if(numX==0)
        dv = 9E99;
        return;
    end

    flybyBodies = bodiesInfo(2:end-1);
    numFB = length(flybyBodies);
    pBodyInfo = getParentBodyInfo(bodiesInfo{1}, celBodyData);
    xferGmu = pBodyInfo.gm;

    tm = x(:,end-numFB:end);
    tm = round(tm);
    tm(tm==2) = -1;
    numTM = size(tm,2);

    x = x(:,1:end-numTM);
    daTimes = cumsum(x,2);

    gmu = zeros(length(bodiesInfo),numX);
    rVectsB = zeros(3,numX,size(x,2));
    vVectsB = zeros(3,numX,size(x,2));
    for(i=1:length(bodiesInfo)) %#ok<*NO4LP>
        bodyInfo = bodiesInfo{i};
        [rVect, vVect] = getStateAtTime(bodyInfo, daTimes(:,i)', xferGmu);

        rVectsB(:,:,i) = rVect;
        vVectsB(:,:,i) = vVect;
        
        gmu(i,:) = bodyInfo.gm * ones(1,numX);
        
        if(i==1)
            vBDepart = vVect;
        elseif(i==length(bodiesInfo))
            vBArrive = vVect;
        end
    end
    gmu(1,:) = [];
    gmu(end,:) = [];
    gmu = reshape(gmu',1,numel(gmu'));
    
    rVectsB = reshape(rVectsB,3,length(bodiesInfo)*numX);
    r1B = rVectsB(:,1:end-size(x,1));
    r2B = rVectsB(:,size(x,1)+1:end);

    vVectsB = reshape(vVectsB,3,length(bodiesInfo)*numX);
    vB = vVectsB(:,size(x,1)+1:end-size(x,1));

    xferGmuL = xferGmu * ones(1,(length(bodiesInfo)-1)*numX);

    dt = x(:,2:end) .* tm;
    dt = reshape(dt,1,numel(dt));

    [v1, v2] = lambertBattinVector(r1B, r2B, dt, 0, xferGmuL);
    v1D = v1(:,1:numX);
    v1 = v1(:,numX+1:end);
    v2A = v2(:,end-numX+1:end);
    v2 = v2(:,1:end-numX);
    
    vInfIn = v2 - vB;
    vInfOut = v1 - vB;
    
    vInfDepart = v1D - vBDepart;
    vInfDNorm = sqrt(sum(abs(vInfDepart).^2,1));
    vInfDNorm = (vInfDNorm');
    
    vInfArrive = v2A - vBArrive;
    vInfANorm = sqrt(sum(abs(vInfArrive).^2,1));
    vInfANorm = (vInfANorm');
    
    [smaIn, eIn, hHat, sHat, smaOut, eOut, oHat] = computeMultiFlyByParameters(vInfIn, vInfOut, gmu);
    [hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, ~, ~, rp] = computeHyperOrbitFromMultiFlybyParams(smaIn, eIn, hHat, sHat, true);
    [hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, ~, ~, rp2] = computeHyperOrbitFromMultiFlybyParams(smaOut, eOut, hHat, oHat, false);

    if(any(abs(rp-rp2)>1E-6))
        warn(num2str(abs(rp-rp2)));
    end
    
    orbitIn = [hSMAIn', hEccIn', hIncIn', hRAANIn', hArgIn', zeros(size(hSMAIn')), ((1-eIn).*smaIn)'];
    orbitOut = [hSMAOut', hEccOut', hIncOut', hRAANOut', hArgOut', zeros(size(hSMAOut')), ((1-eOut).*smaOut)'];
    
    [~,vVectIn]=vect_getStatefromKepler(hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, zeros(size(hArgIn)), gmu);
    [~,vVectOut]=vect_getStatefromKepler(hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, zeros(size(hArgOut)), gmu);
    deltaVVect = vVectOut-vVectIn;
    deltaV = sqrt(sum(abs(deltaVVect).^2,1));
    totDV = sum(reshape(deltaV,numX,length(flybyBodies)),2);
    
    dv = vInfDNorm + totDV + vInfANorm;
    dv(isnan(dv)) = max(dv)+10;
end

