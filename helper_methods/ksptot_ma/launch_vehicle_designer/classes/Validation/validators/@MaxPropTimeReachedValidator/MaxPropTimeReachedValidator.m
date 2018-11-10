classdef MaxPropTimeReachedValidator < AbstractLaunchVehicleDataValidator
    %MaxPropTimeReachedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = MaxPropTimeReachedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            maxPropTime = obj.lvdData.settings.maxScriptPropTime;
            lastRunExecTime = obj.lvdData.script.lastRunExecTime;
            
            if(lastRunExecTime >= maxPropTime)
                str = sprintf('Maximum propagation time of %.3f sec reached or exceeded.  Propagation terminated.', maxPropTime);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end