classdef SqpOptions < matlab.mixin.SetGet
    %SqpOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties  
        %Tolerances
        optTol(1,1) double = NaN;
        stepTol(1,1) double = NaN;
        tolCon(1,1) double = NaN;
        
        %Maximums
        maxIter(1,1) double = 500;
        maxFuncEvals(1,1) double = 3000;
        
        %Parallel
        useParallel(1,1) SqpUseParallelEnum = SqpUseParallelEnum.DoNotUseParallel;
        numWorkers(1,1) double = feature('numCores');
        
        %Finite Differences
        finDiffStepSize(1,1) double = 0.0001;
        % computeOptimalStepSizes(1,1) logical = false;
        
        %SQP Algo Specific
        terminationType(1,1) SqpTerminationCondEnum = SqpTerminationCondEnum.Schittkowski;
        maxLineSearchFun(1,1) double = 30;
    end
    
    methods 
        function obj = SqpOptions()

        end
        
        function options = getOptionsForOptimizer(obj, x0)            
            options = optimset('Display','iter');
            
            if(not(isnan(obj.optTol)))
                options = optimset(options, 'TolFun', obj.optTol);
            end
            
            if(not(isnan(obj.stepTol)))
                options = optimset(options, 'TolX', obj.stepTol);
            end
            
            if(not(isnan(obj.tolCon)))
                options = optimset(options, 'TolCon', obj.tolCon);
            end
            
            if(not(isnan(obj.maxIter)))
                options = optimset(options, 'MaxIter', obj.maxIter);
            end
            
            if(not(isnan(obj.maxFuncEvals)))
                options = optimset(options, 'MaxFunEvals', obj.maxFuncEvals);
            end
            
            if(not(isnan(obj.finDiffStepSize)))
                options = optimset(options, 'DiffMaxChange', obj.finDiffStepSize);
                options = optimset(options, 'DiffMinChange', obj.finDiffStepSize);
            end
                        
            options = optimset(options, ...
                               'UseParallel', obj.useParallel.optionVal); 

            %Need to do the non-standard elements later so they don't get
            %overwritten or removed by another call to optimset().
            options.Termination = obj.terminationType.optionVal;

            if(not(isnan(obj.maxLineSearchFun)))
                options.MaxLineSearchFun = obj.maxLineSearchFun;
            end
        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel.optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.numWorkers;
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            if(obj.numWorkers < 1 || obj.numWorkers > feature('numCores'))
                obj.numWorkers = feature('numCores');
            end
        end
    end
end