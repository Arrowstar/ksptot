classdef LaunchVehicleEvent < matlab.mixin.SetGet
    %LaunchVehicleEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        termCond(1,1) AbstractEventTerminationCondition = EventDurationTermCondition(0);
        termCondDir(1,1) EventTermCondDirectionEnum = EventTermCondDirectionEnum.NoDir
        actions AbstractEventAction
        
        name char = 'Untitled Event';
        script LaunchVehicleScript
        
        colorLineSpec(1,1) EventColorLineSpec 
        plotMethod(1,1) EventPlottingMethodEnum = EventPlottingMethodEnum.PlotContinuous

        integratorObj(1,:) AbstractIntegrator = AbstractIntegrator.empty(1,0);
        propagatorObj(1,:) AbstractPropagator = AbstractPropagator.empty(1,0);

        propDir(1,1) PropagationDirectionEnum = PropagationDirectionEnum.Forward;
        
        checkForSoITrans(1,1) logical = true;
        
        disableOptim(1,1) logical = false;
        
        execActionsNode(1,1) ActionExecNodeEnum = ActionExecNodeEnum.AfterProp;
        
        %%%%%
        %Propagators
        %%%%%
        forceModelPropagator(1,:) ForceModelPropagator
        twoBodyPropagator(1,:) TwoBodyPropagator
        secOrdGravOnlyPropagator(1,:) SecondOrderGravOnlyPropagator
        
        %%%%%
        %Integrators
        %%%%%
        %Adaptive Step Size
        ode45Integrator(1,:) ODE45Integrator
        ode113Integrator(1,:) ODE113Integrator
        ode78Integrator(1,:) ODE78Integrator
        ode89Integrator(1,:) ODE89Integrator
        ode23Integrator(1,:) ODE23Integrator 
        ode23sIntegrator(1,:) ODE23sIntegrator 
        ode15sIntegrator(1,:) ODE15sIntegrator
        rkn1210Integrator(1,:) RKN1210Integrator
        
        %Fixed Step Size
        ode5Integrator(1,:) ODE5Integrator
    end
    
    properties(Dependent)
        lvdData LvdData
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    properties(Transient, Access=private)
        hasActiveOptVarsTF logical = false(0);
        hasActiveOptVarsVars AbstractOptimizationVariable = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = LaunchVehicleEvent(script)
            if(nargin > 0)
                obj.script = script;
            end
            
            obj.colorLineSpec = EventColorLineSpec();

            obj.integratorObj = ODE45Integrator();
            obj.propagatorObj = ForceModelPropagator();
            
            obj.forceModelPropagator = ForceModelPropagator();
            obj.twoBodyPropagator = TwoBodyPropagator();
            obj.secOrdGravOnlyPropagator = SecondOrderGravOnlyPropagator();
            
            obj.ode45Integrator = ODE45Integrator();
            obj.ode113Integrator = ODE113Integrator();
            obj.ode78Integrator = ODE78Integrator();
            obj.ode89Integrator = ODE89Integrator();
            obj.ode23Integrator = ODE23Integrator();
            obj.ode23sIntegrator = ODE23sIntegrator();
            obj.ode15sIntegrator = ODE15sIntegrator();
            obj.ode5Integrator = ODE5Integrator();
            obj.rkn1210Integrator = RKN1210Integrator();
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.script.lvdData;
        end
        
        function addAction(obj, newAction)
            obj.actions(end+1) = newAction;
        end
        
        function removeAction(obj, action)
            [~, vars] = action.hasActiveOptimVar();
            if(not(isempty(vars)))
                for(i=1:length(vars))
                    obj.lvdData.optimizer.vars.removeVariable(vars(i));
                end
            end
            
            obj.actions([obj.actions] == action) = [];
        end
        
        function removeActionByInd(obj, ind)
            if(ind >= 1 && ind <= length(obj.actions))
                obj.removeAction(obj.actions(ind));
            end
        end
        
        function action = getActionForInd(obj, ind)
            action = AbstractEventAction.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.actions))
                action = obj.actions(ind);
            end
        end
        
        function numActions = getNumberOfActions(obj)
            numActions = length(obj.actions);
        end
        
        function evtNum = getEventNum(obj)
            for(i=1:length(obj))
                thisEvtNum = obj(i).script.getNumOfEvent(obj(i));
                if(isempty(thisEvtNum))
                    thisEvtNum = NaN;
                end
                evtNum(i) = thisEvtNum; %#ok<AGROW> 
            end
        end
        
        function listboxStr = getListboxStr(obj)
            hasOpt = obj.hasActiveOptVars();
            if(obj.disableOptim == true)
                optStr = '❄';
            elseif(hasOpt && obj.disableOptim == false)
                optStr = '*';
            else
                optStr = '';
            end
            
            totalNumEvents = obj.script.getTotalNumOfEvents();
            numDigits = floor(log10(abs(totalNumEvents)+1)) + 1;

            listboxStr = sprintf('%0*i - %s%s', numDigits, obj.getEventNum(), optStr, obj.name);
        end

        function htmlListboxStr = getHtmlListboxStr(obj)
            colorRGB = 255*obj.colorLineSpec.color.color;

