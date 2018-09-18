classdef LvdOptimization < matlab.mixin.SetGet
    %LvdOptimization Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        vars(1,1) OptimizationVariableSet = OptimizationVariableSet()
        objFcn(1,1) AbstractObjectiveFcn = NoOptimizationObjectiveFcn()
        constraints(1,1) ConstraintSet =  ConstraintSet()
    end
    
    methods
        function obj = LvdOptimization(lvdData)
            obj.lvdData = lvdData;
            
            obj.vars = OptimizationVariableSet();
            obj.objFcn = NoOptimizationObjectiveFcn();
            obj.constraints = ConstraintSet(obj, lvdData);
        end
        
        function optimize(obj, hMaMainGUI, writeOutput)  
            maData = getappdata(hMaMainGUI,'ma_data');
            
            objFuncWrapper = @(x) obj.objFcn.evalObjFcn(x, maData);
            x0All = obj.vars.getTotalXVector();
            [lbAll, ubAll] = obj.vars.getTotalBndsVector();
            nonlcon = @(x) obj.constraints.evalConstraints(x, maData);
            
            optimAlg = maData.settings.optimAlg;
            options = optimoptions('fmincon','Algorithm','sqp', 'Diagnostics','on', 'Display','iter-detailed','TolFun',1E-6,'TolX',1E-6,'TolCon',1E-6,'ScaleProblem','none','MaxIter',500,'UseParallel',false,'OutputFcn',[],'InitBarrierParam',1.0,'InitTrustRegionRadius',0.1,'HonorBounds',true,'MaxFunctionEvaluations',3000);
            problem = createOptimProblem('fmincon', 'objective',objFuncWrapper, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', options);
            
            %TODO           
            ma_ObserveOptimGUI(hMaMainGUI, problem, true, writeOutput);
            

            
            
        end
    end
end