classdef IpOptOptimizer < AbstractGradientOptimizer
    %FminconOptimizer Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = private)
        options(1,1) IpoptOptions = IpoptOptions();
    end
    
    methods
        function obj = IpOptOptimizer()
            obj.options = IpoptOptions();
        end
        
        function optimize(obj, lvdOpt, writeOutput)
            global ipoptFuncCount ipoptLastXVect
            ipoptFuncCount = 0;
            
            [x0All, actVars, varNameStrs] = lvdOpt.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = lvdOpt.vars.getTotalScaledBndsVector();
            typicalX = lvdOpt.vars.getTypicalScaledXVector();
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
            propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
            handlesObsOptimGui = ma_ObserveOptimGUI(celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);
            
            recorder = ma_OptimRecorder();
            outputFnc = @(iterNum, fVal, iterInfo) obj.outputFunc(iterNum, fVal, iterInfo, handlesObsOptimGui, objFuncWrapper, cFun, lbAll, ubAll, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
            problem.funcs.iterfunc = outputFnc;
            
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
            lvd_editIpoptOptionsGUI(obj);
        end
        
        function tf = usesParallel(obj)
            tf = obj.options.usesParallel().optionVal;
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
            
            cOut = [c(:)';ceq(:)'];
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
        
        function stop = outputFunc(~, iterNum, fVal, iterInfo,   handlesObsOptimGui, objFcn, constrFunc, lb, ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll)
            global ipoptFuncCount ipoptLastXVect
            state = 'iter';
            
            x = ipoptLastXVect;
            cOut = constrFunc(x);
            cMax = max([0, max(cOut)]);
            
            optimValues.constrviolation = cMax;
            optimValues.firstorderopt = iterInfo.inf_du;
            optimValues.funccount = ipoptFuncCount;
            optimValues.fval = fVal;
            optimValues.iteration = iterNum;

            if(iterNum == 0)
                ma_OptimOutputFunc(x, optimValues, 'init', handlesObsOptimGui, objFcn, lb, ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
            end
            
            stop = ma_OptimOutputFunc(x, optimValues, state, handlesObsOptimGui, objFcn, lb, ub, celBodyData, recorder, propNames, writeOutput, varNameStrs, lbUsAll, ubUsAll);
            stop = not(logical(stop));
        end
    end
end