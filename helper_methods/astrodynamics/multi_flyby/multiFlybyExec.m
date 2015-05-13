function [x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive] = multiFlybyExec(bodiesInfo, lWindDef, bnds, popSize, numGen, celBodyData)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    nvars = length(bodiesInfo)+(length(bodiesInfo)-1);

    flybyBodies = bodiesInfo(2:end-1);
    nFlybyBodies = length(flybyBodies);
    minRadii = zeros(1, nFlybyBodies*popSize);
    maxRadii = zeros(1, nFlybyBodies*popSize);
    minRadiiSingle = [];
    maxRadiiSingle = [];
    for(i=1:nFlybyBodies) %#ok<*NO4LP>
        inds = (i-1)*popSize+1:i*popSize;
        atmoRad = (flybyBodies{i}.radius + flybyBodies{i}.atmohgt);
        minRadii(inds) = atmoRad*ones(size(inds));
        minRadiiSingle(i) = atmoRad;

        pBodyInfo = getParentBodyInfo(flybyBodies{i}, celBodyData);
        rSOI = getSOIRadius(flybyBodies{i}, pBodyInfo);
        maxRadii(inds) = rSOI*ones(size(inds));
        maxRadiiSingle(i) = rSOI;
    end

    [lb, ub] = getMultiFlybyLBUB(lWindDef(1), lWindDef(2), bodiesInfo, celBodyData);
    lb(2:1+length(bnds(:,1))) = [bnds(:,1)];
    ub(2:1+length(bnds(:,2))) = [bnds(:,2)];
    
    IntCon = 1:nvars;
    IntCon = IntCon(end-(length(bodiesInfo)-1)+1:end);

    fitnessfcn = @(x) multiFlybyObjFunc(x, bodiesInfo,celBodyData);
    nonlcon = @(x) multiFlybyNonlcon(x, fitnessfcn,minRadii,maxRadii);
    options = gaoptimset('Vectorized','on',...
                         'PopulationSize',popSize,...
                         'Display','iter',...
                         'PlotFcns', {@gaplotbestf, @gaplotscorediversity},...
                         'TolFun',1E-10,...
                         'Generations',numGen,...
                         'EliteCount',round(popSize/15));
    [~,~,~,~,population,scores] = ga(fitnessfcn,nvars,[],[],[],[],lb,ub,nonlcon,IntCon,options);
    
    hGAPlot = findobj('Name','Genetic Algorithm');
    if(ishandle(hGAPlot))
        close(hGAPlot);
    end
    
    c = nonlcon(population);
    numCPerRow = size(c,2);
    cTest = c <= 0;
    cTest = sum(cTest,2);
    Ind = find(cTest==numCPerRow);
    if(~isempty(Ind))
        populationC = population(Ind,:);
        scoresC = scores(Ind,:);

        [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, celBodyData);
    else
        cMaxes = max(abs(c),[],1);
        cNorm = zeros(size(c));
        for(i=1:length(cMaxes))
            cNorm(:,i) = c(:,i)/cMaxes(i);
        end        
        [~,cI] = min(sum(cNorm,2));
        
        scoresC = scores(cI,:);
        populationC = population(cI,:);
        [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, celBodyData);
        
        warning('No valid solutions');
    end
end

