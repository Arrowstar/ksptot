classdef IpoptOptions < matlab.mixin.SetGet
    %IpoptOptions Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Convergence
        constr_viol_tol(1,1) double = 0.0001
        dual_inf_tol(1,1) double = 1
        max_cpu_time(1,1) double = 1E6 %seconds
        max_iter(1,1) double = 3000
        tol(1,1) double = 1E-8
        
        %Line Search
        alpha_for_y(1,1) IpOptAlphaForYEnum = IpOptAlphaForYEnum.Primal
        alpha_red_factor(1,1) double = 0.5
        corrector_type(1,1) IpOptCorrectorTypeEnum = IpOptCorrectorTypeEnum.None;
        nu_inc(1,1) double = 0.0001
        nu_init(1,1) double = 1E-6
        recalc_y(1,1) IpOptRecalcYEnum = IpOptRecalcYEnum.No 
        
        %Parallel
        useParallel(1,1) IpoptUseParallelEnum = IpoptUseParallelEnum.DoNotUseParallel;
    end
    
    methods
        function obj = IpoptOptions()

        end
        
        function ipoptDotOptions = getOptionsForOptimizer(obj)
            ipoptDotOptions.print_level = 5;
            ipoptDotOptions.hessian_approximation = 'limited-memory';
            ipoptDotOptions.honor_original_bounds = 'yes';
            ipoptDotOptions.print_timing_statistics = 'yes';
%             ipoptDotOptions.print_user_options = 'yes';
            ipoptDotOptions.mu_strategy = 'adaptive';
            ipoptDotOptions.linear_solver = 'ma57';
            
            %Convergence
            if(not(isnan(obj.constr_viol_tol)))
                ipoptDotOptions.constr_viol_tol = obj.constr_viol_tol;
            end
            
            if(not(isnan(obj.dual_inf_tol)))
                ipoptDotOptions.dual_inf_tol = obj.dual_inf_tol;
            end
            
            if(not(isnan(obj.max_cpu_time)))
                ipoptDotOptions.max_cpu_time = obj.max_cpu_time;
            end
            
            if(not(isnan(obj.max_iter)))
                ipoptDotOptions.max_iter = obj.max_iter;
            end
            
            if(not(isnan(obj.tol)))
                ipoptDotOptions.tol = obj.tol;
            end
            
            %Line Search
            ipoptDotOptions.alpha_for_y = obj.alpha_for_y.optStr;
            
            if(not(isnan(obj.alpha_red_factor)))
                ipoptDotOptions.alpha_red_factor = obj.alpha_red_factor;
            end
            
            ipoptDotOptions.corrector_type = obj.corrector_type.optStr;
            
            if(not(isnan(obj.nu_inc)))
                ipoptDotOptions.nu_inc = obj.nu_inc;
            end
            
%             if(not(isnan(obj.nu_init)))
%                 ipoptDotOptions.nu_init = obj.nu_init;
%             end
            obj.nu_init = 1000;
            
            ipoptDotOptions.recalc_y = obj.recalc_y.optStr;            
        end
        
        function tf = usesParallel(obj)
%             tf = obj.useParallel;
            tf = IpoptUseParallelEnum.UseParallel;
        end
    end
end

