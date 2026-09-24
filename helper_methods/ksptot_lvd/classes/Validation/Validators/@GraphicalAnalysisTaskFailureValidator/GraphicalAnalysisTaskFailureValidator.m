classdef GraphicalAnalysisTaskFailureValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = GraphicalAnalysisTaskFailureValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            if(isempty(obj.lvdData.graphAnalysis) || obj.lvdData.graphAnalysis.getNumTasks() == 0)
                return;
            end

            entries = obj.lvdData.stateLog.getAllEntries();
            if(isempty(entries))
                return;
            end

            try
                [~,~,eventNums,times,taskLabels,~,failureMask,failureMessages] = ...
                    obj.lvdData.graphAnalysis.executeTasks([], min([entries.time]), max([entries.time]), [], []);
            catch ME
                str = sprintf('Graphical analysis tasks could not be evaluated: %s', ME.message);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                return;
            end

            if(isempty(failureMask) || ~any(failureMask(:)))
                return;
            end

            details = {};
            for(j=1:size(failureMask,2))
                failureInds = find(failureMask(:,j));
                if(isempty(failureInds))
                    continue;
                end

                eventStr = 'unknown';
                validEventNums = eventNums(failureInds);
                validEventNums = validEventNums(isfinite(validEventNums));
                if(~isempty(validEventNums))
                    eventStr = makeEventsStr(unique(validEventNums));
                end

                message = failureMessages{failureInds(1),j};
                if(isempty(message))
                    message = 'unknown evaluation error';
                end
                firstTime = times(failureInds(1));
                taskLabel = char(taskLabels(j));
                details{end+1} = sprintf('%s (Events: %s; first time %.3f): %s', taskLabel, eventStr, firstTime, message);
            end

            if(~isempty(details))
                str = sprintf('Graphical analysis task evaluation failed:\n%s', strjoin(unique(details, 'stable'), newline));
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end
