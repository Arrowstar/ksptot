classdef ThirdBodyGravityValidator < AbstractLaunchVehicleDataValidator
    %ThirdBodyGravityValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = ThirdBodyGravityValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            warnEvtNoBodiesNums = [];
            warnEvtHasBodiesNums = [];
            evts = obj.lvdData.script.evts;
            for(i=1:length(evts))
                evt = evts(i);
                if(evt.propagatorObj == evt.forceModelPropagator)
                    forceModels = evt.forceModelPropagator.forceModels;
                    stateLogEntry = obj.lvdData.stateLog.getFirstStateLogForEvent(evt);
                    
                    if(ismember(ForceModelsEnum.Gravity3rdBody, forceModels) && ...
                       isempty(stateLogEntry.thirdBodyGravity.bodies))
                        warnEvtNoBodiesNums(end+1) =  evt.getEventNum(); %#ok<AGROW>
                    end
                    
                    if(not(ismember(ForceModelsEnum.Gravity3rdBody, forceModels)) && ...
                       not(isempty(stateLogEntry.thirdBodyGravity.bodies)))
                        warnEvtHasBodiesNums(end+1) =  evt.getEventNum(); %#ok<AGROW>
                    end
                end
            end
                        
            if(not(isempty(warnEvtNoBodiesNums)))
                eventStr = makeEventsStr(unique(warnEvtNoBodiesNums));
                str = sprintf('Some events have the Third Body Gravity force model active but there are no third body gravity sources active in the event''s initial state. (Events: %s)', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
            
            if(not(isempty(warnEvtHasBodiesNums)))
                eventStr = makeEventsStr(unique(warnEvtHasBodiesNums));
                str = sprintf('Some events have third body gravity sources active in the event''s initial state but the Third Body Gravity force model is inactive. (Events: %s)', eventStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end