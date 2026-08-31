classdef LaunchVehicleScript < matlab.mixin.SetGet
    %LaunchVehicleScript Summary of this class goes here
    %   Detailed explanation goes here
    
    events
        ScriptPropagationStarted
        ScriptPropagationFinished
        EventPropagationStarted
        EventPropagationEnded
    end
    
    properties
        evts LaunchVehicleEvent
        simDriver LaunchVehicleSimulationDriver
        lastRunExecTime(1,1) double = 0;
        
        lvdData LvdData
        
        nonSeqEvts LaunchVehicleNonSeqEvents 
    end

    properties(Transient)
        nextEventToRun LaunchVehicleEvent
        
        %Incremental re-propagation bookkeeping (see executeScript).
        lastRunSparseFlag(1,1) logical = false
        lastRunCompletedFully(1,1) logical = false
        lastRunUsedIncremental(1,1) logical = false
        lastNumEvtsIntegrated(1,1) double = 0
        lastNumEvtsSkipped(1,1) double = 0
    end
        
    properties(Constant)
        emptyEvtArr = LaunchVehicleEvent.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleScript(lvdData, simDriver)
            obj.lvdData = lvdData;
            obj.simDriver = simDriver;
            obj.nonSeqEvts = LaunchVehicleNonSeqEvents(lvdData);
        end
        
        function addEvent(obj, newEvt)
            obj.evts(end+1) = newEvt;
        end
        
        function addEventAtInd(obj, newEvt, ind)
            if(not(isempty(obj.evts)))
                if(ind == length(obj.evts))
                    obj.evts(end+1) = newEvt;
                else
                    obj.evts = [obj.evts(1:ind), newEvt, obj.evts(ind+1:end)];
                end
            else
                obj.evts(end+1) = newEvt;
            end
        end
        
        function removeEvent(obj, evt)
            termCondOptVar = evt.termCond.getExistingOptVar();
            if(not(isempty(termCondOptVar)))
                obj.lvdData.optimizer.vars.removeVariable(termCondOptVar);
            end
            
            actions = evt.actions;
            for(i=1:length(actions))
                evt.removeAction(actions(i));
            end
            
            obj.evts(obj.evts == evt) = [];
        end
        
        function removeEventFromIndex(obj, ind)
            if(ind >= 1 && ind <= length(obj.evts))
                obj.removeEvent(obj.evts(ind));
            end
        end
        
        function evtNum = getNumOfEvent(obj, evt)
            evtNum = [];
            
            if(not(isempty(evt)))
                evtNum = find(obj.evts == evt);
            end
        end
        
        function evt = getEventForInd(obj, ind)
            evt = obj.emptyEvtArr;
            
            if(ind >= 1 && ind <= length(obj.evts))
                evt = obj.evts(ind);
            end
        end
        
        function numEvents = getTotalNumOfEvents(obj)
            numEvents = length(obj.evts);
        end
        
        function [timeEvts, timeEvtsListboxStrs] = getAllEvtsThatOccurAtTime(obj, time)
            stateLog = obj.lvdData.stateLog;
            
            timeEvts = LaunchVehicleEvent.empty(1,0);
            timeEvtsListboxStrs = string.empty(1,0);
            for(i=1:length(obj.evts))
                evt = obj.evts(i);
                subStateLog = stateLog.entries([stateLog.entries.event] == evt);
                
                if(not(isempty(subStateLog)))
                    switch evt.plotMethod
                        case EventPlottingMethodEnum.PlotContinuous
                            t1 = subStateLog(1).time;
                            t2 = subStateLog(end).time;
                            
                        case EventPlottingMethodEnum.SkipFirstState
                            if(numel(subStateLog) >= 2)
                                t1 = subStateLog(2).time;
                            else
                                t1 = subStateLog(1).time;
                            end
                            t2 = subStateLog(end).time;
                            
                        case EventPlottingMethodEnum.DoNotPlot
                            t1 = Inf;
                            t2 = -Inf;
                        otherwise
                           error('Unknown event plotting method: %s', evt.plotMethod.name); 
                    end
                  
                else
                    t1 = Inf;
                    t2 = -Inf;
                end
                
                if(t1 > t2 && (isfinite(t1) && isfinite(t2)))
                    t1Temp = t2;
                    t2Temp = t1;
                    
                    t1 = t1Temp;
                    t2 = t2Temp;
                end
                
                if(time >= t1 && time <= t2)
                    timeEvts(end+1) = evt; %#ok<AGROW>
                    timeEvtsListboxStrs(end+1) = string(evt.getListboxStr()); %#ok<AGROW>
                end
            end
        end
        
        function moveEvtAtIndexDown(obj, ind)
            if(ind < length(obj.evts))
                obj.evts([ind+1,ind]) = obj.evts([ind,ind+1]);
            end
        end
        
        function moveEvtAtIndexUp(obj, ind)
            if(ind > 1)
                obj.evts([ind,ind-1]) = obj.evts([ind-1,ind]);
            end
        end
        
        function [listboxStr, events] = getListboxStr(obj)
            listboxStr = cell(length(obj.evts),1);
            
            for(i=1:length(obj.evts))
                listboxStr{i} = obj.evts(i).getListboxStr();
            end
            
            events = obj.evts;
        end

        function [htmlListboxStrEvts, events] = getHtmlListboxStr(obj)  
            htmlListboxStrEvts = cell(length(obj.evts),1);
            for(i=1:length(obj.evts))
                htmlListboxStrEvts{i} = obj.evts(i).getHtmlListboxStr();
            end
            
            events = obj.evts;
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesStage(stage);
            end
            
            tf = tf || obj.nonSeqEvts.usesStage(stage);
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesEngine(engine);
            end
            
            tf = tf || obj.nonSeqEvts.usesEngine(engine);
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesTank(tank);
            end
            
            tf = tf || obj.nonSeqEvts.usesTank(tank);
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesEngineToTankConn(engineToTank);
            end
            
            tf = tf || obj.nonSeqEvts.usesEngineToTankConn(engineToTank);
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesStopwatch(stopwatch);
            end
            
            tf = tf || obj.nonSeqEvts.usesStopwatch(stopwatch);
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesExtremum(extremum);
            end
            
            tf = tf || obj.nonSeqEvts.usesExtremum(extremum);
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesTankToTankConn(tankToTank);
            end
            
            tf = tf || obj.nonSeqEvts.usesTankToTankConn(tankToTank);
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesCalculusCalc(calculusCalc);
            end
            
            tf = tf || obj.nonSeqEvts.usesCalculusCalc(calculusCalc);
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesPwrSink(powerSink);
            end
            
            tf = tf || obj.nonSeqEvts.usesPwrSink(powerSink);
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesPwrSrc(powerSrc);
            end
            
            tf = tf || obj.nonSeqEvts.usesPwrSrc(powerSrc);
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesPwrStorage(powerStorage);
            end
            
            tf = tf || obj.nonSeqEvts.usesPwrStorage(powerStorage);
        end
        
        function tf = usesSensor(obj, sensor)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesSensor(sensor);
            end
            
            tf = tf || obj.nonSeqEvts.usesSensor(sensor);
        end

        function tf = usesPluginVariable(obj, pluginVar)
            arguments
                obj(1,1) 
                pluginVar(1,1) LvdPluginOptimVarWrapper
            end

            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesPluginVariable(pluginVar);
            end
            
            tf = tf || obj.nonSeqEvts.usesPluginVariable(pluginVar);
        end
        
        function stateLog = executeScript(obj, isSparseOutput, evtToStartScriptExecAt, evalConstraints, allowInterrupt, dispEvtPropTimes, notifyScriptEvents, allowIncrementalReuse)
            arguments
                obj(1,1) LaunchVehicleScript
                isSparseOutput(1,1) logical
                evtToStartScriptExecAt(1,:) LaunchVehicleEvent
                evalConstraints(1,1) logical
                allowInterrupt(1,1) logical
                dispEvtPropTimes(1,1) logical
                notifyScriptEvents(1,1) logical = true;
                allowIncrementalReuse(1,1) logical = false;
            end
            
            stateLog = obj.lvdData.stateLog;
            vars = obj.lvdData.optimizer.vars;

            %Capture the previous run's completion state before resetting:
            %the resolver needs it to decide whether the cache is trustworthy.
            prevCompletedFully = obj.lastRunCompletedFully;
            obj.lastRunCompletedFully = false;

            %Resolve where propagation must begin for this evaluation.
            incrementalAllowed = allowIncrementalReuse && obj.lvdData.settings.enableIncrementalRepropagation;
            useIncremental = incrementalAllowed;

            if(useIncremental)
                [useIncremental, evtStartNum, skipPropagation] = obj.resolvePropagationStartPoint(evtToStartScriptExecAt, isSparseOutput, prevCompletedFully);
            else
                %Classic behavior: always propagate the full script.
                evtStartNum = 1;
                skipPropagation = false;
            end
            
            if(skipPropagation)
                %No variable inputs changed since the last committed
                %evaluation and the cached log has the right granularity:
                %serve it as-is without re-integrating anything.
                vars.commitPendingX();
                
                obj.lastRunUsedIncremental = true;
                obj.lastNumEvtsIntegrated = 0;
                obj.lastNumEvtsSkipped = obj.getTotalNumOfEvents();
                obj.lastRunCompletedFully = true;
                
                return;
            end
            
            %execute plugins that occur before propagation
            obj.lvdData.plugins.executePluginsBeforeProp(stateLog);

            if(evtStartNum <= 1 || not(obj.canResumeFromCachedLog(evtStartNum)))
                evtStartNum = 1;
                stateLog.clearStateLog();
                initStateLogEntry = obj.lvdData.initialState; 
                initStateLogEntry.event = obj.lvdData.script.getEventForInd(evtStartNum);
                initStateLogEntry.integrationGroup = IntegrationGroup(1);
                obj.nonSeqEvts.resetAllNumExecsRemaining();
            else
                %Reuse the cached propagation results for all events before
                %evtStartNum: clear them out of the working log and pick up
                %from the last state they produced.
                stateLog.clearStateLogAtOrAfterEvent(obj.getEventForInd(evtStartNum));
                initStateLogEntry = stateLog.getFinalStateLogEntry().deepCopy();
                
                if(not(isempty(stateLog.nonSeqEvtsStates)))
                    obj.nonSeqEvts = stateLog.getFinalNonSeqEvtsState().nonSeqEvts.copy();
                end
            end
            
            %Continue integration group numbering from the cached entries so
            %that resumed logs match full-run logs entry for entry.
            integrationNum = 1;
            if(evtStartNum > 1 && stateLog.getNumberOfEntries() > 0)
                cachedEntries = stateLog.getAllEntries();
                grpNums = zeros(1, length(cachedEntries));
                for(i = 1:length(cachedEntries))
                    grpNums(i) = cachedEntries(i).integrationGroup.integrationGroupNum;
                end

                integrationNum = max(grpNums) + 1;
            end
            
            %Seed the working state's event and integration group so that
            %entries produced by the resumed tail are tagged identically to
            %a full propagation run.
            if(evtStartNum > 1)
                initStateLogEntry.event = obj.getEventForInd(evtStartNum);
                initStateLogEntry.integrationGroup = IntegrationGroup(integrationNum);
            end

            %A cold start logs its initial-state entry; a resumed run must
            %not, or an extra boundary entry would be duplicated into the
            %log relative to a full run.
            if(evtStartNum <= 1)
                stateLog.appendStateLogEntries(initStateLogEntry);
            end
            initStateLogEntry = initStateLogEntry.deepCopy();
            
            %notify that script propagation has started
            if(notifyScriptEvents && isOnParallelWorker() == false)
                notify(obj, 'ScriptPropagationStarted');
            end
            
            obj.lvdData.plugins.initializePlugins();
            
            tPropTime = 0;
            if(~isempty(obj.evts))
                %The simulated-duration budget (simDriver.simMaxDur) is
                %measured from the start of the script, not from wherever
                %this evaluation happens to begin integrating.  It reaches
                %the integrator as maxT, which is both the tspan endpoint
                %and a hard termination condition on every event, so taking
                %it from a resumed run's seed state would hand the tail
                %events a fresh budget and terminate them somewhere a full
                %run would not.  On a cold start initStateLogEntry is
                %lvdData.initialState, so this is the same value.
                tStartSimTime = obj.lvdData.initialState.time;
                tStartPropTime = tic();
                
                obj.nextEventToRun = obj.getEventForInd(evtStartNum);
                maxIntegrationDuration = obj.simDriver.maxPropTime;
                numEvtsExecuted = 0;
                while(not(isempty(obj.nextEventToRun)) && toc(tStartPropTime) < maxIntegrationDuration) 
                    initStateLogEntry = obj.executeEvent(initStateLogEntry, stateLog, tStartSimTime, tStartPropTime, integrationNum, notifyScriptEvents, allowInterrupt, isSparseOutput, dispEvtPropTimes);
                    initStateLogEntry = initStateLogEntry.deepCopy();

                    integrationNum = integrationNum + 1;
                    numEvtsExecuted = numEvtsExecuted + 1;
                end
                
                tPropTime = toc(tStartPropTime);
                
                %execute plugins after propagation
                obj.lvdData.plugins.executePluginsAfterProp(stateLog);
            else
                stateLog.appendStateLogEntries(initStateLogEntry.deepCopy());
            end

            %basically, if we run out of time and not all events run, then
            %just grab the last state and set all events to use that as
            %their one state.  This means all events will have states,
            %which avoids issues with constraints and objective function
            %eval.
            if(not(isempty(obj.nextEventToRun)))
                eventsWithStates = unique([stateLog.entries.event]);
                eventsWithNoStates = setdiff(obj.evts, eventsWithStates);

                finalState = stateLog.entries(end);
                for(i=1:length(eventsWithNoStates))
                    evtNoState = eventsWithNoStates(i);
                    finalStateHere = finalState.deepCopy();
                    finalStateHere.event = evtNoState;
                    stateLog.appendStateLogEntries(finalStateHere);
                end
            end
            
            obj.lastRunExecTime = tPropTime;
            
            %Bookkeeping for incremental re-propagation: mark the pending x
            %vector as committed (propagation results now exist for it) and
            %record how much of the script was re-integrated.  The commit
            %happens whenever incremental mode was allowed, even when this
            %evaluation propagated everything: a full run is a perfectly
            %good baseline for the next evaluation's change detection.
            obj.lastRunSparseFlag = isSparseOutput;
            obj.lastNumEvtsIntegrated = numEvtsExecuted;
            if(evtStartNum <= 1)
                obj.lastNumEvtsSkipped = 0;
            else
                obj.lastNumEvtsSkipped = evtStartNum - 1;
            end
            obj.lastRunUsedIncremental = useIncremental && evtStartNum > 1;

            %Only a run whose while-loop exhausted the event list (no
            %watchdog timeout) leaves a cache that is safe to skip against.
            obj.lastRunCompletedFully = isempty(obj.nextEventToRun);

            if(incrementalAllowed)
                vars.commitPendingX();
            end
            
            if(evalConstraints)
                x=obj.lvdData.optimizer.vars.getTotalScaledXVector();
                [c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds, ~, consts, cCInds, cCeqInds, valueStateComps] = obj.lvdData.optimizer.constraints.evalConstraints(x, false, evtToStartScriptExecAt, allowInterrupt, []);

                if(isempty(obj.lvdData.optimizer.constraints.lastRunValues))
                    obj.lvdData.optimizer.constraints.lastRunValues = ConstraintValues();
                end

                obj.lvdData.optimizer.constraints.lastRunValues.updateValues(c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds, consts, cCInds, cCeqInds, valueStateComps);
            end
            
            %notify that script propagation has ended
            if(notifyScriptEvents && isOnParallelWorker() == false)
                notify(obj, 'ScriptPropagationFinished');
            end
        end

        function [initStateLogEntry] = executeEvent(obj, initStateLogEntry, stateLog, tStartSimTime, tStartPropTime, integrationNum, notifyScriptEvents, allowInterrupt, isSparseOutput, dispEvtPropTimes)
            arguments(Input)
                obj(1,1) LaunchVehicleScript
                initStateLogEntry(1,1) LaunchVehicleStateLogEntry
                stateLog(1,1) LaunchVehicleStateLog
                tStartSimTime(1,1) double
                tStartPropTime(1,1) uint64
                integrationNum(1,1) double
                notifyScriptEvents(1,1) logical
                allowInterrupt(1,1) logical
                isSparseOutput(1,1) logical
                dispEvtPropTimes(1,1) logical
            end

            arguments(Output)
                initStateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            ttt = tic();
            evt = obj.nextEventToRun;
            evtNum = evt.getEventNum();

            %Set this first so if an action or plugin modifies it, that'll
            %take effect
            obj.nextEventToRun = obj.getEventForInd(evtNum + 1);
            
            %notify that event propagation has started
            if(notifyScriptEvents && isOnParallelWorker() == false)
                notify(obj, 'EventPropagationStarted', ScriptEventPropagationData(evt));
            end
            
            intGroup = IntegrationGroup(integrationNum);
            initStateLogEntry.event = evt; %need to set the event on the initial state
            initStateLogEntry.integrationGroup = intGroup;
            
            %allow interrupting script execution with figure
            if(allowInterrupt && usejava('desktop'))
                drawnow;
            end
            
            %execute plugins that occur before event
            obj.lvdData.plugins.executePluginsBeforeEvent(stateLog, evt);
                               
            if(evt.execActionsNode == ActionExecNodeEnum.BeforeProp)
                tActions = tic;
                %Execute Actions
                initStateLogEntry = initStateLogEntry.deepCopy(); %this state log entry must be copied or the answers will change
                initStateLogEntry.integrationGroup = intGroup;
                stateLog.appendStateLogEntries(initStateLogEntry);
                actionStateLogEntries = evt.cleanupEvent(initStateLogEntry); %this executes the actions

                %Add state log entries to state log
                if(not(isempty(actionStateLogEntries)))
                    for(i=1:length(actionStateLogEntries))
                        actionStateLogEntries(i).integrationGroup = intGroup;
                    end

                    stateLog.appendStateLogEntries(actionStateLogEntries);
                    initStateLogEntry = actionStateLogEntries(end).deepCopy(); %this state log entry must be copied or the answers will change;
                    initStateLogEntry.integrationGroup = intGroup;
                end
                ttActions = toc(tActions);
            end
            
            %Get applicable non sequential events and initialize
            activeNonSeqEvts = obj.nonSeqEvts.getNonSeqEventsForScriptEvent(evt);
            for(j=1:length(activeNonSeqEvts))
                activeNonSeqEvts(j).initEvent(initStateLogEntry);
            end
            
            %Init Event
            evt.initEvent(initStateLogEntry);
                                
            %Execute Event (propagation)
            tPropagate = tic;
            newStateLogEntries = evt.executeEvent(initStateLogEntry, obj.simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts);
            [newStateLogEntries.integrationGroup] = deal(intGroup);
            stateLog.appendStateLogEntries(newStateLogEntries);
            ttPropagate = toc(tPropagate);
            
            %Execute Actions After Event Propagation
            initStateLogEntry = newStateLogEntries(end).deepCopy();  %this state log entry must be copied or the answers will change
            initStateLogEntry.integrationGroup = intGroup;
            if(evt.execActionsNode == ActionExecNodeEnum.AfterProp)
                tActions = tic;
                %Execute Actions
                actionStateLogEntries = evt.cleanupEvent(initStateLogEntry);

                %Add state log entries to state log
                if(not(isempty(actionStateLogEntries)))
                    for(i=1:length(actionStateLogEntries))
                        actionStateLogEntries(i).integrationGroup = intGroup;
                    end

                    stateLog.appendStateLogEntries(actionStateLogEntries);
                    initStateLogEntry = actionStateLogEntries(end).deepCopy(); %this state log entry must be copied or the answers will change;
                    initStateLogEntry.integrationGroup = intGroup;
                end
                ttActions = toc(tActions);
            end

            stateLog.appendNonSeqEvtsState(obj.nonSeqEvts.copy(), evt);
            
            %execute plugins that occur after event
            obj.lvdData.plugins.executePluginsAfterEvent(stateLog, evt);
            
            %notify that event propagation has ended
            if(notifyScriptEvents && isOnParallelWorker() == false)
                notify(obj, 'EventPropagationEnded', ScriptEventPropagationData(evt));
            end
            
            evtTime = toc(ttt);
            if(dispEvtPropTimes)
                fprintf('(%s) Duration to execute Event %u: %0.3f s (Propagation: %0.3f s; Actions: %0.3f s) (Evt Dur: %0.3f s)\n', datestr(now,'hh:MM:ss'), evtNum, evtTime, ttPropagate, ttActions, newStateLogEntries(end).time-newStateLogEntries(1).time);
            end
        end
    end

    methods(Access=private)
        function evtStartNum = normalizeStartEvtNum(obj, evtToStartScriptExecAt)
            if(isempty(evtToStartScriptExecAt))
                evtStartNum = 1;
            else
                evtStartNum = evtToStartScriptExecAt.getEventNum();
            end

            if(isempty(evtStartNum) || not(isnumeric(evtStartNum)) || isnan(evtStartNum) || evtStartNum < 1)
                evtStartNum = 1;
            end

            totalEvts = obj.getTotalNumOfEvents();
            if(totalEvts > 0 && evtStartNum > totalEvts)
                evtStartNum = totalEvts;
            end
        end

        function [useIncremental, evtStartNum, skipPropagation] = resolvePropagationStartPoint(obj, evtToStartScriptExecAt, isSparseOutput, prevCompletedFully)
            %RESOLVEPROPAGATIONSTARTPOINT Decides how much of the script to
            %re-propagate for this evaluation.
            %
            %   Returns:
            %       useIncremental  - true when cached results are being
            %                         leveraged at all this evaluation (the
            %                         pending x vector should be committed).
            %       evtStartNum     - the event number to begin propagation
            %                         from.
            %       skipPropagation - true when nothing changed and the
            %                         existing state log can be served as-is.
            %
            %   Reuse is only ever attempted when the caller explicitly
            %   allowed it AND the setting is enabled; the guards below then
            %   reject any script whose execution cannot be assumed
            %   deterministic given unchanged optimization variables.

            useIncremental = false;
            evtStartNum = obj.normalizeStartEvtNum(evtToStartScriptExecAt);
            skipPropagation = false;

            floorEvtNum = evtStartNum;

            %Guard: script looping / flow modification invalidates all
            %static reuse assumptions.  Force a full run.
            if(scriptContainsSetNextEventAction(obj.lvdData))
                useIncremental = false;
                evtStartNum = 1;
                return;
            end

            %Guard: plugins execute arbitrary code each evaluation and may
            %mutate anything; do not assume unchanged inputs.
            if(obj.lvdData.plugins.getNumPlugins() > 0)
                useIncremental = false;
                evtStartNum = 1;
                return;
            end

            vars = obj.lvdData.optimizer.vars;
            pendingX = vars.getPendingX();
            committedX = vars.getCommittedX();

            %No committed baseline yet (first evaluation, or the variable
            %set changed): fall back to a STATIC resume floor derived from
            %where the active variables live.  Events hosting no active
            %variables cannot have changed since the cached results were
            %produced, so reuse remains valid; anything else forces a full
            %run.  A caller-provided floor event is ignored in favor of
            %this internally-derived one, which can only be more safe.
            if(isempty(pendingX) || isempty(committedX) || numel(pendingX) ~= numel(committedX))
                evtNums = vars.getXElementEvtNums();

                if(isempty(pendingX) || numel(evtNums) ~= numel(pendingX))
                    evtStartNum = floorEvtNum;
                else
                    evtStartNum = min(max(evtNums, 1));
                end

                useIncremental = evtStartNum > 1;
                return;
            end

            changedInds = find(pendingX(:).' ~= committedX(:).');

            if(isempty(changedInds))
                %Nothing changed since the last committed evaluation.  The
                %entire cached log can be reused as-is when it was produced
                %by a complete run with matching output granularity;
                %otherwise re-run the tail per the static floor.
                if(prevCompletedFully && obj.lastRunSparseFlag == isSparseOutput)
                    useIncremental = true;
                    skipPropagation = true;
                    return;
                end

                evtStartNum = floorEvtNum;
                useIncremental = evtStartNum > 1;
                return;
            end

            %Some inputs changed: resume from the earliest event that hosts
            %a changed variable.  Variables not owned by a specific event
            %(vehicle, initial state, plugin wrappers) map to 0 -> event 1,
            %forcing a full run whenever they change.
            evtNums = vars.getXElementEvtNums();

            if(numel(evtNums) ~= numel(pendingX))
                evtStartNum = floorEvtNum;
                useIncremental = evtStartNum > 1;
                return;
            end

            evtStartNum = min(max(evtNums(changedInds), 1));
            useIncremental = true;
        end

        function tf = canResumeFromCachedLog(obj, evtStartNum)
            %CANRESUMEFROMCACHEDLOG True when the current state log contains
            %propagation results for every event before evtStartNum, so the
            %script can pick up from there.

            tf = obj.lvdData.stateLog.getNumberOfEntries() > 0;

            for(i = 1:(evtStartNum-1))
                evt = obj.getEventForInd(i);
                if(isempty(evt) || isempty(obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt)))
                    tf = false;
                    return;
                end
            end
        end
    end

   methods (Static)
      function s = loadobj(s)
         if(isempty(s.nonSeqEvts))
             s.nonSeqEvts = LaunchVehicleNonSeqEvents(s.lvdData);
         end
      end
   end
end

