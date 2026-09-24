classdef EngineWithoutTankValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = EngineWithoutTankValidator(lvdData)
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
                for(j=1:numel(stage.engines))
                    engine = stage.engines(j);
                    connections = lv.getEngineToTankConnsForEngine(engine);
                    hasTank = false;
                    for(k=1:numel(connections))
                        if(~isempty(connections(k).tank))
                            hasTank = true;
                            break;
                        end
                    end

                    if(~hasTank)
                        str = sprintf('Engine "%s" on stage "%s" has no connected tank.', engine.name, stage.name);
                        warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                    end
                end
            end
        end
    end
end
