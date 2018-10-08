function stop = ma_OptimOutputFunc(x, optimValues, state, handles, problem, celBodyData, recorder, propNames)
    stop = false;
    switch state
        case 'iter'
            stop = get(handles.cancelButton,'Value');
            
            recorder.iterNums(end+1) = optimValues.iteration;
            recorder.xVals(end+1) = {x};
            recorder.fVals(end+1) = optimValues.fval;
            recorder.maxCVal(end+1) = optimValues.constrviolation;    
        case 'interrupt'
            stop = get(handles.cancelButton,'Value');
    end
    
    if(stop == true)
        return;
    end
    
    [~, stateLog] = problem.objective(x);

    if(isa(stateLog,'LaunchVehicleStateLog'))
        stateLog = stateLog.getMAFormattedStateLogMatrix();
    end
    
    writeOptimStatus(handles, optimValues, state);
    writeFinalState(handles, stateLog, celBodyData, propNames);
    generatePlots(x, optimValues, state, handles, problem.lb, problem.ub);
    drawnow;
end


function writeOptimStatus(handles, optimValues, state)
    persistent timer;
    
    elapTime = 0;
    switch state
        case 'iter'
            elapTime = toc(timer);
        case 'interrupt'
            elapTime = toc(timer);
        case 'init'
            timer = tic;
            elapTime = 0;
    end
    
    outStr = {};
    outStr{end+1} = ['State                = ', state];
    outStr{end+1} = '                        ';
    outStr{end+1} = ['Iterations           = ', num2str(optimValues.iteration)];
    outStr{end+1} = ['Function Evals       = ', num2str(optimValues.funccount)];
    outStr{end+1} = ['Objective Value      = ', num2str(optimValues.fval)];
    outStr{end+1} = ['Constraint Violation = ', num2str(optimValues.constrviolation)];
    outStr{end+1} = ['Optimality           = ', num2str(optimValues.firstorderopt,5)];
    outStr{end+1} = ['Step Size            = ', num2str(optimValues.stepsize)];
    outStr{end+1} = ['                       ' ];
    outStr{end+1} = ['Elapsed Time         = ', num2str(elapTime), ' sec'];
    
    set(handles.optimStatusLabel, 'String', outStr);
end

function writeFinalState(handles, stateLog, celBodyData, propNames)
    whichState = 'final';
    hStateReadoutLabel = handles.finalStateOptimLabel;
    ma_UpdateStateReadout(hStateReadoutLabel, whichState, propNames, stateLog, celBodyData);
end
    
function generatePlots(x, optimValues, state, handles, lb, ub)
    persistent fValPlotIsLog
    
    if(isempty(fValPlotIsLog))
        fValPlotIsLog = true;
    end
    
    switch state
        case 'init'
            set(handles.dispAxes,'Visible','on');
            subplot(handles.dispAxes);
            fValPlotIsLog = true;
    end
    
    set(groot,'CurrentFigure',handles.ma_ObserveOptimGUI);
    
    subplot(3,1,1);
    optimplotxKsptot(x, optimValues, state, lb, ub);
    
    h=subplot(3,1,2);
    if(optimValues.fval<=0)
        fValPlotIsLog = false;
        set(h,'yscale','linear');
    end
    optimplotfval(x, optimValues, state);
    if(fValPlotIsLog)
        set(h,'yscale','log');
    else
        set(h,'yscale','linear');
    end
    
    subplot(3,1,3);
    optimplotconstrviolation(x, optimValues, state);
end