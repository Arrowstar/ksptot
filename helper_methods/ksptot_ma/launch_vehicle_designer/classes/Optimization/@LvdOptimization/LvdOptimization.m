classdef LvdOptimization < matlab.mixin.SetGet
    %LvdOptimization Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        vars OptimizationVariableSet
        objFcn(1,1) AbstractObjectiveFcn = NoOptimizationObjectiveFcn()
        constraints(1,1) ConstraintSet =  ConstraintSet()
    end
    
    methods
        function obj = LvdOptimization(lvdData)
            obj.lvdData = lvdData;
            
            obj.vars = OptimizationVariableSet(obj.lvdData);
            obj.objFcn = NoOptimizationObjectiveFcn();
            obj.constraints = ConstraintSet(obj, lvdData);
        end
        
        function optimize(obj, writeOutput)                        
            [x0All, actVars, varNameStrs] = obj.vars.getTotalScaledXVector();
            [lbAll, ubAll, lbUsAll, ubUsAll] = obj.vars.getTotalScaledBndsVector();
            typicalX = obj.vars.getTypicalScaledXVector();
            
            if(isempty(x0All) && isempty(actVars))
                return;
            end
            
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
            
            evtToStartScriptExecAt = obj.lvdData.script.getEventForInd(evtNumToStartScriptExecAt);
            
            objFuncWrapper = @(x) obj.objFcn.evalObjFcn(x, evtToStartScriptExecAt);
            nonlcon = @(x) obj.constraints.evalConstraints(x, true, evtToStartScriptExecAt, true);
                        
            usePara = obj.lvdData.settings.optUsePara;
            scaleProb = obj.lvdData.settings.getScaleProbStr();
            
            optSubroutine = obj.lvdData.settings.optSubroutine;
            if(optSubroutine == LvdOptimSubroutineEnum.fmincon)
                optimAlg = obj.lvdData.settings.optAlgo.algoName;
                
                options = optimoptions('fmincon','Algorithm',optimAlg, 'Diagnostics','on', 'Display','iter-detailed','TolFun',1E-10,'TolX',1E-10,'TolCon',1E-10,'ScaleProblem',scaleProb,'TypicalX',typicalX,'MaxIter',500,'UseParallel',usePara,'OutputFcn',[],'HonorBounds',true,'MaxFunctionEvaluations',3000, 'FunValCheck','on');
                problem = createOptimProblem('fmincon', 'objective',objFuncWrapper, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', options);
            elseif(optSubroutine == LvdOptimSubroutineEnum.patternseach)
                if(strcmpi(scaleProb,'obj-and-constr'))
                    scaleMesh = true;
                else
                    scaleMesh = false;
                end
                
                initMeshSize = norm(typicalX)/(10*length(typicalX));
                options = optimoptions('patternsearch','Display','diagnose','FunctionTolerance',1E-6,'MeshTolerance',1E-6,'ConstraintTolerance',1E-10,'ScaleMesh',scaleMesh,'MaxIterations',500,'UseParallel',usePara,'OutputFcn',[],'MaxFunctionEvaluations',3000, 'PollMethod','GPSPositiveBasis2N', 'SearchMethod','MADSPositiveBasisNp1', 'Cache','on','CacheSize',1E6,'AccelerateMesh',true, 'InitialMeshSize',initMeshSize, 'UseCompletePoll',usePara, 'UseCompleteSearch',usePara);
                
                problem.objective = objFuncWrapper;
                problem.x0 = x0All;
                problem.Aineq = [];
                problem.bineq = [];
                problem.Aeq = [];
                problem.beq = [];
                problem.lb = lbAll;
                problem.ub = ubAll;
                problem.nonlcon = nonlcon;
                problem.options = options;
                problem.solver = 'patternsearch';
            end
            
            problem.lvdData = obj.lvdData; %need to get lvdData in somehow
                    
            ma_ObserveOptimGUI(obj.lvdData.celBodyData, problem, true, writeOutput, [], varNameStrs, lbUsAll, ubUsAll);
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
end