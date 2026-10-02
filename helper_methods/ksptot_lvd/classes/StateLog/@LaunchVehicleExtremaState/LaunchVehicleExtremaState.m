classdef LaunchVehicleExtremaState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleExtremaState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        extrema LaunchVehicleExtrema
        value(1,1) double = NaN;
        active(1,1) LaunchVehicleExtremaRecordingEnum = LaunchVehicleExtremaRecordingEnum.Recording;
    end
    
    properties(Constant)
        gaTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());

        CumulativeDeltaVTask = 'Cumulative Delta-V Expended';
    end
    
    methods
        function obj = LaunchVehicleExtremaState(extrema)
            obj.extrema = extrema;
        end
        
        function val = getValue(obj)
            val = obj.value;
        end
                
        function [newValue] = updateExtremaStateWithStateLogEntry(obj, stateLogEntry, prevValue, maSubLog)
            if(nargin < 4)
                maSubLog = [];
            end
            if(strcmp(obj.extrema.quantStr, LaunchVehicleExtremaState.CumulativeDeltaVTask))
                %A path integral: this lone integrator entry has no history
                %to integrate.  Carry the value through unchanged and let
                %updateCumulativeDeltaVExtrema compute it from the log.
                obj.value = prevValue;
                newValue = prevValue;
                return;
            end

            if(obj.active == LaunchVehicleExtremaRecordingEnum.Recording) %if it's not recording, then we can just return the exState as it is b/c it won't change
                maTaskList = LaunchVehicleExtremaState.gaTaskList;

                if(isempty(maSubLog))
                    maSubLog = stateLogEntry.getMAFormattedStateLogMatrix(true);
                end
                taskStr = obj.extrema.quantStr;
                prevDistTraveled = 0;
                refBodyId = obj.extrema.frame.getOriginBody().id;
                propNames = obj.extrema.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();

                celBodyData = obj.extrema.lvdData.celBodyData;

                if(ismember(taskStr,maTaskList))
                    [depVarValue, depVarUnit, ~] = ma_getDepVarValueUnit(1, maSubLog, taskStr, prevDistTraveled, refBodyId, [], [], propNames, [], celBodyData, false);
                else
                    [depVarValue, depVarUnit] = lvd_getDepVarValueUnit(1, stateLogEntry, taskStr, refBodyId, celBodyData, false, obj.extrema.frame);
                end
                
                newValue = obj.updateExtremaStateWithValue(depVarValue, prevValue, depVarUnit);
            else
                newValue = obj.value;
            end
        end

        function newValue = updateExtremaStateWithValue(obj, depVarValue, prevValue, depVarUnit)
            %updateExtremaStateWithValue Folds one sample of the quantity
            %into the running extremum carried in as prevValue.
            if(obj.active ~= LaunchVehicleExtremaRecordingEnum.Recording)
                newValue = obj.value;
                return;
            end

            if(isempty(obj.value))
                obj.value = depVarValue;
            else
                if(obj.extrema.type == LaunchVehicleExtremaTypeEnum.Maximum)
                    if(isnan(prevValue) || prevValue < depVarValue)
                        obj.value = depVarValue;
                    else
                        obj.value = prevValue;
                    end
                elseif(obj.extrema.type == LaunchVehicleExtremaTypeEnum.Minimum)
                    if(isnan(prevValue) || prevValue > depVarValue)
                        obj.value = depVarValue;
                    else
                        obj.value = prevValue;
                    end
                end
            end

            newValue = obj.value;

            if(isempty(obj.extrema.unitStr))
                obj.extrema.unitStr = depVarUnit;
            end
        end
    end

    methods(Static)
        function updateCumulativeDeltaVExtrema(stateLog, newEntries)
            %updateCumulativeDeltaVExtrema Computes every extremum on
            %Cumulative Delta-V Expended over newEntries, which must be the
            %tail of stateLog (just appended by LaunchVehicleScript).
            %
            %The quantity integrates over the whole log, and the entries
            %the integrator produces do not reach the log until the event
            %(including any restarted integration segments) has finished,
            %so it cannot be sampled entry by entry the way other extrema
            %are.  Instead the event's entries are folded in here, against
            %the same full-log integral the graphical analysis task uses,
            %starting from the value carried in on the event's first
            %entry.
            %
            %ponytail: mid-event resets (a non-sequential event resetting
            %the extremum) are not honoured; the fold runs straight across
            %the event.  Track per-entry reset state if that ever matters.
            if(isempty(newEntries) || isempty(newEntries(1).extremaStates))
                return;
            end

            exStates = newEntries(1).extremaStates;
            exInds = [];
            for(j=1:numel(exStates)) %#ok<*NO4LP>
                if(strcmp(exStates(j).extrema.quantStr, LaunchVehicleExtremaState.CumulativeDeltaVTask))
                    exInds(end+1) = j; %#ok<AGROW>
                end
            end

            if(isempty(exInds))
                return;
            end

            entries = stateLog.getAllEntries();
            numEntries = numel(entries);
            if(numEntries < numel(newEntries) || entries(end) ~= newEntries(end))
                return; %not the log's tail: nothing to anchor the integral to
            end

            [~, depVarUnit, cumVals] = lvd_CumulativeDeltaVTasks(numEntries, entries);
            offset = numEntries - numel(newEntries);

            for(j=exInds)
                value = newEntries(1).extremaStates(j).value;
                for(k=1:numel(newEntries))
                    value = newEntries(k).extremaStates(j).updateExtremaStateWithValue(cumVals(offset + k), value, depVarUnit);
                end
            end
        end
    end
    
    methods(Access=protected)
        function copyObj = copyElement(obj)
            copyObj = copyElement@matlab.mixin.Copyable(obj);
            
            for(i=1:length(obj))
                copyObj(i).extrema = obj(i).extrema;
            end
        end
    end
end