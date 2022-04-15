classdef NomadOptimizer < AbstractOptimizer
    %NomadOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) NomadOptions = NomadOptions();
    end
    
    methods
        function obj = NomadOptimizer()
            obj.options = NomadOptions();
        end
        
        function [exitflag, message] = optimize(obj, lvdOpt, writeOutput, callOutputFcn, hLvdMainGUI)
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            typicalX = lvdOpt.vars.getTypicalScaledXVector();
            lvdData = lvdOpt.lvdData;
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
            evtNumToStartScriptExecAt = obj.getEvtNumToStartScriptExecAt(lvdOpt, actVars);
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nonlcon = @(x, tfRunScript, stateLog) lvdOpt.constraints.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, true, stateLog);
                        
            opts = obj.options.getOptionsForOptimizer();
            constrTypeStr = obj.options.getConstrTypeStr();
            useParallel = obj.options.usesParallel();
            
            [c, ceq] = lvdOpt.constraints.evalConstraints(x0All, true, evtToStartScriptExecAt, false, []);
            numConstr = length(c) + 2*length(ceq);
            bboutput = horzcat({'OBJ'}, repmat({constrTypeStr},1,numConstr));
            numElemPerOutput = length(bboutput);
            bboutput = strjoin(bboutput,' ');
            nomadNonlconWrapper = @(x) NomadOptimizer.nomadConstrWrapper(x, nonlcon);
            
            pp = gcp('nocreate');
            if(isempty(pp) || useParallel == false) %
                numWorkers = 0;
                useParallel = false;
            else
                numWorkers = pp.NumWorkers;
                useParallel = true;
            end
            
            numVars = length(x0All);
            f = @(x) NomadOptimizer.nomadObjConstrWrapper(x, objFuncWrapper, nomadNonlconWrapper, numVars, numElemPerOutput, numWorkers, lvdData);
            opts = nomadset(opts, 'bb_output_type',bboutput);
            
            problem.objective = f; %f
            problem.x0 = x0All;
            problem.lb = lbAll;
            problem.ub = ubAll;
            problem.options = opts;
            
            problem.solver = 'nomad';
            
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
                    
            %%% Run optimizer
            celBodyData = lvdOpt.lvdData.celBodyData;
            recorder = ma_OptimRecorder();
            
            if(callOutputFcn)
                propNames = lvdOpt.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
%                 handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);

                out = AppDesignerGUIOutput();
                ma_ObserveOptimGUI_App(out);
                handlesObsOptimGui = out.output{1};

%                 outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
                hOptimStatusLabel = handlesObsOptimGui.optimStatusLabel;
                hFinalStateOptimLabel = handlesObsOptimGui.finalStateOptimLabel;
                hDispAxes = handlesObsOptimGui.dispAxesPanel;
                hCancelButton = handlesObsOptimGui.cancelButton;
                optimStartTic = tic();
                
                outputFnc = @(x, optimValues, state) NomadOptimizer.getOutputFunction(x, optimValues, state, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                                                      problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll, optimStartTic);

                nomadOutput1 = @(iter, fval, x, state) NomadOptimizer.nomadIterFunWrapper(iter, fval, x, outputFnc, state, numVars);
                nomadOutput2 = @(iter, fval, x) nomadOutput1(iter, fval, x, 'iter');
                problem.options = nomadset(problem.options, 'iterfun',nomadOutput2);
                nomadOutput1(0,NaN,x0All,'init');
            end
            
            problem.UseParallel = useParallel;
            [exitflag, message] = lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder, callOutputFcn);
            
            if(callOutputFcn)
                close(handlesObsOptimGui.ma_ObserveOptimGUI);
            end
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
        
        function tf = usesParallel(obj)
            tf = obj.getOptions().usesParallel();
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.options.getNumParaWorkers();
        end
        
        function openOptionsDialog(obj)
