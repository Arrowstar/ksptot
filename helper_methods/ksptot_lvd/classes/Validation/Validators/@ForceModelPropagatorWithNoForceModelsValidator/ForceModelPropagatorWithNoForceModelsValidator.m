classdef ForceModelPropagatorWithNoForceModelsValidator < AbstractLaunchVehicleDataValidator
    %ForceModelPropagatorWithNoForceModelsValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = ForceModelPropagatorWithNoForceModelsValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);
                
                if(evt.propagatorObj == evt.forceModelPropagator)
                    forceModels = evt.forceModelPropagator.forceModels;
                    if(length(forceModels) == 1 && forceModels == ForceModelsEnum.Gravity)
                        warnEvtNums(end+1) =  evt.getEventNum(); %#ok<AGROW>
                    end
                end
            end
                        
            if(not(isempty(warnEvtNums)))
                eventStr = makeEventsStr(unique(warnEvtNums));
                str = sprintf('Some events use Force Model propagators but have no force models active.  Consider switching to Two Body propagators on these events instead. (Events: %s)', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
            
        end
    end
end