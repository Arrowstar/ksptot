classdef LaunchVehicleStateLog < matlab.mixin.SetGet
    %LaunchVehicleStateLog Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        entries LaunchVehicleStateLogEntry
        
        nonSeqEvtsStates NonSeqEvtsState
    end
    
    methods
        function obj = LaunchVehicleStateLog()
            
        end
        
        function appendStateLogEntries(obj, newStateLogEntries)
            obj.entries = horzcat(obj.entries, newStateLogEntries);
        end
        
        function clearStateLog(obj)
            obj.entries = LaunchVehicleStateLogEntry.empty(1,0);
            obj.nonSeqEvtsStates = NonSeqEvtsState.empty(1,0);
        end
        
        function clearStateLogAtOrAfterEvent(obj, evt)
            evtNumBnd = evt.getEventNum();
            
            indsToClear = NaN(size(obj.entries));
            for(i=1:length(obj.entries))               
                if(obj.entries(i).event.getEventNum() >= evtNumBnd)
                    indsToClear(i) = i;
                end
            end
            
            indsToClear(isnan(indsToClear)) = [];
            obj.entries(indsToClear) = [];
            
            indsToClear = NaN(size(obj.entries));
            for(i=1:length(obj.nonSeqEvtsStates))
                if(obj.nonSeqEvtsStates(i).event.getEventNum() >= evtNumBnd)
                    indsToClear(i) = i;
                end
            end
            
            indsToClear(isnan(indsToClear)) = [];
            obj.nonSeqEvtsStates(indsToClear) = [];
        end
        
        function stateLog = getMAFormattedStateLogMatrix(obj)
            stateLog = zeros(length(obj.entries), 13);
            for(i=1:length(obj.entries)) %#ok<*NO4LP>
                stateLog(i,:) = obj.entries(i).getMAFormattedStateLogMatrix();
            end
        end
        
        function numEntries = getNumberOfEntries(obj)
            numEntries = length(obj.entries);
        end
        
        function allEntries = getAllEntries(obj)
            allEntries = obj.entries;
        end
        
        function stateLogEntry = getFirstStateLogForEvent(obj, event)
            subStateLog = obj.entries([obj.entries.event] == event);
            stateLogEntry = subStateLog(1);
        end
        
        function stateLogEntry = getLastStateLogForEvent(obj, event)
            subStateLog = obj.entries([obj.entries.event] == event);
            stateLogEntry = subStateLog(end);
        end
        
        function subStateLog = getAllStateLogEntriesForEvent(obj, event)
            subStateLog = obj.entries([obj.entries.event] == event);
        end
               
        function subLog = getStateLogEntriesBetweenTimes(obj, t1, t2)
            subLog = obj.entries([obj.entries.time] >= t1 & [obj.entries.time] <= t2);
        end
        
        function stateLogEntry = getFinalStateLogEntry(obj)
            stateLogEntry = obj.entries(end);
        end
        
        function [tStart, tEnd] = getStartAndEndTimes(obj)
            tStart = min([obj.entries.time]);
            tEnd = max([obj.entries.time]);
        end
        
        function appendNonSeqEvtsState(obj, nonSeqEvts, event)
            bool = [obj.nonSeqEvtsStates.event] == event;
            if(any(bool))
                ind = find(bool,1);
                obj.nonSeqEvtsStates(ind).nonSeqEvts = nonSeqEvts;
            else
                obj.nonSeqEvtsStates(end+1) = NonSeqEvtsState(event, nonSeqEvts);
            end
        end
        
        function nonSeqEvtsState = getFinalNonSeqEvtsState(obj)
            events = [obj.nonSeqEvtsStates.event];
            eventNums = arrayfun(@getEventNum, events, 'UniformOutput',false);
            eventNums = cell2mat(eventNums);
            [~,I] = max(eventNums);
            
            nonSeqEvtsState = obj.nonSeqEvtsStates(I);
        end
    end
end