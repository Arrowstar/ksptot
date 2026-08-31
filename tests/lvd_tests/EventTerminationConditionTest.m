classdef EventTerminationConditionTest < KsptotTestCase
    %EventTerminationConditionTest LVD AbstractEventTerminationCondition subclasses.
    %
    % One parameterized test dispatches (by name, via a switch) to a
    % per-type check method -- the "fixture-generator map" called for by
    % the test plan, realized as testCase.(['check' termCondCase])()
    % since matlab.unittest TestParameter values must be simple data, not
    % function handles bound to the test instance.
    %
    % Each check builds a small analytic fixture (a real
    % LaunchVehicleStateLogEntry from LvdData.getDefaultLvdData, mutated
    % to a known state) and compares the term condition's
    % getEventTermCondFuncHandle() output against a hand-derived
    % independent oracle -- never against the condition's own internal
    % helper objects.
    %
    % Frame gotcha: AbstractEventTerminationCondition.frame is only
    % auto-populated by the static loadobj() backward-compat path, NOT by
    % initTermCondition(). Every condition whose eventTermCond reads
    % obj.frame (Altitude, TrueAnomaly, Apoapsis/PeriapsisAltitude,
    % FlightPathAngle, Latitude/Longitude/AscendingNode/DescendingNode)
    % therefore has its .frame set explicitly here, after
    % initTermCondition, to the body's own body-centered-inertial frame.
    % Setting frame equal to the body's own BCI frame makes the
    % frame-conversion step an algebraic identity (same frame in and out,
    % same evaluation time), which is what lets altitude/apoapsis/etc.
    % oracles below be simple, closed-form textbook formulas rather than
    % reimplementations of LvdGeometry's frame-conversion machinery.
    %
    % "Non-rotating body" trick (established in
    % DragThrustLiftSrpForceModelTest): bodyInfo.rotperiod = Inf and
    % bodyInfo.rotini = 0 collapses the body-fixed (ECEF) frame onto the
    % body-centered-inertial (BCI) frame, so latitude/longitude/NED/wind
    % frame math collapses to plain spherical-coordinate formulas on the
    % raw inertial position/velocity vectors. Used for
    % Latitude/Longitude/AscendingNode/DescendingNode/DynamicPressure and
    % all six attitude conditions.
    %
    % Generic infrastructure reused as oracle-building blocks (consistent
    % with Phase 1's use of getAtmoDensityAtAltitude/
    % getLatLongAltFromInertialVect): getAtmoDensityAtAltitude,
    % getPressureAtAltitude, computeWindFrame, computeNedFrame. These are
    % shared navigation/atmosphere utilities, not the termination-
    % condition logic under test. The one piece of "under test" math that
    % IS reimplemented completely independently (not calling
    % rotm2eulARH.m) is the ZYX Euler-angle extraction used by all six
    % attitude conditions -- see localZyxEuler() below.
    %
    % Skipped/lighter coverage (documented, not silently omitted):
    %   - SoITransitionTermCondition: only the SoI-radius ("up") branch is
    %     exercised, using a leaf body (testCase.mun) so the "down" branch
    %     (leaving SoI into a child body) never executes. The down branch
    %     requires getAbsPositBetweenSpacecraftAndBody_fast_mex and a
    %     multi-body ephemeris chain; reproducing that independently was
    %     judged out of proportion to the risk for this pass.
    %   - PowerNetChargeRateTermCondition: exercised only at the
    %     boundary case of zero configured power sources/sinks (net
    %     charge rate must be exactly zero regardless of the storage
    %     state). getStorageChargeRatesDueToSourcesSinks' full multi
    %     source/sink computation is complex enough that reimplementing it
    %     independently was judged out of proportion to the value added
    %     here; the zero-source/sink boundary is still a real, meaningful
    %     regression check (it catches e.g. an accidental nonzero-rate
    %     default, wrong sign convention, or reading the wrong y segment).

    properties(TestParameter)
        termCondCase = {'Altitude', 'EventDurationForward', 'EventDurationBackward', ...
            'TrueAnomaly', 'ApoapsisAltitude', 'PeriapsisAltitude', 'FlightPathAngle', ...
            'Latitude', 'Longitude', 'AscendingNode', 'DescendingNode', ...
            'DynamicPressure', 'PowerNetChargeRate', ...
            'SeaLevelThrustToWeightFullThrottle', 'SeaLevelThrustToWeightZeroThrottle', ...
            'SoITransitionUpBranch', 'StopwatchValueNotRunning', 'StopwatchValueRunning', ...
            'TankMassTwoTankIndexing', 'Throttle', 'TotalVehicleEpsStateOfCharge', ...
            'AngleOfAttack', 'BankAngle', 'Pitch', 'Roll', 'SideSlipAngle', 'Yaw'};
    end

    methods(Test)
        function terminationConditionMatchesIndependentOracle(testCase, termCondCase)
            testCase.(['check' termCondCase])();
        end
    end

    methods(Access=private)

        %% ---------------------------------------------------- Altitude

        function checkAltitude(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = entry.centralBody;

            targetAlt = 100; %km
            termCond = AltitudeTermCondition(targetAlt);
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            %With obj.frame == bodyInfo's own BCI frame, the frame
            %round-trip inside eventTermCond is an algebraic identity, so
            %actualAltitude collapses to exactly norm(rVect)-radius.
            for(offset = [-50, 150]) %#ok<*NO4LP>
                rVect = (bodyInfo.radius + targetAlt + offset) * normVector([1; 0.3; 0.2]);
                [value, isterminal, direction] = hndl(0, [rVect; 0; 0; 0]);

                testCase.verifyEqual(value, offset, 'AbsTol', 1e-8, ...
                    'AltitudeTermCondition value does not match norm(r)-radius-target');
                testCase.verifyEqual(isterminal, 1);
                testCase.verifyEqual(direction, 0);
            end
        end

        %% ------------------------------------------------- EventDuration

        function checkEventDurationForward(testCase)
            termCond = EventDurationTermCondition(100);
            termCond.t0 = 5;
            termCond.propDir = PropagationDirectionEnum.Forward;
            hndl = termCond.getEventTermCondFuncHandle();

            testCase.verifyEqual(hndl(105, []), 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(hndl(55, []), -50, 'AbsTol', 1e-10);
            testCase.verifyEqual(hndl(205, []), 100, 'AbsTol', 1e-10);
        end

        function checkEventDurationBackward(testCase)
            termCond = EventDurationTermCondition(100);
            termCond.t0 = 5;
            termCond.propDir = PropagationDirectionEnum.Backward;
            hndl = termCond.getEventTermCondFuncHandle();

            testCase.verifyEqual(hndl(-95, []), 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(hndl(-45, []), 50, 'AbsTol', 1e-10);
        end

        %% -------------------------------------------------- TrueAnomaly

        function checkTrueAnomaly(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = entry.centralBody;
            gmu = bodyInfo.gm;

            sma = bodyInfo.radius + 300;
            ecc = 0;
            inc = 0.4; raan = 0.2; argp = 0;
            nu0 = 0;
            targetTru = 1.0;

            [r0, v0] = refCoe2Rv(sma, ecc, inc, raan, argp, nu0, gmu);

            entry.position = r0;
            entry.velocity = v0;
            entry.time = 0;

            termCond = TrueAnomalyTermCondition(targetTru);
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            n = sqrt(gmu / sma^3);
            deltaT0 = (targetTru - nu0) / n; %ecc=0 => mean anomaly == true anomaly exactly

            value0 = hndl(0, [r0; v0]);
            testCase.verifyEqual(value0, deltaT0, 'RelTol', 1e-8, ...
                'TrueAnomalyTermCondition value at t=0 does not match analytic deltaT');

            [r1, v1] = refKeplerPropagate(r0, v0, gmu, deltaT0);
            [valueAtCrossing, isterminal, direction] = hndl(deltaT0, [r1; v1]);
            testCase.verifyEqual(valueAtCrossing, 0, 'AbsTol', 1e-4, ...
                'TrueAnomalyTermCondition value is not ~0 at the analytically-propagated crossing time');
            testCase.verifyEqual(isterminal, 1);
            testCase.verifyEqual(direction, 0);
        end

        %% ------------------------------------ Apoapsis/PeriapsisAltitude, FlightPathAngle

        function checkApoapsisAltitude(testCase)
            [bodyInfo, r, v] = testCase.buildKeplerFixture();
            [~, entry] = testCase.buildDefaultEntry();
            entry.position = r; entry.velocity = v; entry.time = 0;

            sma = 8000; ecc = 0.3;
            apoAlt = sma * (1 + ecc) - bodyInfo.radius;

            for(shift = [15, -20])
                termCond = ApoapsisAltitudeTermCondition(apoAlt + shift);
                termCond.initTermCondition(entry);
                termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
                hndl = termCond.getEventTermCondFuncHandle();

                value = hndl(0, [r; v]);
                testCase.verifyEqual(value, -shift, 'RelTol', 1e-6, ...
                    'ApoapsisAltitudeTermCondition value does not match sma*(1+e)-radius-target');
            end
        end

        function checkPeriapsisAltitude(testCase)
            [bodyInfo, r, v] = testCase.buildKeplerFixture();
            [~, entry] = testCase.buildDefaultEntry();
            entry.position = r; entry.velocity = v; entry.time = 0;

            sma = 8000; ecc = 0.3;
            periAlt = sma * (1 - ecc) - bodyInfo.radius;

            for(shift = [-20, 15])
                termCond = PeriapsisAltitudeTermCondition(periAlt + shift);
                termCond.initTermCondition(entry);
                termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
                hndl = termCond.getEventTermCondFuncHandle();

                value = hndl(0, [r; v]);
                testCase.verifyEqual(value, -shift, 'RelTol', 1e-6, ...
                    'PeriapsisAltitudeTermCondition value does not match sma*(1-e)-radius-target');
            end
        end

        function checkFlightPathAngle(testCase)
            [bodyInfo, r, v] = testCase.buildKeplerFixture();
            [~, entry] = testCase.buildDefaultEntry();
            entry.position = r; entry.velocity = v; entry.time = 0;

            ecc = 0.3; nu = 0.9;
            fpa = atan2(ecc * sin(nu), 1 + ecc * cos(nu));

            termCond = FlightPathAngleTermCondition(fpa + 0.05);
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            value = hndl(0, [r; v]);
            testCase.verifyEqual(value, -0.05, 'AbsTol', 1e-6, ...
                'FlightPathAngleTermCondition value does not match the independent atan2(e sin(nu), 1+e cos(nu)) formula');
        end

        %% -------------------------------------- Latitude/Longitude family

        function checkLatitude(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();

            lat0 = 0.3; long0 = -1.0; r = bodyInfo.radius + 120;
            rVect = r * [cos(lat0)*cos(long0); cos(lat0)*sin(long0); sin(lat0)];
            vVect = [0.1; -0.2; 0.15];

            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            termCond = LatitudeTermCondition(lat0 + 0.07);
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            [value, isterminal, direction] = hndl(0, [rVect; vVect]);
            testCase.verifyEqual(value, -0.07, 'AbsTol', 1e-6, ...
                'LatitudeTermCondition value does not match asin(z/r)-target under the non-rotating-body trick');
            testCase.verifyEqual(isterminal, 1);
            testCase.verifyEqual(direction, 0);
        end

        function checkLongitude(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();

            lat0 = 0.3; long0 = -1.0; r = bodyInfo.radius + 120;
            rVect = r * [cos(lat0)*cos(long0); cos(lat0)*sin(long0); sin(lat0)];
            vVect = [0.1; -0.2; 0.15];

            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            termCond = LongitudeTermCondition(long0 - 0.09);
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            value = hndl(0, [rVect; vVect]);
            %geoElem.long is wrapped to [0,2*pi) internally while obj.long
            %(the raw target property) is not, so the difference is only
            %meaningful modulo 2*pi -- compare with verifyAngleEqual, as
            %with the other wrapped-angle term conditions below.
            testCase.verifyAngleEqual(value, 0.09, 1e-6, ...
                'LongitudeTermCondition value does not match atan2(y,x)-target under the non-rotating-body trick (mod 2*pi)');
        end

        function checkAscendingNode(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();
            gmu = bodyInfo.gm;

            sma = bodyInfo.radius + 150; inc = 0.6; raan = 0.4;
            [r, v] = refCoe2Rv(sma, 0, inc, raan, 0, 0, gmu); %u=argp+nu=0 -> ascending node itself

            entry.position = r; entry.velocity = v; entry.time = 0;

            termCond = AscendingNodeTermCondition();
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            [value, isterminal, direction] = hndl(0, [r; v]);
            testCase.verifyEqual(value, 0, 'AbsTol', 1e-6, ...
                'AscendingNodeTermCondition value is not ~0 exactly at the ascending node (u=0)');
            testCase.verifyEqual(isterminal, 1);
            testCase.verifyEqual(direction, 1.0, ...
                'AscendingNodeTermCondition must report an ascending (+1) direction');
        end

        function checkDescendingNode(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();
            gmu = bodyInfo.gm;

            sma = bodyInfo.radius + 150; inc = 0.6; raan = 0.4;
            [r, v] = refCoe2Rv(sma, 0, inc, raan, 0, pi, gmu); %u=pi -> descending node

            entry.position = r; entry.velocity = v; entry.time = 0;

            termCond = DescendingNodeTermCondition();
            termCond.initTermCondition(entry);
            termCond.frame = bodyInfo.getBodyCenteredInertialFrame();
            hndl = termCond.getEventTermCondFuncHandle();

            [value, isterminal, direction] = hndl(0, [r; v]);
            testCase.verifyEqual(value, 0, 'AbsTol', 1e-6, ...
                'DescendingNodeTermCondition value is not ~0 exactly at the descending node (u=pi)');
            testCase.verifyEqual(isterminal, 1);
            testCase.verifyEqual(direction, -1.0, ...
                'DescendingNodeTermCondition must report a descending (-1) direction');
        end

        %% ------------------------------------------------ DynamicPressure

        function checkDynamicPressure(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();

            altitude = 15; %km, inside atmohgt
            rVect = (bodyInfo.radius + altitude) * normVector([0.6; 0.3; 0.9]);
            vVect = [0.4; -0.3; 0.2];

            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            lat = asin(rVect(3) / norm(rVect));
            long = atan2(rVect(2), rVect(1));
            density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, 0, long);
            vMagMS = norm(vVect) * 1000; %non-rotating trick: vVectECEF == vVect exactly
            dynP_kPa = density * vMagMS^2 / 2 / 1000;

            termCond = DynamicPressureTermCondition(dynP_kPa + 3);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            value = hndl(0, [rVect; vVect]);
            testCase.verifyEqual(value, -3, 'RelTol', 1e-6, ...
                'DynamicPressureTermCondition value does not match 0.5*rho*v^2 [kPa] minus target');
        end

        %% -------------------------------------------- PowerNetChargeRate

        function checkPowerNetChargeRate(testCase)
            [~, entry] = testCase.buildEntryWithBattery();

            numTank = entry.getNumActiveTankStates();
            numStorage = entry.getNumActivePwrStorageStates();
            y = [entry.position(:); entry.velocity(:); 3.3 * ones(numTank, 1); 55 * ones(numStorage, 1)];

            termCond = PowerNetChargeRateTermCondition(6);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            %No power sources/sinks are configured on the fixture vehicle,
            %so the net storage charge rate must be exactly zero
            %regardless of the storage SoC value in y -- a real, if
            %narrow, regression check on this boundary case.
            value = hndl(0, y);
            testCase.verifyEqual(value, -6, 'AbsTol', 1e-9, ...
                'PowerNetChargeRateTermCondition value is not exactly -target with zero sources/sinks configured');
        end

        %% ------------------------------------- SeaLevelThrustToWeight

        function checkSeaLevelThrustToWeightFullThrottle(testCase)
            testCase.checkSeaLevelThrustToWeight(1, 2);
        end

        function checkSeaLevelThrustToWeightZeroThrottle(testCase)
            testCase.checkSeaLevelThrustToWeight(0, 5);
        end

        function checkSeaLevelThrustToWeight(testCase, throttleVal, shift)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = entry.centralBody;

            throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            throttleModel.setPolyTerms(throttleVal, 0, 0);
            entry.throttleModel = throttleModel;

            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1; 0.2; 0.3]); %vacuum
            vVect = [0.5; 1.6; 0.1];
            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            termCond = SeaLevelThrustToWeightTermCondition(0); %placeholder, set target below
            termCond.initTermCondition(entry);

            %Vacuum control point transcribed from LaunchVehicle.createDefaultLaunchVehicle
            %(same value trusted, without re-derivation, in
            %DragThrustLiftSrpForceModelTest.thrustForceMatchesVacuumThrustCurve).
            vacThrustKN = 215;
            totalThrustN = throttleVal * vacThrustKN * 1000;

            dryMass = entry.getTotalVehicleDryMass();
            tankStates = entry.getAllActiveTankStates();
            tankMassesTotal = sum([tankStates.tankMass]);
            totalMassKg = (dryMass + tankMassesTotal) * 1000;

            gSlAccel = (bodyInfo.gm / bodyInfo.radius^2) * 1000;
            totalSlWeightN = totalMassKg * gSlAccel;
            twExpected = totalThrustN / totalSlWeightN;

            termCond.targetTtW = twExpected + shift;
            hndl = termCond.getEventTermCondFuncHandle();

            y = [rVect; vVect; [tankStates.tankMass]'];
            value = hndl(0, y);
            testCase.verifyEqual(value, -shift, 'RelTol', 1e-6, ...
                'SeaLevelThrustToWeightTermCondition value does not match the vacuum-thrust-curve T/W oracle');
        end

        %% --------------------------------------------- SoITransition

        function checkSoITransitionUpBranch(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            leafBody = testCase.mun;
            testCase.assumeEmpty(leafBody.getChildrenBodyInfo(testCase.celBodyData), ...
                'Fixture assumes testCase.mun is a leaf body with no children (SoI down-branch skipped by design)');

            entry.centralBody = leafBody;

            termCond = SoITransitionTermCondition();
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            rSOI = leafBody.getCachedSoIRadius();
            vVect = [0.2; 0.1; -0.15]; %arbitrary, non-degenerate

            rVectIn = (rSOI - 10) * normVector([1; 0.3; 0.4]);
            [valueIn, isterminalIn, directionIn] = hndl(0, [rVectIn; vVect]);
            testCase.verifyEqual(valueIn, 10, 'RelTol', 1e-6);
            testCase.verifyEqual(isterminalIn, 1);
            testCase.verifyEqual(directionIn, -1);

            rVectOut = (rSOI + 10) * normVector([1; 0.3; 0.4]);
            valueOut = hndl(0, [rVectOut; vVect]);
            testCase.verifyEqual(valueOut, -10, 'RelTol', 1e-6);
        end

        %% ------------------------------------------------- StopwatchValue

        function checkStopwatchValueNotRunning(testCase)
            [~, entry, ~] = testCase.buildEntryWithStopwatch(StopwatchRunningEnum.NotRunning, 12);
            sw = entry.launchVehicle.stopwatches(1);

            termCond = StopwatchValueTermCondition(sw, 20);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            for(t = [0, 500]) %value must be t-independent while not running
                [value, isterminal, direction] = hndl(t, []);
                testCase.verifyEqual(value, 8, 'AbsTol', 1e-10, ...
                    'StopwatchValueTermCondition (not running) value does not equal target-startValue');
                testCase.verifyEqual(isterminal, 1);
                testCase.verifyEqual(direction, 0);
            end
        end

        function checkStopwatchValueRunning(testCase)
            [~, entry, ~] = testCase.buildEntryWithStopwatch(StopwatchRunningEnum.Running, 5);
            sw = entry.launchVehicle.stopwatches(1);
            entry.time = 0;

            termCond = StopwatchValueTermCondition(sw, 50);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            value10 = hndl(10, []);
            testCase.verifyEqual(value10, 35, 'AbsTol', 1e-10, ...
                'StopwatchValueTermCondition (running) value does not equal target-(startValue+deltaT) at t=10');

            valueCross = hndl(45, []);
            testCase.verifyEqual(valueCross, 0, 'AbsTol', 1e-10, ...
                'StopwatchValueTermCondition (running) value is not 0 at the analytic crossing time');
        end

        %% ------------------------------------------------------ TankMass

        function checkTankMassTwoTankIndexing(testCase)
            [~, entry, tank1, tank2] = testCase.buildEntryWithTwoTanks();

            y = [entry.position(:); entry.velocity(:); 3.3; 6.6];

            termCond1 = TankMassTermCondition(tank1, 2.5);
            termCond1.initTermCondition(entry);
            hndl1 = termCond1.getEventTermCondFuncHandle();
            value1 = hndl1(0, y);
            testCase.verifyEqual(value1, 3.3 - 2.5, 'AbsTol', 1e-10, ...
                'TankMassTermCondition does not resolve tank #1 to y-vector index 1');

            termCond2 = TankMassTermCondition(tank2, 4.5);
            termCond2.initTermCondition(entry);
            hndl2 = termCond2.getEventTermCondFuncHandle();
            value2 = hndl2(0, y);
            testCase.verifyEqual(value2, 6.6 - 4.5, 'AbsTol', 1e-10, ...
                'TankMassTermCondition does not resolve tank #2 to y-vector index 2');
        end

        %% ------------------------------------------------------- Throttle

        function checkThrottle(testCase)
            [~, entry] = testCase.buildDefaultEntry();

            throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            throttleModel.setPolyTerms(0.42, 0, 0);
            entry.throttleModel = throttleModel;

            termCond = ThrottleTermCondition(0.5);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            tankStates = entry.getAllActiveTankStates();
            y = [entry.position(:); entry.velocity(:); [tankStates.tankMass]'];

            value = hndl(0, y);
            testCase.verifyEqual(value, 0.42 - 0.5, 'AbsTol', 1e-10, ...
                'ThrottleTermCondition value does not match constant-poly-throttle minus target');
        end

        %% --------------------------------- TotalVehicleEpsStateOfCharge

        function checkTotalVehicleEpsStateOfCharge(testCase)
            [~, entry] = testCase.buildEntryWithBattery();

            tankMassVal = 2.5;
            storageSoCVal = 9.75;
            y = [entry.position(:); entry.velocity(:); tankMassVal; storageSoCVal];

            termCond = TotalVehicleEpsStateOfChargeTermCondition(storageSoCVal + 4);
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            value = hndl(0, y);
            testCase.verifyEqual(value, -4, 'AbsTol', 1e-10, ...
                'TotalVehicleEpsStateOfChargeTermCondition value does not read the storage-SoC y-segment (possible index confusion with the tank-mass segment)');
        end

        %% ---------------------------------------------- Attitude family

        function checkAngleOfAttack(testCase)
            [angOfAttack, ~, ~, ~, ~, ~] = testCase.computeAttitudeAngles();
            target = angOfAttack - 0.08; %not wrapped by production code
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'AngleOfAttackTermCondition', ...
                @() AngleOfAttackTermCondition(target), angOfAttack - target, false);
        end

        function checkBankAngle(testCase)
            [~, bankAng, ~, ~, ~, ~] = testCase.computeAttitudeAngles();
            target = bankAng + 0.12;
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'BankAngleTermCondition', ...
                @() BankAngleTermCondition(target), bankAng - target, true);
        end

        function checkPitch(testCase)
            [~, ~, pitchAngle, ~, ~, ~] = testCase.computeAttitudeAngles();
            target = pitchAngle - 0.05;
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'PitchTermCondition', ...
                @() PitchTermCondition(target), pitchAngle - target, false);
        end

        function checkRoll(testCase)
            [~, ~, ~, rollAngle, ~, ~] = testCase.computeAttitudeAngles();
            target = rollAngle + 0.15;
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'RollTermCondition', ...
                @() RollTermCondition(target), rollAngle - target, true);
        end

        function checkSideSlipAngle(testCase)
            [~, ~, ~, ~, angOfSideslip, ~] = testCase.computeAttitudeAngles();
            target = angOfSideslip - 0.10;
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'SideSlipAngleTermCondition', ...
                @() SideSlipAngleTermCondition(target), angOfSideslip - target, true);
        end

        function checkYaw(testCase)
            [~, ~, ~, ~, ~, yawAngle] = testCase.computeAttitudeAngles();
            target = yawAngle + 0.20;
            testCase.runAttitudeCheck(@(hndl, y) hndl(0, y), 'YawTermCondition', ...
                @() YawTermCondition(target), yawAngle - target, true);
        end

        %% ----------------------------------------------- Shared fixtures

        function [lvdData, entry] = buildDefaultEntry(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [bodyInfo, r, v] = buildKeplerFixture(testCase)
            bodyInfo = testCase.kerbin;
            gmu = bodyInfo.gm;
            sma = 8000; ecc = 0.3; inc = 0.5; raan = 1.0; argp = 0.7; nu = 0.9;
            [r, v] = refCoe2Rv(sma, ecc, inc, raan, argp, nu, gmu);
        end

        function [entry, bodyInfo] = buildNonRotatingEntry(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;
            entry.centralBody = bodyInfo;
        end

        function [lvdData, entry, tank1, tank2] = buildEntryWithTwoTanks(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            stg.addTank(tank2);

            lvdData.initStateModel.clearAllTankStatesAndRegenerate();

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, battery] = buildEntryWithBattery(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);

            battery = LaunchVehicleBasicElectricalBattery(stg);
            battery.name = 'Test Battery';
            battery.maxCapacity = 100;
            battery.initialStateOfCharge = 37;
            stg.addPwrStorage(battery);

            stgState = lvdData.initStateModel.stageStates(1);
            newState = battery.createDefaultInitialState(stgState);
            stgState.addPowerStorageState(newState);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, sw] = buildEntryWithStopwatch(testCase, startOn, startValue)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw = LaunchVehicleStopwatch(lvdData);
            sw.startOn = startOn;
            sw.startValue = startValue;
            lvdData.launchVehicle.addStopwatch(sw);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [angOfAttack, bankAng, pitchAngle, rollAngle, angOfSideslip, yawAngle] = computeAttitudeAngles(testCase)
            %computeAttitudeAngles Independent oracle for all six attitude
            %term conditions, evaluated at the single shared fixture state
            %(non-rotating body, identity steering => bodyX/Y/Z = global
            %axes). computeWindFrame/computeNedFrame (generic navigation
            %infrastructure) are reused directly; the ZYX Euler-angle
            %extraction itself (the part that IS the logic under test) is
            %reimplemented from scratch in localZyxEuler, not via
            %rotm2eulARH.m.
            [~, ~, rVect, vVect] = testCase.attitudeFixtureState();

            Rwind = computeWindFrame(rVect, vVect); %non-rotating trick => ECEF==ECI
            eulWind = localZyxEuler(Rwind'); %R_vehicleBody_2_bodyInertial = eye(3)
            angOfSideslip = eulWind(1);
            angOfAttack = eulWind(2);
            bankAng = eulWind(3);

            Rned = computeNedFrame(0, rVect, testCase.attitudeFixtureBody());
            eulNed = localZyxEuler(Rned');
            yawAngle = eulNed(1);
            pitchAngle = eulNed(2);
            rollAngle = eulNed(3);
        end

        function [entry, bodyInfo, rVect, vVect] = attitudeFixtureState(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;
            entry.centralBody = bodyInfo;
            entry.steeringModel = TestIdentitySteeringModel();

            rVect = (bodyInfo.radius + 200) * normVector([0.4; 0.6; 0.7]);
            vVect = [0.6; -0.9; 0.3];
            entry.position = rVect; entry.velocity = vVect; entry.time = 0;
        end

        function bodyInfo = attitudeFixtureBody(testCase)
            [~, bodyInfo] = testCase.attitudeFixtureState();
        end

        function runAttitudeCheck(testCase, ~, name, termCondFactory, expectedValue, isWrapped)
            [entry, ~, rVect, vVect] = testCase.attitudeFixtureState();

            termCond = termCondFactory();
            termCond.initTermCondition(entry);
            hndl = termCond.getEventTermCondFuncHandle();

            [value, isterminal, direction] = hndl(0, [rVect; vVect]);

            if(isWrapped)
                testCase.verifyAngleEqual(value, expectedValue, 1e-6, ...
                    sprintf('%s value does not match the independent ZYX-Euler oracle (mod 2*pi)', name));
            else
                testCase.verifyEqual(value, expectedValue, 'AbsTol', 1e-6, ...
                    sprintf('%s value does not match the independent ZYX-Euler oracle', name));
            end
            testCase.verifyEqual(isterminal, 1);
            testCase.verifyEqual(direction, 0);
        end
    end
end

function eul = localZyxEuler(R)
    %localZyxEuler Independent from-scratch ZYX Euler-angle extraction.
    %
    % This is the textbook decomposition for R = Rz(eul1)*Ry(eul2)*Rx(eul3)
    % and is deliberately NOT derived from or cross-checked against
    % rotm2eulARH.m -- it exists so the six attitude term-condition tests
    % have an oracle that shares no code with the production Euler-angle
    % extraction path.
    eul = zeros(1, 3);
    eul(1) = atan2(R(2,1), R(1,1));
    eul(2) = atan2(-R(3,1), sqrt(R(1,1)^2 + R(2,1)^2));
    eul(3) = atan2(R(3,2), R(3,3));
end
