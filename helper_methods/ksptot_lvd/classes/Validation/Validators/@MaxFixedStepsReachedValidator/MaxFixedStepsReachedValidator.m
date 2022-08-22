classdef MaxFixedStepsReachedValidator < AbstractLaunchVehicleDataValidator
    %MaxSimTimeReachedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = MaxFixedStepsReachedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts)) %#ok<*NO4LP> 
                evt = evts(i);

                integratorOptions = evt.integratorObj.getOptions();
                integrationStep = integratorOptions.getIntegratorStepSize();
                integrationMaxFixedSteps = integratorOptions.getIntegratorMaxNumFixedSteps();

                if(integrationStep > 0) %fixed step requested
                    stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                    numEntries = numel(stateLogEntries);

                    if(numEntries >= integrationMaxFixedSteps)
                        warnEvtNums(end+1) = evt.getEventNum(); %#ok<AGROW> 
                    end
                end

                if(not(isempty(warnEvtNums)))
                    eventStr = makeEventsStr(unique(warnEvtNums));
                    str = sprintf('Maximum number of fixed step sizes reached on some events. (Events: %s)\n%s', eventStr);
                    warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW> 
                end
            end
        end
    end
end