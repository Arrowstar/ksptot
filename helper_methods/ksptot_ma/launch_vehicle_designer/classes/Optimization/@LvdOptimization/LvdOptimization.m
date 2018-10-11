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
        
        function optimize(obj, writeOutput)            
            objFuncWrapper = @(x) obj.objFcn.evalObjFcn(x);
            x0All = obj.vars.getTotalXVector();
            [lbAll, ubAll] = obj.vars.getTotalBndsVector();
            nonlcon = @(x) obj.constraints.evalConstraints(x);
            
            optimAlg = 'interior-point';
            usePara = true;
            options = optimoptions('fmincon','Algorithm',optimAlg, 'Diagnostics','on', 'Display','iter-detailed','TolFun',1E-10,'TolX',1E-10,'TolCon',1E-10,'ScaleProblem','none','MaxIter',500,'UseParallel',usePara,'OutputFcn',[],'HonorBounds',true,'MaxFunctionEvaluations',3000, 'FunValCheck','on');
            problem = createOptimProblem('fmincon', 'objective',objFuncWrapper, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', options);
            
            problem.lvdData = obj.lvdData; %need to get lvdData in somehow
                    
            ma_ObserveOptimGUI(obj.lvdData.celBodyData, problem, true, writeOutput);
        end
        
        function tf = usesStage(obj, stage)
            tf = obj.objFcn.usesStage(stage);
            
            tf = tf || obj.constraints.usesStage(stage);
        end
        
        function tf = usesEngine(obj, engine)
            tf = obj.objFcn.usesEngine(engine);
            
            tf = tf || obj.constraints.usesEngine(engine);
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.objFcn.usesTank(tank);
            
            tf = tf || obj.constraints.usesTank(tank);
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.objFcn.usesEngineToTankConn(engineToTank);
            
            tf = tf || obj.constraints.usesEngineToTankConn(engineToTank);
        end
    end
end