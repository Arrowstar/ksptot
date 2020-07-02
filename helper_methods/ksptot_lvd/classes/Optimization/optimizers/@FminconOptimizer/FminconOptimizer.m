classdef FminconOptimizer < AbstractGradientOptimizer
    %FminconOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        options(1,1) FminconOptions = FminconOptions();
    end
    
    methods
        function obj = FminconOptimizer()
            obj.options = FminconOptions();
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
            nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true, []);
                            
            opts = obj.options.getOptionsForOptimizer(typicalX);
            
            if(lvdOpt.gradAlgo == LvdOptimizerGradientCalculationAlgoEnum.BuiltIn)
                objFunToPass = objFuncWrapper;
                opts = optimoptions(opts, 'SpecifyObjectiveGradient',false);
            elseif(lvdOpt.gradAlgo == LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences)
                gradCalcMethod = lvdOpt.customFiniteDiffsCalcMethod;
                objFunToPass = @(x) obj.objFuncWithGradient(objFuncWrapper, x, gradCalcMethod, obj.usesParallel());
                opts = optimoptions(opts, 'SpecifyObjectiveGradient',true);
                
                sparsityTF = gradCalcMethod.shouldComputeSparsity();
                if(sparsityTF)
                    hMsgBox = msgbox('Computing sparsity.  Please wait...');
                else
                    hMsgBox = NaN;
                end
                
                fAtX0 = objFunToPass(x0All);
                gradCalcMethod.computeGradientSparsity(objFuncWrapper, x0All, fAtX0, obj.usesParallel());
                
                if(sparsityTF && isgraphics(hMsgBox))
                    close(hMsgBox);
                end
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
        
        function openOptionsDialog(obj)
            lvd_editFminconOptionsGUI(obj);
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.useParallel.optionVal;
        end
    end
    
    methods(Access=private)
        function [f, g, stateLog] = objFuncWithGradient(~, objFun, x, gradCalcMethod, useParallel)
            [f, stateLog] = objFun(x);
            
            if(nargout >= 2)
                g = gradCalcMethod.computeGrad(objFun, x, f, useParallel);
            end
        end
    end
end