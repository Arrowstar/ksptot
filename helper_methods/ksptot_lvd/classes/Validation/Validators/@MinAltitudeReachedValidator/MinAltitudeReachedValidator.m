classdef MinAltitudeReachedValidator < AbstractLaunchVehicleDataValidator
    %MaxSimTimeReachedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = MinAltitudeReachedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            minAltitude = obj.lvdData.settings.minAltitude;

            entries = obj.lvdData.stateLog.getAllEntries();
            altitudes = [entries.altitude];
            bool = altitudes <= minAltitude;
            
            if(any(bool))
                events = unique([entries(bool).event]);
                for(i=1:length(events))
                    eventNums(i) = events(i).getEventNum(); %#ok<AGROW>
                end
                eventsStr = makeEventsStr(unique(eventNums));
                
                str = sprintf('Minimum altitude of %.3f km reached or exceeded.  Propagation terminated early. (Events: %s)', minAltitude, eventsStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end