classdef MinAltitudeReachedValidator < AbstractLaunchVehicleDataValidator
    %MaxSimTimeReachedValidator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
    end
    
    methods
        function obj = MinAltitudeReachedValidator(lvdData)
            obj.lvdData = lvdData;
        end
        
        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);
            
            finalEntry = obj.lvdData.stateLog.getFinalStateLogEntry();
            minAltitude = obj.lvdData.settings.minAltitude;
            
            if(finalEntry.altitude <= minAltitude)
                str = sprintf('Minimum altitude of %.3f km reached or exceeded.  Propagation terminated.', minAltitude);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end