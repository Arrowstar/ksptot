classdef NomadOptimizer < AbstractOptimizer
    %NomadOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = NomadOptimizer()
%             obj.options = PatternSearchOptions();
        end
        
        function optimize(obj, lvdOpt, writeOutput)
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            typicalX = lvdOpt.vars.getTypicalScaledXVector();
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
            evtNumToStartScriptExecAt = obj.getEvtNumToStartScriptExecAt(lvdOpt, actVars);
            evtToStartScriptExecAt = lvdOpt.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) lvdOpt.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nomadObjFunc = @(x) NomadOptimizer.nomadObjFuncWrapper(x, objFuncWrapper);
            nonlcon = @(x, tfRunScript, stateLog) lvdOpt.constraints.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, true, stateLog);
                        
            [c, ceq] = lvdOpt.constraints.evalConstraints(x0All, true, evtToStartScriptExecAt, false, []);
            numConstr = length(c) + 2*length(ceq);
            bboutput = horzcat(repmat({'PB'},1,numConstr));
            numElemPerOutput = length(bboutput);
%             bboutput = strjoin(bboutput,' ');
            nomadNonlconWrapper = @(x) NomadOptimizer.nomadConstrWrapper(x, nonlcon);
            nlrhs = zeros(1,numConstr);
            
            pp = gcp('nocreate');
            if(true) %
                blockSize = 1;
                numWorkers = 0;
                useParallel = false;
            else
                blockSize = 100;
                numWorkers = pp.NumWorkers;
                useParallel = true;
            end
            
%             numVars = length(x0All);
%             f = @(x) NomadOptimizer.nomadObjConstrWrapper(x, objFuncWrapper, nonlcon, numVars, numElemPerOutput, numWorkers);
            opts = nomadset('display_degree',3, 'display_all_eval',0, 'bb_output_type',bboutput, 'stop_if_feasible',1); %, 'bb_max_block_size',blockSize
            
            problem.objective = nomadObjFunc; %f
            problem.x0 = x0All;
            problem.lb = lbAll;
            problem.ub = ubAll;
            problem.nlcon = nomadNonlconWrapper;
            problem.nlrhs = nlrhs;
            problem.xtype = repmat('C',1,length(x0All));
            problem.options = opts;
            
            problem.solver = 'nomad';
            
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
                    
            %%% Run optimizer
            celBodyData = lvdOpt.lvdData.celBodyData;
            propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
            handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);
            
            recorder = ma_OptimRecorder();
            outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
            nomadOutput1 = @(iter, fval, x, state) NomadOptimizer.nomadIterFunWrapper(iter, fval, x, outputFnc, state, nomadNonlconWrapper);
            nomadOutput2 = @(iter, fval, x) nomadOutput1(iter, fval, x, 'iter');
            problem.options = nomadset(problem.options, 'iterfun',nomadOutput2);
            problem.UseParallel = useParallel;
            
            nomadOutput1(0,NaN,x0All,'init');
            lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder);
            close(handlesObsOptimGui.ma_ObserveOptimGUI);
        end
        
        function options = getOptions(obj)
            
        end
        
        function tf = usesParallel(obj)
            tf = false;
        end
        
        function openOptionsDialog(obj)
            
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
        
        function [fc, stateLogs] = nomadObjConstrWrapper(x, objFun, nonlcon, numVars, numElementsInEachOutput, M)
            try
                if(numel(x) == numVars)
                    numEvals = 1;
                else
                    numEvals = size(x,1);
                end

                x = reshape(x, numEvals, numel(x)/numEvals);

                fc = NaN(numEvals,numElementsInEachOutput);

                for(i=1:numEvals)
                    stateLogs(i) = LaunchVehicleStateLog(); %#ok<AGROW>
                end

                if(M > 0 && numEvals > 1)
                    parfor(i=1:numEvals,M)
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
            [c, ceq] = nonlcon(xI);

            fcRow = [f; c(:); ceq(:); -1*ceq(:)]';
        end
        
        function stop = nomadIterFunWrapper(iter, fval, x, outputFnc, state, nonlcon)
            c = nonlcon(x);
            c(c <= 0) = 0;
            cViol = norm(c);
            
            optimValues.constrviolation = max(cViol, 0);
            optimValues.funccount = iter;
            optimValues.fval = fval;
            optimValues.iteration = iter;
            optimValues.stepsize = 0;
            optimValues.firstorderopt = 0;

            [stop,~,~] = outputFnc(x, optimValues, state);
            stop = logical(stop);
        end
    end
end