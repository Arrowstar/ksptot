classdef EngineMixtureValidator < AbstractLaunchVehicleDataValidator
    %EngineMixtureValidator Warns on inconsistent engine propellant
    %mixtures and engine-to-tank priority/weight plumbing.
    %
    % Rules (all warning-only, never errors):
    %   * a custom mixture must sum to 1 and use positive fractions;
    %   * every mixture fluid should have at least one connected tank of
    %     that type, and every connected tank's fluid should appear in the
    %     mixture (otherwise that tank never flows / that species starves);
    %   * flow weights must be NaN (even) or positive.

    properties
        lvdData LvdData
    end

    methods
        function obj = EngineMixtureValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            lv = obj.lvdData.launchVehicle;
            if(isempty(lv) || isempty(lv.stages))
                return;
            end

            for(i=1:length(lv.stages)) %#ok<*NO4LP>
                stage = lv.stages(i);

                for(j=1:length(stage.engines))
                    engine = stage.engines(j);
                    conns = lv.getEngineToTankConnsForEngine(engine);

                    for(k=1:length(conns))
                        w = conns(k).flowWeight;
                        if(not(isnan(w)) && ~(isscalar(w) && isfinite(w) && w > 0))
                            str = sprintf(['Engine "%s" on stage "%s": connection to tank "%s" has an invalid flow weight (%s). Use blank (even split) or a positive number.'], ...
                                          engine.name, stage.name, conns(k).tank.name, mat2str(w));
                            warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW>
                        end
                    end

                    if(not(engine.hasCustomMixture()))
                        continue;
                    end

                    fracs = engine.mixtureFractions;
                    if(any(~isfinite(fracs)) || any(fracs <= 0) || abs(sum(fracs) - 1) > 1e-9)
                        str = sprintf('Engine "%s" on stage "%s" has a mixture whose fractions must be positive and sum to 1 (got sum %.12g).', ...
                                      engine.name, stage.name, sum(fracs));
                        warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW>
                    end

                    mixTypes = engine.mixtureFluidTypes;
                    connTanks = LaunchVehicleTank.empty(1,0);
                    for(k=1:length(conns))
                        if(not(isempty(conns(k).tank)))
                            connTanks(end+1) = conns(k).tank; %#ok<AGROW>
                        end
                    end

                    for(m=1:length(mixTypes))
                        if(not(any([connTanks.tankType] == mixTypes(m))))
                            str = sprintf('Engine "%s" on stage "%s": mixture fluid "%s" has no connected tank, so the engine can never burn it.', ...
                                          engine.name, stage.name, mixTypes(m).name);
                            warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW>
                        end
                    end

                    for(k=1:length(connTanks))
                        if(not(any(mixTypes == connTanks(k).tankType)))
                            str = sprintf('Engine "%s" on stage "%s": connected tank "%s" holds "%s", which is not in the mixture and will never flow.', ...
                                          engine.name, stage.name, connTanks(k).name, connTanks(k).tankType.name);
                            warnings(end+1) = LaunchVehicleDataValidationWarning(str); %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
