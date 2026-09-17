classdef TankCapacityValidator < AbstractLaunchVehicleDataValidator
    %TankCapacityValidator Warns when a tank is loaded beyond its capacity.

    properties
        lvdData LvdData
    end

    methods
        function obj = TankCapacityValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            lv = obj.lvdData.launchVehicle;
            if(isempty(lv))
                return;
            end

            for(i=1:length(lv.stages)) %#ok<*NO4LP>
                stage = lv.stages(i);

                for(j=1:length(stage.tanks))
                    tank = stage.tanks(j);

                    if(tank.initialMass > tank.getCapacity())
                        str = sprintf('Tank "%s" on stage "%s" has an initial propellant mass (%.3f mT) greater than its capacity (%.3f mT).', ...
                                      tank.name, stage.name, tank.initialMass, tank.getCapacity());
                        warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW>
                    end
                end
            end
        end
    end
end
