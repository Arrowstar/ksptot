classdef SurrogateOptimizer < AbstractOptimizer
    %SurrogateOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        options(1,1) SurrogateOptimizerOptions = SurrogateOptimizerOptions();
    end
    
    methods
        function obj = SurrogateOptimizer()
            obj.options = SurrogateOptimizerOptions();
        end
        
        function [exitflag, message] = optimize(obj, lvdOpt, writeOutput, callOutputFcn, hLvdMainGUI)
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
            evtNumToStartScriptExecAt = obj.getEvtNumToStartScriptExecAt(lvdOpt, actVars);
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true, []);
            objconstr = @(x) SurrogateOptimizer.getObjConstr(x, objFuncWrapper, nonlcon);       
            
            opts = obj.options.getOptionsForOptimizer(x0All);
                                                
            problem = struct('objective',objconstr, 'lb', lbAll, 'ub', ubAll, 'options', opts);
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
            problem.solver = 'surrogateopt';     
            
            %%% Run optimizer
            recorder = ma_OptimRecorder();
            celBodyData = lvdOpt.lvdData.celBodyData;
            
            if(callOutputFcn)
                propNames = lvdOpt.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
                handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);
                
                hOptimStatusLabel = handlesObsOptimGui.optimStatusLabel;
                hFinalStateOptimLabel = handlesObsOptimGui.finalStateOptimLabel;
                hDispAxes = handlesObsOptimGui.dispAxes;
                hCancelButton = handlesObsOptimGui.cancelButton;
                optimStartTic = tic();

%                 outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);

                outputFnc = @(x, optimValues, state) SurrogateOptimizer.getOutputFunction(x, optimValues, state, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                                                          problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll, optimStartTic);
                problem.options.OutputFcn = outputFnc;
            end
            
            [exitflag, message] = lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder, callOutputFcn);
            
            if(callOutputFcn)
                close(handlesObsOptimGui.ma_ObserveOptimGUI);
            end
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
               
        function openOptionsDialog(obj)
%             lvd_editSurrogateOptOptionsGUI(obj);

            output = AppDesignerGUIOutput({false});
            lvd_editSurrogateOptOptionsGUI_App(obj, output);
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.useParallel.optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.options.getNumParaWorkers();
        end
    end
    
    methods(Static, Access=private)
        function [objconstr, stateLog] = getObjConstr(x, objFunc, nonlcon)
            if(isempty(x))
                 objconstr.Fval = realmax;
                 objconstr.Ineq = [];
            else
                [fval, stateLog] = objFunc(x);
                [c, ceq] = nonlcon(x);

                cFull = [c(:);
                         ceq(:);
                         -ceq(:);];

                 objconstr.Fval = fval;
                 objconstr.Ineq = cFull;
            end
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
                       
            if(strcmpi(state,'iter'))
                [~, stateLog] = objFcn(optimValues.currentX);

%                 finalStateLogEntry = stateLog.getFinalStateLogEntry();
%                 finalStateLogEntryMA = finalStateLogEntry.getMAFormattedStateLogMatrix(true);

                stateLogMA = stateLog.getMAFormattedStateLogMatrix(true);
                
                ma_UpdateStateReadout(hFinalStateOptimLabel, 'final', propNames, stateLogMA, celBodyData);
            end
            
            if(strcmpi(state,'init') || strcmpi(state,'iter'))
                SurrogateOptimizer.writeOptimStatus(hOptimStatusLabel, optimValues, state, writeOutput, optimStartTic);
                SurrogateOptimizer.generatePlots(x, optimValues, state, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll);
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
            outStr{end+1} = ['Current Point Flag   = ', optimValues.currentFlag];
            outStr{end+1} = ['Number Surr. Resets  = ', num2str(optimValues.surrogateResetCount)];
            outStr{end+1} = '                       ';
            outStr{end+1} = ['Elapsed Time         = ', num2str(elapTime), ' sec'];
            
            set(hOptimStatusLabel, 'String', outStr);
            
            switch state
                case 'iter'
                    formatstr = ' %- 12.1i %- 12.0i %- 12.6g %- 12.3g %- 12s %- 12.3i';

                    iter = optimValues.iteration;
                    fcnt = optimValues.funccount;
                    val  = optimValues.fval;
                    feas = optimValues.constrviolation;
                    optm = optimValues.currentFlag;
                    step = optimValues.surrogateResetCount;

                    hRow = sprintf(formatstr,iter,fcnt,val,feas,optm,step);
                    writeOutput(hRow,'append');
                case 'init'
                    hdrStr = sprintf('%- 13s%- 13s%- 13s%- 13s%- 13s%- 13s', 'Iteration','Fcn-Count','f(x)-Value', 'Feasibility', 'Current Flag', 'Reset Cnt');
                    writeOutput(hdrStr,'append');
            end
        end
        
        function generatePlots(x, optimValues, state, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll)
            persistent fValPlotIsLog hPlot1 hPlot2 hPlot3

            if(isempty(fValPlotIsLog))
                fValPlotIsLog = true;
            end

            switch state
                case 'init'
                    if(isvalid(hDispAxes))
                        set(hDispAxes,'Visible','on');
                        subplot(hDispAxes);
                        axes(hDispAxes);
                    end
                    fValPlotIsLog = true;
                    
                    if(isempty(x))
                        x = lb;
                    end
                    
                    if(isempty(optimValues.currentX))
                        optimValues.currentX = lb;
                    end
            end

            if(strcmpi(state,'init'))
                hPlot1 = subplot(2,1,1);
            else
                axes(hPlot1);
            end
            optimplotxKsptot(optimValues.currentX, optimValues, state, lb, ub, varLabels, lbUsAll, ubUsAll);

%             if(strcmpi(state,'init'))
%                 hPlot2 = subplot(3,1,2);
%                 h = hPlot2;
%             else
%                 h = hPlot2;
%                 axes(hPlot2);
%             end
%             if(optimValues.fval<=0)
%                 fValPlotIsLog = false;
%                 set(h,'yscale','linear');
%             end
%             optimplotfvalconstr(x, optimValues, state);
%             if(fValPlotIsLog)
%                 set(h,'yscale','log');
%             else
%                 set(h,'yscale','linear');
%             end
%             grid on;
%             grid minor;

            if(strcmpi(state,'init'))
                hPlot3 = subplot(2,1,2);
                h = hPlot3;
            else
                h = hPlot3;
                axes(hPlot3);
            end
            surrogateoptplot(x, optimValues, state);

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