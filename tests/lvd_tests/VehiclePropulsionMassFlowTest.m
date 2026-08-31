classdef VehiclePropulsionMassFlowTest < KsptotTestCase
    %VehiclePropulsionMassFlowTest Exercises the static propulsion kernel
    %LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines().
    %
    % That function is the single point where LVD converts "throttle +
    % ambient pressure + vehicle topology" into (a) per-tank propellant mass
    % flow rates, (b) total thrust, (c) an inertial thrust force vector and
    % (d) alternator/electric-engine charge rates.  It is called from the
    % force model, the ODE right hand side, several constraints, several
    % termination conditions and a handful of dependent-variable tasks, so a
    % regression here is felt everywhere.
    %
    % ORACLE STRATEGY
    % ---------------
    % Every expected value below is computed from first principles using the
    % *documented* stock engine curve definitions rather than by calling the
    % production helpers that the code under test calls:
    %
    %   ThrustPressureCurve (default): 215 kN @ 0 kPa, 168 kN @ 101.325 kPa
    %   IspPressureCurve    (default): 350 s  @ 0 kPa, 250 s  @ 101.325 kPa
    %   FuelThrottleCurve   (default): 1.0 at 0% fuel and 1.0 at 100% fuel
    %
    % and the rocket equation mass flow definition
    %
    %   mdot = -thrust / (g0 * Isp)     [mT/s], g0 = 9.80665 m/s^2
    %
    % All fixtures are evaluated only at the two curve knots (0 kPa and
    % 101.325 kPa) so the curve interpolant never enters the oracle; at a
    % knot the curve value is the tabulated value by definition.  Off-knot
    % pressures would require reimplementing the spline, which would not be
    % an independent oracle.
    %
    % TEST ISOLATION NOTE
    % -------------------
    % getTankMassFlowRatesDueToEngines() memoises its engine->tank index map
    % in a *persistent* (session-global) variable keyed only on
    % [numel(tankStates), sum([stgStates.active])].  Two different vehicle
    % topologies that happen to share that key therefore share a cache entry.
    % To keep these tests order-independent each distinct topology below uses
    % a distinct tank-state count:
    %
    %   1 tank  -> stock single engine / single tank (identical topology to
    %              the stock fixtures used by the other lvd_tests files)
    %   2 tanks -> two stage fixture whose *active* stage 1 topology is still
    %              "engine 1 -> tank state 1", i.e. identical to the two-tank
    %              fixtures in EventActionTest / EventTerminationConditionTest
    %   3 tanks -> one engine feeding tank states 1 and 2 (used nowhere else)
    %   4 tanks -> one engine feeding tank states 1 and 2 through two
    %              separately toggleable connections, used to check that the
    %              engine -> tank index memo tracks run-time plumbing changes
    %              (see checkConnectionDeactivationHonoredByMassFlow)

    properties(Constant)
        %Stock engine curve knots -- see class comment.
        VAC_THRUST_KN = 215;
        VAC_ISP_S     = 350;
        SL_THRUST_KN  = 168;
        SL_ISP_S      = 250;
        SL_PRESS_KPA  = 101.325;

        %Standard gravity used by KSPTOT's getG0(); repeated here so the
        %oracle does not depend on the value the production code reads.
        G0_MPS2 = 9.80665;

        %Engine thrust direction in body axes used by every fixture.  A
        %deliberately non-axis-aligned unit vector so that a dropped or
        %transposed attitude DCM cannot pass by coincidence.
        BODY_THRUST_DIR = [0.6; 0; 0.8];
    end

    properties(TestParameter)
        caseName = { ...
            'SingleEngineSingleTankVacuum', ...
            'SingleEngineSingleTankSeaLevel', ...
            'ThrustVectorRotatedByAttitudeDcm', ...
            'PartialThrottleScalesFlowExactly', ...
            'ZeroThrottleProducesNothing', ...
            'DrainedSoleTankForcesZeroThrottle', ...
            'InactiveEngineProducesNothing', ...
            'InactiveStageProducesNothing', ...
            'AlternatorChargesAtRawThrottle', ...
            'FullBatteryClampsAlternatorRate', ...
            'OneEngineTwoTanksSplitsEvenly', ...
            'DrainedTankExcludedFromSplit', ...
            'ConnectionDeactivationHonoredByMassFlow', ...
        };
    end

    methods(Test)
        function tankMassFlowMatchesIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)
        %% ---------------------------------------------------------------
        %  Single engine, single tank
        %  ---------------------------------------------------------------
        function checkSingleEngineSingleTankVacuum(testCase)
            [~, entry] = testCase.buildStockFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots, thrust, forceVect, ecRates] = testCase.callMassFlow(entry, tankStates, 1, 0);

            expThrust = testCase.VAC_THRUST_KN;
            expMdot   = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);

            testCase.verifyEqual(numel(mdots), 1, 'one tank state in, one mdot out');
            testCase.verifyEqual(mdots(1), expMdot, 'AbsTol', 1e-12, ...
                'vacuum mdot must equal -T/(g0*Isp) at the 0 kPa curve knot');
            testCase.verifyEqual(thrust, expThrust, 'AbsTol', 1e-10, ...
                'vacuum thrust must equal the 0 kPa thrust curve knot');
            testCase.verifyLessThan(mdots(1), 0, 'propellant flow out of a tank must be negative');

            testCase.verifyVectorEqual(forceVect, testCase.expectedForceVect(expThrust, 1), ...
                1e-12, 'vacuum thrust force vector');
            testCase.verifyEmpty(ecRates, 'stock vehicle has no electrical storage');
        end

        function checkSingleEngineSingleTankSeaLevel(testCase)
            [~, entry] = testCase.buildStockFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, tankStates, 1, testCase.SL_PRESS_KPA);

            expThrust = testCase.SL_THRUST_KN;
            expMdot   = testCase.mdotFor(testCase.SL_THRUST_KN, testCase.SL_ISP_S);

            testCase.verifyEqual(mdots(1), expMdot, 'AbsTol', 1e-12, ...
                'sea level mdot must equal -T/(g0*Isp) at the 101.325 kPa curve knot');
            testCase.verifyEqual(thrust, expThrust, 'AbsTol', 1e-10, ...
                'sea level thrust must equal the 101.325 kPa thrust curve knot');

            %Physical sanity that is independent of the numbers above: a
            %stock engine is weaker but *thirstier* at sea level.
            testCase.verifyLessThan(thrust, testCase.VAC_THRUST_KN, ...
                'sea level thrust must be below vacuum thrust');
            testCase.verifyLessThan(mdots(1), testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S), ...
                'sea level mass flow must be larger in magnitude than vacuum mass flow');

            testCase.verifyVectorEqual(forceVect, testCase.expectedForceVect(expThrust, 1), ...
                1e-12, 'sea level thrust force vector');
        end

        function checkThrustVectorRotatedByAttitudeDcm(testCase)
            %The force vector is the body frame thrust rotated into the
            %inertial frame by the attitude DCM and converted kN -> mT*km/s^2
            %(a factor of 1/1000).  Build the expected value by hand from a
            %DCM this test constructs itself.
            [~, entry] = testCase.buildStockFixture();

            dcm = testCase.handBuiltDcm();

            throttle = 0.8;
            [~, thrust, forceVect] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), throttle, 0);

            expThrust    = throttle * testCase.VAC_THRUST_KN;
            expBodyForce = (expThrust * testCase.BODY_THRUST_DIR) / 1000;
            expForce     = dcm * expBodyForce;

            testCase.verifyEqual(thrust, expThrust, 'AbsTol', 1e-10, 'throttled vacuum thrust');
            testCase.verifyVectorEqual(forceVect, expForce, 1e-13, ...
                'force vector must be dcm * (thrust_kN * bodyDir / 1000)');

            %The force magnitude is frame independent, so check it separately
            %against the scalar thrust output; this catches a DCM that is not
            %orthonormal as well as a unit slip.
            testCase.verifyEqual(norm(forceVect), expThrust/1000, 'AbsTol', 1e-13, ...
                '|forceVect| must be the scalar thrust in mT*km/s^2');
        end

        function checkPartialThrottleScalesFlowExactly(testCase)
            %The stock FuelThrottleCurve is identically 1.0, so the fuel
            %remaining adjustment is the identity and mdot must be *exactly*
            %throttle * baseMdot -- not merely close to it.
            [~, entry] = testCase.buildStockFixture();

            baseMdot   = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            baseThrust = testCase.VAC_THRUST_KN;

            for(throttle = [0.05, 0.37, 0.5, 0.999]) %#ok<*NO4LP>
                [mdots, thrust] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), throttle, 0);

                testCase.verifyEqual(mdots(1), throttle*baseMdot, 'AbsTol', 1e-15, ...
                    sprintf('mdot must scale exactly linearly with throttle (throttle = %g)', throttle));
                testCase.verifyEqual(thrust, throttle*baseThrust, 'AbsTol', 1e-12, ...
                    sprintf('thrust must scale exactly linearly with throttle (throttle = %g)', throttle));
            end
        end

        function checkZeroThrottleProducesNothing(testCase)
            [~, entry] = testCase.buildStockFixture();

            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), 0, 0);

            testCase.verifyEqual(mdots(1), 0, 'zero throttle must give exactly zero mass flow');
            testCase.verifyEqual(thrust, 0, 'zero throttle must give exactly zero thrust');
            testCase.verifyVectorEqual(forceVect, [0;0;0], 0, ...
                'zero throttle must give an exactly zero force vector');
        end

        function checkDrainedSoleTankForcesZeroThrottle(testCase)
            %An engine whose only connected tank is empty must be shut down:
            %totalConnTankMass <= 0 forces adjustedThrottle to 0, so thrust,
            %mass flow and force all collapse to zero even at full throttle.
            [~, entry] = testCase.buildStockFixture();
            tankStates = entry.getAllActiveTankStates();

            %sanity: with fuel present this fixture does produce thrust
            [~, thrustWithFuel] = testCase.callMassFlow(entry, tankStates, 1, 0);
            testCase.verifyGreaterThan(thrustWithFuel, 0, 'fixture must produce thrust when fuelled');

            tankStates(1).tankMass = 0;
            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, tankStates, 1, 0);

            testCase.verifyEqual(mdots(1), 0, 'a drained sole tank must not flow');
            testCase.verifyEqual(thrust, 0, 'a drained sole tank must force the throttle to zero');
            testCase.verifyVectorEqual(forceVect, [0;0;0], 0, 'drained sole tank force vector');
        end

        function checkInactiveEngineProducesNothing(testCase)
            [~, entry] = testCase.buildStockFixture();
            entry.stageStates(1).engineStates(1).active = false;

            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), 1, 0);

            testCase.verifyEqual(mdots(1), 0, 'an inactive engine must not draw propellant');
            testCase.verifyEqual(thrust, 0, 'an inactive engine must not produce thrust');
            testCase.verifyVectorEqual(forceVect, [0;0;0], 0, 'inactive engine force vector');
        end

        %% ---------------------------------------------------------------
        %  Two stages: the inactive one must contribute nothing
        %  ---------------------------------------------------------------
        function checkInactiveStageProducesNothing(testCase)
            [~, entry] = testCase.buildTwoStageFixture();
            entry.stageStates(2).active = false;

            %Deliberately pass *all* tank states (including the inactive
            %stage's tank) the way the force model does, so the test proves
            %the inactive stage is skipped rather than simply absent.
            tankStates = entry.getAllTankStates();
            testCase.assertEqual(numel(tankStates), 2, 'two stage fixture must expose two tank states');

            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, tankStates, 1, 0);

            expThrust = testCase.VAC_THRUST_KN;                                  % stage 1 only
            expMdot   = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);

            testCase.verifyEqual(mdots(1), expMdot, 'AbsTol', 1e-12, ...
                'the active stage tank must flow at the full single engine rate');
            testCase.verifyEqual(mdots(2), 0, ...
                'the inactive stage tank must not flow at all');
            testCase.verifyEqual(thrust, expThrust, 'AbsTol', 1e-10, ...
                'only the active stage engine may contribute thrust');
            testCase.verifyVectorEqual(forceVect, testCase.expectedForceVect(expThrust, 1), ...
                1e-12, 'two stage force vector (active stage only)');
        end

        %% ---------------------------------------------------------------
        %  Electrical coupling
        %  ---------------------------------------------------------------
        function checkAlternatorChargesAtRawThrottle(testCase)
            %An alternator equipped engine charges storage at
            %altPwrRate * throttle EC/s.  Note the production code passes the
            %*raw* throttle (not the fuel-curve adjusted one) to
            %getPowerRate(), which is the behaviour asserted here; with the
            %stock fuel throttle curve (identically 1.0) the two coincide, so
            %this assertion is not sensitive to that distinction.
            altRate  = 7;
            throttle = 0.5;

            [~, entry] = testCase.buildAlternatorFixture(altRate, 100, 40);

            [~, thrust, ~, ecRates] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), throttle, 0);

            testCase.verifyEqual(numel(ecRates), 1, 'fixture has exactly one battery');
            testCase.verifyEqual(ecRates(1), altRate*throttle, 'AbsTol', 1e-12, ...
                'alternator charge rate must be altPwrRate * throttle');
            testCase.verifyEqual(thrust, throttle*testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, ...
                'adding an alternator must not change the thrust');
        end

        function checkFullBatteryClampsAlternatorRate(testCase)
            %A battery already at maximum capacity is excluded from the
            %charge split (bool = soc < maxCapacity), so with a single full
            %battery the alternator output goes nowhere.
            altRate  = 7;
            throttle = 0.5;
            maxCap   = 100;

            [~, entry] = testCase.buildAlternatorFixture(altRate, maxCap, maxCap);

            [~, ~, ~, ecRates] = testCase.callMassFlow(entry, entry.getAllActiveTankStates(), throttle, 0);

            testCase.verifyEqual(ecRates(1), 0, ...
                'a full battery must receive exactly zero charge rate');
        end

        %% ---------------------------------------------------------------
        %  One engine feeding two tanks
        %  ---------------------------------------------------------------
        function checkOneEngineTwoTanksSplitsEvenly(testCase)
            %Three tank states; the engine is connected to tank states 1 and
            %2 only.  The engine's total mass flow is unchanged -- it is
            %simply divided evenly between the tanks it can draw from.
            [~, entry] = testCase.buildThreeTankFixture();
            tankStates = entry.getAllActiveTankStates();
            testCase.assertEqual(numel(tankStates), 3, 'three tank fixture');

            [mdots, thrust] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);

            testCase.verifyEqual(mdots(1), baseMdot/2, 'AbsTol', 1e-12, ...
                'tank 1 must take exactly half the engine mass flow');
            testCase.verifyEqual(mdots(2), baseMdot/2, 'AbsTol', 1e-12, ...
                'tank 2 must take exactly half the engine mass flow');
            testCase.verifyEqual(mdots(3), 0, ...
                'the unconnected tank must not flow');
            testCase.verifyEqual(sum(mdots), baseMdot, 'AbsTol', 1e-12, ...
                'the split must conserve the engine total mass flow');
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, ...
                'splitting flow across tanks must not change thrust');
        end

        function checkDrainedTankExcludedFromSplit(testCase)
            %Same topology, but tank state 2 is empty.  It must drop out of
            %flowFromTankInds entirely, so the *whole* engine flow comes from
            %tank 1.  Thrust is unaffected because propellant still remains
            %in the connected set.
            [~, entry] = testCase.buildThreeTankFixture();
            tankStates = entry.getAllActiveTankStates();
            tankStates(2).tankMass = 0;

            [mdots, thrust] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);

            testCase.verifyEqual(mdots(1), baseMdot, 'AbsTol', 1e-12, ...
                'the only tank with propellant must supply the entire engine flow');
            testCase.verifyEqual(mdots(2), 0, 'a drained tank must not flow');
            testCase.verifyEqual(mdots(3), 0, 'the unconnected tank must not flow');
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, ...
                'thrust must be unaffected while any connected tank still has propellant');
        end

        function checkConnectionDeactivationHonoredByMassFlow(testCase)
            %Deactivating an engine-to-tank connection at run time -- what
            %SetEngineTankConnActiveStateEventAction does -- must change which
            %tanks the engine draws from on the very next mass flow call.
            %
            %getTankMassFlowRatesDueToEngines() memoises the engine -> tank
            %state index map, so this exercises the memo's invalidation as
            %much as the flow split itself.  The memo lives on the
            %LaunchVehicleState instance (see getEngineToTankStateIndices) and
            %is cleared by clearCachedConnEnginesTanks(); it used to live in a
            %session-global `persistent` keyed on
            %[numel(tankStates), sum([stgStates.active])], which sees neither
            %the plumbing nor which vehicle it is looking at.  Both calls
            %below deliberately pass an unchanged tank count and active-stage
            %count so that a count-keyed memo cannot pass this test.

            [~, entry, connToDeactivate] = testCase.buildFourTankFixture();
            tankStates = entry.getAllActiveTankStates();
            testCase.assertEqual(numel(tankStates), 4, 'four tank fixture must have four tank states');

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);

            %Warm the memo with the "engine feeds tanks 1 and 2" topology.
            mdotsBefore = testCase.callMassFlow(entry, tankStates, 1, 0);
            testCase.verifyEqual(mdotsBefore(1), baseMdot/2, 'AbsTol', 1e-12, ...
                'before deactivation tank 1 supplies half the flow');
            testCase.verifyEqual(mdotsBefore(2), baseMdot/2, 'AbsTol', 1e-12, ...
                'before deactivation tank 2 supplies half the flow');

            %Now deactivate the engine -> tank 2 connection exactly the way
            %SetEngineTankConnActiveStateEventAction does at run time.
            for(i = 1:numel(entry.lvState.e2TConns))
                if(entry.lvState.e2TConns(i).conn == connToDeactivate)
                    entry.lvState.e2TConns(i).active = false;
                end
            end
            entry.lvState.clearCachedConnEnginesTanks();

            %The vehicle state itself now correctly reports a single
            %connected tank...
            engine = entry.stageStates(1).engineStates(1).engine;
            testCase.verifyEqual(numel(entry.lvState.getTanksConnectedToEngine(engine)), 1, ...
                'the state object correctly sees only one connected tank after deactivation');

            %...and so must the mass flow kernel, even though the memo key a
            %count-based cache would use, [numel(tankStates), numActiveStages]
            %= [4, 1], is unchanged.
            mdotsAfter = testCase.callMassFlow(entry, tankStates, 1, 0);

            testCase.verifyEqual(mdotsAfter(1), baseMdot, 'AbsTol', 1e-12, ...
                'the sole remaining connected tank must supply the entire engine flow');
            testCase.verifyEqual(mdotsAfter(2), 0, 'AbsTol', 1e-12, ...
                'the disconnected tank must not be drained');
            testCase.verifyEqual(mdotsAfter(3), 0, 'tanks 3 and 4 were never connected');
            testCase.verifyEqual(mdotsAfter(4), 0, 'tanks 3 and 4 were never connected');
        end

        %% ---------------------------------------------------------------
        %  Oracle helpers
        %  ---------------------------------------------------------------
        function mdot = mdotFor(testCase, thrustKN, ispSec)
            %mdotFor Propellant mass flow rate in mT/s from thrust and Isp.
            %
            % thrust [kN] = mdot [mT/s] * g0 [m/s^2] * Isp [s], negated
            % because propellant leaves the tank.
            mdot = -thrustKN / (testCase.G0_MPS2 * ispSec);
        end

        function forceVect = expectedForceVect(testCase, thrustKN, throttle)
            %expectedForceVect Inertial thrust force in mT*km/s^2.
            %
            % The kernel is handed the attitude state built by
            % attitudeStateForTests(), so the expected rotation is exactly
            % the hand written DCM below -- no production steering model is
            % involved in either the actual or the expected value.
            forceVect = testCase.handBuiltDcm() * ((throttle * thrustKN * testCase.BODY_THRUST_DIR) / 1000);
        end

        function attState = attitudeStateForTests(testCase)
            %attitudeStateForTests A hand built attitude state.
            %
            % LaunchVehicleStateLogEntry.attitude is a Dependent property
            % that rebuilds itself from the steering model on every access,
            % so it cannot be assigned.  Since the mass flow kernel takes the
            % attitude state as an explicit argument, the tests supply their
            % own and keep the steering model out of the oracle entirely.
            attState = LaunchVehicleAttitudeState(testCase.handBuiltDcm());
        end

        function dcm = handBuiltDcm(~)
            %handBuiltDcm A hand written, obviously orthonormal 3-2 rotation.
            a = 0.7;
            b = -0.3;

            rotZ = [cos(a), -sin(a), 0;
                    sin(a),  cos(a), 0;
                         0,       0, 1];

            rotY = [ cos(b), 0, sin(b);
                          0, 1,      0;
                    -sin(b), 0, cos(b)];

            dcm = rotZ * rotY;
        end

        %% ---------------------------------------------------------------
        %  Fixture helpers
        %  ---------------------------------------------------------------
        function [mdots, thrust, forceVect, ecRates] = callMassFlow(testCase, entry, tankStates, throttle, presskPa)
            %callMassFlow Marshals a state log entry into the static kernel's
            %argument list, the same way ThrustForceModel does.
            tankMasses = [tankStates.tankMass]';

            pwrStorageStates = entry.getAllActivePwrStorageStates();
            storageSoCs = zeros(1, numel(pwrStorageStates));
            for(i = 1:numel(pwrStorageStates))
                storageSoCs(i) = pwrStorageStates(i).getStateOfCharge();
            end

            [mdots, thrust, forceVect, ecRates] = ...
                LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines( ...
                    tankStates, tankMasses, entry.stageStates, throttle, entry.lvState, ...
                    presskPa, entry.time, entry.position, entry.velocity, entry.centralBody, ...
                    entry.steeringModel, storageSoCs, pwrStorageStates, testCase.attitudeStateForTests());
        end

        function [lvdData, entry] = buildStockFixture(testCase)
            %buildStockFixture Stock vehicle: one stage, one engine, one tank.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.launchVehicle.stages(1).engines(1).bodyFrameThrustVect = testCase.BODY_THRUST_DIR;

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, battery] = buildAlternatorFixture(testCase, altRate, maxCap, initSoC)
            %buildAlternatorFixture Stock vehicle plus an alternator on the
            %engine and one basic battery.  Tank count stays at 1 so the
            %persistent engine->tank cache key is unchanged.
            [lvdData, entry] = testCase.buildStockFixture();

            stg = lvdData.launchVehicle.stages(1);
            stg.engines(1).hasAlternator = true;
            stg.engines(1).altPwrRate = altRate;

            battery = LaunchVehicleBasicElectricalBattery(stg);
            battery.name = 'Alternator Test Battery';
            battery.maxCapacity = maxCap;
            battery.initialStateOfCharge = initSoC;
            stg.addPwrStorage(battery);

            stgState = entry.stageStates(1);
            stgState.addPowerStorageState(battery.createDefaultInitialState(stgState));
        end

        function [lvdData, entry] = buildTwoStageFixture(testCase)
            %buildTwoStageFixture Stock stage 1 plus a second stage with its
            %own engine and tank.  Two tank states total.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            lv.stages(1).engines(1).bodyFrameThrustVect = testCase.BODY_THRUST_DIR;

            stgB = LaunchVehicleStage(lv);
            stgB.name = 'Second Stage';
            stgB.dryMass = 1;
            lv.addStage(stgB);

            engB = LaunchVehicleEngine(stgB);
            engB.name = 'Second Stage Engine';
            engB.bodyFrameThrustVect = testCase.BODY_THRUST_DIR;
            stgB.addEngine(engB);

            tankB = LaunchVehicleTank(stgB);
            tankB.name = 'Second Stage Tank';
            tankB.initialMass = 3;
            stgB.addTank(tankB);

            lv.addEngineToTankConnection(EngineToTankConnection(tankB, engB));

            entry = testCase.regenerateInitialStateEntry(lvdData);
        end

        function [lvdData, entry] = buildThreeTankFixture(testCase)
            %buildThreeTankFixture One stage, one engine, three tanks; the
            %engine is connected to tanks 1 and 2 only.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);
            engine.bodyFrameThrustVect = testCase.BODY_THRUST_DIR;

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Split Tank Two';
            tank2.initialMass = 6;
            stg.addTank(tank2);

            tank3 = LaunchVehicleTank(stg);
            tank3.name = 'Unconnected Tank Three';
            tank3.initialMass = 7;
            stg.addTank(tank3);

            lv.addEngineToTankConnection(EngineToTankConnection(tank2, engine));

            entry = testCase.regenerateInitialStateEntry(lvdData);
        end

        function [lvdData, entry, conn2] = buildFourTankFixture(testCase)
            %buildFourTankFixture One stage, one engine, four tanks; the
            %engine is connected to tanks 1 and 2 via two separately
            %toggleable connections, conn2 being the tank 2 one.  The tank
            %count of four is used by no other fixture in the suite, so a
            %count-keyed memo elsewhere in the suite cannot mask a stale read
            %here.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);
            engine.bodyFrameThrustVect = testCase.BODY_THRUST_DIR;

            names  = {'Four Tank Fixture Tank Two', 'Four Tank Fixture Tank Three', 'Four Tank Fixture Tank Four'};
            masses = [6, 7, 8];
            newTanks = LaunchVehicleTank.empty(1,0);
            for(i = 1:numel(names))
                tk = LaunchVehicleTank(stg);
                tk.name = names{i};
                tk.initialMass = masses(i);
                stg.addTank(tk);
                newTanks(end+1) = tk; %#ok<AGROW>
            end

            conn2 = EngineToTankConnection(newTanks(1), engine);
            lv.addEngineToTankConnection(conn2);

            entry = testCase.regenerateInitialStateEntry(lvdData);
        end

        function entry = regenerateInitialStateEntry(testCase, lvdData)
            %regenerateInitialStateEntry Rebuilds the initial state model so
            %the stage/engine/tank/connection states match a vehicle whose
            %topology was edited after construction.
            bodyInfo = LvdData.getDefaultInitialBodyInfo(testCase.celBodyData);
            lvdData.initStateModel = ...
                InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, bodyInfo);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end
    end
end
