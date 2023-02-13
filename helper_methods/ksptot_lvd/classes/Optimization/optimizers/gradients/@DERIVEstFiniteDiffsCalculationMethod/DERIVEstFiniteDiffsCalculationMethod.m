classdef DERIVEstFiniteDiffsCalculationMethod < AbstractGradientCalculationMethod
    %CustomFiniteDiffsCalculationMethod
    %   Detailed explanation goes here
    
    properties        
        
    end
    
    methods
        function obj = DERIVEstFiniteDiffsCalculationMethod()
            
        end
        
        function tf = useBuiltInMethod(obj)
            tf = false;
        end
        
        function tf = shouldComputeSparsity(obj)
            tf = false;
        end
        
        function computeGradientSparsity(obj, fun, x0, fAtX0, useParallel)
            error('Does not compute sparsity.');
        end
        
        function grad = computeGrad(obj, fun, x0, ~, useParallel)
            [grad,errest,finaldelta] = gradest(fun, x0, useParallel);
            grad = grad(:)';
        end
        
        function jac = computeJacobian(obj, cFun, x0, ~, useParallel)
            [jac,err] = jacobianest(cFun,x0,useParallel);
        end
        
        function openOptionsDialog(obj)           
            output = AppDesignerGUIOutput({false});
            lvd_finiteDiffOptionsGUI_App(obj, output);
        end
    end
end