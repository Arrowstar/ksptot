function [x,fval,exitflag,output,solutions] = multiStartCommonRun(waitBarStr, numIter, fun, x0, A, b, lb, ub, nonlcon, hUiProgDlg)
%multiStartCommonRun Summary of this function goes here
%   Detailed explanation goes here

    arguments
        waitBarStr (1,:) char
        numIter 
        fun 
        x0 double
        A double
        b double
        lb double
        ub double
        nonlcon 
        hUiProgDlg = [];
    end

    ticID = tic;
    
    if(strcmpi('CustomStartPointSet', class(numIter)))
        numIterAct = numIter.NumStartPoints;
    else 
        numIterAct = numIter;
    end

    if(not(isempty(hUiProgDlg)))
        hWaitBar = hUiProgDlg;
    else
        hWaitBar = waitbar(0, waitBarStr);
    end

    warning ('off','all');
    opts = optimoptions(@fmincon,'Algorithm','interior-point', 'TolFun', eps, 'TolX', eps, 'MaxIter', 300, 'FinDiffType', 'central', 'ScaleProblem', 'obj-and-constr');
    problem = createOptimProblem('fmincon','objective',fun,'x0',x0,'Aineq',A,'bineq',b,'lb',lb,'ub',ub,'nonlcon',nonlcon,'options',opts);
    ms = MultiStart('Display', 'iter', 'OutputFcns', @(optimValues, state) msOutFcn(optimValues, state, numIterAct, hWaitBar, waitBarStr, ticID));
    disp(waitBarStr);
    [x,fval,exitflag,output,solutions] = run(ms,problem,numIter);
    warning ('on','all');
    
    if(~isa(hWaitBar, 'matlab.ui.dialog.ProgressDialog'))
        close(hWaitBar);
    end
end

