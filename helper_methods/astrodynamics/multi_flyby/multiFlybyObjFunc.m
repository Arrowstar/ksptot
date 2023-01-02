function [dv, rp, orbitIn, orbitOut, deltaVVect, vInfDNorm, vInfDepart, vInfArrive, totDV, r1B, r2B, v1Output, v2Output, xferRp] =  multiFlybyObjFunc(x, numRevsArr,bodiesInfo,includeDepartVInf,includeArrivalVInf, eSMA, eEcc, eInc, eRAAN, eArg, celBodyData)
%multiFlybyObjFunc Summary of this function goes here
%   Detailed explanation goes here
    numX = size(x,1);
    
    if(numX==0)
        dv = 9E99;
        rp = [];
        orbitIn = [];
        orbitOut = [];
        deltaVVect = [];
        vInfDNorm = [];
        vInfDepart = [];
        vInfArrive = [];
        totDV = [];
        r1B = [];
        r2B = [];
        v1Output = []; 
        v2Output = []; 
        xferRp = [];
        return;
    end

    eSMA = repmat(eSMA, [1, numX]);
    eEcc = repmat(eEcc, [1, numX]);
    eInc = repmat(eInc, [1, numX]);
    eRAAN = repmat(eRAAN, [1, numX]);
    eArg = repmat(eArg, [1, numX]);

    flybyBodies = bodiesInfo(2:end-1);
    numFB = length(flybyBodies);
    numREVS = length(bodiesInfo) - 1;
    numDepartTru = 1;
    
    tm = x(:, end-numREVS-numFB-numDepartTru : end-numREVS-numDepartTru);
    tm = round(tm);
    tm(tm==2) = -1;
    numTM = size(tm,2);
    
    numRevInds = x(:, end-numREVS+1-numDepartTru : end-numDepartTru);
    
    departTrus = x(:,end);

    x = x(:, 1:end-numTM-numREVS-numDepartTru);
    daTimes = cumsum(x,2);

    gmu = zeros(length(bodiesInfo),numX);
    rVectsB = zeros(3,numX,size(x,2));
    vVectsB = zeros(3,numX,size(x,2));
    for(i=1:length(bodiesInfo)) %#ok<*NO4LP>
        bodyInfo = bodiesInfo{i};
        [rVect, vVect] = getStateAtTime(bodyInfo, daTimes(:,i)', getParentGM(bodyInfo, celBodyData));
        
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
    r1B = rVectsB(:,1:end-numX);
    r2B = rVectsB(:,numX+1:end);

    vVectsB = reshape(vVectsB,3,length(bodiesInfo)*numX);
    vB = vVectsB(:,numX+1:end-numX);

    tempXferGmu = zeros(1,length(bodiesInfo)-1);
    for(i=1:length(bodiesInfo)-1)
        parentBodyInfo = bodiesInfo{i}.getParBodyInfo(celBodyData);
        tempXferGmuScalar = parentBodyInfo.gm;
        
%         tempXferGmuScalar = getParentGM(bodiesInfo{i}, celBodyData);
        tempXferGmu((i-1)*numX+1:i*numX) = tempXferGmuScalar;
    end
    xferGmuL = tempXferGmu;
    
%     xferGmuL = xferGmu * ones(1,(length(bodiesInfo)-1)*numX);

    dt = x(:,2:end) .* tm;
    dt = reshape(dt,1,numel(dt));

    popSize = size(r1B,2) / (length(bodiesInfo)-1);

    for(i=1:size(numRevInds,2))
        numRevInd = round(numRevInds(:,i));
        numRev((i-1)*popSize+1 : i*popSize) = numRevsArr{i}(numRevInd);         
    end
    
    bool = numRev == 0;
    
    v1 = zeros(size(r1B));
    v2 = v1;
    
    xferRp = zeros(1,size(r1B,2));
    
    if(any(bool)) %use the faster vectorized solver
        [v1(:,bool), v2(:,bool)] = lambertBattinVector(r1B(:,bool), r2B(:,bool), dt(bool), numRev(bool), xferGmuL(bool));
        
        [xferSma, xferEcc, ~, ~, ~, ~] = vect_getKeplerFromState(r1B(:,bool),v1(:,bool),xferGmuL(bool), true);
        [~, xferRp(bool)] = computeApogeePerigee(xferSma, xferEcc);
    end
    if(any(~bool))                      %use the slower but multi-rev capable lambert loop
        bool = ~bool;
        inds = find(bool);
        
        for(i=1:length(inds))
            ind = inds(i);
            try
                [v1L, v2L, ~, exitflag] = orbit.lambert(r1B(:,ind)', r2B(:,ind)', dt(ind)/86400, numRev(ind), xferGmuL(ind));

                [xferSma, xferEcc, ~, ~, ~, ~] = getKeplerFromState(r1B(:,ind),v1L,xferGmuL(ind), true);
                [~, xferRp(ind)] = computeApogeePerigee(xferSma, xferEcc);
                
                if(any(isnan(v1L)) || any(isnan(v2L)) || exitflag == -1 || exitflag == -2)
                    v1L(isnan(v1L)) = 9E99;
                    v2L(isnan(v2L)) = 9E99;
                end
            catch ME %#ok<NASGU>
                v1L = 9E99 * ones(1,3);
                v2L = 9E99 * ones(1,3);
            end
            
            v1(:,ind) = v1L';
            v2(:,ind) = v2L';
        end
    end
    
    xferRp(isnan(xferRp)) = Inf;
    
    v1Output = v1;
    v2Output = v2;
    
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
    [hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, ~, ~, ~] = computeHyperOrbitFromMultiFlybyParams(smaOut, eOut, hHat, oHat, false);

%     if(any(abs(rp-rp2)>1E-6))
%         warning(num2str(abs(rp-rp2)));
%     end
    
    orbitIn = [hSMAIn', hEccIn', hIncIn', hRAANIn', hArgIn', zeros(size(hSMAIn')), ((1-eIn).*smaIn)'];
    orbitOut = [hSMAOut', hEccOut', hIncOut', hRAANOut', hArgOut', zeros(size(hSMAOut')), ((1-eOut).*smaOut)'];
    
    [~,vVectIn]=vect_getStatefromKepler(hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, zeros(size(hArgIn)), gmu);
    [~,vVectOut]=vect_getStatefromKepler(hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, zeros(size(hArgOut)), gmu);
    deltaVVect = vVectOut-vVectIn;
    deltaV = sqrt(sum(abs(deltaVVect).^2,1));
    totDV = sum(reshape(deltaV,numX,length(flybyBodies)),2);
    
    dv = totDV;
    
    if(includeDepartVInf)
        eTA = departTrus;
        gmus = repmat(bodiesInfo{1}.gm, size(eSMA));
        [hSMA, hEcc, hInc, hRAAN, hArg, hTA] = vect_computeHypOrbitFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmus, vInfDepart);
        
        [eRVect, evVect] = vect_getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmus);
        [hRvect, hvVect] = vect_getStatefromKepler(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmus);
        departDeltaVVect = hvVect - evVect;
        departDeltaV = vecnorm(departDeltaVVect);

        dv = dv + departDeltaV(:);
    end
    
    if(includeArrivalVInf)
        dv = dv + vInfANorm;
    end
    
%     dv = vInfDNorm + totDV + vInfANorm;

    dv(dv>=1E99) = NaN;
    dv(isnan(dv)) = max(dv)+10;
end