%             style="color: rgb(%u,%u,%u);"   colorRGB(1),colorRGB(2),colorRGB(3), 
            htmlListboxStr = sprintf('<option value="%u" title="%s">▉ %s</option>', obj.getEventNum(), obj.getListboxStr(), obj.getListboxStr());
        end
        
        function [aListboxStr, actions] = getActionsListboxStr(obj)
            aListboxStr = {};
            actions = AbstractEventAction.empty(0,1);
            
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                aListboxStr{end+1} = obj.actions(i).getName(); %#ok<AGROW>
                actions(end+1) = obj.actions(i); %#ok<AGROW>
            end
        end
        
        function initEvent(obj, initialStateLogEntry)
            obj.termCond.initTermCondition(initialStateLogEntry);
        end
        
        function initEventOnRestart(obj, initialStateLogEntry)
            if(obj.termCond.shouldBeReinitOnRestart())
                obj.initEvent(initialStateLogEntry);
            end
        end
        
        function newStateLogEntries = cleanupEvent(obj, finalStateLogEntry)
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                obj.actions(i).initAction(finalStateLogEntry);
            end
            
            newStateLogEntries = LaunchVehicleStateLogEntry.empty(1,0);
            for(i=1:length(obj.actions))
                newStateLogEntry = obj.actions(i).executeAction(finalStateLogEntry);
                
                newStateLogEntries(end+1) = newStateLogEntry; %#ok<AGROW>
                finalStateLogEntry = newStateLogEntry;
            end
        end
        
        function newStateLogEntries = executeEvent(obj, initStateLogEntry, simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts)
            [newStateLogEntries] = simDriver.integrateOneEvent(obj, initStateLogEntry, tStartPropTime, tStartSimTime, isSparseOutput, obj.checkForSoITrans, activeNonSeqEvts);
        end
        
        function tf = usesStage(obj, stage)
            tf = obj.termCond.usesStage(stage);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesStage(stage);
            end
        end
        
        function tf = usesEngine(obj, engine)
            tf = obj.termCond.usesEngine(engine);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.termCond.usesTank(tank);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.termCond.usesEngineToTankConn(engineToTank);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = obj.termCond.usesStopwatch(stopwatch);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesStopwatch(stopwatch);
            end
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesExtremum(extremum);
            end
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesTankToTankConn(tankToTank);
            end
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesCalculusCalc(calculusCalc);
            end
        end
        
        function tf = usesEvent(obj, event)
            tf = false;
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEvent(event);
            end
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = obj.termCond.usesPwrSink(powerSink);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrSink(powerSink);
            end
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = obj.termCond.usesPwrSrc(powerSrc);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrSrc(powerSrc);
            end
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = obj.termCond.usesPwrStorage(powerStorage);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrStorage(powerStorage);
            end
        end
        
        function tf = usesSensor(obj, sensor)
            tf = obj.termCond.usesSensor(sensor);
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesSensor(sensor);
            end
        end
        
        function toggleOptimDisable(obj, lvdData)
            obj.disableOptim = not(obj.disableOptim);
            
            lvdData.optimizer.vars.clearCachedVarEvtDisabledStatus();
        end
        
        function [tf, vars] = hasActiveOptVars(obj)
            if(isempty(obj.hasActiveOptVarsTF) || isempty(obj.hasActiveOptVarsVars))
                tf = false;
                vars = obj.emptyVarArr;

                tcOptVar = obj.termCond.getExistingOptVar();
                if(not(isempty(tcOptVar)))
                    tf = any(tcOptVar.getUseTfForVariable());

                    vars(end+1) = tcOptVar;
                end

                for(i=1:length(obj.actions))
                    [aTf, aVars] = obj.actions(i).hasActiveOptimVar();
                    tf = tf || aTf;

                    if(isempty(vars))
                        vars = aVars;
                    else
                        vars = horzcat(vars, aVars); %#ok<AGROW>
                    end
                end
                
                obj.hasActiveOptVarsTF = tf;
                obj.hasActiveOptVarsVars = vars;
            else
                tf = obj.hasActiveOptVarsTF;
                vars = obj.hasActiveOptVarsVars;
            end
        end
        
        function clearActiveOptVarsCache(obj)
            obj.hasActiveOptVarsTF = false(0);
            obj.hasActiveOptVarsVars = AbstractOptimizationVariable.empty(0,1);
        end
        
        function createUpdatedSetKinematicStateObjs(obj)
            for(i=1:length(obj.actions))
                action = obj.actions(i);
                
                if(isa(action,'SetKinematicStateAction'))
                    action.generateLvComponentElements();
                end
            end            
        end
    end
         
    methods(Static)
        function newEvent = getDefaultEvent(script)
            newEvent = LaunchVehicleEvent(script);
            newEvent.termCond = EventDurationTermCondition(0);
        end
        
        function obj = loadobj(obj)
            for(i=1:length(obj.actions))
                obj.actions(i).event = obj;
            end
            
            if(isempty(obj.forceModelPropagator))
                obj.forceModelPropagator = ForceModelPropagator();
            end
            
            if(isempty(obj.twoBodyPropagator))
                obj.twoBodyPropagator = TwoBodyPropagator();
            end

            if(isempty(obj.secOrdGravOnlyPropagator))
                obj.secOrdGravOnlyPropagator = SecondOrderGravOnlyPropagator();
            end

            if(isempty(obj.propagatorObj))
                obj.propagatorObj = obj.forceModelPropagator;
            end
            
            if(isempty(obj.ode45Integrator))
                obj.ode45Integrator = ODE45Integrator();
            end
            
            if(isempty(obj.ode113Integrator))
                obj.ode113Integrator = ODE113Integrator();
            end
            
            if(isempty(obj.ode78Integrator))
                obj.ode78Integrator = ODE78Integrator();
            end

            if(isempty(obj.ode89Integrator))
                obj.ode89Integrator = ODE89Integrator();
            end

            if(isempty(obj.ode23Integrator))
                obj.ode23Integrator = ODE23Integrator();
            end
            
            if(isempty(obj.ode23sIntegrator))
                obj.ode23sIntegrator = ODE23sIntegrator();
            end
            
            if(isempty(obj.ode15sIntegrator))
                obj.ode15sIntegrator = ODE15sIntegrator();
            end
            
            if(isempty(obj.ode5Integrator))
                obj.ode5Integrator = ODE5Integrator();
            end

            if(isempty(obj.rkn1210Integrator))
                obj.rkn1210Integrator = RKN1210Integrator();
            end
            
            if(isempty(obj.integratorObj))
                obj.integratorObj = obj.ode45Integrator;
            end
        end
    end
end

