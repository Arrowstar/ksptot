classdef SomeEventsNotPlottedValidator < AbstractLaunchVehicleDataValidator
    %SomeEventsNotPlottedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = SomeEventsNotPlottedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            evts = obj.lvdData.script.evts;

            selViewProfile = obj.lvdData.viewSettings.selViewProfile;
            plotAllEvents = selViewProfile.plotAllEvents;
            eventsToPlot = selViewProfile.eventsToPlot;

            if(plotAllEvents == false && not(all(ismember(evts, eventsToPlot))) && not(isempty(eventsToPlot))) %numel(eventsToPlot) < numel(evts)
                warnEvtNums = getEventNum(evts(not(ismember(evts, eventsToPlot))));

                if(not(isempty(warnEvtNums)))
                    eventStr = makeEventsStr(unique(warnEvtNums));
                    str = sprintf('The following events are not being plotted. (Events: %s)\n%s', eventStr);
                    warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                end
            end
        end
    end
end