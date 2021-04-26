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

            [c, ceq, values, lb, ub, type, eventNum, cEventInds, ceqEventInds, consts, cCInds, cCeqInds, valueStateComps] = obj.lvdData.optimizer.constraints.lastRunValues.getValues();
            
            eventNums = [];
            detailStrs = {};
            for(i=1:length(values)) %#ok<NO4LP>
                const = consts(i);
                [unit, ~, ~, ~, ~, ~] = const.getConstraintStaticDetails();
                if(const.evalType == ConstraintEvalTypeEnum.FixedBounds)
                    if(values(i) <= lb(i) || values(i) >= ub(i))
                        eventNums(end+1) = eventNum(i); %#ok<AGROW>
                        detailStrs{end+1} = sprintf('%s Constraint (Event %u) - Value = %f %s, Bounds: [%f %s, %f %s]',type{i},eventNum(i), values(i), unit, lb(i), unit, ub(i), unit); %#ok<AGROW>
                    end
                    
                elseif(const.evalType == ConstraintEvalTypeEnum.StateComparison)
                    subC = c(cCInds == i);
                    subCeq = ceq(cCeqInds == i);
                    if(any(subC > 0) || any(subCeq ~= 0))
                        eventNums(end+1) = eventNum(i); %#ok<AGROW>
                        
                        symbol = const.stateCompType.symbol;
                        compEvent = const.stateCompEvent;
                        compEventNum = compEvent.getEventNum();
                        
                        valueStateComp = valueStateComps(i);
                        if(not(isnan(valueStateComps)))
                            valueStateCompStr = sprintf(', Value = %f %s', valueStateComp, unit);
                        else
                            valueStateCompStr = '';
                        end
                        
                        detailStrs{end+1} = sprintf('%s Constraint (Event %u) - Value = %f %s, (%s Event %u %s%s)',type{i},eventNum(i), values(i), unit, symbol, compEventNum, type{i}, valueStateCompStr); %#ok<AGROW>
                    end
                    
                else
                    error('Unknown constraint evaluation type.');
                    
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