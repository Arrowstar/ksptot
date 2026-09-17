classdef LaunchVehicleEvent < matlab.mixin.SetGet
    %LaunchVehicleEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        termCond(1,1) AbstractEventTerminationCondition = EventDurationTermCondition(0);
        termCondDir(1,1) EventTermCondDirectionEnum = EventTermCondDirectionEnum.NoDir

        %Termination conditions 2..N.  Condition 1 stays in termCond /
        %termCondDir so that missions saved before multiple termination
        %conditions existed load and propagate unchanged.
        extraTermConds(1,:) AbstractEventTerminationCondition = AbstractEventTerminationCondition.empty(1,0);
        extraTermCondDirs(1,:) EventTermCondDirectionEnum = EventTermCondDirectionEnum.empty(1,0);
        termCondLogic(1,1) EventTermCondLogicEnum = EventTermCondLogicEnum.Any;

        actions AbstractEventAction

        name char = 'Untitled Event';
        script LaunchVehicleScript

        %A6: organization of long scripts
        groupName char = '';
        notes char = '';

        %A10: per-event overrides of the global LvdSettings limits
        useEvtMinAltitude(1,1) logical = false;
        evtMinAltitude(1,1) double = 0;
        minAltIsTerrainRelative(1,1) logical = false;
        useEvtMaxDur(1,1) logical = false;
        evtMaxDur(1,1) double = Inf;
        
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

        %A1 "All" logic: one latch per termination condition, cleared by
        %initEvent and set as each condition fires.  Transient because it is
        %propagation scratch state, not part of the mission definition.
        termCondLatched(1,:) logical = false(1,0);
    end
    
    methods
        function obj = LaunchVehicleEvent(script)
            if(nargin > 0)
                obj.script = script;
            end
            
            obj.colorLineSpec = EventColorLineSpec();

            obj.integratorObj = ODE45Integrator();

            obj.forceModelPropagator = ForceModelPropagator();
            obj.propagatorObj = obj.forceModelPropagator;

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
            
            if(isempty(obj.notes))
                notesStr = '';
            else
                notesStr = ' 🗒';
            end

            totalNumEvents = obj.script.getTotalNumOfEvents();
            numDigits = floor(log10(abs(totalNumEvents)+1)) + 1;

            listboxStr = sprintf('%0*i - %s%s%s', numDigits, obj.getEventNum(), optStr, obj.name, notesStr);
        end

        function tf = isInGroup(obj, groupNameToTest)
            tf = strcmp(obj.groupName, groupNameToTest);
        end

        function htmlListboxStr = getHtmlListboxStr(obj)
            str = getListboxStr(obj);

            colorRGB = obj.colorLineSpec.color.color;
            colorRGB255 = 255*obj.colorLineSpec.color.color;
            colorHSV = rgb2hsv(colorRGB);

            if(colorHSV(3) > 0.5)
                bgColorRGB255 = 255*hsv2rgb([0,0,0.3]);
            else
                bgColorRGB255 = 255*hsv2rgb([0,0,0.7]);
            end
            
            htmlListboxStr = sprintf('<p style="background-color: rgb(%0.3f,%0.3f,%0.3f); color:rgb(%0.3f,%0.3f,%0.3f); font: 10.666px Helvetica, sans-serif">%s</p>', ...
                                      bgColorRGB255(1), bgColorRGB255(2), bgColorRGB255(3), colorRGB255(1), colorRGB255(2), colorRGB255(3), str);
        end
        
        function [aListboxStr, actions] = getActionsListboxStr(obj)
            aListboxStr = {};
            actions = AbstractEventAction.empty(0,1);
            
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                aListboxStr{end+1} = obj.actions(i).getName(); %#ok<AGROW>
                actions(end+1) = obj.actions(i); %#ok<AGROW>
            end
        end
        
        function termConds = getAllTermConds(obj)
            %getAllTermConds Condition 1 (termCond) followed by conditions 2..N.
            termConds = horzcat(obj.termCond, obj.extraTermConds);
        end

        function dirs = getAllTermCondDirs(obj)
            dirs = horzcat(obj.termCondDir, obj.extraTermCondDirs);

            %Tolerate a mission whose extra directions array got out of step
            %with its extra conditions array (hand-edited or partially
            %constructed): missing entries default to NoDir.
            numConds = 1 + numel(obj.extraTermConds);
            if(numel(dirs) < numConds)
                dirs(numel(dirs)+1:numConds) = EventTermCondDirectionEnum.NoDir;
            elseif(numel(dirs) > numConds)
                dirs = dirs(1:numConds);
            end
        end

        function num = getNumTermConds(obj)
            num = 1 + numel(obj.extraTermConds);
        end

        function str = getTermCondSummaryStr(obj)
            %getTermCondSummaryStr Condition 1's name, followed by how many
            %more conditions there are and how they combine.  For a single
            %condition this is exactly the condition's name, which is what
            %the event editor showed before multiple conditions existed.
            str = obj.termCond.getName();

            numExtra = numel(obj.extraTermConds);
            if(numExtra > 0)
                switch obj.termCondLogic
                    case EventTermCondLogicEnum.All
                        logicStr = 'all must fire';
                    otherwise
                        logicStr = 'first to fire ends event';
                end

                str = sprintf('%s  (+%u more; %s)', str, numExtra, logicStr);
            end
        end

        function addTermCond(obj, termCond, termCondDir)
            if(nargin < 3 || isempty(termCondDir))
                termCondDir = EventTermCondDirectionEnum.NoDir;
            end

            existingDirs = obj.getAllTermCondDirs();
            obj.extraTermConds(end+1) = termCond;
            obj.extraTermCondDirs = horzcat(existingDirs(2:end), termCondDir);

            obj.clearActiveOptVarsCache();
        end

        function setTermCondByInd(obj, ind, termCond)
            %setTermCondByInd Replaces condition ind (1-based, over the
            %combined list) in place, leaving its direction alone.
            if(ind < 1 || ind > obj.getNumTermConds())
                return;
            end

            if(ind == 1)
                obj.termCond = termCond;
            else
                obj.extraTermConds(ind-1) = termCond;
            end

            obj.clearActiveOptVarsCache();
        end

        function setTermCondDirByInd(obj, ind, termCondDir)
            %setTermCondDirByInd Sets the direction of condition ind (1-based,
            %over the combined list), normalizing the stored arrays on the way
            %through so a short extraTermCondDirs cannot go unnoticed.
            if(ind < 1 || ind > obj.getNumTermConds())
                return;
            end

            dirs = obj.getAllTermCondDirs();
            dirs(ind) = termCondDir;

            obj.termCondDir = dirs(1);
            obj.extraTermCondDirs = dirs(2:end);
        end

        function removeTermCondByInd(obj, ind)
            %removeTermCondByInd Removes condition ind (1-based, over the
            %combined list).  Removing condition 1 promotes condition 2 into
            %its place; an event always keeps at least one condition.
            if(ind < 1 || ind > obj.getNumTermConds() || obj.getNumTermConds() == 1)
                return;
            end

            allConds = obj.getAllTermConds();
            allDirs = obj.getAllTermCondDirs();

            removedCond = allConds(ind);
            allConds(ind) = [];
            allDirs(ind) = [];

            obj.termCond = allConds(1);
            obj.termCondDir = allDirs(1);
            obj.extraTermConds = allConds(2:end);
            obj.extraTermCondDirs = allDirs(2:end);

            optVar = removedCond.getExistingOptVar();
            if(not(isempty(optVar)) && not(isempty(obj.script)) && not(isempty(obj.lvdData)))
                obj.lvdData.optimizer.vars.removeVariable(optVar);
            end

            obj.clearActiveOptVarsCache();
        end

        function [fcnHandles, dirs, condInds] = getActiveTermCondFuncHandles(obj)
            %getActiveTermCondFuncHandles The termination conditions the
            %integrator should watch right now.  Under Any logic that is all
            %of them; under All logic the conditions that have already fired
            %are dropped so they neither re-trigger nor stop the remaining
            %ones from being reached.
            allConds = obj.getAllTermConds();
            allDirs = obj.getAllTermCondDirs();

            condInds = 1:numel(allConds);
            if(obj.termCondLogic == EventTermCondLogicEnum.All)
                latched = obj.getTermCondLatches();
                condInds = condInds(~latched);

                if(isempty(condInds))
                    %Everything has fired already: fall back to the last
                    %condition so the integrator still has a terminal event.
                    condInds = numel(allConds);
                end
            end

            fcnHandles = cell(1, numel(condInds));
            for(i=1:numel(condInds))
                fcnHandles{i} = allConds(condInds(i)).getEventTermCondFuncHandle();
            end

            dirs = allDirs(condInds);
        end

        function latched = getTermCondLatches(obj)
            latched = obj.termCondLatched;

            numConds = obj.getNumTermConds();
            if(numel(latched) ~= numConds)
                latched = false(1, numConds);
                obj.termCondLatched = latched;
            end
        end

        function latchTermCond(obj, ind)
            latched = obj.getTermCondLatches();
            if(ind >= 1 && ind <= numel(latched))
                latched(ind) = true;
                obj.termCondLatched = latched;
            end
        end

        function tf = allTermCondsLatched(obj)
            tf = all(obj.getTermCondLatches());
        end

        function resetTermCondLatches(obj)
            obj.termCondLatched = false(1, obj.getNumTermConds());
        end

        function initEvent(obj, initialStateLogEntry)
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                termConds(i).initTermCondition(initialStateLogEntry);
            end

            obj.resetTermCondLatches();
        end

        function initEventOnRestart(obj, initialStateLogEntry)
            %Re-initialize only the conditions that ask for it, and never
            %clear the "All" latches: a restart is a continuation of the same
            %event, not a new one.
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                if(termConds(i).shouldBeReinitOnRestart())
                    termConds(i).initTermCondition(initialStateLogEntry);
                end
            end
        end
        
        function newStateLogEntries = cleanupEvent(obj, finalStateLogEntry)
            %cleanupEvent Runs this event's actions in order against the given
            %state log entry and returns one entry per action.
            %
            %   Simple actions mutate finalStateLogEntry in place and return
            %   that same handle, so for an N-action event the returned array
            %   holds N references to one object whose contents are the
            %   post-all-actions state.  This is intentional: the caller
            %   (LaunchVehicleScript.executeEvent) hands in a deep copy of the
            %   integrator's final entry, so the pre-action state survives as
            %   its own log entry and the post-action state is what every
            %   per-action entry reports.  Actions that need a fresh object
            %   (SetKinematicStateAction) may return a new handle; the loop
            %   chains whatever comes back into the next action.
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
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesStage(stage);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesStage(stage);
            end
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesEngine(engine);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesTank(tank);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesEngineToTankConn(engineToTank);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesStopwatch(stopwatch);
            end
            
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
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesPwrSink(powerSink);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrSink(powerSink);
            end
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesPwrSrc(powerSrc);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrSrc(powerSrc);
            end
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesPwrStorage(powerStorage);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPwrStorage(powerStorage);
            end
        end
        
        function tf = usesSensor(obj, sensor)
            tf = false;
            termConds = obj.getAllTermConds();
            for(i=1:numel(termConds))
                tf = tf || termConds(i).usesSensor(sensor);
            end
            
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesSensor(sensor);
            end
        end

        function tf = usesPluginVariable(obj, pluginVar)
            arguments
                obj(1,1) 
                pluginVar(1,1) LvdPluginOptimVarWrapper
            end

            tf = false;
            for(i=1:length(obj.actions))
                tf = tf || obj.actions(i).usesPluginVariable(pluginVar);
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

                termConds = obj.getAllTermConds();
                for(i=1:numel(termConds))
                    tcOptVar = termConds(i).getExistingOptVar();
                    if(not(isempty(tcOptVar)))
                        tf = tf || any(tcOptVar.getUseTfForVariable());

                        vars(end+1) = tcOptVar; %#ok<AGROW>
                    end
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

