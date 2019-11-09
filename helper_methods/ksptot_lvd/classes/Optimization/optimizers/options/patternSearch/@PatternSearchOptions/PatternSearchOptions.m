classdef PatternSearchOptions < matlab.mixin.SetGet
    %FminconOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Parallel
        useParallel(1,1) PatternSearchUseParallelEnum = PatternSearchUseParallelEnum.UseParallel;
        
        %Tolerances
        cacheTol(1,1) double = eps;
        conTol(1,1) double = 1E-10;
        funTol(1,1) double = 1E-6;        
        meshTol(1,1) double = 1E-6;
        stepTol(1,1) double = 1E-6;
        
        %Cache
        cache(1,1) PatternSearchUseCacheEnum = PatternSearchUseCacheEnum.UseCache;
        cacheSize(1,1) uint64 = 1E6;
        
        %Mesh
        accelMesh(1,1) PatternSearchUseMeshAccelEnum = PatternSearchUseMeshAccelEnum.UseAccel;
        initMeshSize(1,1) double = 1;
        meshContrFact(1,1) double = 0.5;
        meshExpFact(1,1) double = 2.0;
        meshRotate(1,1) PatternSearchUseMeshRotationEnum = PatternSearchUseMeshRotationEnum.UseMeshRotation;

        %Maximums
        maxFunEvals(1,1) uint64 = 3000;
        maxIters(1,1) uint64 = 500;
        
        %Polling
        pollMethod(1,1) PattSrchPollMethodEnum = PattSrchPollMethodEnum.GPSPositiveBasis2N;
        pollOrder(1,1) PattSrchPollOrderEnum = PattSrchPollOrderEnum.Consecutive;
        useCompletePoll(1,1) PatternSearchUseCompletePollEnum = PatternSearchUseCompletePollEnum.UseCompletePoll;
        
        %Search
        scaleMesh(1,1) PatternSearchUseMeshScalingEnum = PatternSearchUseMeshScalingEnum.UseMeshScaling;
        searchFunc(1,1) PattSrchSearchFcnEnum = PattSrchSearchFcnEnum.None;
        useCompleteSearch(1,1) PatternSearchUseCompleteSearchEnum = PatternSearchUseCompleteSearchEnum.UseCompleteSearch;
        
        %Penalty
        initPenalty(1,1) double = 10;
        penaltyFact(1,1) double = 100;
    end
    
    methods 
        function obj = PatternSearchOptions()

        end
        
        function options = getOptionsForOptimizer(obj, ~)
            options = optimoptions(@patternsearch,'Display','diagnose');
                                   
            if(not(isnan(obj.cacheTol)))
                options = optimoptions(options, 'CacheTol', obj.cacheTol);
            end
            
            if(not(isnan(obj.conTol)))
                options = optimoptions(options, 'ConstraintTolerance', obj.conTol);
            end
            
            if(not(isnan(obj.funTol)))
                options = optimoptions(options, 'FunctionTolerance', obj.funTol);
            end
            
            if(not(isnan(obj.meshTol)))
                options = optimoptions(options, 'MeshTolerance', obj.meshTol);
            end
            
            if(not(isnan(obj.stepTol)))
                options = optimoptions(options, 'StepTolerance', obj.stepTol);
            end
            
            if(obj.cache.optionVal)
                options = optimoptions(options, 'Cache', 'on');
            else
                options = optimoptions(options, 'Cache', 'off');
            end
            
            if(not(isnan(obj.cacheSize)))
                options = optimoptions(options, 'CacheSize', double(obj.cacheSize));
            end
            
            options = optimoptions(options, 'AccelerateMesh', obj.accelMesh.optionVal);
            
            if(not(isnan(obj.initMeshSize)))
                options = optimoptions(options, 'InitialMeshSize', obj.initMeshSize);
            end
            
            if(not(isnan(obj.meshContrFact)))
                options = optimoptions(options, 'MeshContractionFactor', obj.meshContrFact);
            end
            
            if(not(isnan(obj.meshExpFact)))
                options = optimoptions(options, 'MeshExpansionFactor', obj.meshExpFact);
            end
            
            if(obj.meshRotate.optionVal)
                options = optimoptions(options, 'MeshRotate', 'on');
            else
                options = optimoptions(options, 'MeshRotate', 'off'); 
            end
           
            if(not(isnan(obj.maxIters)))
                options = optimoptions(options, 'MaxIterations', double(obj.maxIters));
            end
            
            if(not(isnan(obj.maxFunEvals)))
                options = optimoptions(options, 'MaxFunctionEvaluations', double(obj.maxFunEvals));
            end

            options = optimoptions(options, 'PollMethod', obj.pollMethod.optionStr);
            
            options = optimoptions(options, 'PollOrderAlgorithm', obj.pollOrder.optionStr);
            
            options = optimoptions(options, 'UseCompletePoll', obj.useCompletePoll.optionVal);
            
            options = optimoptions(options, 'ScaleMesh', obj.scaleMesh.optionVal);
            
            options = optimoptions(options, 'SearchFcn', obj.searchFunc.optionFcn);
            
            options = optimoptions(options, 'UseCompleteSearch', obj.useCompleteSearch.optionVal);
            
            if(not(isnan(obj.penaltyFact)))
                options = optimoptions(options, 'PenaltyFactor', obj.penaltyFact);
            end
            
            if(not(isnan(obj.initPenalty)))
                options = optimoptions(options, 'InitialPenalty', obj.initPenalty);
            end           
            
            options = optimoptions(options, 'UseParallel',obj.useParallel.optionVal);
        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel;
        end
    end
end