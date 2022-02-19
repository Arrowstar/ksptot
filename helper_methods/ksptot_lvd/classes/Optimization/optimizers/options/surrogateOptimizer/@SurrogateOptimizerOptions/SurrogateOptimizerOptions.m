classdef SurrogateOptimizerOptions < matlab.mixin.SetGet
    %SurrogateOptimizerOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Tolerances
        tolCon(1,1) double = 1E-6;
        
        %Maximums
        maxFuncEvals(1,1) double = NaN;
        
        %Parallel
        useParallel(1,1) SurrogateOptUseParallelEnum = SurrogateOptUseParallelEnum.DoNotUseParallel;
        numWorkers(1,1) double = feature('numCores');
        
        %Other Options
        batchUpdateInterval(1,1) double = NaN;
        minSampleDistance(1,1) double = NaN
        minSurrogatePoints(1,1) double = NaN;
    end
    
    methods 
        function obj = SurrogateOptimizerOptions()

        end
        
        function options = getOptionsForOptimizer(obj, x0)            
            options = optimoptions(@surrogateopt, 'Display','iter');
            
            x0 = x0(:)'; %needs to be a row
            options = optimoptions(options, 'InitialPoints', x0);
            
            %%%
            
            if(not(isnan(obj.tolCon)))
                options = optimoptions(options, 'ConstraintTolerance', obj.tolCon);
            end
            
            if(not(isnan(obj.maxFuncEvals)))
                options = optimoptions(options, 'MaxFunctionEvaluations', obj.maxFuncEvals);
            end   
            
            %%%
            
            if(not(isnan(obj.batchUpdateInterval)))
                options = optimoptions(options, 'BatchUpdateInterval', obj.batchUpdateInterval);
            end
            
            if(not(isnan(obj.minSampleDistance)))
                options = optimoptions(options, 'MinSampleDistance', obj.minSampleDistance);
            end
            
            if(not(isnan(obj.minSurrogatePoints)))
                options = optimoptions(options, 'MinSurrogatePoints', obj.minSurrogatePoints);
            end
                        
            options = optimoptions(options, ...
                                   'UseVectorized', false, ...
                                   'PlotFcn', {}, ...
                                   'UseParallel', obj.useParallel.optionVal);    
        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel;
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