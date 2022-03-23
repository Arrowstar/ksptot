classdef PatternSearchOptimizer < AbstractOptimizer
    %PatternSearchOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) PatternSearchOptions = PatternSearchOptions();
    end
    
    methods
        function obj = PatternSearchOptimizer()
            obj.options = PatternSearchOptions();
        end
        
        function optimize(obj, lvdOpt, writeOutput, callOutputFcn, hLvdMainGUI)
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
%             typicalX = lvdOpt.vars.getTypicalScaledXVector();
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
            evtNumToStartScriptExecAt = obj.getEvtNumToStartScriptExecAt(lvdOpt, actVars);
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true, []);
                        
%             initMeshSize = norm(typicalX)/(10*length(typicalX));
            opts = obj.options.getOptionsForOptimizer(x0All);
%             opts = optimoptions(opts, 'ScaleMesh',scaleMesh, 'UseParallel',usePara, 'InitialMeshSize',initMeshSize);
            
            problem.objective = objFuncWrapper;
            problem.x0 = x0All;
            problem.Aineq = [];
            problem.bineq = [];
            problem.Aeq = [];
            problem.beq = [];
            problem.lb = lbAll;
            problem.ub = ubAll;
            problem.nonlcon = nonlcon;
            problem.options = opts;
            problem.solver = 'patternsearch';
            
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
                    
            %%% Run optimizer
            celBodyData = lvdOpt.lvdData.celBodyData;
            recorder = ma_OptimRecorder();
            
            if(callOutputFcn)
                propNames = lvdOpt.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
                handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);

                hOptimStatusLabel = handlesObsOptimGui.optimStatusLabel;
                hFinalStateOptimLabel = handlesObsOptimGui.finalStateOptimLabel;
                hDispAxes = handlesObsOptimGui.dispAxes;
                hCancelButton = handlesObsOptimGui.cancelButton;
                optimStartTic = tic();
                
                outputFnc = @(optimvalues,options,flag) PatternSearchOptimizer.getOutputFunction(optimvalues,options,flag, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                                                              problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll, optimStartTic);
                problem.options.OutputFcn = outputFnc;
            end
            
            lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder, callOutputFcn);
            
            if(callOutputFcn)
                close(handlesObsOptimGui.ma_ObserveOptimGUI);
            end
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.useParallel.optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.options.getNumParaWorkers();
        end
        
        function openOptionsDialog(obj)
%             lvd_editPatternSearchOptionsGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_editPatternSearchOptionsGUI_App(obj, output);
        end
    end
    
    methods(Static, Access=private)
        function [stop,options,optchanged] = getOutputFunction(optimValues,options,flag, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                               objFcn, lb, ub, celBodyData, recorder, propNames, writeOutput, varLabels, lbUsAll, ubUsAll, optimStartTic)
            
            optchanged = false;
            x = optimValues.x;
            maxConstr = PatternSearchOptimizer.getConstrViolation(optimValues);              

            switch flag
                case 'iter'
                    stop = get(hCancelButton,'Value');

                    recorder.iterNums(end+1) = optimValues.iteration;
                    recorder.xVals(end+1) = {x};
                    recorder.fVals(end+1) = optimValues.fval;            
                    recorder.maxCVal(end+1) = maxConstr;
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
                       
            if(strcmpi(flag,'init') || strcmpi(flag,'iter'))
                PatternSearchOptimizer.writeOptimStatus(hOptimStatusLabel, optimValues, flag, writeOutput, optimStartTic);
                ma_UpdateStateReadout(hFinalStateOptimLabel, 'final', propNames, stateLogMA, celBodyData);
                PatternSearchOptimizer.generatePlots(x, optimValues, flag, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll);
                drawnow;
            end
        end
        
        function writeOptimStatus(hOptimStatusLabel, optimValues, flag, writeOutput, timer)
            elapTime = toc(timer);

            maxConstr = PatternSearchOptimizer.getConstrViolation(optimValues);
            
            if(length(optimValues.method) > 13)
                method = optimValues.method(1:13);
            else
                method = optimValues.method;
            end
            
            outStr = {};
            outStr{end+1} = ['State                = ', flag];
            outStr{end+1} = '                        ';
            outStr{end+1} = ['Iterations           = ', num2str(optimValues.iteration)];
            outStr{end+1} = ['Function Evals       = ', num2str(optimValues.funccount)];
            outStr{end+1} = ['Objective Value      = ', num2str(optimValues.fval)];
            outStr{end+1} = ['Constraint Violation = ', num2str(maxConstr)];
            outStr{end+1} = ['Method               = ', method];
            outStr{end+1} = ['Mesh Size            = ', num2str(optimValues.meshsize)];
            outStr{end+1} = '                       ';
            outStr{end+1} = ['Elapsed Time         = ', num2str(elapTime), ' sec'];
            
            set(hOptimStatusLabel, 'String', outStr);
            
            switch flag
                case 'iter'
                    formatstr = ' %- 12.1i %- 12.0i %- 12.6g %- 12.3g %- 13s %- 12.3g';

                    iter = optimValues.iteration;
                    fcnt = optimValues.funccount;
                    val  = optimValues.fval;
                    feas = maxConstr;
                    mesh = optimValues.meshsize;

                    hRow = sprintf(formatstr,iter,fcnt,val,feas,method,mesh);
                    writeOutput(hRow,'append');
                case 'init'
                    hdrStr = sprintf('%- 13s%- 13s%- 13s%- 13s%- 13s%- 13s', 'Iteration','Fcn-Count','f(x)-Value', 'Feasibility', 'Method', 'Mesh Size');
                    writeOutput(hdrStr,'append');
            end
        end
        
        function generatePlots(x, optimValues, flag, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll)
            persistent fValPlotIsLog hPlot1 hPlot2 hPlot3

            if(isempty(fValPlotIsLog))
                fValPlotIsLog = true;
            end

            switch flag
                case 'init'
                    if(isvalid(hDispAxes))
                        set(hDispAxes,'Visible','on');
                        subplot(hDispAxes);
                        axes(hDispAxes);
                    end
                    fValPlotIsLog = true;
            end

            if(strcmpi(flag,'init'))
                hPlot1 = subplot(3,1,1);
            else
                axes(hPlot1);
            end
            optimplotxKsptot(x, optimValues, flag, lb, ub, varLabels, lbUsAll, ubUsAll);

            if(strcmpi(flag,'init'))
                hPlot2 = subplot(3,1,2);
                h = hPlot2;
            else
                h = hPlot2;
                axes(hPlot2);
            end
            if(optimValues.fval<=0)
                fValPlotIsLog = false;
                set(h,'yscale','linear');
            end
            psplotbestf(optimValues, flag);
            if(fValPlotIsLog)
                set(h,'yscale','log');
            else
                set(h,'yscale','linear');
            end
            grid on;
            grid minor;

            if(strcmpi(flag,'init'))
                hPlot3 = subplot(3,1,3);
                h = hPlot3;
            else
                h = hPlot3;
                axes(hPlot3);
            end
            psplotmaxconstr(optimValues, flag);

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
        
        function maxConstr = getConstrViolation(optimValues)
            if(not(isfield(optimValues,'nonlinineq')))
                optimValues.nonlinineq = [];
            end
            
            if(not(isfield(optimValues,'nonlineq')))
                optimValues.nonlineq = [];
            end
            
            maxConstr = max([max(abs(optimValues.nonlinineq)), max(abs(optimValues.nonlineq))]);

            if(isempty(maxConstr))
                maxConstr = 0;
            end
        end
    end
end