%             lvd_editNomadOptionsGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_editNomadOptionsGUI_App(obj, output);
        end
    end
    
    methods(Static, Access=private)
        function [f, stateLog] = nomadObjFuncWrapper(x, objFuncWrapper)
            global nomadCachedX nomadCachedStateLog
            
            [f, stateLog] = objFuncWrapper(x);
            
            nomadCachedX = x;
            nomadCachedStateLog = stateLog;
        end
        
        function c = nomadConstrWrapper(x, nonlcon)
            global nomadCachedX nomadCachedStateLog
            
            if(numel(x) ~= numel(nomadCachedX))
                nomadCachedX = NaN(size(x));
            end
            
            if(all(x(:) == nomadCachedX(:)))
                [cM, ceqM] = nonlcon(x, false, nomadCachedStateLog);
            else
                [cM, ceqM] = nonlcon(x, true, []);
            end
            
            c = [cM(:); ceqM(:); -1*ceqM(:)]';
            c = c(:);
        end
        
        function [fc, stateLogs] = nomadObjConstrWrapper(x, objFun, nonlcon, numVars, numElementsInEachOutput, M, lvdData)
            try
                if(numel(x) == numVars)
                    numEvals = 1;
                else
                    numEvals = size(x,1);
                end

                x = reshape(x, numEvals, numel(x)/numEvals);

                fc = NaN(numEvals,numElementsInEachOutput);

                for(i=1:numEvals) %#ok<NO4LP>
                    stateLogs(i) = LaunchVehicleStateLog(lvdData); %#ok<AGROW>
                end

                if(M > 0 && numEvals > 1)
                    pp = gcp();
                    opts = parforOptions(pp,'RangePartitionMethod','fixed','SubrangeSize',ceil(pp.NumWorkers/numEvals));
                    parfor(i=1:numEvals,opts)
                        xI = x(i,:);
                        [fcRow, stateLog] = NomadOptimizer.loopInternal(xI, objFun, nonlcon);

                        fc(i,:) = fcRow;
                        stateLogs(i) = stateLog;
                    end
                else
                    for(i=1:numEvals)
                        xI = x(i,:);
                        [fcRow, stateLog] = NomadOptimizer.loopInternal(xI, objFun, nonlcon);

                        fc(i,:) = fcRow;
                        stateLogs(i) = stateLog;
                    end
                end
            catch ME
                disp(ME.message);
            end
        end
        
        function [fcRow, stateLog] = loopInternal(xI, objFun, nonlcon)
            [f, stateLog] = objFun(xI);
            [c] = nonlcon(xI);

            fcRow = [f; c(:);]';
        end
        
        function stop = nomadIterFunWrapper(iter, fval, x, outputFnc, state, numVars)
            if(numel(x) == numVars)
                numEvals = 1;
            else
                numEvals = size(x,1);
            end

            x = reshape(x, numEvals, numel(x)/numEvals);
            
            f = fval(:,1);
            c = fval(:,2:end);
            
            if(isempty(c))
                [fval,I] = min(f);
                cViol = 0;
                xx = x(I,:);
            else
                c(c <= 0) = 0;
                cViol = sqrt(sum(c.^2,2));
                
                [minViolation,I] = min(cViol);
                
                if(sum(cViol == minViolation) > 1)
                    boolC = cViol == minViolation;
                    fBool = f(boolC);
                    [minFBool,~] = min(fBool);
                    
                    boolF = f == minFBool;
                    II = find(boolF & boolC,1,'first');
                    
                    fval = f(II);
                    cViol = minViolation;
                    xx = x(II,:);
                else
                    fval = f(I);
                    cViol = minViolation;
                    xx = x(I,:);
                end
            end
            
            optimValues.constrviolation = max(cViol, 0);
            optimValues.funccount = iter;
            optimValues.fval = fval;
            optimValues.iteration = iter;
            optimValues.stepsize = 0;
            optimValues.firstorderopt = 0;

            stop = outputFnc(xx, optimValues, state);
            stop = logical(stop);
        end
        
        function stop = getOutputFunction(x, optimValues, state, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                               objFcn, lb, ub, celBodyData, recorder, propNames, writeOutput, varLabels, lbUsAll, ubUsAll, optimStartTic)
            switch state
                case 'iter'
                    stop = get(hCancelButton,'Value');

                    recorder.iterNums(end+1) = optimValues.iteration;
                    recorder.xVals(end+1) = {x};
                    recorder.fVals(end+1) = optimValues.fval;            
                    recorder.maxCVal(end+1) = optimValues.constrviolation;
                case {'init','interrupt','done'}
                    stop = get(hCancelButton,'Value');
            end
            
            if(stop == true)
                return;
            end
            
            [~, stateLog] = objFcn(x);
            
