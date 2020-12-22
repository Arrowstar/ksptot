classdef OptimizationVariablesNearBoundsValidator < AbstractLaunchVehicleDataValidator
    %NoOptimizationVariablesValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = OptimizationVariablesNearBoundsValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            varSet = obj.lvdData.optimizer.vars;
            [x, ~, varNameStrs, ~] = varSet.getTotalScaledXVector();
            [lb, ub] = varSet.getTotalScaledBndsVector();
            
            warnInd = [];
            for(i=1:length(x)) %#ok<*NO4LP>
                normX = (x(i) - lb(i)) / (ub(i) - lb(i));
                
                if(normX >= 0.99 || normX <= 0.01 || (ub(i) == lb(i) && x(i) == lb(i)))
                    warnInd(end+1) = i; %#ok<AGROW>
                end
            end
            
            if(isempty(warnInd))
                return;
            end

            for(i=1:length(warnInd))
                varNames{i} = varNameStrs{warnInd(i)}; %#ok<AGROW>
            end
            
            varNamesSubStr = strjoin(varNames,'\n');
            
            str = sprintf('Variables are near optimization bounds on some events:\n%s', varNamesSubStr);
            warnings(end+1) = LaunchVehicleDataValidationWarning(str);
        end
    end
end