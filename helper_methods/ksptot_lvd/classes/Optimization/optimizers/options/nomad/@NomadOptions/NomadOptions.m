classdef NomadOptions < matlab.mixin.SetGet
    %NomadOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Parallel
        useParallel(1,1) PatternSearchUseParallelEnum = PatternSearchUseParallelEnum.DoNotUseParallel;
        numWorkers(1,1) double = feature('numCores');
        
        %basic parameters
        direction_type(1,1) NomadDirectionTypeEnum = NomadDirectionTypeEnum.OrthoN1Quad;
        initial_mesh_size(1,1) double = NaN;
        
        %term conditions
        max_bb_eval(1,1) double = NaN;
        max_time(1,1) double = NaN;
        max_cache_memory(1,1) double = NaN;
        max_iterations(1,1) double = NaN;
        stop_if_feasible(1,1) NomadStopIfFeasibleEnum = NomadStopIfFeasibleEnum.DoNotStopIfFeasible;
        
        %constraints
        constrType(1,1) NomadConstraintType = NomadConstraintType.PB;
        h_max_0(1,1) double = NaN;
        h_min(1,1) double = 1E-4;
        h_norm(1,1) NomadHNormTypeEnum = NomadHNormTypeEnum.L2;
        
        %VNS 
        vns_trigger(1,1) double = NaN;
    end
    
    methods 
        function obj = NomadOptions()

        end
        
        function options = getOptionsForOptimizer(obj, ~)
            options = nomadset();
            
            options = nomadset(options, 'direction_type', obj.direction_type.optionStr);
            
            if(not(isnan(obj.initial_mesh_size)))
                options = nomadset(options, 'initial_mesh_size', obj.fullAccNum2Str(obj.initial_mesh_size));
            end
            
            if(not(isnan(obj.max_bb_eval)))
                options = nomadset(options, 'max_bb_eval', obj.max_bb_eval);
            end
            
            if(not(isnan(obj.max_time)))
                options = nomadset(options, 'max_time', obj.max_time);
            end
            
            if(not(isnan(obj.max_cache_memory)))
                options = nomadset(options, 'max_cache_memory', obj.max_cache_memory);
            end
            
            if(not(isnan(obj.max_iterations)))
                options = nomadset(options, 'max_iterations', obj.max_iterations);
            end
            
            options = nomadset(options, 'stop_if_feasible', obj.stop_if_feasible.optVal);
            
            if(not(isnan(obj.h_max_0)))
                options = nomadset(options, 'h_max_0', obj.h_max_0);
            end
            
            if(not(isnan(obj.h_min)))
                options = nomadset(options, 'h_min', obj.h_min);
            end

            if(not(isnan(obj.h_min)))
                options = nomadset(options, 'h_min', obj.h_min);
            end
            
            options = nomadset(options, 'h_norm', obj.h_norm.optionStr);
            
            if(not(isnan(obj.vns_trigger)))
                options = nomadset(options, 'vns_search', obj.vns_trigger);
            end

            options = nomadset(options, ...
                               'nm_search',0, ...
                               'display_degree',3, ...
                               'display_all_eval',0, ...
                               'bb_max_block_size',100000000000);
        end
        
        function tf = usesParallel(obj)
            tf = obj.useParallel.optionVal;
        end
        
        function numWorkers = getNumParaWorkers(obj)
            numWorkers = obj.numWorkers;
        end
        
        function constrType = getConstrTypeStr(obj)
            constrType = obj.constrType.optionStr;
        end
    end
end