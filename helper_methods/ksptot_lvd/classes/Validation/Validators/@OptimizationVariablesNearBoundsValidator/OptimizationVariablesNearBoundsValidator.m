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
            varSet.sortVarsByEvtNum();
            [x, ~, varNameStrs, xUnscaled] = varSet.getTotalScaledXVector();
            [lb, ub, LwrBndsUnscaled, UprBndsUnscaled] = varSet.getTotalScaledBndsVector();
            varSet.get
            
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

            varNames = string.empty(1,0);
            for(i=1:length(warnInd))
                varNames(i) = sprintf("%s (%0.3f <= %0.3f <= %0.3f)", varNameStrs{warnInd(i)}, LwrBndsUnscaled(warnInd(i)), xUnscaled(warnInd(i)), UprBndsUnscaled(warnInd(i))); %#ok<AGROW>
            end
            
            varNamesSubStr = strjoin(varNames,'\n');
            
            str = sprintf('Variables are near optimization bounds on some events:\n%s', varNamesSubStr);
            warnings(end+1) = LaunchVehicleDataValidationWarning(str);
        end
    end
end