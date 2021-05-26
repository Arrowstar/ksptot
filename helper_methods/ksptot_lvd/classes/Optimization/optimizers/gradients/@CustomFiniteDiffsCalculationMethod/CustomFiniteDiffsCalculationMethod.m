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
            
            if(isempty(fAtX0))
                fAtX0 = fun(x0);
            end
            
            g = computeGradAtPoint(fun, x0, fAtX0, obj.h, obj.diffType, double(obj.numPts), sparsity, useParallel);
            g = g(:)';
        end
        
        function J = computeJacobian(obj, cFun, x0, cAtX0, useParallel)
            sparsity = [];
            
            if(isempty(cAtX0))
                cAtX0 = cFun(x0);
            end
            
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
        
        function optimalStepSizes = determineOptimalStepSizes(fun, x0)
            fAtX0 = fun(x0);
            
            hValsToTest = 10.^[-14:-2]; %#ok<NBRAK>
%             hValsToTest = 2.^[-40:2:-6];
            
            p = 1;
            N = length(hValsToTest);

            hWaitbar = waitbar(0,'Computing optimal step sizes, please wait...');
            derivs = [];
            q = parallel.pool.DataQueue;
            q.afterEach(@updateParallelWaitbar);
            
            pp = gcp('nocreate');
            if(not(isempty(pp)))
                M = pp.NumWorkers;
            else
                M = 0;
            end
            
            parfor(i=1:length(hValsToTest), M)
                fd = CustomFiniteDiffsCalculationMethod();
                fd.h = hValsToTest(i);

                if(numel(fAtX0) > 1)
                    g = fd.computeJacobian(fun, x0, fAtX0, false);
                    derivs(:,i) = g(:);
                else
                    g = fd.computeGrad(fun, x0, fAtX0, false); 
                    derivs(:,i) = g(:);
                end
                
                q.send(i); %#ok<PFBNS>
            end
            
            if(isvalid(hWaitbar))
                close(hWaitbar);
            end
            
            rawBestHStep = [];
            for(i=1:size(derivs,1))
                derivRow = derivs(i,:);
                
                hValLogDiff = diff(log(hValsToTest));
                derivValueDiffs = abs(diff(derivRow));
                hStepDeriv = derivValueDiffs ./ hValLogDiff;
                [~,I] = min(hStepDeriv);
                rawBestHStep(i) = hValsToTest(I); %#ok<AGROW>
                
%                 hA = axes(figure()); %#ok<LAXES>
%                 hold on
%     %             semilogx(hA, hValsToTest, derivRow, 'o-');
%                 semilogx(hA, hValsToTest(1:end-1), hStepDeriv, 'o-');
%                 hold off;
%                 hA.XScale = 'log';
            end
            
            reshapedBestHStep = reshape(rawBestHStep,[numel(fAtX0),numel(x0)]);
            optimalStepSizes = max(reshapedBestHStep,[],1);
            
            function updateParallelWaitbar(~)
                waitbar(p/N, hWaitbar);
                p = p + 1;
            end
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