classdef FminconOptions < matlab.mixin.SetGet
    %FminconOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        algorithm(1,1) LvdFminconAlgorithmEnum = LvdFminconAlgorithmEnum.InteriorPoint;
        
        %Tolerances
        optTol(1,1) double = 1E-10;
        stepTol(1,1) double = 1E-10;
        tolCon(1,1) double = 1E-10;
        
        %Maximums
        maxIter(1,1) uint64 = 500;
        maxFuncEvals(1,1) uint64 = 3000;
        
        %Parallel
        useParallel(1,1) FminconUseParallelEnum = FminconUseParallelEnum.DoNotUseParallel;
        
        %Finite Differences
        finDiffStepSize(1,1) double = 1E-8;
        finDiffType FminconFiniteDiffTypeEnum = FminconFiniteDiffTypeEnum.TwoPtForwardDiff;
        
        %TypicalX
        typicalXType OptimizerTypicalXEnum = OptimizerTypicalXEnum.InitialValues;
        
        %Interior-Point options
        hessianApproxAlg FminconHessApproxAlgEnum = FminconHessApproxAlgEnum.BFGS;
        initBarrierParam(1,1) double = 0.1;
        initTrustRegionRadius(1,1) double = NaN;
        maxProjCGIter(1,1) double = NaN;
        subproblemAlgorithm FminconIpSubprobAlgEnum = FminconIpSubprobAlgEnum.Factorization;
        tolProjCG(1,1) double = 0.01;
        tolProjCGAbs(1,1) double = 1E-10;
        
        %Active-Set options
        funcTol(1,1) double = 1E-10;
        maxSQPIter(1,1) double = NaN;
        relLineSrchBnd(1,1) double = NaN;
        relLineSrchBndDuration(1,1) double = 1;
        tolConSQP(1,1) double = 1E-6;
    end
    
    methods 
        function obj = FminconOptions()

        end
        
        function options = getOptionsForOptimizer(obj, x0)
            if(obj.typicalXType == OptimizerTypicalXEnum.InitialValues)
                typicalX = x0;
            else
                typicalX = ones(size(x0));
            end
            
            options = optimoptions(@fmincon, 'Algorithm',obj.algorithm.algoName, ...
                                             'Diagnostics','on', ....
                                             'Display','iter-detailed', ...
                                             'HonorBounds',true, ...
                                             'FunValCheck','on');
            
            if(not(isnan(obj.optTol)))
                options = optimoptions(options, 'OptimalityTolerance', obj.optTol);
            end
            
            if(not(isnan(obj.stepTol)))
                options = optimoptions(options, 'StepTolerance', obj.stepTol);
            end
            
            if(not(isnan(obj.tolCon)))
                options = optimoptions(options, 'ConstraintTolerance', obj.tolCon);
            end
            
            if(not(isnan(obj.maxIter)))
                options = optimoptions(options, 'MaxIterations', obj.maxIter);
            end
            
            if(not(isnan(obj.maxFuncEvals)))
                options = optimoptions(options, 'MaxFunctionEvaluations', obj.maxFuncEvals);
            end
            
            if(not(isnan(obj.finDiffStepSize)))
                options = optimoptions(options, 'FiniteDifferenceStepSize', obj.finDiffStepSize);
            end
            %%%
            if(not(isnan(obj.initBarrierParam)))
                options = optimoptions(options, 'InitBarrierParam', obj.initBarrierParam);
            end
            
            if(not(isnan(obj.initTrustRegionRadius)))
                options = optimoptions(options, 'InitTrustRegionRadius', obj.initTrustRegionRadius);
            end
            
            if(not(isnan(obj.maxProjCGIter)))
                options = optimoptions(options, 'MaxProjCGIter', obj.maxProjCGIter);
            end
            
            if(not(isnan(obj.tolProjCG)))
                options = optimoptions(options, 'TolProjCG', obj.tolProjCG);
            end
            
            if(not(isnan(obj.tolProjCGAbs)))
                options = optimoptions(options, 'TolProjCGAbs', obj.tolProjCGAbs);
            end
            %%%
            if(not(isnan(obj.funcTol)))
                options = optimoptions(options, 'FunctionTolerance', obj.funcTol);
            end
            
            if(not(isnan(obj.maxSQPIter)))
                options = optimoptions(options, 'MaxSQPIter', obj.maxSQPIter);
            end
            
            if(not(isnan(obj.relLineSrchBnd)))
                options = optimoptions(options, 'RelLineSrchBnd', obj.relLineSrchBnd);
            end
            
            if(not(isnan(obj.relLineSrchBndDuration)))
                options = optimoptions(options, 'RelLineSrchBndDuration', obj.relLineSrchBndDuration);
            end
            
            if(not(isnan(obj.tolConSQP)))
                options = optimoptions(options, 'TolConSQP', obj.tolConSQP);
            end
                        
            options = optimoptions(options, ...
                                   'UseParallel', obj.useParallel.optionVal, ...
                                   'FiniteDifferenceType', obj.finDiffType.optionStr, ...
                                   'TypicalX', typicalX, ...
                                   'HessianApproximation', obj.hessianApproxAlg.optionStr, ...
                                   'SubproblemAlgorithm', obj.subproblemAlgorithm.optionStr);    
        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel;
        end
    end
end