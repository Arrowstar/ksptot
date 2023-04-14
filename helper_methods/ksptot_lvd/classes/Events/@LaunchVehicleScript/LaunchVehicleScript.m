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
        
        function stateLog = executeScript(obj, isSparseOutput, evtToStartScriptExecAt, evalConstraints, allowInterrupt, dispEvtPropTimes, notifyScriptEvents)
            arguments
                obj(1,1) LaunchVehicleScript
                isSparseOutput(1,1) logical
                evtToStartScriptExecAt(1,:) LaunchVehicleEvent
                evalConstraints(1,1) logical
                allowInterrupt(1,1) logical
                dispEvtPropTimes(1,1) logical
                notifyScriptEvents(1,1) logical = true;
            end
            
            stateLog = obj.lvdData.stateLog;
            
            if(not(isempty(evtToStartScriptExecAt)))
                evtStartNum = evtToStartScriptExecAt.getEventNum();
            else
                evtStartNum = 1;
            end
            
            %execute plugins that occur before propagation
            obj.lvdData.plugins.executePluginsBeforeProp(stateLog);

            if(isempty(evtStartNum) || evtStartNum <= 1)
                evtStartNum = 1;  %disable the event start exec time optimization for now, it is buggy/broken
                stateLog.clearStateLog();
                initStateLogEntry = obj.lvdData.initialState; 
                initStateLogEntry.event = obj.lvdData.script.getEventForInd(evtStartNum);
                initStateLogEntry.integrationGroup = IntegrationGroup(1);
                obj.nonSeqEvts.resetAllNumExecsRemaining();
            else
                stateLog.clearStateLogAtOrAfterEvent(evtToStartScriptExecAt);
                initStateLogEntry = stateLog.getFinalStateLogEntry().deepCopy();
                obj.nonSeqEvts = stateLog.getFinalNonSeqEvtsState().nonSeqEvts.copy();
            end
            
            stateLog.appendStateLogEntries(initStateLogEntry);
            initStateLogEntry = initStateLogEntry.deepCopy();
            
            %notify that script propagation has started
            if(notifyScriptEvents && isOnParallelWorker() == false)
                notify(obj, 'ScriptPropagationStarted');
            end
            
            obj.lvdData.plugins.initializePlugins();
            
            tPropTime = 0;
            if(~isempty(obj.evts))                
                tStartSimTime = initStateLogEntry.time;
                tStartPropTime = tic();
                
                obj.nextEventToRun = obj.evts(1);
                maxIntegrationDuration = obj.simDriver.maxPropTime;
                integrationNum = 1;
                while(not(isempty(obj.nextEventToRun)) && toc(tStartPropTime) < maxIntegrationDuration)
                    initStateLogEntry = obj.executeEvent(initStateLogEntry, stateLog, tStartSimTime, tStartPropTime, integrationNum, notifyScriptEvents, allowInterrupt, isSparseOutput, dispEvtPropTimes);
                    initStateLogEntry = initStateLogEntry.deepCopy();

                    integrationNum = integrationNum + 1;
                end
                
                tPropTime = toc(tStartPropTime);
                
                %execute plugins after propagation
                obj.lvdData.plugins.executePluginsAfterProp(stateLog);
            else
                stateLog.appendStateLogEntries(initStateLogEntry.deepCopy());
            end
            
            obj.lastRunExecTime = tPropTime;
            
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
            defaultNextEventToRun = obj.nextEventToRun;
            
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

   methods (Static)
      function s = loadobj(s)
         if(isempty(s.nonSeqEvts))
             s.nonSeqEvts = LaunchVehicleNonSeqEvents(s.lvdData);
         end
      end
   end
end