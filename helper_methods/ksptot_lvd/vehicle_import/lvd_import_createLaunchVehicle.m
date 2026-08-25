function newLv = lvd_import_createLaunchVehicle(lvdData, spec)
%lvd_import_createLaunchVehicle Builds a LaunchVehicle object from a craft
%import specification produced by lvd_import_analyzeCraft.
%
%   newLv = lvd_import_createLaunchVehicle(lvdData, spec)
%
%   The returned LAUNCHVEHICLE is fully populated (stages ordered first to
%   burn, engines with thrust/Isp pressure curves, tanks with initial
%   propellant masses, engine-to-tank connections, and tank-to-tank
%   crossfeed connections) but is NOT installed into lvdData; callers
%   assign it (typically via lvd_import_applyToLvdData) so they can veto
%   or preview first.
%
%   Fluid groups named in the spec that do not exist in the vehicle's
%   tank type set (e.g., 'Solid Fuel') are added automatically.

    newLv = LaunchVehicle(lvdData);

    ensureFluidTypes(newLv, spec);

    allTanksByInstanceID = containers.Map('KeyType', 'char', 'ValueType', 'any');
    allEnginesByInstanceID = containers.Map('KeyType', 'char', 'ValueType', 'any');

    for(s = 1:numel(spec.stages))
        specStage = spec.stages(s);

        stage = LaunchVehicleStage(newLv);
        stage.name = specStage.name;
        stage.dryMass = specStage.dryMass_mT;

        % Tanks first so engine connections can resolve them.
        stageTanks = LaunchVehicleTank.empty(1, 0);
        for(t = 1:numel(specStage.tanks))
            specTank = specStage.tanks(t);

            tank = LaunchVehicleTank(stage);
            tank.name = specTank.name;
            tank.initialMass = specTank.propMass_mT;
            tank.tankType = findFluidType(newLv, specTank.fluidTypeName);

            stage.addTank(tank);
            stageTanks(end+1) = tank; %#ok<AGROW>
            allTanksByInstanceID(specTank.instanceID) = tank;
        end

        stageEngines = LaunchVehicleEngine.empty(1, 0);
        for(e = 1:numel(specStage.engines))
            specEngine = specStage.engines(e);

            engine = LaunchVehicleEngine(stage);
            engine.name = specEngine.name;
            engine.minThrottle = specEngine.minThrottle;
            engine.maxThrottle = specEngine.maxThrottle;

            vacThrust = specEngine.vacThrust_kN;
            ispVac = max(specEngine.ispVac_s, 1e-6);
            ispSL = max(specEngine.ispSL_s, 1e-6);

            % Constant mass flow assumption: SL thrust scales with Isp.
            slThrust = vacThrust * ispSL / ispVac;

            engine.thrustPressCurve = ThrustPressureCurve.getCurveFromPoints( ...
                [LaunchVehicleEngine.vacPress, LaunchVehicleEngine.seaLvlPress], ...
                [vacThrust, slThrust]);
            engine.ispPressCurve = IspPressureCurve.getCurveFromPoints( ...
                [LaunchVehicleEngine.vacPress, LaunchVehicleEngine.seaLvlPress], ...
                [ispVac, ispSL]);

            stage.addEngine(engine);
            stageEngines(end+1) = engine; %#ok<AGROW>
            allEnginesByInstanceID(specEngine.instanceID) = engine;
        end

        % Engine-to-tank connections for this stage.
        for(c = 1:numel(specStage.e2tConns))
            conn = specStage.e2tConns(c);
            tankObj = stageTanks(conn.tankIdx);
            engineObj = stageEngines(conn.engineIdx);

            newLv.addEngineToTankConnection(EngineToTankConnection(tankObj, engineObj));
        end

        % Register the fully-populated stage on the vehicle.
        newLv.stages(end+1) = stage; %#ok<AGROW>
    end

    % Tank-to-tank crossfeed connections (asparagus staging).
    for(c = 1:numel(spec.t2tConns))
        specConn = spec.t2tConns(c);

        srcSpecTank = spec.stages(specConn.srcStageIdx).tanks(specConn.srcTankIdx);
        tgtSpecTank = spec.stages(specConn.tgtStageIdx).tanks(specConn.tgtTankIdx);

        if(~isKey(allTanksByInstanceID, srcSpecTank.instanceID) || ...
           ~isKey(allTanksByInstanceID, tgtSpecTank.instanceID))
            continue;
        end

        srcTankObj = allTanksByInstanceID(srcSpecTank.instanceID);
        tgtTankObj = allTanksByInstanceID(tgtSpecTank.instanceID);

        t2tConn = TankToTankConnection(srcTankObj, tgtTankObj);
        t2tConn.initFlowRate = specConn.flowRate_mTs; % mT/s

        newLv.addTankToTankConnection(t2tConn);
    end

end

function ensureFluidTypes(newLv, spec)
%ensureFluidTypes Adds any fluid group names used by the spec that are not
%already present in the vehicle's tank type set.

    existing = {};
    for(i = 1:length(newLv.tankTypes.types))
        existing{end+1} = newLv.tankTypes.types(i).name; %#ok<AGROW>
    end

    needed = {};
    for(s = 1:numel(spec.stages))
        for(t = 1:numel(spec.stages(s).tanks))
            nameIn = spec.stages(s).tanks(t).fluidTypeName;
            if(~any(strcmpi(existing, nameIn)) && ~any(strcmpi(needed, nameIn)))
                needed{end+1} = nameIn; %#ok<AGROW>
            end
        end
    end

    for(i = 1:numel(needed))
        newLv.tankTypes.addType(TankFluidType(needed{i}));
    end

end

function fType = findFluidType(newLv, fluidTypeName)
%findFluidType Resolves a fluid type by (case-insensitive) name; falls back
%to the first type when not found so imports never hard-fail here.

    fType = [];
    for(i = 1:length(newLv.tankTypes.types))
        if(strcmpi(newLv.tankTypes.types(i).name, fluidTypeName))
            fType = newLv.tankTypes.types(i);
            return;
        end
    end

    if(isempty(fType) && ~isempty(newLv.tankTypes.types))
        fType = newLv.tankTypes.types(1);
    end

end
