classdef LaunchVehicleScript < matlab.mixin.SetGet
    %LaunchVehicleScript Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evts LaunchVehicleEvent
        simDriver LaunchVehicleSimulationDriver
        lastRunExecTime(1,1) double = 0;
        
        lvdData LvdData
        
        nonSeqEvts LaunchVehicleNonSeqEvents 
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
        
        function listboxStr = getListboxStr(obj)
            listboxStr = cell(length(obj.evts),1);
            
            for(i=1:length(obj.evts))
                listboxStr{i} = obj.evts(i).getListboxStr();
            end
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
        
        function stateLog = executeScript(obj, isSparseOutput, evtToStartScriptExecAt, evalConstraints, allowInterrupt)
            stateLog = obj.lvdData.stateLog;
            
            if(not(isempty(evtToStartScriptExecAt)))
                evtStartNum = evtToStartScriptExecAt.getEventNum();
            else
                evtStartNum = 1;
            end
            
            if(isempty(evtStartNum) || evtStartNum <= 1)
                evtStartNum = 1;  %disable the event start exec time optimization for now, it is buggy/broken
                stateLog.clearStateLog();
                initStateLogEntry = obj.lvdData.initialState; 
                obj.nonSeqEvts.resetAllNumExecsRemaining();
            else
                stateLog.clearStateLogAtOrAfterEvent(evtToStartScriptExecAt);
                initStateLogEntry = stateLog.getFinalStateLogEntry().deepCopy();
                obj.nonSeqEvts = stateLog.getFinalNonSeqEvtsState().nonSeqEvts.copy();
            end
            
            tPropTime = 0;
            if(~isempty(obj.evts))
                
                tStartSimTime = initStateLogEntry.time;
                tStartPropTime = tic();
                for(i=evtStartNum:length(obj.evts)) %#ok<*NO4LP>
                    evt = obj.evts(i);
                    
                    %allow interrupting script execution with figure
                    %callbacks on every other event
                    if(allowInterrupt && logical(mod(i,2)) && usejava('desktop'))
                        drawnow;
                    end
                    
                    %Init Event
                    evt.initEvent(initStateLogEntry);
                    initStateLogEntry.event = evt;

                    %Get applicable non sequential events and initialize
                    activeNonSeqEvts = obj.nonSeqEvts.getNonSeqEventsForScriptEvent(evt);
                    for(j=1:length(activeNonSeqEvts))
                        activeNonSeqEvts(j).initEvent(initStateLogEntry);
                    end
                    
                    %Execute Event
                    newStateLogEntries = evt.executeEvent(initStateLogEntry, obj.simDriver, tStartPropTime, tStartSimTime, isSparseOutput, activeNonSeqEvts);
                    stateLog.appendStateLogEntries(newStateLogEntries);

                    %Clean Up Event
                    initStateLogEntry = newStateLogEntries(end).deepCopy(); %this state log entry must be copied or the answers will change
                    actionStateLogEntries = evt.cleanupEvent(initStateLogEntry);
                    
                    %Add state log entries to state log
                    if(not(isempty(actionStateLogEntries)))
                        stateLog.appendStateLogEntries(actionStateLogEntries);
                        initStateLogEntry = actionStateLogEntries(end).deepCopy(); %this state log entry must be copied or the answers will change;
                    end
                    
                    stateLog.appendNonSeqEvtsState(obj.nonSeqEvts.copy(), evt);
                end
                
                tPropTime = toc(tStartPropTime);
            else
                stateLog.appendStateLogEntries(initStateLogEntry.deepCopy());
            end
            
            obj.lastRunExecTime = tPropTime;
            
            if(evalConstraints)
                x=obj.lvdData.optimizer.vars.getTotalScaledXVector();
                [c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds] = obj.lvdData.optimizer.constraints.evalConstraints(x, false, evtToStartScriptExecAt, allowInterrupt);

                if(isempty(obj.lvdData.optimizer.constraints.lastRunValues))
                    obj.lvdData.optimizer.constraints.lastRunValues = ConstraintValues();
                end

                obj.lvdData.optimizer.constraints.lastRunValues.updateValues(c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds);
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