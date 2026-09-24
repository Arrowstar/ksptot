classdef TankWithoutConsumerValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = TankWithoutConsumerValidator(lvdData)
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
                for(j=1:numel(stage.tanks))
                    tank = stage.tanks(j);
                    engineConnections = lv.getEngineToTankConnsForTank(tank);
                    tankConnections = lv.getTankToTankConnsForSrcTank(tank);

                    if(isempty(engineConnections) && isempty(tankConnections))
                        str = sprintf('Tank "%s" on stage "%s" is not connected to an engine or tank-to-tank source.', tank.name, stage.name);
                        warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                    end
                end
            end
        end
    end
end
