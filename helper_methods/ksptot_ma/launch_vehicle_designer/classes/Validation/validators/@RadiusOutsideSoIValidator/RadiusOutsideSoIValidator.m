classdef RadiusOutsideSoIValidator < AbstractLaunchVehicleDataValidator
    %RadiusOutsideSoIValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = RadiusOutsideSoIValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);
                
                stateLogEntries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);

                for(j=1:length(stateLogEntries))
                    stateLogEntry = stateLogEntries(j);
                    scRadius = norm(stateLogEntry.position);
                    bodyInfo = stateLogEntry.centralBody;
                    rSoI = getSOIRadius(bodyInfo, bodyInfo.getParBodyInfo(bodyInfo.celBodyData));
                    
                    if(scRadius > rSoI + 0.1)
                        warnEvtNums(end+1) =  evt.getEventNum();
                    end
                end
            end
                        
            if(not(isempty(warnEvtNums)))
                eventStr = makeEventsStr(unique(warnEvtNums));
                str = sprintf('Vehicle is outside of SoI radius of current central body. (Events: %s)', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
            
        end
    end
end