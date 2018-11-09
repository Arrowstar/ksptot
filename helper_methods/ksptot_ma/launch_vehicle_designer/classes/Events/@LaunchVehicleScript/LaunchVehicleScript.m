classdef LaunchVehicleScript < matlab.mixin.SetGet
    %LaunchVehicleScript Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evts(1,:) LaunchVehicleEvent
        
        lvdData LvdData
    end
    
    properties%(Access=private)
        simDriver LaunchVehicleSimulationDriver
    end
    
    methods
        function obj = LaunchVehicleScript(lvdData, simDriver)
            obj.lvdData = lvdData;
            obj.simDriver = simDriver;
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
            evt = LaunchVehicleEvent.empty(1,0);
            
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
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
            
            for(i=1:length(obj.evts))
                tf = tf || obj.evts(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function stateLog = executeScript(obj)
%             profile on;
            initStateLogEntry = obj.lvdData.initialState;
            stateLog = obj.lvdData.stateLog;
            
            stateLog.clearStateLog();
            
            if(~isempty(obj.evts))
                
                tStartSimTime = initStateLogEntry.time;
                tStartPropTime = tic();
                for(i=1:length(obj.evts)) %#ok<*NO4LP>
                    obj.evts(i).initEvent(initStateLogEntry);
                    initStateLogEntry.event = obj.evts(i);

                    newStateLogEntries = obj.evts(i).executeEvent(initStateLogEntry, obj.simDriver, tStartPropTime, tStartSimTime);
                    stateLog.appendStateLogEntries(newStateLogEntries);

                    initStateLogEntry = newStateLogEntries(end).deepCopy();
                    actionStateLogEntries = obj.evts(i).cleanupEvent(initStateLogEntry);
                    
                    if(not(isempty(actionStateLogEntries)))
                        stateLog.appendStateLogEntries(actionStateLogEntries);
                        initStateLogEntry = actionStateLogEntries(end).deepCopy();
                    end
                end
            else
                stateLog.appendStateLogEntries(initStateLogEntry.deepCopy());
            end
            
            x=obj.lvdData.optimizer.vars.getTotalScaledXVector();
            [c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds] = obj.lvdData.optimizer.constraints.evalConstraints(x);
            
            if(isempty(obj.lvdData.optimizer.constraints.lastRunValues))
                obj.lvdData.optimizer.constraints.lastRunValues = ConstraintValues();
            end
            
            obj.lvdData.optimizer.constraints.lastRunValues.updateValues(c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds);
            
%             profile viewer;
        end
    end
end