%             finalStateLogEntry = stateLog.getFinalStateLogEntry();
%             finalStateLogEntryMA = finalStateLogEntry.getMAFormattedStateLogMatrix(true);

            stateLogMA = stateLog.getMAFormattedStateLogMatrix(true);
            
            if(strcmpi(state,'init') || strcmpi(state,'iter'))
                NomadOptimizer.writeOptimStatus(hOptimStatusLabel, optimValues, state, writeOutput, optimStartTic);
                ma_UpdateStateReadout(hFinalStateOptimLabel, 'final', propNames, stateLogMA, celBodyData);
                NomadOptimizer.generatePlots(x, optimValues, state, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll);
                drawnow;
            end
        end
        
        function writeOptimStatus(hOptimStatusLabel, optimValues, state, writeOutput, timer)
            elapTime = toc(timer);

            outStr = {};
            outStr{end+1} = ['State                = ', state];
            outStr{end+1} = '                        ';
            outStr{end+1} = ['Iterations           = ', num2str(optimValues.iteration)];
            outStr{end+1} = ['Function Evals       = ', num2str(optimValues.funccount)];
            outStr{end+1} = ['Objective Value      = ', num2str(optimValues.fval)];
            outStr{end+1} = ['Constraint Violation = ', num2str(optimValues.constrviolation)];
            outStr{end+1} = '                       ';
            outStr{end+1} = ['Elapsed Time         = ', num2str(elapTime), ' sec'];
            
            set(hOptimStatusLabel, 'String', outStr);
            
            switch state
                case 'iter'
                    formatstr = ' %- 12.1i %- 12.0i %- 12.6g %- 12.3g';

                    iter = optimValues.iteration;
                    fcnt = optimValues.funccount;
                    val  = optimValues.fval;
                    feas = optimValues.constrviolation;

                    hRow = sprintf(formatstr,iter,fcnt,val,feas);
                    writeOutput(hRow,'append');
                case 'init'
                    hdrStr = sprintf('%- 13s%- 13s%- 13s%- 13s', 'Iteration','Fcn-Count','f(x)-Value', 'Feasibility');
                    writeOutput(hdrStr,'append');
            end
        end
        
        function generatePlots(x, optimValues, state, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll)
            persistent fValPlotIsLog tLayout hPlot1 hPlot2 hPlot3

            if(isempty(fValPlotIsLog))
                fValPlotIsLog = true;
            end

            switch state
                case 'init'
                    if(isvalid(hDispAxes))
%                         set(hDispAxes,'Visible','on');
%                         subplot(hDispAxes);
%                         axes(hDispAxes);
                        tLayout = tiledlayout(hDispAxes, 3,1);
                    end
                    fValPlotIsLog = true;
            end

            if(strcmpi(state,'init'))
                hPlot1 = nexttile(tLayout, 1);
                hPlot1.XTickLabel= [];
                hPlot1.YTickLabel= [];
                hPlot1.ZTickLabel= [];
                axes(hPlot1);
            else
                axes(hPlot1);
            end
            optimplotxKsptot(x, optimValues, state, lb, ub, varLabels, lbUsAll, ubUsAll);

            if(strcmpi(state,'init'))
                hPlot2 = nexttile(tLayout, 2);
                hPlot2.XTickLabel= [];
                hPlot2.YTickLabel= [];
                hPlot2.ZTickLabel= [];
                h = hPlot2;
            else
                h = hPlot2;
                axes(hPlot2);
            end
            if(optimValues.fval<=0)
                fValPlotIsLog = false;
                set(h,'yscale','linear');
            end
            optimplotfvalKsptot(x, optimValues, state);
            if(fValPlotIsLog)
                set(h,'yscale','log');
            else
                set(h,'yscale','linear');
            end
            grid on;
            grid minor;

            if(strcmpi(state,'init'))
                hPlot3 = nexttile(tLayout, 3);
                hPlot3.XTickLabel= [];
                hPlot3.YTickLabel= [];
                hPlot3.ZTickLabel= [];
                h = hPlot3;
            else
                h = hPlot3;
                axes(hPlot3);
            end
            optimplotconstrviolationKsptot(x, optimValues, state);

            if(not(isempty(h.Children)))
                hLine = h.Children(1);
                if(isa(hLine,'matlab.graphics.chart.primitive.Line'))
                    yDataLine = hLine.YData;
                    if(abs(max(yDataLine) / min(yDataLine)) >= 10 && all(yDataLine > 0))
                        set(h,'yscale','log');
                    else
                        set(h,'yscale','linear');
                    end
                else
                    set(h,'yscale','linear');
                end
            end

            grid on;
            grid minor;
        end
    end
end