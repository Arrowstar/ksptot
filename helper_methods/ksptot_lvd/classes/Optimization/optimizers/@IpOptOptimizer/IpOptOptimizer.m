classdef IpOptOptimizer < AbstractGradientOptimizer
    %IpOptOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        options(1,1) IpoptOptions = IpoptOptions();
    end
    
    methods
        function obj = IpOptOptimizer()
            obj.options = IpoptOptions();
        end
        
        function optimize(obj, lvdOpt, writeOutput, callOutputFcn, hLvdMainGUI)
            global ipoptFuncCount ipoptLastXVect
            ipoptFuncCount = 0;
            
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            ipoptLastXVect = x0All;
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
            evtNumToStartScriptExecAt = obj.getEvtNumToStartScriptExecAt(lvdOpt, actVars);
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true, []);    
            cFun = @(x) obj.computeConstrs(nonlcon, x);
            [~, numIneq, numEq] = cFun(x0All);
            numConstrs = numIneq + numEq;
            
            if(lvdOpt.gradAlgo == LvdOptimizerGradientCalculationAlgoEnum.BuiltIn)
                gradCalcMethod = lvdOpt.customFiniteDiffsCalcMethod;
            else
                gradCalcMethod = lvdOpt.getGradAlgoForEnum(lvdOpt.gradAlgo);
            end
            
            %sparsity calculations
            sparsityTF = gradCalcMethod.shouldComputeSparsity();
            if(sparsityTF)
%                 hMsgBox = msgbox('Computing sparsity.  Please wait...');
                hMsgBox = uiprogressdlg(hLvdMainGUI, 'Message','Computing sparsity.  Please wait...', 'Title','Computing Sparsity', 'Indeterminate',true, 'Icon','info');
            else
                hMsgBox = NaN;
            end

            fAtX0 = objFuncWrapper(x0All);
            gradCalcMethod.computeGradientSparsity(objFuncWrapper, x0All, fAtX0, obj.usesParallel());

            if(sparsityTF && isgraphics(hMsgBox))
                close(hMsgBox); drawnow nocallbacks;
            end
            %end sparsity calculations
            
            funcs.objective = @(x) obj.computeObjFun(objFuncWrapper, x);
            funcs.gradient = @(x) obj.computeGrad(funcs.objective, x, gradCalcMethod, obj.usesParallel());
            funcs.constraints = cFun;
            funcs.jacobian = @(x) obj.computeJacobian(cFun, x, gradCalcMethod, obj.usesParallel());
            funcs.jacobianstructure = @() obj.computeJacobianStruct(length(x0All), numConstrs);
            
            optionsStruct.lb = lbAll;
            optionsStruct.ub = ubAll;
            optionsStruct.cl = [-Inf * ones(numIneq,1); zeros(numEq,1)];
            optionsStruct.cu = zeros(numConstrs,1);
            optionsStruct.ipopt = obj.options.getOptionsForOptimizer();
            
            problem.x0 = x0All;
            problem.funcs = funcs;
            problem.options = optionsStruct;
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
            problem.solver = 'ipopt';
            problem.UseParallel = obj.usesParallel();
            
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
                
                outputFnc = @(iterNum, fVal, iterInfo) IpOptOptimizer.outputFunc(iterNum, fVal, iterInfo, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, objFuncWrapper, cFun, lbAll, ubAll, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll, optimStartTic);
                problem.funcs.iterfunc = outputFnc;
            end
            
            lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder, callOutputFcn);
            
            if(callOutputFcn)
                close(handlesObsOptimGui.ma_ObserveOptimGUI);
            end
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
        
        function setGradientCalculationMethod(obj, newGradCalcMethod)
            obj.gradCalcMethod = newGradCalcMethod;
        end
        
        function openOptionsDialog(obj)
