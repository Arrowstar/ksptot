classdef NomadOptions < matlab.mixin.SetGet
    %NomadOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Parallel
        useParallel(1,1) PatternSearchUseParallelEnum = PatternSearchUseParallelEnum.UseParallel;
        
        %basic parameters
        direction_type(1,1) %enum
        initial_mesh_size(1,1) double = NaN;
        
        %term conditions
        max_bb_eval(1,1) double = NaN;
        max_time(1,1) double = NaN;
        max_cache_memory(1,1) double = 2000;
        max_eval(1,1) double = NaN;
        max_iterations(1,1) double = NaN;
        stop_if_feasible(1,1) %enum
        
        %constraints
        constrType(1,1) %enum
        h_max_0(1,1) double = 1E20;
        h_min(1,1) double = 1E-4;
        h_norm(1,1) %enum
        
        %VNS 
        vns_search(1,1) %enum
    end
    
    methods 
        function obj = NomadOptions()

        end
        
        function options = getOptionsForOptimizer(obj, ~)

        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel.optionVal;
        end
    end
end