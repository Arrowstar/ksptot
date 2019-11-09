classdef LvdOptimization < matlab.mixin.SetGet
    %LvdOptimization Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        vars OptimizationVariableSet
        objFcn(1,1) AbstractObjectiveFcn = NoOptimizationObjectiveFcn()
        constraints(1,1) ConstraintSet =  ConstraintSet()
        
        %Optimization Algo Selection
        optAlgo(1,1) LvdOptimizerAlgoEnum = LvdOptimizerAlgoEnum.Fmincon;
        
        %Optimizers
        fminconOpt(1,1) FminconOptimizer = FminconOptimizer();
        patternSearchOpt(1,1) PatternSearchOptimizer = PatternSearchOptimizer();
        
        %Gradient Calc Algo Selection
        gradAlgo(1,1) LvdOptimizerGradientCalculationAlgoEnum = LvdOptimizerGradientCalculationAlgoEnum.BuiltIn;

        %Gradient Calculation Algos
        builtInGradMethod(1,1) BuiltInGradientCalculationMethod = BuiltInGradientCalculationMethod();
        customFiniteDiffsCalcMethod(1,1) CustomFiniteDiffsCalculationMethod = CustomFiniteDiffsCalculationMethod();
    end
    
    methods
        function obj = LvdOptimization(lvdData)
            obj.lvdData = lvdData;
            
            obj.vars = OptimizationVariableSet(obj.lvdData);
            obj.objFcn = NoOptimizationObjectiveFcn();
            obj.constraints = ConstraintSet(obj, lvdData);
            
            obj.optAlgo = LvdOptimizerAlgoEnum.Fmincon;
            obj.fminconOpt = FminconOptimizer();
            obj.patternSearchOpt = PatternSearchOptimizer();
            
            obj.builtInGradMethod = BuiltInGradientCalculationMethod();
            obj.customFiniteDiffsCalcMethod = CustomFiniteDiffsCalculationMethod();
        end
        
        function optimize(obj, writeOutput)                        
            optimizer = obj.getSelectedOptimizer();
            optimizer.optimize(obj, writeOutput);
        end
        
        function optimizer = getSelectedOptimizer(obj)
            optAlgorithm = obj.optAlgo;
            if(optAlgorithm == LvdOptimizerAlgoEnum.Fmincon)
                optimizer = obj.fminconOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.PatternSearch)
                optimizer = obj.patternSearchOpt;
            end
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
    
    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.vars.lvdData))
                obj.vars.lvdData = obj.lvdData;
            end
        end        
    end
    
    methods(Access=private)
        function evtNumToStartScriptExecAt = getEvtNumToStartScriptExecAt(obj, actVars)
            evtNumToStartScriptExecAt = obj.lvdData.script.getTotalNumOfEvents();
            for(i=1:length(actVars)) %#ok<*NO4LP>
                var = actVars(i);
                
                if(isVarInLaunchVehicle(var, obj.lvdData) || isVarInLaunchVehicle(var, obj.lvdData))
                    varEvtNum = 1;
                else
                    varEvtNum = getEventNumberForVar(var, obj.lvdData);
                    
                    if(isempty(varEvtNum))
                        varEvtNum = 1;
                    end
                end
                
                if(varEvtNum < evtNumToStartScriptExecAt)
                    evtNumToStartScriptExecAt = varEvtNum;
                end
                
                if(evtNumToStartScriptExecAt == 1)
                    break; %it can't go lower than 1, so we're executing the whole thing.  No reason to keep going.
                end
            end
        end
    end
end