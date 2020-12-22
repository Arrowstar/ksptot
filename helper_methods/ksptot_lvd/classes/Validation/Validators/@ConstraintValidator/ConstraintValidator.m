classdef ConstraintValidator < AbstractLaunchVehicleDataValidator
    %NoOptimizationVariablesValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = ConstraintValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            [c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds] = obj.lvdData.optimizer.constraints.lastRunValues.getValues();
            
            eventNums = [];
            detailStrs = {};
            for(i=1:length(values)) %#ok<NO4LP>
                if(values(i) <= lb(i) || values(i) >= ub(i))
                    eventNums(end+1) = eventNum(i); %#ok<AGROW>
                    detailStrs{end+1} = sprintf('%s Constraint (Event %u) - Value = %f, Bounds: [%f, %f]',type{i},eventNum(i), values(i), lb(i), ub(i)); %#ok<AGROW>
                end
            end
            
            if(not(isempty(eventNums)))
                eventStr = makeEventsStr(unique(eventNums));

                str = sprintf('Optimization constraints are active or violated on some events (Events: %s)\n%s', eventStr,strjoin(detailStrs,'\n'));
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end