classdef AtmoWithNoDragModelValidator < AbstractLaunchVehicleDataValidator
    %AtmoWithNoDragModelValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = AtmoWithNoDragModelValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);
                
                if(not(any(evt.forceModels == ForceModelsEnum.Drag)))                    
                    stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                    
                    for(j=1:length(stateLogEntries))
                        stateLogEntry = stateLogEntries(j);
                        bodyInfo = stateLogEntry.centralBody;
                        altitude = norm(stateLogEntry.position) - bodyInfo.radius;
                        
                        if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                            warnEvtNums(end+1) = evt.getEventNum(); %#ok<AGROW>
                            break;
                        end
                    end
                end
            end
            
            if(not(isempty(warnEvtNums)))
                eventStr = makeEventsStr(unique(warnEvtNums));
                str = sprintf('Drag model is disabled on events that exist in an atmosphere. (Events: %s)\n%s', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end