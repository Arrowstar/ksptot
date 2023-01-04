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

        %surrogate model
        useSurrogateModelSearch(1,1) logical = false;
        surrogateOptions NomadSurrogateOptions
    end
    
    methods 
        function obj = NomadOptions()
            obj.surrogateOptions = NomadSurrogateOptions();
        end
        
        function options = getOptionsForOptimizer(obj, ~)
            options = struct('direction_type', obj.direction_type.optionStr);
                      
%             if(not(isnan(obj.initial_mesh_size)))
%                 options.INITIAL_MESH_SIZE = obj.initial_mesh_size;
%             end
            
            if(not(isnan(obj.max_bb_eval)))
                options.max_bb_eval = obj.max_bb_eval;
            end
            
            if(not(isnan(obj.max_time)))
                options.max_time = obj.max_time;
            end
            
%             if(not(isnan(obj.max_cache_memory)))
%                 options.max_cache_memory = obj.max_cache_memory;
%             end
            
            if(not(isnan(obj.max_iterations)))
                options.max_iterations = obj.max_iterations;
            end
            
            options.stop_if_feasible = obj.stop_if_feasible.optVal;
            
            if(not(isnan(obj.h_max_0)))
                options.h_max_0 = obj.h_max_0;
            end
            
%             if(not(isnan(obj.h_min)))
%                 options.h_min = obj.h_min;
%             end
            
%             options.h_norm = obj.h_norm.optionStr;
            
            if(not(isnan(obj.vns_trigger)))
                options.VNS_MADS_SEARCH_TRIGGER = obj.vns_trigger;

                if(obj.vns_trigger > 0)
                    options.VNS_MADS_SEARCH = true;
                else
                    options.VNS_MADS_SEARCH = false;
                end
            end

            options.nm_search = 0;
            options.display_degree = 3;
            options.display_all_eval = 1;
            options.bb_max_block_size = 100000000000;
            options.DISPLAY_STATS = 'BBE TIME OBJ CONS_H H_MAX';
            options.SGTELIB_MODEL_SEARCH = obj.useSurrogateModelSearch;

            if(obj.useSurrogateModelSearch)
                options.SGTELIB_MODEL_DEFINITION = obj.surrogateOptions.getSurrogateModelDefinitionString();
            end
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

    methods(Static)
        function obj = loadobj(obj)
            arguments
                obj NomadOptions
            end

            if(isempty(obj.surrogateOptions))
                obj.surrogateOptions = NomadSurrogateOptions();
            end
        end
    end
end