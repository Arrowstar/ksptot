classdef FminconOptimizer < AbstractGradientOptimizer
    %FminconOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        options(1,1) FminconOptions = FminconOptions();
        gradCalcMethod(1,1) AbstractGradientCalculationMethod = CustomFiniteDiffsCalculationMethod();
    end
    
    methods
        function obj = FminconOptimizer()
            obj.options = FminconOptions();
            obj.gradCalcMethod = CustomFiniteDiffsCalculationMethod();
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
            nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true);
                        
            usePara = lvdOpt.lvdData.settings.optUsePara;
            scaleProb = lvdOpt.lvdData.settings.getScaleProbStr();
            optimAlg = lvdOpt.lvdData.settings.optAlgo.algoName;
            
            opts = obj.options.getOptionsForOptimizer(typicalX);
            opts = optimoptions(opts, 'UseParallel',usePara, 'ScaleProblem',scaleProb, 'Algorithm',optimAlg, 'CheckGradients',true);
            
            if(obj.gradCalcMethod.useBuiltInMethod())
                objFunToPass = objFuncWrapper;
                opts = optimoptions(opts, 'SpecifyObjectiveGradient',false);
            else
                objFunToPass = @(x) obj.objFuncWithGradient(objFuncWrapper, x, usePara);
                opts = optimoptions(opts, 'SpecifyObjectiveGradient',true);
            end
            
            problem = createOptimProblem('fmincon', 'objective',objFunToPass, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', opts);
            problem.lvdData = lvdOpt.lvdData; %need to get lvdData in somehow
                    
            %%% Run optimizer
            celBodyData = lvdOpt.lvdData.celBodyData;
            propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
            handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);
            
            recorder = ma_OptimRecorder();
            outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, problem.objective, problem.lb, problem.ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
            problem.options.OutputFcn = outputFnc;
            
            lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder);
            close(handlesObsOptimGui.ma_ObserveOptimGUI);
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
        
        function setGradientCalculationMethod(obj, newGradCalcMethod)
            obj.gradCalcMethod = newGradCalcMethod;
        end
    end
    
    methods(Access=private)
        function [f, g, stateLog] = objFuncWithGradient(obj, objFun, x, useParallel)
            [f, stateLog] = objFun(x);
            
            if(nargout >= 2)
                g = obj.gradCalcMethod.computeGrad(objFun, x, f, useParallel);
            end
        end
    end
end