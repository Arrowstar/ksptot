function [x,fval,exitflag,output,solutions] = multiStartCommonRun(waitBarStr, numIter, fun, x0, A, b, lb, ub, nonlcon)
%multiStartCommonRun Summary of this function goes here
%   Detailed explanation goes here

    ticID = tic;
    
    if(strcmpi('CustomStartPointSet', class(numIter)))
        numIterAct = numIter.NumStartPoints;
    else 
        numIterAct = numIter;
    end

    hWaitBar = waitbar(0, waitBarStr);
    warning ('off','all');
    opts = optimoptions(@fmincon,'Algorithm','interior-point', 'TolFun', eps, 'TolX', eps, 'MaxIter', 300, 'FinDiffType', 'central', 'ScaleProblem', 'obj-and-constr');
    problem = createOptimProblem('fmincon','objective',fun,'x0',x0,'Aineq',A,'bineq',b,'lb',lb,'ub',ub,'nonlcon',nonlcon,'options',opts);
    ms = MultiStart('Display', 'iter', 'OutputFcns', @(optimValues, state) msOutFcn(optimValues, state, numIterAct, hWaitBar, waitBarStr, ticID));
    disp(waitBarStr);
    [x,fval,exitflag,output,solutions] = run(ms,problem,numIter);
    warning ('on','all');
    close(hWaitBar);
end

