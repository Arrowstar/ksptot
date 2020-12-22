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
        
        function optimize(obj, lvdOpt, writeOutput, callOutputFcn)
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
                propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
                handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);

                outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
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
            lvd_editPatternSearchOptionsGUI(obj);
        end
    end
end