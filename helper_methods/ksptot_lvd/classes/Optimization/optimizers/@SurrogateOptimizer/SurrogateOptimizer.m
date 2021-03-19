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
        
        function optimize(obj, lvdOpt, writeOutput, callOutputFcn)
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            typicalX = lvdOpt.vars.getTypicalScaledXVector();
            
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
               
        function openOptionsDialog(obj)
            lvd_editSurrogateOptOptionsGUI(obj);
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.useParallel.optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.options.getNumParaWorkers();
%             numWorkers = feature('numcores');
        end
    end
    
    methods(Static, Access=private)
        function objconstr = getObjConstr(x, objFunc, nonlcon)
            fval = objFunc(x);
            [c, ceq] = nonlcon(x);
            
            cFull = [c(:);
                     ceq(:);
                     -ceq(:);];
                 
             objconstr.Fval = fval;
             objconstr.Ineq = cFull;
        end
    end
end