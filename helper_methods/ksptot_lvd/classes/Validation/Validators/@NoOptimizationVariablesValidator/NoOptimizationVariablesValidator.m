classdef NoOptimizationVariablesValidator < AbstractLaunchVehicleDataValidator
    %NoOptimizationVariablesValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = NoOptimizationVariablesValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            varSet = obj.lvdData.optimizer.vars;
            numVars = length(varSet.getTotalScaledXVector());
            if(numVars == 0)
                str = sprintf('No optimization variables enabled on script.');
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end