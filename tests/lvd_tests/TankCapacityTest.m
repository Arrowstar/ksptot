classdef TankCapacityTest < KsptotTestCase
    %TankCapacityTest Tank capacity (C1): every tank has a capacity, the
    %fuel-remaining percentage that drives engine throttle curves is measured
    %against it, tank-to-tank crossfeed stops when the receiving tank is
    %full, the validator warns when a tank is loaded past it, and tanks saved
    %before capacities existed get one on load.
    %
    %   LaunchVehicleTank.capacity / getCapacity / getLegacyCapacity,
    %   LaunchVehicleStateLogEntry (fuel remaining %),
    %   TankToTankConnection (clamp), TankCapacityValidator, LaunchVehicle.loadobj.
    %
    % Expected values are hand-computed from the stock vehicle (4 mT tank,
    % 215 kN vacuum engine) and a throttle curve set to a known straight line.

    properties(TestParameter)
        caseName = {'DefaultsAndAccessors', 'FuelRemainingUsesCapacity', ...
                    'CrossfeedClampsAtCapacity', 'ValidatorBothPolarities', ...
                    'CopyAndSummary', 'LegacyLoadMigration', 'ExampleMissionLoadsWithCapacities'};
    end

    properties(Constant)
        VAC_THRUST_KN = 215;
    end

    methods(Test)
        function tankCapacityMatchesRule(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)
        function checkDefaultsAndAccessors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank = stg.tanks(1);

            testCase.verifyEqual(tank.capacity, tank.initialMass, ...
                'The stock vehicle''s tank is created full: capacity equals the initial load.');
            testCase.verifyEqual(tank.getCapacity(), 4);

            fresh = LaunchVehicleTank(stg);
            testCase.verifyEqual(fresh.capacity, 0, 'A brand new tank is empty and holds nothing until told otherwise.');
            testCase.verifyClass(fresh.capacity, 'double');
            testCase.verifySize(fresh.capacity, [1 1]);

            tank.capacity = 7.5;
            testCase.verifyEqual(tank.getCapacity(), 7.5);

            %There is no "undefined" capacity any more: empty and negative
            %values are rejected by the property itself.
            testCase.verifyError(@() set(tank, 'capacity', []), 'MATLAB:validation:IncompatibleSize');
            testCase.verifyError(@() set(tank, 'capacity', -1), 'MATLAB:validators:mustBeNonnegative');
            testCase.verifyEqual(tank.capacity, 7.5, 'A rejected assignment must leave the value alone.');
        end

        function checkFuelRemainingUsesCapacity(testCase)
            [entry, tank, tankStates] = testCase.buildFuelCurveFixture();

            %Capacity equal to the initial mass (the stock vehicle) reproduces
            %the historical value: half-drained -> 50% -> curve value 0.6.
            testCase.assertEqual(tank.capacity, tank.initialMass);
            tankStates(1).tankMass = 0.5 * tank.initialMass;
            thrust = testCase.vacuumThrust(entry, tankStates, 1.0);
            testCase.verifyEqual(thrust, 0.6 * testCase.VAC_THRUST_KN, 'RelTol', 1e-12, ...
                'capacity == initialMass must reproduce the historical fuel-remaining percentage.');

            %Full tank: 100% -> 1.0.
            tankStates(1).tankMass = tank.initialMass;
            thrust = testCase.vacuumThrust(entry, tankStates, 1.0);
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'RelTol', 1e-12);

            %A tank loaded to half its capacity is 50% full even though it is
            %at its initial mass: curve value 0.6.
            tank.capacity = 2 * tank.initialMass;
            tankStates(1).tankMass = tank.initialMass;
            thrust = testCase.vacuumThrust(entry, tankStates, 1.0);
            testCase.verifyEqual(thrust, 0.6 * testCase.VAC_THRUST_KN, 'RelTol', 1e-12, ...
                'Fuel remaining must be measured against the capacity, not the initial mass.');

            %Quarter full -> 0.2 + 0.8*0.25 = 0.4.
            tankStates(1).tankMass = 0.25 * tank.capacity;
            thrust = testCase.vacuumThrust(entry, tankStates, 1.0);
            testCase.verifyEqual(thrust, 0.4 * testCase.VAC_THRUST_KN, 'RelTol', 1e-12);
        end

        function checkCrossfeedClampsAtCapacity(testCase)
            [~, tank2, tankStates, connState] = testCase.buildCrossfeedFixture(0.05);
            tank2.capacity = 3;

            %Below capacity: flows normally.
            masses = [4, 2.9];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [-0.05, 0.05], 'AbsTol', 1e-15, 'Below capacity the flow must be unchanged.');

            %Exactly full: stops (>= boundary), source included.
            masses = [4, 3];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0], 'AbsTol', 1e-15, 'A full target tank must stop the transfer, source included.');

            %Over full: stops.
            masses = [4, 3.5];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0], 'AbsTol', 1e-15);

            %Empty source: nothing flows (historical rule).
            masses = [0, 1];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0], 'AbsTol', 1e-15);

            %A target that holds nothing accepts nothing.
            tank2.capacity = 0;
            masses = [4, 0];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0], 'AbsTol', 1e-15, 'Zero capacity means the tank is always full.');

            %External source into a capped tank obeys the same clamp.
            tank2.capacity = 3;
            connState.conn.srcTank = LaunchVehicleTank.empty(1,0);
            masses = [4, 2];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0.05], 'AbsTol', 1e-15, 'External inflow below capacity must continue.');
            masses = [4, 3];
            mdots = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, masses, connState);
            testCase.verifyEqual(mdots(:)', [0, 0], 'AbsTol', 1e-15, 'External inflow into a full tank must stop.');
        end

        function checkValidatorBothPolarities(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            tank.initialMass = 4;
            validator = TankCapacityValidator(lvdData);

            %Registered in the orchestrator.
            classes = arrayfun(@(v) class(v), lvdData.validation.validators, 'UniformOutput', false);
            testCase.verifyTrue(any(strcmp(classes, 'TankCapacityValidator')), 'TankCapacityValidator must be registered.');

            tank.capacity = 4;
            [errs, warns] = validator.validate();
            testCase.verifyEmpty(errs, 'Overfilling is a warning, never an error.');
            testCase.verifyEmpty(warns, 'Initial mass equal to capacity is allowed (boundary).');

            tank.capacity = 3.999;
            [~, warns] = validator.validate();
            testCase.verifyNumElements(warns, 1, 'Initial mass above capacity must warn once.');
            testCase.verifyClass(warns, 'LaunchVehicleDataValidationWarning');
            testCase.verifyTrue(contains(warns(1).str, tank.name) && contains(warns(1).str, 'capacity'), ...
                'The warning must name the tank and mention capacity.');

            tank.capacity = 10;
            [~, warns] = validator.validate();
            testCase.verifyEmpty(warns, 'Initial mass below capacity: no warning.');
        end

        function checkCopyAndSummary(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);

            tank.capacity = 9.25;
            summ = tank.getTankSummaryStr();
            testCase.verifyTrue(contains(summ{1}, 'Prop Mass = 4.000 mT') && contains(summ{1}, 'Capacity = 9.250 mT'), ...
                'The summary must always report both the load and the capacity.');

            cp = tank.copy();
            testCase.verifyEqual(cp.capacity, 9.25, 'copy() must carry the capacity across.');
            testCase.verifyEqual(cp.initialMass, tank.initialMass);
        end

        function checkLegacyLoadMigration(testCase)
            %A mission saved before capacities existed loads its tanks with
            %the class default (0).  LaunchVehicle.loadobj must give them the
            %capacity that reproduces the old behaviour.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);

            plain = stg.tanks(1);              %4 mT, no optimization variable
            plain.capacity = 0;

            optimized = LaunchVehicleTank(stg);  %optimized up to 10 mT
            optimized.name = 'Optimized';
            optimized.initialMass = 4;
            optimized.capacity = 0;
            var = optimized.getNewOptVar();
            var.setUseTfForVariable(true);
            var.setBndsForVariable(1, 10);
            stg.addTank(optimized);

            inactive = LaunchVehicleTank(stg);   %bounds present but not optimized
            inactive.name = 'Inactive Variable';
            inactive.initialMass = 4;
            inactive.capacity = 0;
            var2 = inactive.getNewOptVar();
            var2.setUseTfForVariable(false);
            var2.setBndsForVariable(1, 10);
            stg.addTank(inactive);

            unbounded = LaunchVehicleTank(stg);  %optimized with an infinite upper bound
            unbounded.name = 'Unbounded';
            unbounded.initialMass = 4;
            unbounded.capacity = 0;
            var3 = unbounded.getNewOptVar();
            var3.setUseTfForVariable(true);
            var3.setBndsForVariable(0, Inf);
            stg.addTank(unbounded);

            explicit = LaunchVehicleTank(stg);   %saved with a capacity already
            explicit.name = 'Explicit';
            explicit.initialMass = 4;
            explicit.capacity = 6;
            stg.addTank(explicit);

            LaunchVehicle.loadobj(lv);

            testCase.verifyEqual(plain.capacity, 4, 'A legacy tank gets its initial mass as capacity.');
            testCase.verifyEqual(optimized.capacity, 10, ...
                'When the initial mass is being optimized the capacity must cover the whole range: the upper bound.');
            testCase.verifyEqual(inactive.capacity, 4, 'An inactive variable''s bounds do not count.');
            testCase.verifyEqual(unbounded.capacity, 4, 'An infinite upper bound falls back to the initial mass.');
            testCase.verifyEqual(explicit.capacity, 6, 'A capacity that was saved must not be touched.');

            testCase.verifyEqual(plain.getLegacyCapacity(), 4);
            testCase.verifyEqual(optimized.getLegacyCapacity(), 10);
        end

        function checkExampleMissionLoadsWithCapacities(testCase)
            %A shipped example written long before capacities existed: every
            %tank must come back with capacity >= its initial load, i.e. the
            %fuel-remaining percentage starts at 100% exactly as it always did.
            hits = dir(fullfile(ksptotTestRoot(), 'examples', 'LaunchVehicleDesigner', '**', 'lvdExample_SimpleHohmannTransfer.mat'));
            testCase.assumeNotEmpty(hits, 'Example mission not present in this checkout.');

            loaded = load(fullfile(hits(1).folder, hits(1).name), 'lvdData');
            lv = loaded.lvdData.launchVehicle;

            numTanks = 0;
            for(i = 1:numel(lv.stages)) %#ok<*NO4LP>
                for(j = 1:numel(lv.stages(i).tanks))
                    tank = lv.stages(i).tanks(j);
                    numTanks = numTanks + 1;
                    testCase.verifyEqual(tank.capacity, tank.getLegacyCapacity(), ...
                        sprintf('Tank "%s" must load with its legacy capacity.', tank.name));
                    testCase.verifyGreaterThanOrEqual(tank.capacity, tank.initialMass);
                end
            end
            testCase.assertGreaterThan(numTanks, 0, 'Fixture: the example must have tanks.');
        end

        %% ------------------------------------------------------------ fixtures
        function [entry, tank, tankStates] = buildFuelCurveFixture(testCase)
            %Stock vehicle whose engine throttles down linearly from 1.0 at
            %100% fuel to 0.2 at 0% fuel.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank = stg.tanks(1);
            engine = stg.engines(1);

            curve = engine.fuelThrottleCurve;
            curve.sortElems();
            testCase.assertEqual([curve.elems.indepVar], [0, 100], 'Fixture: expected the two stock knots.');
            curve.elems(1).depVar = 0.2;
            curve.elems(2).depVar = 1.0;
            curve.generateCurve();
            testCase.assertEqual(curve.evalCurve(50), 0.6, 'AbsTol', 1e-12, 'Fixture: curve is not the expected straight line.');

            entry = lvdData.initStateModel.getInitialStateLogEntry();
            tankStates = entry.getAllActiveTankStates();
            testCase.assertNumElements(tankStates, 1);
        end

        function thrust = vacuumThrust(~, entry, tankStates, throttle)
            masses = [tankStates.tankMass]';
            pwrStates = entry.getAllActivePwrStorageStates();
            socs = zeros(1, numel(pwrStates));
            attState = LaunchVehicleAttitudeState();
            [~, thrust] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines( ...
                tankStates, masses, entry.stageStates, throttle, entry.lvState, 0, ...
                entry.time, entry.position, entry.velocity, entry.centralBody, ...
                entry.steeringModel, socs, pwrStates, attState);
        end

        function [tank1, tank2, tankStates, connState] = buildCrossfeedFixture(testCase, flowRate)
            %One stage, two tanks, tank1 -> tank2 crossfeed at the given rate.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Crossfeed Target';
            tank2.initialMass = 1;
            tank2.capacity = 1;
            stg.addTank(tank2);

            conn = TankToTankConnection(tank1, tank2);
            connState = TankToTankConnState(conn);
            connState.flowRate = flowRate;
            connState.active = true;

            bodyInfo = LvdData.getDefaultInitialBodyInfo(testCase.celBodyData);
            lvdData.initStateModel = InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, bodyInfo);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            tankStates = entry.getAllActiveTankStates();
            testCase.assertNumElements(tankStates, 2, 'Fixture: expected two tank states.');
            testCase.assertSameHandle(tankStates(1).tank, tank1);
            testCase.assertSameHandle(tankStates(2).tank, tank2);
        end
    end
end
