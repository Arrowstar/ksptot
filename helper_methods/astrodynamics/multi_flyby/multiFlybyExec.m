function [x, dv, rp, orbitsIn, orbitsOut, xferOrbits, deltaVVect, vInfDNorm, c, vInfDepart, vInfArrive, numRev] = multiFlybyExec(bodiesInfo, lWindDef, bnds, minCbPeriHgt, maxMsnDur, popSize, numGen, includeDepartVInf, includeArrivalVInf, maxDepartVInf, maxArriveVInf, eSMA, eEcc, eInc, eRAAN, eArg, celBodyData)
%multiFlybyExec Summary of this function goes here
%   Detailed explanation goes here

    nvars = length(bodiesInfo) + (length(bodiesInfo)-1) + (length(bodiesInfo)-1) + 1;

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
    
    parentBodyInfo = bodiesInfo{1}.getParBodyInfo(celBodyData);
    minXferRad = parentBodyInfo.radius + parentBodyInfo.atmohgt + minCbPeriHgt;

    [lb, ub] = getMultiFlybyLBUB(lWindDef(1), lWindDef(2), bodiesInfo, celBodyData);
    lb(2:1+length(bnds(:,1))) = bnds(:,1);
    ub(2:1+length(bnds(:,2))) = bnds(:,2);
    maxRevs = bnds(:,3);
    maxDeltaV = bnds(:,4);
    
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

    %departure true anomaly relative to initial eccentric orbit
    lb(end+1) = 0;
    ub(end+1) = 2*pi;
    
    IntCon = 1:nvars;
    IntCon = IntCon(length(bodiesInfo)+1:end-1);
   
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
    
    fitnessfcn = @(x) multiFlybyObjFunc(x, numRevsArr,bodiesInfo,includeDepartVInf,includeArrivalVInf, eSMA, eEcc, eInc, eRAAN, eArg, celBodyData);
    nonlcon = @(x) multiFlybyNonlcon(x, fitnessfcn,minRadiiSingle,maxRadiiSingle,minXferRad,maxDepartVInf,maxArriveVInf,maxDeltaV(2:end));
    options = gaoptimset('Vectorized','on',...
                         'PopulationSize',popSize,...
                         'Display','iter',...
                         'PlotFcns', {@gaplotbestf, @gaplotscorediversity},...
                         'TolFun',1E-10,...
                         'TolCon', 1E-6,...
                         'Generations',numGen);
    [xstar,fstar,exitflag,output,population,scores] = ga(fitnessfcn,nvars,A,b,[],[],lb,ub,nonlcon,IntCon,options);
    
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
    
    [c, ~] = nonlcon(population);
%     numCPerRow = size(c,2);
%     cTest = c <= 0;
%     cTest = sum(cTest,2);
%     Ind = find(cTest==numCPerRow);
    cBool = all(c <= 0, 2);
    if(any(cBool))
        [~,cI] = min(scores(cBool));
        x = population(cI, :);
    else
        [~,cI] = min(scores);
        x = population(cI, :);
    end

    [dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, vInfDepart, vInfArrive, totDV, r1B, r2B, v1Output, v2Output, xferRp] = fitnessfcn(x);
    c = nonlcon(x); 

    numREVS = length(bodiesInfo) - 1;
    numDepartTru = 1;
    numRevInds = x(:,end-numREVS+1-numDepartTru:end-numDepartTru);
    
    for(i=1:size(numRevInds,2)) %#ok<*NO4LP>
        numRevInd = numRevInds(:,i);
        numRev(i) = numRevsArr{i}(numRevInd); %#ok<AGROW>
    end

    xferOrbits = getMultiFlybyXferOrbits(x, numRev, r1B, r2B, v1Output, v2Output, bodiesInfo, celBodyData);

%     if(~isempty(Ind))
%         populationC = population(Ind,:);
%         scoresC = scores(Ind,:);
% 
%         [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, maxDeltaV(2:end), celBodyData);
%     else
%         cMaxes = max(abs(c),[],1);
%         cNorm = zeros(size(c));
%         for(i=1:length(cMaxes))
%             cNorm(:,i) = c(:,i)/cMaxes(i);
%         end        
%         [~,cI] = min(sum(cNorm,2));
%         
%         scoresC = scores(cI,:);
%         populationC = population(cI,:);
%         [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(scoresC, populationC, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, maxDeltaV(2:end), celBodyData);
%         
%         warning('No valid solutions');
%     end

%     try
%         fitnessfcnFmincon = @(xx) multiFlybyObjFunc(joinIntConToNonInts(xx, x, IntCon), numRevsArr,bodiesInfo,includeDepartVInf,includeArrivalVInf,celBodyData);
%         nonlconFmincon = @(xx) multiFlybyNonlcon(joinIntConToNonInts(xx, x, IntCon), fitnessfcnFmincon,minRadiiSingle,maxRadiiSingle,minXferRad,maxDepartVInf,maxArriveVInf);
% 
%         notIntBool = not(ismember(1:length(x), IntCon));
% 
%         x0Fmincon = x(notIntBool);
% 
%         hLB = lb(notIntBool);     
%         hUB = ub(notIntBool);
% 
%         Afmincon = A(:,notIntBool);
% 
%         options = optimoptions(@fmincon, 'Display','iter', ...
%                                          'Algorithm','interior-point', ...
%                                          'OptimalityTolerance',1E-10, ...
%                                          'UseParallel',false, ...
%                                          'BarrierParamUpdate','predictor-corrector', ...
%                                          'HonorBounds',true);
% 
%         f = msgbox('Attempting gradient-based hybrid optimization... please wait.','Hybrid Optimization','help');
%         [xfmincon, fval, exitFlag] = fmincon(fitnessfcnFmincon,x0Fmincon,Afmincon,b,[],[],hLB,hUB,nonlconFmincon,options);
%         
%         if(isvalid(f))
%             close(f);
%         end
%         
%         if(exitFlag > 0 && fval < min(scoresC))
%             xfminconTotal = x;
%             xfminconTotal(notIntBool) = xfmincon;
%             [x, dv, rp, orbitsIn, orbitsOut, deltaVVect, vInfDNorm, xferOrbits, c, vInfDepart, vInfArrive, numRev] = findSaneTraj(fval, xfminconTotal, bodiesInfo, lb, ub, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, numRevsArr, maxDepartVInf, maxArriveVInf, celBodyData);      
%         end
%     catch ME
%         warning(ME.identifier, 'Hybrid optimization call failed, reverting back to GA solution.  Msg:\n\n%s', ME.message);
%     end
end

function x = joinIntConToNonInts(nonIntX, allX, IntCon)
    notIntBool = not(ismember(1:length(allX), IntCon));
    if(numel(nonIntX) == numel(allX))
        nonIntX = nonIntX(notIntBool);
    end
    
    x = allX;
    x(notIntBool) = nonIntX;    
end
