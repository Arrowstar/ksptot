classdef LaunchVehicleStateLog < matlab.mixin.SetGet
    %LaunchVehicleStateLog Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        entries LaunchVehicleStateLogEntry
        nonSeqEvtsStates NonSeqEvtsState

        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleStateLog(lvdData)
            obj.lvdData = lvdData;
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
        
        function stateLog = getMAFormattedStateLogMatrix(obj, needMasses)
            stateLog = zeros(length(obj.entries), 13);
            for(i=1:length(obj.entries)) %#ok<*NO4LP>
                stateLog(i,:) = obj.entries(i).getMAFormattedStateLogMatrix(needMasses);
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
            
            if(not(isempty(subStateLog)))
                stateLogEntry = subStateLog(1);
            else
                stateLogEntry = LaunchVehicleStateLogEntry.empty(1,0);
            end
        end
        
        function stateLogEntry = getLastStateLogForEvent(obj, event)
            subStateLog = obj.entries([obj.entries.event] == event);
            if(not(isempty(subStateLog)))
                stateLogEntry = subStateLog(end);
            else
                stateLogEntry = LaunchVehicleStateLogEntry.empty(1,0);
            end
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

        function stateLogEntries = breakUpStateLogBySoIChunk(obj)
            e = LaunchVehicleStateLogEntry.empty(1,0);

            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);

                subStateLog = obj.getAllStateLogEntriesForEvent(evt);

%                 switch evt.plotMethod
%                     case EventPlottingMethodEnum.PlotContinuous
%                         %nothing here
% 
%                     case EventPlottingMethodEnum.SkipFirstState
%                         subStateLog = subStateLog(2:end);
%                         
%                     case EventPlottingMethodEnum.DoNotPlot
%                         subStateLog = LaunchVehicleStateLogEntry.empty(1,0);
% 
%                     otherwise
%                         error('Unknown plotting method: %s', evt.plotMethod.name);
%                 end

                if(not(isempty(subStateLog)))
                    e = horzcat(e, subStateLog(:)'); %#ok<AGROW> 
                end
            end

            times = [e.time];
            cbs = [e.centralBody];
            cbIds = [cbs.id];
            data = [times(:), cbIds(:)];

            [~,I] = sortrows(data, [1,2]);
            e = e(I);

            centralBodies = [e.centralBody];
            cbIds = [centralBodies.id];
            cbIdDiff = diff(cbIds);
            inds = find(cbIdDiff ~= 0);

            curInd = 1;
            stateLogEntries = {};
            for(i=1:length(inds)+1)
                if(i <= length(inds))
                    ind = inds(i);
                else
                    ind = length(e);
                end

                ee = e(curInd:ind);

                times = [ee.time];

                evts = [ee.event];
                evtNums = [];
                for(j=1:length(evts))
                    evtNums(j) = evts(j).getEventNum(); %#ok<AGROW> 
                end
                data = [times(:), evtNums(:)];
                [~,I] = sortrows(data,[2,1]);
                ee = ee(I);

                evtNumsUnique = unique(evtNums);
                for(j=1:length(evtNumsUnique))
                    evtNum = evtNumsUnique(j);

                    bool = getEventNum([ee.event]) == evtNum;
                    sub_ee = ee(bool);

                    for(k=1:length(sub_ee))
                        stateLogEntries{i,j}(k,:) = sub_ee(k).getMAFormattedStateLogMatrix(false); %#ok<AGROW> 
                    end
                end

                curInd = ind+1;
            end
        end
    end
end