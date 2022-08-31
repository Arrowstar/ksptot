classdef MaxSimTimeReachedValidator < AbstractLaunchVehicleDataValidator
    %MaxSimTimeReachedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = MaxSimTimeReachedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            maxSimTime = obj.lvdData.settings.simMaxDur;
            [tStart, tEnd] = obj.lvdData.stateLog.getStartAndEndTimes();
            
            if(tEnd - tStart >= maxSimTime)
                str = sprintf('Maximum simulation time of %.3f sec reached or exceeded.  Propagation terminated.  Consider increasing the maximum simulation time.', maxSimTime);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end