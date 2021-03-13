function [x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive, numRev] = multiFlybyExec(bodiesInfo, lWindDef, bnds, minCbPeriHgt, maxMsnDur, popSize, numGen, includeDepartVInf, includeArrivalVInf, maxDepartVInf, maxArriveVInf, celBodyData)
%multiFlybyExec Summary of this function goes here
%   Detailed explanation goes here

    nvars = length(bodiesInfo)+(length(bodiesInfo)-1)+(length(bodiesInfo)-1);

    flybyBodies = bodiesInfo(2:end-1);
    nFlybyBodies = length(flybyBodies);
    nSegments = nFlybyBodies + 1;
    minRadii = zeros(1, nFlybyBodies*popSize);
    maxRadii = zeros(1, nFlybyBodies*popSize);
    minRadiiSingle = [];
    maxRadiiSingle = [];
    for(i=1:nFlybyBodies) %#ok<*NO4LP>
        inds = (i-1)*popSize+1:i*popSize;
        atmoRad = (flybyBodies{i}.radius + flybyBodies{i}.atmohgt);
        minRadii(inds) = atmoRad*ones(size(inds));
        minRadiiSingle(i) = atmoRad; %#ok<AGROW>

        parentBodyInfo = flybyBodies{i}.getParBodyInfo(celBodyData);
        rSOI = getSOIRadius(flybyBodies{i}, parentBodyInfo);
        maxRadii(inds) = rSOI*ones(size(inds));
        maxRadiiSingle(i) = rSOI; %#ok<AGROW>
    end
    
    parentBodyInfo = flybyBodies{1}.getParBodyInfo(celBodyData);
    minXferRad = parentBodyInfo.radius + parentBodyInfo.atmohgt + minCbPeriHgt;

    [lb, ub] = getMultiFlybyLBUB(lWindDef(1), lWindDef(2), bodiesInfo, celBodyData);
    lb(2:1+length(bnds(:,1))) = bnds(:,1);
    ub(2:1+length(bnds(:,2))) = bnds(:,2);
    maxRevs = bnds(:,3);
    
    for(i=1:length(maxRevs))
        tmpNumRevsArrCell = -maxRevs(i):1:maxRevs(i);
        
        if(bodiesInfo{i}.id == bodiesInfo{i+1}.id)
            tmpNumRevsArrCell(tmpNumRevsArrCell==0) = [];
            
            if(isempty(tmpNumRevsArrCell))
                tmpNumRevsArrCell = [-1,1];
            end
        end
        
        numRevsArr{i} = tmpNumRevsArrCell; %#ok<AGROW>
        lb(end+1) = 1; %#ok<AGROW>
        ub(end+1) = length(tmpNumRevsArrCell); %#ok<AGROW>
    end
    
    IntCon = 1:nvars;
    IntCon = IntCon(length(bodiesInfo)+1:end);
   
    %linear constraint for the max mission duration
	if(maxMsnDur == Inf)
        maxMsnDur = realmax;
    else
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        maxMsnDur = maxMsnDur * secInDay; %convert to seconds
	end
    
    A = zeros(1,nvars);
    A(2:nSegments+1) = 1;
    b = maxMsnDur;
    
    fitnessfcn = @(x) multiFlybyObjFunc(x, numRevsArr,bodiesInfo,includeDepartVInf,includeArrivalVInf,celBodyData);
    nonlcon = @(x) multiFlybyNonlcon(x, fitnessfcn,minRadiiSingle,maxRadiiSingle,minXferRad,maxDepartVInf,maxArriveVInf);
    options = gaoptimset('Vectorized','on',...
                         'PopulationSize',popSize,...
                         'Display','iter',...
                         'PlotFcns', {@gaplotbestf, @gaplotscorediversity},...
                         'TolFun',1E-10,...
                         'Generations',numGen,...
                         'EliteCount',round(popSize/15));
    [~,~,exitflag,output,population,scores] = ga(fitnessfcn,nvars,A,b,[],[],lb,ub,nonlcon,IntCon,options);
    
    hGAPlot = findobj('Name','Genetic Algorithm');
    if(ishandle(hGAPlot))
        clf(hGAPlot);
    end
    
    if(isempty(population))
        x = [];
        dv = [];
        rp = []; 
        orbitsIn = [];
        orbitsOut = [];
        xferOrbits = [];
        deltaVVect = [];
        vInfDNorm = [];
        c = [];
        vInfDepart = [];
        vInfArrive = [];
        numRev = [];
        
        msgTxt = sprintf('The optimizer code terminated abnormally.\n\nExit code: %i\nExist Msg: %s\n\nIf you are using the maximum mission duration constraint, be sure that this constraint can be satisfied with the provided waypoint flight times!', exitflag, output.message);
        warndlg(msgTxt,'MFMS Run Abnormal Termination','modal');
                
        return
    end
    
    c = nonlcon(population);
    numCPerRow = size(c,2);
    cTest = c <= 0;
    cTest = sum(cTest,2);
    Ind = find(cTest==numCPerRow);
    if(~isempty(Ind))
        populationC = population(Ind,:);
        scoresC = scores(Ind,:);

        [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, celBodyData);
    else
        cMaxes = max(abs(c),[],1);
        cNorm = zeros(size(c));
        for(i=1:length(cMaxes))
            cNorm(:,i) = c(:,i)/cMaxes(i);
        end        
        [~,cI] = min(sum(cNorm,2));
        
        scoresC = scores(cI,:);
        populationC = population(cI,:);
        [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, celBodyData);
        
        warning('No valid solutions');
    end
end