%             lvd_editIpoptOptionsGUI(obj);
            
            output = AppDesignerGUIOutput({false});
            lvd_editIpoptOptionsGUI_App(obj, output);
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.usesParallel().optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.options.getNumParaWorkers();
        end
    end
    
    methods(Access=private)
        function [f, stateLog] = computeObjFun(~, objFun, x)
            global ipoptFuncCount ipoptLastXVect
            
            ipoptFuncCount = ipoptFuncCount + 1;
            ipoptLastXVect = x;
            [f, stateLog] = objFun(x);
        end
        
        function [g, stateLog] = computeGrad(~, objFun, x, gradCalcMethod, useParallel)
            [f, stateLog] = objFun(x);
            g = gradCalcMethod.computeGrad(objFun, x, f, useParallel);
        end
        
        function [cOut, numIneq, numEq] = computeConstrs(~, nonlcon, x)
            [c, ceq] = nonlcon(x);
            
            cOut = [c(:);ceq(:)];
            numIneq = length(c);
            numEq = length(ceq);
        end
        
        function J = computeJacobian(~, cFun, x, gradCalcMethod, useParallel)
            cAtX0 = cFun(x);
            J = gradCalcMethod.computeJacobian(cFun, x, cAtX0, useParallel);
            J = sparse(J);
        end
        
        function Js = computeJacobianStruct(~, numVars, numConstrs)
            Js = sparse(ones(numConstrs, numVars));
        end
    end
    
    methods(Static, Access=private)
        function stop = outputFunc(iterNum, fVal, iterInfo, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, objFcn, constrFunc, lb, ub, celBodyData, recorder, propNames, writeOutput, varLabels, lbUsAll, ubUsAll, optimStartTic)
            global ipoptFuncCount ipoptLastXVect
            
            x = ipoptLastXVect;
            cOut = constrFunc(x);
            cMax = max([0, max(cOut)]);
            
            optimValues.constrviolation = cMax;
            optimValues.firstorderopt = iterInfo.inf_pr;
            optimValues.funccount = ipoptFuncCount;
            optimValues.fval = fVal;
            optimValues.iteration = iterNum;
            optimValues.stepsize = iterInfo.d_norm;

            if(iterNum == 0)
                states = {'init','iter'};
            else
                states = {'iter'};
            end
            
            for(i=1:length(states))
                state = states{i};
                
                stop = IpOptOptimizer.getOutputFunction(x, optimValues, state, hOptimStatusLabel, hFinalStateOptimLabel, hDispAxes, hCancelButton, ...
                                                        objFcn, lb, ub, celBodyData, recorder, propNames, writeOutput, varLabels, lbUsAll, ubUsAll, optimStartTic);
            end
            
            stop = not(logical(stop));
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
                IpOptOptimizer.writeOptimStatus(hOptimStatusLabel, optimValues, state, writeOutput, optimStartTic);
                ma_UpdateStateReadout(hFinalStateOptimLabel, 'final', propNames, stateLogMA, celBodyData);
                IpOptOptimizer.generatePlots(x, optimValues, state, hDispAxes, lb, ub, varLabels, lbUsAll, ubUsAll);
                
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
            outStr{end+1} = ['Optimality           = ', num2str(optimValues.firstorderopt)];
            outStr{end+1} = ['Step Size            = ', num2str(optimValues.stepsize)];
            outStr{end+1} = '                       ';
            outStr{end+1} = ['Elapsed Time         = ', num2str(elapTime), ' sec'];
            
            set(hOptimStatusLabel, 'String', outStr);
            
            switch state
                case 'iter'
                    formatstr = ' %- 12.1i %- 12.0i %- 12.6g %- 12.3g %- 12.3g %- 12.3g';

                    iter = optimValues.iteration;
                    fcnt = optimValues.funccount;
                    val  = optimValues.fval;
                    feas = optimValues.constrviolation;
                    optm = optimValues.firstorderopt;
                    step = optimValues.stepsize;

                    hRow = sprintf(formatstr,iter,fcnt,val,feas,optm,step);
                    writeOutput(hRow,'append');
                case 'init'
                    hdrStr = sprintf('%- 13s%- 13s%- 13s%- 13s%- 13s%- 13s', 'Iteration','Fcn-Count','f(x)-Value', 'Feasibility', 'Optimality', 'Norm. Step');
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
            end

            if(strcmpi(state,'init'))
                hPlot1 = subplot(3,1,1);
            else
                axes(hPlot1);
            end
            optimplotxKsptot(x, optimValues, state, lb, ub, varLabels, lbUsAll, ubUsAll);

            if(strcmpi(state,'init'))
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
            optimplotfvalKsptot(x, optimValues, state);
            if(fValPlotIsLog)
                set(h,'yscale','log');
            else
                set(h,'yscale','linear');
            end
            grid on;
            grid minor;

            if(strcmpi(state,'init'))
                hPlot3 = subplot(3,1,3);
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