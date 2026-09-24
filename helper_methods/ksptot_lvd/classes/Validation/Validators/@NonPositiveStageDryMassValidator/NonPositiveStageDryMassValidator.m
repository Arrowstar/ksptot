classdef NonPositiveStageDryMassValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = NonPositiveStageDryMassValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            lv = obj.lvdData.launchVehicle;
            if(isempty(lv) || isempty(lv.stages))
                return;
            end

            for(i=1:numel(lv.stages))
                stage = lv.stages(i);
                dryMass = stage.getStageDryMass();
                if(~isfinite(dryMass) || dryMass <= 0)
                    str = sprintf('Stage "%s" has invalid dry mass (%.3f mT).', stage.name, dryMass);
                    warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                end
            end
        end
    end
end
