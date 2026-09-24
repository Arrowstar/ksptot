classdef ElectricEngineWithoutChargeValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = ElectricEngineWithoutChargeValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            warnEventNums = [];
            warnEngineNames = {};
            evts = obj.lvdData.script.evts;
            for(i=1:numel(evts))
                evt = evts(i);
                if(isempty(evt.propagatorObj) || ~evt.propagatorObj.canProduceThrust())
                    continue;
                end

                entries = lvd_getValidationPropagationEntries(obj.lvdData, evt);
                for(j=1:numel(entries))
                    entry = entries(j);
                    throttle = entry.throttle;
                    if(~isfinite(throttle))
                        continue;
                    end

                    storageStates = entry.getAllActivePwrStorageStates();
                    storageSoCs = zeros(1, numel(storageStates));
                    for(k=1:numel(storageStates))
                        storageSoCs(k) = storageStates(k).getStateOfCharge();
                    end

                    stageStates = entry.stageStates;
                    for(k=1:numel(stageStates))
                        stageState = stageStates(k);
                        if(~stageState.active)
                            continue;
                        end

                        for(m=1:numel(stageState.engineStates))
                            engineState = stageState.engineStates(m);
                            if(~engineState.active)
                                continue;
                            end

                            engine = engineState.engine;
                            if(~engine.reqsElecCharge)
                                continue;
                            end

                            if(engine.adjustThrottle(throttle, []) > 0 && (isempty(storageSoCs) || sum(storageSoCs) <= 0))
                                warnEventNums(end+1) = evt.getEventNum();
                                warnEngineNames{end+1} = engine.name;
                            end
                        end
                    end
                end
            end

            if(~isempty(warnEventNums))
                eventStr = makeEventsStr(unique(warnEventNums));
                engineStr = strjoin(unique(warnEngineNames, 'stable'), ', ');
                str = sprintf('Electric engines are commanded on with no active positive state of charge. (Events: %s; Engines: %s)', eventStr, engineStr);
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end
