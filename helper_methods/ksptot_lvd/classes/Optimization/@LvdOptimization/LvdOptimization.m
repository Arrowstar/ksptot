classdef LvdOptimization < matlab.mixin.SetGet
    %LvdOptimization Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        vars OptimizationVariableSet
%         objFcn(1,1) AbstractObjectiveFcn = NoOptimizationObjectiveFcn()
        objFcn(1,1) AbstractObjectiveFcn = CompositeObjectiveFcn()
        constraints(1,1) ConstraintSet =  ConstraintSet()
        
        %Optimization Algo Selection
        optAlgo(1,1) LvdOptimizerAlgoEnum = LvdOptimizerAlgoEnum.Fmincon;
        
        %Optimizers
        fminconOpt(1,1) FminconOptimizer = FminconOptimizer();
        patternSearchOpt(1,1) PatternSearchOptimizer = PatternSearchOptimizer();
        nomadOpt(1,1) NomadOptimizer = NomadOptimizer();
        ipoptOpt(1,1) IpOptOptimizer = IpOptOptimizer();
        surragateOpt(1,1) SurrogateOptimizer = SurrogateOptimizer();
        sqpOpt(1,1) SQPOptimizer = SQPOptimizer();
        adamNlOptOpt(1,1) AdamNlOptOptimizer = AdamNlOptOptimizer();

        %Gradient Calc Algo Selection
        gradAlgo(1,1) LvdOptimizerGradientCalculationAlgoEnum = LvdOptimizerGradientCalculationAlgoEnum.BuiltIn;

        %Gradient Calculation Algos
        builtInGradMethod(1,1) BuiltInGradientCalculationMethod = BuiltInGradientCalculationMethod();
        customFiniteDiffsCalcMethod(1,1) CustomFiniteDiffsCalculationMethod = CustomFiniteDiffsCalculationMethod();
        derivEstFiniteDiffCalcMethod(1,1) DERIVEstFiniteDiffsCalculationMethod = DERIVEstFiniteDiffsCalculationMethod();
    end

    properties(Transient, Access=private)
        %Same-x propagation cache (see propagateForX).  Every field must match
        %for a hit; propCacheCounter is the script's propagationCounter as it
        %stood immediately after the cached propagation finished, so any
        %executeScript call made by anyone else invalidates the entry.
        propCacheX double = []
        propCacheSparse logical = false
        propCacheStartEvt LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0)
        propCacheCounter double = NaN
        propCacheHits(1,1) double = 0
        propCacheMisses(1,1) double = 0
    end
    
    methods
        function obj = LvdOptimization(lvdData)
            obj.lvdData = lvdData;
            
            obj.vars = OptimizationVariableSet(obj.lvdData);
            obj.objFcn = CompositeObjectiveFcn(GenericObjectiveFcn.empty(1,0), ObjFcnDirectionTypeEnum.Minimize, ObjFcnCompositeMethodEnum.Sum, lvdData.optimizer, lvdData);
            obj.constraints = ConstraintSet(obj, lvdData);
            
            obj.optAlgo = LvdOptimizerAlgoEnum.Fmincon;
            obj.fminconOpt = FminconOptimizer();
            obj.patternSearchOpt = PatternSearchOptimizer();
            obj.nomadOpt = NomadOptimizer();
            obj.ipoptOpt = IpOptOptimizer();
            obj.surragateOpt = SurrogateOptimizer();
            obj.adamNlOptOpt = AdamNlOptOptimizer();

            obj.builtInGradMethod = BuiltInGradientCalculationMethod();
            obj.customFiniteDiffsCalcMethod = CustomFiniteDiffsCalculationMethod();
        end
        
        function [exitflag, message] = optimize(obj, writeOutput, callOutputFcn, hLvdMainGUI, progressFcn)
            arguments
                obj
                writeOutput
                callOutputFcn
                hLvdMainGUI
                progressFcn = [];
            end

            obj.vars.removeUselessVars();
            obj.vars.sortVarsByEvtNum();
            optimizer = obj.getSelectedOptimizer();

            [x0All, actVars, ~] = obj.vars.getTotalScaledXVector();

            if(isempty(x0All) && isempty(actVars))
                message = 'There are no optimization variables enabled in this mission.  Optimization requires at least one variable.  Please enable at least one variable to continue with optimization.';

                %consoleOptimize and the case matrix pass an empty handle:
                %there is no figure to raise a dialog against, and uialert([])
                %errors, which turned "no variables enabled" into an opaque
                %crash in every headless run.  -Inf is the exit flag callers
                %already read as "failed due to error".
                if(isempty(hLvdMainGUI))
                    disp(message);
                else
                    uialert(hLvdMainGUI, message, 'Launch Vehicle Designer', 'Icon','error');
                end

                exitflag = -Inf;

                return;
            end

            [exitflag, message] = optimizer.optimize(obj, writeOutput, callOutputFcn, hLvdMainGUI, progressFcn);
        end

        function [exitflag, message] = consoleOptimize(obj, progressFcn)
            %consoleOptimize Headless optimization: no Observe window, no
            %dialogs.  progressFcn, when given, is called as
            %progressFcn(iteration, fval, maxConstrViol, optimality) after
            %every solver iteration the selected optimizer reports; it is
            %how case-matrix runs watch each case converge.
            arguments
                obj
                progressFcn = [];
            end

            global options_gravParamType %#ok<GVMIS>

            if(isempty(options_gravParamType))
                options_gravParamType = 'kspStockLike';
            end

            writeOutput = @(varargin) disp('');
            callOutputFcn = false;

            [exitflag, message] = obj.optimize(writeOutput, callOutputFcn, [], progressFcn);
        end
        
        function optimizer = getSelectedOptimizer(obj)
            optAlgorithm = obj.optAlgo;
            optimizer = obj.getOptimizerForEnum(optAlgorithm);
        end

        function stateLog = propagateForX(obj, x, useSparse, evtToStartScriptExecAt, allowInterrupt)
            %propagateForX Applies the scaled x vector to the mission and
            %propagates it, unless the identical request was the most recent
            %propagation, in which case the existing state log is returned.
            %
            %   The objective function and the constraint set each ask for a
            %   propagation at the same x in turn.  When incremental
            %   re-propagation cannot help (loops, plugins, or disabled), that
            %   is two full propagations per optimizer step; this method
            %   collapses them to one.
            %
            %   Cache validity: x (exact isequal on the column form), the
            %   sparse-output flag, the start event handle, and the script's
            %   propagationCounter must all equal the values recorded when
            %   the cached propagation finished.  Any executeScript call not
            %   made through this method bumps the counter and forces a miss,
            %   so edits made through the GUI between evaluations can never
            %   be served stale results.  Errors from executeScript propagate
            %   to the caller and leave the cache empty.
            arguments
                obj(1,1) LvdOptimization
                x double
                useSparse(1,1) logical
                evtToStartScriptExecAt(1,:) LaunchVehicleEvent
                allowInterrupt(1,1) logical
            end

            script = obj.lvdData.script;
            settings = obj.lvdData.settings;
            xCol = x(:);

            cacheEnabled = settings.enableSameXPropagationCache;

            if(cacheEnabled && obj.isPropCacheHit(xCol, useSparse, evtToStartScriptExecAt, script.propagationCounter))
                obj.propCacheHits = obj.propCacheHits + 1;

                %Report the same bookkeeping executeScript uses when it serves
                %its own cache: nothing was integrated for this call.
                script.lastNumEvtsIntegrated = 0;
                script.lastNumEvtsSkipped = script.getTotalNumOfEvents();
                script.lastRunUsedIncremental = true;

                stateLog = obj.lvdData.stateLog;
                return;
            end

            obj.propCacheMisses = obj.propCacheMisses + 1;
            obj.clearPropagationCache();

            obj.vars.updateObjsWithScaledVarValues(x);
            stateLog = script.executeScript(useSparse, evtToStartScriptExecAt, false, allowInterrupt, false, false, settings.enableIncrementalRepropagation);

            if(cacheEnabled)
                obj.propCacheX = xCol;
                obj.propCacheSparse = useSparse;
                obj.propCacheStartEvt = evtToStartScriptExecAt;
                obj.propCacheCounter = script.propagationCounter;
            end
        end

        function clearPropagationCache(obj)
            obj.propCacheX = [];
            obj.propCacheSparse = false;
            obj.propCacheStartEvt = LaunchVehicleEvent.empty(1,0);
            obj.propCacheCounter = NaN;
        end

        function [hits, misses] = getPropagationCacheStats(obj)
            hits = obj.propCacheHits;
            misses = obj.propCacheMisses;
        end

        function resetPropagationCacheStats(obj)
            obj.propCacheHits = 0;
            obj.propCacheMisses = 0;
        end
        
        function optimizer = getOptimizerForEnum(obj, optAlgorithm)
            if(optAlgorithm == LvdOptimizerAlgoEnum.Fmincon)
                optimizer = obj.fminconOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.PatternSearch)
                optimizer = obj.patternSearchOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.Nomad)
                optimizer = obj.nomadOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.Ipopt)
                optimizer = obj.ipoptOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.Surrogate)
                optimizer = obj.surragateOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.SQP)
                optimizer = obj.sqpOpt;
            elseif(optAlgorithm == LvdOptimizerAlgoEnum.AdamNlOpt)
                optimizer = obj.adamNlOptOpt;
            else
                error('Unknown LVD optimization algorithm!');
            end
        end
        
        function gradAlgo = getGradAlgoForEnum(obj, gradAlgoEnum)
            if(gradAlgoEnum == LvdOptimizerGradientCalculationAlgoEnum.BuiltIn)
                gradAlgo = obj.builtInGradMethod;
            elseif(gradAlgoEnum == LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences)
                gradAlgo = obj.customFiniteDiffsCalcMethod;
            else
                error('Unknown LVD gradient algorithm!');
            end
        end
        
        function tf = usesParallel(obj)
            tf = obj.getSelectedOptimizer().usesParallel();
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
        
        function tf = usesExtremum(obj, extremum)
            tf = obj.objFcn.usesExtremum(extremum);
            
            tf = tf || obj.constraints.usesExtremum(extremum);
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = obj.objFcn.usesGroundObj(grdObj) || obj.constraints.usesGroundObj(grdObj);
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = obj.objFcn.usesCalculusCalc(calculusCalc);
            
            tf = tf || obj.constraints.usesCalculusCalc(calculusCalc);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.constraints.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.constraints.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = obj.constraints.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = obj.constraints.usesGeometricRefFrame(refFrame);
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = obj.constraints.usesGeometricAngle(angle);
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = obj.constraints.usesGeometricPlane(plane);
        end 
        
        function tf = usesPlugin(obj, plugin)
            tf = obj.constraints.usesPlugin(plugin);
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
        function tf = isPropCacheHit(obj, xCol, useSparse, evtToStartScriptExecAt, currentCounter)
            tf = false;

            if(isempty(obj.propCacheX) || isnan(obj.propCacheCounter))
                return;
            end

            if(obj.propCacheCounter ~= currentCounter)
                return;
            end

            if(obj.propCacheSparse ~= useSparse)
                return;
            end

            if(numel(obj.propCacheStartEvt) ~= numel(evtToStartScriptExecAt))
                return;
            end

            if(not(isempty(evtToStartScriptExecAt)) && not(obj.propCacheStartEvt == evtToStartScriptExecAt))
                return;
            end

            tf = isequal(obj.propCacheX, xCol);
        end

        function evtNumToStartScriptExecAt = getEvtNumToStartScriptExecAt(obj, actVars)
            evtNumToStartScriptExecAt = obj.lvdData.script.getTotalNumOfEvents();
            for(i=1:length(actVars)) %#ok<*NO4LP>
                var = actVars(i);
                
                if(isVarInLaunchVehicle(var, obj.lvdData))
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
        
        function evtNumToEndScriptExecAt = getEvtNumToEndScriptExecAt(obj)
            [~, activeVars, ~, ~] = obj.vars.getTotalScaledXVector();
            
            evtNumToEndScriptExecAt = -1;
            for(i=1:length(activeVars))
                var = activeVars(i);
                
                if(isVarInLaunchVehicle(var, obj.lvdData))
                    varEvtNum = 1;
                else
                    varEvtNum = getEventNumberForVar(var, obj.lvdData);
                    
                    if(isempty(varEvtNum))
                        varEvtNum = 1;
                    end
                end
                
                if(varEvtNum > evtNumToEndScriptExecAt)
                    evtNumToEndScriptExecAt = varEvtNum;
                end
            end
            
            objFcnEvts = obj.objFcn.getObjFuncEvents();
            for(i=1:length(objFcnEvts))
                objFcnEvtNum = objFcnEvts(i).getEventNum();
                
                if(objFcnEvtNum > evtNumToEndScriptExecAt)
                    evtNumToEndScriptExecAt = objFcnEvtNum;
                end
            end
            
            constrEvts = obj.constraints.getConstrEvents();
            for(i=1:length(constrEvts))
                constrEvtNum = constrEvts(i).getEventNum();
                
                if(constrEvtNum > evtNumToEndScriptExecAt)
                    evtNumToEndScriptExecAt = constrEvtNum;
                end
            end
        end
    end
end