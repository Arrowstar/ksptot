classdef EngineActiveOnInactiveStageValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = EngineActiveOnInactiveStageValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            engines = LaunchVehicleEngine.empty(1,0);
            previousEngineActive = false(1,0);
            details = {};

            initialStageStates = obj.lvdData.initStateModel.stageStates;
            for(i=1:numel(initialStageStates))
                stageState = initialStageStates(i);
                for(j=1:numel(stageState.engineStates))
                    engineState = stageState.engineStates(j);
                    engine = engineState.engine;
                    engineInd = find(engines == engine, 1, 'first');
                    if(isempty(engineInd))
                        engines(end+1) = engine;
                        previousEngineActive(end+1) = engineState.active;
                    else
                        previousEngineActive(engineInd) = engineState.active;
                    end

                    if(~stageState.active && engineState.active)
                        details{end+1} = sprintf('Initial state: engine "%s" on stage "%s" is active while the stage is inactive.', engine.name, stageState.stage.name);
                    end
                end
            end

            evts = obj.lvdData.script.evts;
            for(i=1:numel(evts))
                evt = evts(i);
                entries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                for(j=1:numel(entries))
                    entry = entries(j);
                    for(k=1:numel(entry.stageStates))
                        stageState = entry.stageStates(k);
                        for(m=1:numel(stageState.engineStates))
                            engineState = stageState.engineStates(m);
                            engine = engineState.engine;
                            engineInd = find(engines == engine, 1, 'first');
                            if(isempty(engineInd))
                                engines(end+1) = engine;
                                previousEngineActive(end+1) = false;
                                engineInd = numel(engines);
                                wasActive = false;
                            else
                                wasActive = previousEngineActive(engineInd);
                            end

                            if(~stageState.active && engineState.active && ~wasActive)
                                details{end+1} = sprintf('Event %u: engine "%s" on stage "%s" is activated while the stage is inactive.', evt.getEventNum(), engine.name, stageState.stage.name);
                            end
                            previousEngineActive(engineInd) = engineState.active;
                        end
                    end
                end
            end

            if(~isempty(details))
                str = sprintf('Active engine state is inconsistent with stage state:\n%s', strjoin(unique(details, 'stable'), newline));
                warnings(end+1) = LaunchVehicleDataValidationWarning(str);
            end
        end
    end
end
