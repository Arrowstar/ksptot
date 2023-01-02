classdef ThrottleWithNoThrustModelValidator < AbstractLaunchVehicleDataValidator
    %ThrottleWithNoThrustModelValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = ThrottleWithNoThrustModelValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);
                evtPropagator = evt.propagatorObj;
                propagatorEnum = evtPropagator.propagatorEnum;
                
                if(propagatorEnum == PropagatorEnum.ForceModel)
                    if(not(any(evtPropagator.forceModels == ForceModelsEnum.Thrust)))                    
                        stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                        times = [stateLogEntries.time];
                        finalTime = max(times);

                        for(j=1:length(stateLogEntries))
                            stateLogEntry = stateLogEntries(j);
                            if(stateLogEntry.throttle > 0 && stateLogEntry.time < finalTime) %less than sign so we don't include the final time, which may have actions to enable the throttle and would be erronously picked up here
                                warnEvtNums(end+1) = evt.getEventNum(); %#ok<AGROW>
                                break;
                            end
                        end
                    end
                elseif(propagatorEnum == PropagatorEnum.TwoBody)
                    stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                    times = [stateLogEntries.time];
                    finalTime = max(times);
                    
                    for(j=1:length(stateLogEntries))
                        stateLogEntry = stateLogEntries(j);
                        if(stateLogEntry.throttle > 0 && stateLogEntry.time < finalTime) %less than sign so we don't include the final time, which may have actions to enable the throttle and would be erronously picked up here
                            warnEvtNums(end+1) = evt.getEventNum(); %#ok<AGROW>
                            break;
                        end
                    end            
                end
            end
            
            if(not(isempty(warnEvtNums)))
                eventStr = makeEventsStr(unique(warnEvtNums));
                str = sprintf('Throttle is greater than 0%% on Events with Thrust model disabled. (Events: %s)\n%s', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end