classdef CustomFiniteDiffsCalculationMethod < AbstractGradientCalculationMethod
    %CustomFiniteDiffsCalculationMethod 
    %   Detailed explanation goes here
    
    properties
        h(1,1) double = 1E-7;
        diffType(1,1) FiniteDiffTypeEnum = FiniteDiffTypeEnum.Forward;
        numPts(1,1) uint64 = 2;
        
        %sparsity
        computeSparsity(1,1) logical = false;
        gradientSparsity(:,1) double = [];
    end
    
    methods
        function obj = CustomFiniteDiffsCalculationMethod()

        end
        
        function tf = useBuiltInMethod(obj)
            tf = false;
        end
        
        function tf = shouldComputeSparsity(obj)
            tf = obj.computeSparsity;
        end
        
        function computeGradientSparsity(obj, fun, x0, fAtX0, useParallel)
            if(obj.computeSparsity)
                obj.gradientSparsity = ones(length(x0),1);
                try
                    g = obj.computeGrad(fun, x0, fAtX0, useParallel);
                    g(g~=0) = 1;

                    obj.gradientSparsity = g;
                catch ME
                    obj.gradientSparsity = ones(length(x0),1);
                end
            else
                obj.gradientSparsity = [];
            end
        end
        
        function g = computeGrad(obj, fun, x0, fAtX0, useParallel)
            if(obj.computeSparsity)
                sparsity = obj.gradientSparsity;
            else
                sparsity = [];
            end
            
            g = computeGradAtPoint(fun, x0, fAtX0, obj.h, obj.diffType, double(obj.numPts), sparsity, useParallel);
            g = g(:)';
        end
        
        function J = computeJacobian(obj, cFun, x0, cAtX0, useParallel)
            sparsity = [];
            
            J = computeGradAtPoint(cFun, x0, cAtX0, obj.h, obj.diffType, double(obj.numPts), sparsity, useParallel);
            J = J';
        end
        
        function openOptionsDialog(obj)
            lvd_finiteDiffOptionsGUI(obj);
        end
    end
    
    methods(Static) %, Access=private
        function cOut = combinedConstrFun(x, lvdData)
            evtToStartScriptExecAt = lvdData.script.getEventForInd(1);
            [c, ceq] = lvdData.optimizer.constraints.evalConstraints(x, true, evtToStartScriptExecAt, false, []);
            cOut = [c(:);ceq(:)];
        end
    end
end

% fd = CustomFiniteDiffsCalculationMethod();
% x0 = lvdData.optimizer.vars.getTotalScaledXVector();
% fun = @(x) lvdData.optimizer.objFcn.evalObjFcn(x,lvdData.script.getEventForInd(1));
% fAtX0 = fun(x0);
% fd.computeGrad(fun, x0, fAtX0, true);

% cFun = @(x) CustomFiniteDiffsCalculationMethod.combinedConstrFun(x,lvdData);
% cAtX0 = cFun(x0);
% fd.computeJacobian(cFun, x0, cAtX0, true)