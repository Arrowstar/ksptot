classdef F2GraphicalAnalysisTest < KsptotTestCase
    %F2GraphicalAnalysisTest Additional Graphical Analysis quantities (F2).
    %
    % Covers the F2 task families against closed-form physics rather than
    % stored values:
    %   Group 1: specific orbital energy, specific angular momentum
    %            (magnitude + components), argument of latitude, true
    %            longitude, periapsis/apoapsis latitude and longitude.
    %   Group 2: sensed acceleration (total, axial, normal) in g from
    %            thrust + drag + lift.
    %   Group 3: remaining Delta-V capability, cumulative Delta-V expended
    %            (finite-burn + impulsive), per-engine thrust / Isp /
    %            mass flow rate.
    %   Group 4: ground-object range rate and elevation rate.
    %   Group 5: sun phase angle (vertex at the spacecraft) and downrange
    %            distance from a ground object.
    % Also checks task-list registration, ConstraintEnum entries,
    % ma_getConstraintStaticDetails units, and the GenericMAConstraint
    % evaluation path (including the cumulative history special case).
    %
    % F2 decisions under test: cumulative includes impulsive Delta-V with
    % per-event splits via StateComparison (no split tasks); sensed accel
    % sums thrust + drag + lift; downrange origin is a ground object; sun
    % phase vertex is the spacecraft; per-engine units are kN / s / mT/s
    % with thrust = 0 and mdot = 0 when the engine is off.

    properties(TestParameter)
        caseName = {'OrbitalQuantities', 'ApsisLatLon', 'InclinedComponents', ...
                    'SensedAccel', 'SensedAccelWithAero', ...
                    'RemainingAndPerEngine', 'PerEngineGating', ...
                    'CumulativeDeltaV', 'CumulativeStateComparison', ...
                    'GroundRatesAndDownrange', 'DefensiveBranches', ...
                    'SunPhaseAngle', 'Registration', 'ExampleMissionEndToEnd', ...
                    'ValladoExample25', 'ValladoSpecialCases', 'EccentricityVectorApsis'};
    end

    methods(Test)
        function f2MatchesRule(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)
        %% ---------------- Group 1 ----------------
        function checkOrbitalQuantities(testCase)
            [entry, frame] = testCase.circularEquatorialEntry(1300);
            mu = testCase.kerbin.gm;
            r = 1300;

            e = testCase.evalLvd(entry, 'Specific Orbital Energy', frame);
            testCase.verifyEqual(e, -mu/(2*r), 'RelTol', 1e-12, ...
                'Specific orbital energy must equal -mu/2r on a circular orbit.');

            h = testCase.evalLvd(entry, 'Specific Angular Momentum', frame);
            testCase.verifyEqual(h, sqrt(mu*r), 'RelTol', 1e-12, ...
                'Angular momentum magnitude must equal sqrt(mu*r) on a circular orbit.');

            hx = testCase.evalLvd(entry, 'Specific Angular Momentum (X)', frame);
            hy = testCase.evalLvd(entry, 'Specific Angular Momentum (Y)', frame);
            hz = testCase.evalLvd(entry, 'Specific Angular Momentum (Z)', frame);
            testCase.verifyVectorEqual([hx;hy;hz], [0;0;sqrt(mu*r)], 1e-9, ...
                'Angular momentum of the equatorial test orbit must point along +Z.');

            %Circular equatorial: converter convention puts raan = arg = 0,
            %so argument of latitude and true longitude both equal the
            %orbital longitude (here 0 deg, state on +X).
            u = testCase.evalLvd(entry, 'Argument of Latitude', frame);
            l = testCase.evalLvd(entry, 'True Longitude', frame);
            testCase.verifyEqual(u, 0, 'AbsTol', 1e-9, 'Argument of latitude must be 0 at +X on a circular equatorial orbit.');
            testCase.verifyEqual(l, 0, 'AbsTol', 1e-9, 'True longitude must be 0 at +X on a circular equatorial orbit.');

            %Eccentric spot check of energy (absolute, no Kepler elements).
            [entry2, ~] = testCase.circularEquatorialEntry(1300);
            entry2.velocity = entry2.velocity * 1.1;
            v2 = norm(entry2.velocity);
            e2 = testCase.evalLvd(entry2, 'Specific Orbital Energy', frame);
            testCase.verifyEqual(e2, 0.5*v2^2 - mu/r, 'RelTol', 1e-12, ...
                'Energy must equal v^2/2 - mu/r for a non-circular state.');
        end

        function checkApsisLatLon(testCase)
            mu = testCase.kerbin.gm;
            frame = testCase.kerbinFrame;

            %Eccentric equatorial orbit at periapsis on +X: apsis latitudes
            %are 0 by symmetry; longitudes are antipodal.  The periapsis
            %longitude is cross-checked through the fixed-frame transform
            %(independent of the perifocal construction under test).
            a = 1400; ecc = 0.2;
            rp = a*(1-ecc);
            vp = sqrt(mu*(2/rp - 1/a));
            [entry, ~] = testCase.orbitEntry([rp;0;0], [0;vp;0], 0);

            periLat = testCase.evalLvd(entry, 'Periapsis Latitude (North)', frame);
            apoLat = testCase.evalLvd(entry, 'Apoapsis Latitude (North)', frame);
            testCase.verifyEqual(periLat, 0, 'AbsTol', 1e-9, 'Periapsis latitude of an equatorial orbit must be 0.');
            testCase.verifyEqual(apoLat, 0, 'AbsTol', 1e-9, 'Apoapsis latitude of an equatorial orbit must be 0.');

            periLon = testCase.evalLvd(entry, 'Periapsis Longitude (East)', frame);
            apoLon = testCase.evalLvd(entry, 'Apoapsis Longitude (East)', frame);
            [~, expLon] = getLatLongAltFromInertialVect(entry.time, [rp;0;0], testCase.kerbin);
            testCase.verifyEqual(periLon, rad2deg(AngleZero2Pi(expLon)), 'AbsTol', 1e-9, ...
                'Periapsis longitude must match the fixed-frame longitude of the periapsis direction.');
            testCase.verifyEqual(abs(angleNegPiToPi(deg2rad(apoLon - periLon))), pi, 'AbsTol', 1e-9, ...
                'Apoapsis longitude must be antipodal to periapsis longitude.');

            %Polar orbit with periapsis over the north pole: latitude is
            %+90 regardless of body rotation, so no rotation API is needed.
            [entryP, ~] = testCase.orbitEntry([0;0;rp], [vp;0;0], 0);
            periLatP = testCase.evalLvd(entryP, 'Periapsis Latitude (North)', frame);
            testCase.verifyEqual(periLatP, 90, 'AbsTol', 1e-9, ...
                'Periapsis latitude must be +90 for a polar orbit with periapsis over the north pole.');
        end

        function checkInclinedComponents(testCase)
            %30-degree inclined circular orbit at argument of latitude 90:
            %off-axis momentum components plus wrapped angles, all absolute.
            mu = testCase.kerbin.gm;
            r = 1300;
            vc = sqrt(mu/r);
            ci = cosd(30); si = sind(30);
            [entry, ~] = testCase.orbitEntry([0; r*ci; r*si], [-vc; 0; 0], 0);
            frame = testCase.kerbinFrame;

            h = sqrt(mu*r);
            hx = testCase.evalLvd(entry, 'Specific Angular Momentum (X)', frame);
            hy = testCase.evalLvd(entry, 'Specific Angular Momentum (Y)', frame);
            hz = testCase.evalLvd(entry, 'Specific Angular Momentum (Z)', frame);
            testCase.verifyVectorEqual([hx;hy;hz], [0; -h*si; h*ci], 1e-9, ...
                'Momentum components must match r x v on the inclined orbit.');

            u = testCase.evalLvd(entry, 'Argument of Latitude', frame);
            l = testCase.evalLvd(entry, 'True Longitude', frame);
            testCase.verifyEqual(u, 90, 'AbsTol', 1e-9, ...
                'Argument of latitude must be 90 deg a quarter-turn past the node.');
            testCase.verifyEqual(l, 90, 'AbsTol', 1e-9, ...
                'True longitude must be 90 deg a quarter-turn past the node.');

            %Eccentric inclined orbit at periapsis: periapsis latitude is
            %asin(sin(inc)*sin(arg)) = asin(0.5*sin(90)) = 30 deg, a
            %rotation-proof absolute (longitude would need the spin phase).
            a = 1400; ecc = 0.2;
            rp = a*(1-ecc);
            vp = sqrt(mu*(2/rp - 1/a));
            [entryE, ~] = testCase.orbitEntry([0; rp*ci; rp*si], [-vp; 0; 0], 0);
            periLatE = testCase.evalLvd(entryE, 'Periapsis Latitude (North)', frame);
            testCase.verifyEqual(periLatE, 30, 'AbsTol', 1e-9, ...
                'Periapsis latitude must be 30 deg for inc 30 / arg 90.');
        end

        %% ---------------- Group 2 ----------------
        function checkSensedAccel(testCase)
            [lvdData, entry] = testCase.vacuumEntry();
            frame = testCase.kerbinFrame; %#ok<NASGU>

            %Coast: throttle model returns 0 and there is no atmosphere at
            %2400 km, so all three components are exactly 0.
            testCase.verifyEqual(lvd_SensedAccelTasks(entry, 'totalAccel'), 0, ...
                'Coast-arc sensed acceleration must be 0.');
            testCase.verifyEqual(lvd_SensedAccelTasks(entry, 'axialAccel'), 0, ...
                'Coast-arc axial sensed acceleration must be 0.');
            testCase.verifyEqual(lvd_SensedAccelTasks(entry, 'normalAccel'), 0, ...
                'Coast-arc normal sensed acceleration must be 0.');

            %Full burn: single engine on the body +X axis, so the normal
            %component vanishes and axial equals total.
            stg = lvdData.launchVehicle.stages(1);
            stg.engines(1).minThrottle = 1;
            m = entry.getTotalVehicleMass();
            [baseThrust, ~] = stg.engines(1).getThrustFlowRateForPressure(0);

            total = lvd_SensedAccelTasks(entry, 'totalAccel');
            axial = lvd_SensedAccelTasks(entry, 'axialAccel');
            normal = lvd_SensedAccelTasks(entry, 'normalAccel');

            expectedG = baseThrust/m/getG0(); %kN/mT = m/s^2 -> g
            testCase.verifyEqual(total, expectedG, 'RelTol', 1e-9, ...
                'Burn sensed acceleration must equal thrust/mass in g.');
            testCase.verifyEqual(axial, total, 'RelTol', 1e-12, ...
                'With one engine on the body X axis, axial must equal total.');
            testCase.verifyEqual(normal, 0, 'AbsTol', 1e-9, ...
                'With one engine on the body X axis, normal must vanish.');
            testCase.verifyEqual(total^2, axial^2 + normal^2, 'RelTol', 1e-12, ...
                'Total/axial/normal must satisfy the Pythagorean identity.');
        end

        function checkSensedAccelWithAero(testCase)
            %Decision 2 is thrust + drag + lift: check the aero summation
            %against direct force-model calls at 10 km altitude, engine on
            %and off.  The models themselves are covered by ForceModelTest;
            %what is under test is the wiring (frames, mass division, g).
            [lvdData, entry] = testCase.atmoEntry();
            engine = lvdData.launchVehicle.stages(1).engines(1);

            engine.minThrottle = 0; %coast: thrust 0, aero only
            expGcoast = testCase.directSensedAccelG(entry);
            coastTotal = lvd_SensedAccelTasks(entry, 'totalAccel');
            testCase.verifyGreaterThan(coastTotal, 1e-6, ...
                'Coast drag at 10 km and 1 km/s must be clearly nonzero (else this test is vacuous).');
            testCase.verifyEqual(coastTotal, norm(expGcoast), 'RelTol', 1e-9, ...
                'Coast sensed acceleration must equal |drag + lift| / m.');

            engine.minThrottle = 1; %burn: thrust + aero
            expGburn = testCase.directSensedAccelG(entry);
            burnTotal = lvd_SensedAccelTasks(entry, 'totalAccel');
            burnAxial = lvd_SensedAccelTasks(entry, 'axialAccel');
            burnNormal = lvd_SensedAccelTasks(entry, 'normalAccel');
            testCase.verifyEqual(burnTotal, norm(expGburn), 'RelTol', 1e-9, ...
                'Burn sensed acceleration must equal |thrust + drag + lift| / m.');
            attState = entry.attitude;
            bodyXHat = attState.bodyX(:) / norm(attState.bodyX(:));
            testCase.verifyEqual(burnAxial, dot(expGburn, bodyXHat), 'RelTol', 1e-9, ...
                'Axial sensed acceleration must be the body-X projection of the summed vector.');
            testCase.verifyEqual(burnNormal, norm(expGburn - dot(expGburn, bodyXHat)*bodyXHat), 'RelTol', 1e-9, ...
                'Normal sensed acceleration must be the off-axis remainder of the summed vector.');
        end

        %% ---------------- Group 3 ----------------
        function checkRemainingAndPerEngine(testCase)
            [lvdData, entry] = testCase.vacuumEntry();
            frame = testCase.kerbinFrame;
            stg = lvdData.launchVehicle.stages(1);
            engine = stg.engines(1);
            engine.minThrottle = 1;

            press = getPressureAtAltitude(testCase.kerbin, norm(entry.position) - testCase.kerbin.radius);
            [~, isp] = engine.getThrustIspForPressure(press);
            mWet = entry.getTotalVehicleMass();
            mDry = entry.getTotalVehicleDryMass();
            expectedRem = (getG0()*isp*log(mWet/mDry))/1000;

            rem = testCase.evalLvd(entry, 'Remaining Delta-V Capability', frame);
            testCase.verifyEqual(rem, expectedRem, 'RelTol', 1e-9, ...
                'Remaining Delta-V must follow the rocket equation on active-engine Isp.');

            %Drained tanks: wet mass equals dry mass, capability is 0 even
            %though the engine is still flagged active.
            entryDrained = entry.deepCopy();
            ts = entryDrained.getAllActiveTankStates();
            for(i=1:length(ts))
                ts(i).tankMass = 0;
            end
            remDrained = testCase.evalLvd(entryDrained, 'Remaining Delta-V Capability', frame);
            testCase.verifyEqual(remDrained, 0, ...
                'Remaining Delta-V with empty tanks must be 0.');

            %Per-engine quantities on the burn entry.
            [thrust, ~] = lvd_EngineTasks(entry, 'thrust', engine);
            [mdot, ~] = lvd_EngineTasks(entry, 'mdot', engine);
            [ispEng, ~] = lvd_EngineTasks(entry, 'isp', engine);
            testCase.verifyEqual(ispEng, isp, 'RelTol', 1e-12, 'Per-engine Isp must be the pressure-curve value.');
            [baseThrust, baseMdot] = engine.getThrustFlowRateForPressure(press);
            %Full tanks: fuel curve evaluates to 1 (fixture), throttle is
            %clamped to 1 by minThrottle, so thrust/mdot equal base values.
            testCase.verifyEqual(thrust, baseThrust, 'RelTol', 1e-9, 'Per-engine thrust must equal base thrust at full throttle.');
            testCase.verifyEqual(mdot, baseMdot, 'RelTol', 1e-9, 'Per-engine mdot must equal base mdot at full throttle.');
            testCase.verifyLessThan(mdot, 0, 'Burning mass flow must be negative (outflow convention, matching tank mdot).');

            %Engine off: thrust and mdot are 0, Isp stays defined.
            engStates = entry.getAllEngineStates();
            engStates(1).active = false;
            [thrustOff, ~] = lvd_EngineTasks(entry, 'thrust', engine);
            [mdotOff, ~] = lvd_EngineTasks(entry, 'mdot', engine);
            [ispOff, ~] = lvd_EngineTasks(entry, 'isp', engine);
            testCase.verifyEqual(thrustOff, 0, 'Thrust of an inactive engine must be 0.');
            testCase.verifyEqual(mdotOff, 0, 'Mass flow of an inactive engine must be 0.');
            testCase.verifyEqual(ispOff, isp, 'RelTol', 1e-12, 'Isp of an inactive engine stays at the pressure-curve value.');

            %Dispatcher routing for the per-engine families.
            engStates(1).active = true;
            [engStrs, ~] = lvdData.launchVehicle.getEnginesGraphAnalysisTaskStrs();
            [thrustDisp, thrustUnit] = lvd_getDepVarValueUnit(1, entry, engStrs{2}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(thrustDisp, thrust, 'RelTol', 1e-12, 'Engine-thrust dispatcher routing is broken.');
            testCase.verifyEqual(thrustUnit, 'kN');
            [ispDisp, ispUnit] = lvd_getDepVarValueUnit(1, entry, engStrs{3}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(ispDisp, isp, 'RelTol', 1e-12, 'Engine-Isp dispatcher routing is broken.');
            testCase.verifyEqual(ispUnit, 'sec');
            [mdotDisp, mdotUnit] = lvd_getDepVarValueUnit(1, entry, engStrs{4}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(mdotDisp, mdot, 'RelTol', 1e-12, 'Engine-mdot dispatcher routing is broken.');
            testCase.verifyEqual(mdotUnit, 'mT/s');
        end

        function checkPerEngineGating(testCase)
            %Every off-path in the per-engine evaluation: drained tanks,
            %EC-dependent engine with no charge available, and the
            %two-engine consistency between per-engine and total paths.
            frame = testCase.kerbinFrame;

            %Drained tanks: engine flagged active and throttle commanded,
            %but no propellant to burn.
            [lvdData, entry] = testCase.vacuumEntry();
            engine = lvdData.launchVehicle.stages(1).engines(1);
            engine.minThrottle = 1;
            ts = entry.getAllActiveTankStates();
            for(i=1:length(ts))
                ts(i).tankMass = 0;
            end
            [tDry, ~] = lvd_EngineTasks(entry, 'thrust', engine);
            [mDry, ~] = lvd_EngineTasks(entry, 'mdot', engine);
            [iDry, ~] = lvd_EngineTasks(entry, 'isp', engine);
            testCase.verifyEqual(tDry, 0, 'Thrust with empty tanks must be 0.');
            testCase.verifyEqual(mDry, 0, 'Mass flow with empty tanks must be 0.');
            testCase.verifyGreaterThan(iDry, 0, 'Isp stays defined with empty tanks.');

            %EC-dependent engine on a vehicle with no power storage at all.
            [lvdDataEC, entryEC] = testCase.vacuumEntry();
            testCase.assertEmpty(entryEC.getAllActivePwrStorageStates(), ...
                'Fixture: the stock vehicle must carry no power storage.');
            engineEC = lvdDataEC.launchVehicle.stages(1).engines(1);
            engineEC.minThrottle = 1;
            engineEC.reqsElecCharge = true;
            [tEC, ~] = lvd_EngineTasks(entryEC, 'thrust', engineEC);
            [mEC, ~] = lvd_EngineTasks(entryEC, 'mdot', engineEC);
            testCase.verifyEqual(tEC, 0, 'Thrust with no EC available must be 0.');
            testCase.verifyEqual(mEC, 0, 'Mass flow with no EC available must be 0.');

            %Two engines: per-engine parts must add up to the total path,
            %and the second engine resolves through the dispatcher by number.
            %The entry is (re)built after the vehicle edit so its engine
            %states include the new engine.
            [lvdData2, ~] = testCase.vacuumEntry();
            stg2 = lvdData2.launchVehicle.stages(1);
            eng1 = stg2.engines(1);
            eng1.minThrottle = 1;
            eng2 = LaunchVehicleEngine(stg2);
            eng2.name = 'Second Engine';
            eng2.minThrottle = 1;
            eng2.thrustPressCurve = eng1.thrustPressCurve.copy();
            eng2.ispPressCurve = eng1.ispPressCurve.copy();
            eng2.fuelThrottleCurve = eng1.fuelThrottleCurve.copy();
            stg2.addEngine(eng2);
            lvdData2.launchVehicle.addEngineToTankConnection(EngineToTankConnection(stg2.tanks(1), eng2));
            entry2 = lvdData2.initStateModel.getInitialStateLogEntry();
            entry2.position = [0; 0; testCase.kerbin.radius + 2400];
            entry2.velocity = [1; 0; 0];
            entry2.event = lvdData2.script.getEventForInd(1); %Total Thrust requires a thrust-capable event

            [t1, ~] = lvd_EngineTasks(entry2, 'thrust', eng1);
            [t2, ~] = lvd_EngineTasks(entry2, 'thrust', eng2);
            total = lvd_ThrottleTask(entry2, 'totalthrust', frame);
            testCase.verifyEqual(t1 + t2, total, 'RelTol', 1e-12, ...
                'Per-engine thrusts must sum to the total-thrust path.');

            [engStrs2, ~] = lvdData2.launchVehicle.getEnginesGraphAnalysisTaskStrs();
            testCase.assertNumElements(engStrs2, 8, 'Two engines must yield eight GA strings.');
            testCase.verifyTrue(startsWith(engStrs2{4}, 'Engine 2 Thrust'), ...
                'Second-engine thrust string must carry engine number 2.');
            [t2Disp, ~] = lvd_getDepVarValueUnit(1, entry2, engStrs2{4}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(t2Disp, t2, 'RelTol', 1e-12, ...
                'Second-engine thrust must resolve through the dispatcher.');
        end

        function checkCumulativeDeltaV(testCase)
            %Three-entry log: finite burn step (mass drops, dt > 0) then an
            %impulsive velocity jump at fixed time.
            [lvdData, e1] = testCase.vacuumEntry();
            lvdData.launchVehicle.stages(1).engines(1).minThrottle = 1;
            evt = lvdData.script.getEventForInd(1);

            e1.time = 100;
            e1.event = evt;

            e2 = e1.deepCopy();
            e2.time = 110;
            e2.event = evt;
            ts2 = e2.getAllActiveTankStates();
            ts2(1).tankMass = ts2(1).tankMass - 0.5;

            dvImp = [0.05; 0.02; 0];
            e3 = e2.deepCopy();
            e3.event = evt; %same time as e2: impulsive pair
            e3.velocity = e3.velocity + dvImp;

            entries = [e1, e2, e3];

            %Expected finite part from the same mass-flow evaluation the
            %task uses (throttle model value 0, clamped per-engine by
            %minThrottle = 1 exactly as in the implementation).
            ts1 = e1.getAllActiveTankStates();
            masses1 = [ts1.tankMass]';
            pwrStates = e1.getAllActivePwrStorageStates();
            socs = zeros(1, numel(pwrStates));
            press = getPressureAtAltitude(testCase.kerbin, norm(e1.position) - testCase.kerbin.radius);
            att = e1.attitude;
            [tankMDots, totalThrust, ~] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines( ...
                ts1, masses1, e1.stageStates, 0, e1.lvState, press, ...
                e1.time, e1.position, e1.velocity, testCase.kerbin, ...
                e1.steeringModel, socs, pwrStates, att);
            effIsp = (totalThrust*1000) / (getG0()*abs(sum(tankMDots)*1000));
            dry = e1.getTotalVehicleDryMass();
            m1 = dry + e1.getTotalVehiclePropMass();
            m2 = dry + e2.getTotalVehiclePropMass();
            finiteExp = (getG0()*effIsp*log(m1/m2))/1000;
            impExp = norm(dvImp);

            frame = testCase.kerbinFrame;
            refId = [];
            [v1, u1] = lvd_getDepVarValueUnit(1, entries, 'Cumulative Delta-V Expended', refId, testCase.celBodyData, false, frame);
            [v2, ~] = lvd_getDepVarValueUnit(2, entries, 'Cumulative Delta-V Expended', refId, testCase.celBodyData, false, frame);
            [v3, ~] = lvd_getDepVarValueUnit(3, entries, 'Cumulative Delta-V Expended', refId, testCase.celBodyData, false, frame);

            testCase.verifyEqual(v1, 0, 'Cumulative Delta-V at the first entry must be 0.');
            testCase.verifyEqual(u1, 'km/s', 'Cumulative Delta-V unit must be km/s.');
            testCase.verifyEqual(v2, finiteExp, 'RelTol', 1e-9, ...
                'Cumulative Delta-V after the burn step must equal the finite-burn increment.');
            testCase.verifyEqual(v3, finiteExp + impExp, 'RelTol', 1e-9, ...
                'Cumulative Delta-V must add the impulsive jump (F2: impulsive included).');

            %Staging guard: a dry-mass change across a forward step is a
            %jettison, not propulsion, and must not count.
            e4 = e3.deepCopy();
            e4.time = 120;
            e4.event = evt;
            e4.stageStates(1).active = false;
            entries4 = [entries, e4];
            [v4, ~] = lvd_getDepVarValueUnit(4, entries4, 'Cumulative Delta-V Expended', refId, testCase.celBodyData, false, frame);
            testCase.verifyEqual(v4, v3, 'RelTol', 1e-12, ...
                'A stage jettison (dry-mass change) must not add Delta-V.');

            %Constraint path: value at the final node integrates the whole log.
            stateLog = LaunchVehicleStateLog(lvdData);
            stateLog.appendStateLogEntries(entries4);
            con = GenericMAConstraint('Cumulative Delta-V Expended', evt, 0, 5, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = con.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, v3, 'RelTol', 1e-9, ...
                'GenericMAConstraint on cumulative Delta-V must integrate to the final node.');
        end

        function checkCumulativeStateComparison(testCase)
            %The two history-dependent constraint branches the FinalState
            %check above does not reach: the InitialState node and the
            %StateComparison second value.  Plus the executeTask history
            %contract (plots/sweeps/overlays pass the array; lone entries
            %report 0).
            [lvdData, e1] = testCase.vacuumEntry();
            lvdData.launchVehicle.stages(1).engines(1).minThrottle = 1;
            evt = lvdData.script.getEventForInd(1);

            e1.time = 100;
            e1.event = evt;
            e2 = e1.deepCopy();
            e2.time = 110;
            e2.event = evt;
            ts2 = e2.getAllActiveTankStates();
            ts2(1).tankMass = ts2(1).tankMass - 0.5;
            entries = [e1, e2];

            stateLog = LaunchVehicleStateLog(lvdData);
            stateLog.appendStateLogEntries(entries);
            emptyBody = KSPTOT_BodyInfo.empty(1,0);

            conInit = GenericMAConstraint('Cumulative Delta-V Expended', evt, 0, 5, [], [], emptyBody);
            conInit.eventNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, valueInit] = conInit.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(valueInit, 0, 'AbsTol', 1e-12, ...
                'Cumulative Delta-V at the initial node must be 0.');

            conSC = GenericMAConstraint('Cumulative Delta-V Expended', evt, 0, 5, [], [], emptyBody);
            conSC.evalType = ConstraintEvalTypeEnum.StateComparison;
            conSC.stateCompEvent = evt;
            conSC.stateCompNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, valueF, ~, ~, ~, ~, valueSC] = conSC.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyGreaterThan(valueF, 0, ...
                'Cumulative Delta-V at the final node must be positive after a burn step.');
            testCase.verifyEqual(valueSC, 0, 'AbsTol', 1e-12, ...
                'StateComparison second value at the initial node must be 0.');

            %History contract of GraphicalAnalysisTask.executeTask.
            frame = testCase.kerbinFrame;
            task = GraphicalAnalysisTask('Cumulative Delta-V Expended', frame);
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            [vHist, uHist] = task.executeTask(e2, maTaskList, 0, [], [], propNames, ...
                testCase.celBodyData, entries, 2);
            testCase.verifyEqual(vHist, valueF, 'RelTol', 1e-12, ...
                'executeTask with history must match the constraint-path value.');
            testCase.verifyEqual(uHist, 'km/s');
            [vSingle, ~] = task.executeTask(e2, maTaskList, 0, [], [], propNames, testCase.celBodyData);
            testCase.verifyEqual(vSingle, 0, ...
                'executeTask without history (action conditionals during propagation) reports 0 by design.');
        end

        %% ---------------- Groups 4 + 5 ----------------
        function checkGroundRatesAndDownrange(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.assertEqual(lvdData.groundObjs.getNumGroundObj(), 1, 'Fixture: default LVD must carry one ground object.');
            grdObj = lvdData.groundObjs.getGroundObjAtInd(1);
            testCase.assertTrue(grdObj.centralBodyInfo == testCase.kerbin, 'Fixture: default ground object must be on Kerbin.');

            entry = lvdData.initStateModel.getInitialStateLogEntry();
            t = 0;
            entry.time = t;
            R = testCase.kerbin.radius;

            %S/C 500 km east and 500 km up from the station (NED offsets).
            stnInert = testCase.stationInertial(grdObj, t);
            Rn2i = computeNedFrame(t, stnInert, testCase.kerbin);
            rhoNed = [0; 500; -500];
            entry.position = stnInert + Rn2i*rhoNed;
            stnVel = testCase.stationVelFD(grdObj, t);
            vCirc = sqrt(testCase.kerbin.gm/norm(entry.position));
            entry.velocity = Rn2i*[0; vCirc; 0] + stnVel;

            frame = testCase.kerbinFrame;
            rRate = lvd_GrdObjTasks(entry, 'rangeRate', grdObj, frame);
            eRate = lvd_GrdObjTasks(entry, 'elevRate', grdObj, frame);

            %Independent check: central difference of the trusted range /
            %elevation tasks over linearly advanced copies (dt = 0.5 s).
            dt = 0.5;
            eP = entry.deepCopy(); eP.time = t+dt; eP.position = entry.position + entry.velocity*dt;
            eM = entry.deepCopy(); eM.time = t-dt; eM.position = entry.position - entry.velocity*dt;
            [rP, ~] = lvd_GrdObjTasks(eP, 'range', grdObj, frame);
            [rM, ~] = lvd_GrdObjTasks(eM, 'range', grdObj, frame);
            [eP2, ~] = lvd_GrdObjTasks(eP, 'elevation', grdObj, frame);
            [eM2, ~] = lvd_GrdObjTasks(eM, 'elevation', grdObj, frame);

            testCase.verifyEqual(rRate, (rP-rM)/(2*dt), 'AbsTol', 1e-3, ...
                'Range rate must match the finite difference of range.');
            testCase.verifyEqual(eRate, (eP2-eM2)/(2*dt), 'AbsTol', 1e-3, ...
                'Elevation rate must match the finite difference of elevation.');

            %Downrange absolutes: overhead is 0, antipode is pi*R.
            entryOver = entry.deepCopy();
            entryOver.position = stnInert * ((R+500)/R);
            drOver = lvd_GrdObjTasks(entryOver, 'downrange', grdObj, frame);
            testCase.verifyEqual(drOver, 0, 'AbsTol', 1e-6, ...
                'Downrange directly above the station must be 0.');

            entryAnti = entry.deepCopy();
            entryAnti.position = -stnInert * ((R+500)/R);
            drAnti = lvd_GrdObjTasks(entryAnti, 'downrange', grdObj, frame);
            testCase.verifyEqual(drAnti, pi*R, 'RelTol', 1e-6, ...
                'Downrange at the antipode must equal half the circumference.');

            %General geometry cross-check through the fixed-frame transform.
            [scLat, scLon] = getLatLongAltFromInertialVect(t, entry.position, testCase.kerbin, entry.velocity);
            stnGeo = grdObj.getStateAtTime(t);
            drExp = distance(scLat, scLon, stnGeo.lat, stnGeo.long, 'radians') * R;
            dr = lvd_GrdObjTasks(entry, 'downrange', grdObj, frame);
            testCase.verifyEqual(dr, drExp, 'RelTol', 1e-12, ...
                'Downrange must equal the great-circle distance to the station.');

            %Dispatcher routing for the dynamic families (regex + index mapping).
            [rrStrs, ~] = lvdData.groundObjs.getGrdObjRangeRateGraphAnalysisTaskStrs();            [rrDisp, rrUnit] = lvd_getDepVarValueUnit(1, entry, rrStrs{1}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(rrDisp, rRate, 'RelTol', 1e-12, 'Range-rate dispatcher routing is broken.');
            testCase.verifyEqual(rrUnit, 'km/s');
            [erStrs, ~] = lvdData.groundObjs.getGrdObjElevRateGraphAnalysisTaskStrs();
            [erDisp, erUnit] = lvd_getDepVarValueUnit(1, entry, erStrs{1}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(erDisp, eRate, 'RelTol', 1e-12, 'Elevation-rate dispatcher routing is broken.');
            testCase.verifyEqual(erUnit, 'deg/s');
            [drStrs, ~] = lvdData.groundObjs.getGrdObjDownrangeGraphAnalysisTaskStrs();
            [drDisp, drUnit] = lvd_getDepVarValueUnit(1, entry, drStrs{1}, [], testCase.celBodyData, false, frame);
            testCase.verifyEqual(drDisp, dr, 'RelTol', 1e-12, 'Downrange dispatcher routing is broken.');
            testCase.verifyEqual(drUnit, 'km');
        end

        function checkDefensiveBranches(testCase)
            %Guard branches that must return NaN or stay finite instead of
            %erroring: downrange across central bodies, and the zenith
            %singularity (h = 0) in the elevation-rate chain rule.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            grdObj = lvdData.groundObjs.getGroundObjAtInd(1);
            testCase.assertTrue(grdObj.centralBodyInfo == testCase.kerbin, ...
                'Fixture: default ground object must be on Kerbin.');
            frame = testCase.kerbinFrame;

            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.centralBody = testCase.mun;
            drX = lvd_GrdObjTasks(entry, 'downrange', grdObj, frame);
            testCase.verifyTrue(isnan(drX), ...
                'Downrange for a station on another body must be NaN.');

            entry2 = lvdData.initStateModel.getInitialStateLogEntry();
            entry2.time = 0;
            stnInert = testCase.stationInertial(grdObj, 0);
            R = testCase.kerbin.radius;
            entry2.position = stnInert * ((R+500)/R); %directly overhead: h = 0
            entry2.velocity = [0; 2; 0];
            erZen = lvd_GrdObjTasks(entry2, 'elevRate', grdObj, frame);
            testCase.verifyTrue(isfinite(erZen), ...
                'Elevation rate at the zenith must stay finite (h = 0 guard).');
        end

        function checkSunPhaseAngle(testCase)
            [lvdData, entry] = testCase.vacuumEntry(); %#ok<ASGLU>
            ut = 1000;
            entry.time = ut;

            %Sun direction in the Kerbin inertial frame (rotation pattern
            %shared with the SRP force model; the 0/180 deg assertions below
            %are nevertheless absolute geometric checks).
            bodyWrtSun = getPositOfBodyWRTSun(ut, testCase.kerbin, testCase.celBodyData);
            sunif = testCase.celBodyData.getTopLevelBody().getBodyCenteredInertialFrame();
            bci = testCase.kerbin.getBodyCenteredInertialFrame();
            R_sun_to_global = sunif.getRotMatToInertialAtTime(ut,[],[]);
            R_bci_to_global = bci.getRotMatToInertialAtTime(ut,[],[]);
            R_sun_to_bci = R_bci_to_global' * R_sun_to_global;
            toSunBci = R_sun_to_bci * (-bodyWrtSun(:)/norm(bodyWrtSun));

            d = 1000; %km from Kerbin center (parallax to the Sun ~1e-4 rad)
            entryNoon = entry.deepCopy();
            entryNoon.position = d*toSunBci; %between Sun and planet: fully lit face
            entryMid = entry.deepCopy();
            entryMid.position = -d*toSunBci; %anti-sun side: Sun behind planet

            [pNoon, uNoon] = lvd_SunTasks(entryNoon, 'sunPhaseAngle', testCase.celBodyData);
            [pMid, ~] = lvd_SunTasks(entryMid, 'sunPhaseAngle', testCase.celBodyData);

            testCase.verifyEqual(uNoon, 'deg', 'Sun phase angle unit must be deg.');
            testCase.verifyEqual(pNoon, 180, 'AbsTol', 0.05, ...
                'Sun phase angle on the noon side (vertex at S/C) must be 180 deg.');
            testCase.verifyEqual(pMid, 0, 'AbsTol', 0.05, ...
                'Sun phase angle on the midnight side (vertex at S/C) must be 0 deg.');
        end

        %% ---------------- registration ----------------
        function checkRegistration(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            taskList = lvd_getGraphAnalysisTaskList(lvdData, {});

            fixedTasks = {'Specific Orbital Energy', 'Specific Angular Momentum', ...
                'Specific Angular Momentum (X)', 'Specific Angular Momentum (Y)', ...
                'Specific Angular Momentum (Z)', 'Argument of Latitude', ...
                'True Longitude', 'Periapsis Latitude (North)', ...
                'Periapsis Longitude (East)', 'Apoapsis Latitude (North)', ...
                'Apoapsis Longitude (East)', 'Sensed Acceleration (Total)', ...
                'Sensed Acceleration (Axial)', 'Sensed Acceleration (Normal)', ...
                'Remaining Delta-V Capability', 'Cumulative Delta-V Expended', ...
                'Sun Phase Angle'};
            for(i=1:length(fixedTasks)) %#ok<NO4LP>
                testCase.verifyTrue(ismember(fixedTasks{i}, taskList), ...
                    sprintf('Task list must contain "%s".', fixedTasks{i}));
            end

            testCase.verifyTrue(any(startsWith(taskList, 'Engine 1 Thrust - "')), ...
                'Task list must contain the per-engine thrust family.');
            testCase.verifyTrue(any(startsWith(taskList, 'Engine 1 Isp - "')), ...
                'Task list must contain the per-engine Isp family.');
            testCase.verifyTrue(any(startsWith(taskList, 'Engine 1 Mass Flow Rate - "')), ...
                'Task list must contain the per-engine mass-flow family.');
            testCase.verifyTrue(any(startsWith(taskList, 'Ground Object 1 Range Rate to S/C - "')), ...
                'Task list must contain the ground-object range-rate family.');
            testCase.verifyTrue(any(startsWith(taskList, 'Ground Object 1 Elevation Rate to S/C - "')), ...
                'Task list must contain the ground-object elevation-rate family.');
            testCase.verifyTrue(any(startsWith(taskList, 'Ground Object 1 Downrange Distance - "')), ...
                'Task list must contain the ground-object downrange family.');

            %ConstraintEnum + static details for every constrainable fixed type.
            typeToUnit = {'Specific Orbital Energy', 'km^2/s^2'; ...
                'Specific Angular Momentum', 'km^2/s'; ...
                'Argument of Latitude', 'deg'; ...
                'True Longitude', 'deg'; ...
                'Periapsis Latitude (North)', 'deg'; ...
                'Periapsis Longitude (East)', 'deg'; ...
                'Apoapsis Latitude (North)', 'deg'; ...
                'Apoapsis Longitude (East)', 'deg'; ...
                'Sensed Acceleration (Total)', 'g'; ...
                'Sensed Acceleration (Axial)', 'g'; ...
                'Sensed Acceleration (Normal)', 'g'; ...
                'Remaining Delta-V Capability', 'km/s'; ...
                'Cumulative Delta-V Expended', 'km/s'; ...
                'Sun Phase Angle', 'deg'};
            for(i=1:size(typeToUnit,1)) %#ok<NO4LP>
                [ind, ~] = ConstraintEnum.getIndForName(typeToUnit{i,1});
                testCase.verifyNotEmpty(ind, ...
                    sprintf('ConstraintEnum must offer "%s".', typeToUnit{i,1}));
                [unit, ~, ~, ~, ~, ~, ~, usesLbUb] = ma_getConstraintStaticDetails(typeToUnit{i,1});
                testCase.verifyEqual(unit, typeToUnit{i,2}, ...
                    sprintf('Static-details unit mismatch for "%s".', typeToUnit{i,1}));
                testCase.verifyTrue(usesLbUb, ...
                    sprintf('"%s" must use lower/upper bounds.', typeToUnit{i,1}));
            end

            %Every constrainable fixed type evaluates through
            %GenericMAConstraint without error on a real entry.
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            evt = lvdData.script.getEventForInd(1);
            entry.event = evt;
            stateLog = LaunchVehicleStateLog(lvdData);
            stateLog.appendStateLogEntries(entry);
            for(i=1:size(typeToUnit,1)) %#ok<NO4LP>
                con = GenericMAConstraint(typeToUnit{i,1}, evt, 0, 1, [], [], KSPTOT_BodyInfo.empty(1,0));
                try
                    con.evalConstraint(stateLog, testCase.celBodyData);
                catch ME
                    testCase.verifyFail(sprintf('Constraint "%s" failed to evaluate: %s', typeToUnit{i,1}, ME.message));
                end
            end
        end

        %% ---------------- published truth: Vallado + e-vector ----------------
        function checkValladoExample25(testCase)
            %Vallado, Fundamentals of Astrodynamics and Applications,
            %Algorithm 9 / Example 2-5.  Inputs are Vallado's published
            %test vector (companion file ex2_5.m); expected elements come
            %from an independent transcription of his published rv2coe
            %branch logic (h/n/e vectors), NOT from getKeplerFromState.
            %The apsis check goes through yet a third path: the raw
            %eccentricity vector, which uses no orbital elements at all.
            muE = 398600.4418; %Vallado constastro Earth mu, km^3/s^2
            rV = [6524.834; 6862.875; 6448.296];
            vV = [4.901327; 5.533756; -1.976341];
            [entry, frame, ~] = testCase.earthMuEntry(rV, vV, muE);

            ref = testCase.valladoRv2coe(rV, vV, muE);
            testCase.assertEqual(ref.type, 'ei', 'Fixture: Example 2-5 must be inclined-eccentric.');

            testCase.verifyEqual(testCase.evalLvd(entry, 'Semi-major Axis', frame), ref.a, 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: semi-major axis.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Eccentricity', frame), ref.ecc, 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: eccentricity.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Inclination', frame), rad2deg(ref.incl), 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: inclination.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Right Asc. of the Asc. Node', frame), rad2deg(ref.omega), 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: RAAN.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Argument of Periapsis', frame), rad2deg(ref.argp), 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: argument of periapsis.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'True Anomaly', frame), rad2deg(ref.nu), 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: true anomaly.');

            %F2 layer: sums and wrapping of the reference elements.
            testCase.verifyEqual(testCase.evalLvd(entry, 'Specific Orbital Energy', frame), ref.sme, 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: specific orbital energy.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Specific Angular Momentum', frame), ref.magh, 'RelTol', 1e-9, ...
                'Vallado Ex 2-5: angular momentum magnitude.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Argument of Latitude', frame), ...
                testCase.wrap360(rad2deg(ref.argp + ref.nu)), 'AbsTol', 1e-6, ...
                'Vallado Ex 2-5: argument of latitude.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'True Longitude', frame), ...
                testCase.wrap360(rad2deg(ref.omega + ref.argp + ref.nu)), 'AbsTol', 1e-6, ...
                'Vallado Ex 2-5: true longitude.');

            %Apsis via the eccentricity vector (no elements anywhere).
            [periLatE, periLonE] = testCase.evecLatLon(rV, vV, muE, entry.centralBody, +1);
            [apoLatE, apoLonE] = testCase.evecLatLon(rV, vV, muE, entry.centralBody, -1);
            testCase.verifyEqual(testCase.evalLvd(entry, 'Periapsis Latitude (North)', frame), periLatE, 'AbsTol', 1e-6, ...
                'Vallado Ex 2-5: periapsis latitude from the e-vector.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Periapsis Longitude (East)', frame), periLonE, 'AbsTol', 1e-6, ...
                'Vallado Ex 2-5: periapsis longitude from the e-vector.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Apoapsis Latitude (North)', frame), apoLatE, 'AbsTol', 1e-6, ...
                'Vallado Ex 2-5: apoapsis latitude from the e-vector.');
            testCase.verifyAngleEqualDeg( ...
                testCase.evalLvd(entry, 'Apoapsis Longitude (East)', frame), apoLonE, 1e-6, ...
                'Vallado Ex 2-5: apoapsis longitude from the e-vector.');
        end

        function checkValladoSpecialCases(testCase)
            %Exact-angle constructions from Vallado's ex2_5.m stress cases:
            %circular-inclined u = 45 deg, elliptical-equatorial w = 20 deg,
            %circular-equatorial l = 65 deg (prograde and retrograde).  The
            %expected angles hold by construction of the input vectors.
            muE = 398600.4418;

            [entryCI, frameCI, ~] = testCase.earthMuEntry( ...
                [-2693.34555010128; 6428.43425355863; 4491.37782050409], ...
                [-3.95484712246016; -4.28096585381370; 3.75567104538731], muE);
            testCase.verifyEqual(testCase.evalLvd(entryCI, 'Argument of Latitude', frameCI), 45, 'AbsTol', 1e-6, ...
                'Circular inclined u = 45 deg construction must read 45 deg.');

            [entryEE, frameEE, ~] = testCase.earthMuEntry( ...
                [-22739.1086596208; -22739.1086596208; 0.0], ...
                [2.48514004188565; -2.02004112073465; 0.0], muE);
            testCase.verifyEqual(testCase.evalLvd(entryEE, 'Argument of Periapsis', frameEE), 20, 'AbsTol', 1e-6, ...
                'Elliptical equatorial w = 20 deg construction must read 20 deg.');
            refEE = testCase.valladoRv2coe(entryEE.position, entryEE.velocity, muE);
            testCase.verifyEqual(testCase.evalLvd(entryEE, 'True Anomaly', frameEE), rad2deg(refEE.nu), 'AbsTol', 1e-6, ...
                'True anomaly against the transcribed reference (EE case).');
            testCase.verifyEqual(testCase.evalLvd(entryEE, 'True Longitude', frameEE), ...
                testCase.wrap360(rad2deg(refEE.lonper + refEE.nu)), 'AbsTol', 1e-6, ...
                'True longitude = longitude of periapsis + true anomaly (EE case).');

            [entryCE, frameCE, ~] = testCase.earthMuEntry( ...
                [6199.6905946008; 13295.2793851394; 0.0], ...
                [-4.72425923942564; 2.20295826245369; 0.0], muE);
            testCase.verifyEqual(testCase.evalLvd(entryCE, 'True Longitude', frameCE), 65, 'AbsTol', 1e-6, ...
                'Circular equatorial l = 65 deg construction must read 65 deg.');

            [entryCER, frameCER, ~] = testCase.earthMuEntry( ...
                [6199.6905946008; -13295.2793851394; 0.0], ...
                [-4.72425923942564; -2.20295826245369; 0.0], muE);
            testCase.verifyEqual(testCase.evalLvd(entryCER, 'True Longitude', frameCER), 65, 'AbsTol', 1e-6, ...
                'Retrograde circular equatorial l = 65 deg must read 65 deg.');
        end

        function checkEccentricityVectorApsis(testCase)
            %Periapsis direction straight from e = ((v^2-mu/r)*r-(r.v)*v)/mu
            %with Kerbin mu: no Kepler elements, no node/arg conventions.
            mu = testCase.kerbin.gm;
            a = 1400; ecc = 0.2;
            rp = a*(1-ecc);
            vp = sqrt(mu*(2/rp - 1/a));
            ci = cosd(30); si = sind(30);
            rV = [0; rp*ci; rp*si];
            vV = [-vp; 0; 0];
            [entry, ~] = testCase.orbitEntry(rV, vV, 0);
            frame = testCase.kerbinFrame;

            evec = ((dot(vV,vV) - mu/norm(rV))*rV - dot(rV,vV)*vV)/mu;
            testCase.verifyEqual(norm(evec), ecc, 'RelTol', 1e-9, ...
                'Eccentricity-vector magnitude must equal the orbit eccentricity.');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Eccentricity', frame), norm(evec), 'RelTol', 1e-12, ...
                'Eccentricity task must match the eccentricity vector.');

            [periLatE, periLonE] = testCase.evecLatLon(rV, vV, mu, testCase.kerbin, +1);
            [apoLatE, apoLonE] = testCase.evecLatLon(rV, vV, mu, testCase.kerbin, -1);
            testCase.verifyEqual(testCase.evalLvd(entry, 'Periapsis Latitude (North)', frame), periLatE, 'AbsTol', 1e-6, ...
                'Periapsis latitude from the e-vector (inclined orbit).');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Periapsis Longitude (East)', frame), periLonE, 'AbsTol', 1e-6, ...
                'Periapsis longitude from the e-vector (inclined orbit).');
            testCase.verifyEqual(testCase.evalLvd(entry, 'Apoapsis Latitude (North)', frame), apoLatE, 'AbsTol', 1e-6, ...
                'Apoapsis latitude from the e-vector (inclined orbit).');
            testCase.verifyAngleEqualDeg( ...
                testCase.evalLvd(entry, 'Apoapsis Longitude (East)', frame), apoLonE, 1e-6, ...
                'Apoapsis longitude from the e-vector (inclined orbit).');
        end

        %% ---------------- end-to-end ----------------
        function checkExampleMissionEndToEnd(testCase)
            %The full plot path (LvdGraphicalAnalysis.executeTasks with
            %history threading and the cumulative memo) against a real
            %propagated log: no task may fail, cumulative starts at 0, and
            %the remaining-capability drop matches cumulative expended.
            hits = dir(fullfile(ksptotTestRoot(), 'examples', 'LaunchVehicleDesigner', '**', 'lvdExample_SimpleHohmannTransfer.mat'));
            testCase.assumeNotEmpty(hits, 'Example mission not present in this checkout.');

            loaded = load(fullfile(hits(1).folder, hits(1).name), 'lvdData');
            lvdData = loaded.lvdData;
            testCase.assumeGreaterThan(lvdData.stateLog.getNumberOfEntries(), 2, ...
                'Fixture: the example must contain a propagated state log.');

            frame = testCase.kerbin.getBodyCenteredInertialFrame();
            strs = {'Specific Orbital Energy', 'Specific Angular Momentum', ...
                'Argument of Latitude', 'Sensed Acceleration (Total)', ...
                'Remaining Delta-V Capability', 'Cumulative Delta-V Expended', ...
                'Sun Phase Angle'};
            for(k=1:numel(strs)) %#ok<NO4LP>
                lvdData.graphAnalysis.addTask(GraphicalAnalysisTask(strs{k}, frame));
            end

            [tS, tE] = lvdData.stateLog.getStartAndEndTimes();
            [vals, ~, ~, ~, ~, ~, mask] = lvdData.graphAnalysis.executeTasks([], tS, tE, [], []);
            testCase.verifyFalse(any(mask(:)), ...
                'No F2 task may fail evaluation on the example mission log.');

            labels = lvdData.graphAnalysis.getListBoxStr();
            cumCol = vals(:, contains(labels, 'Cumulative Delta-V Expended'));
            remCol = vals(:, contains(labels, 'Remaining Delta-V Capability'));
            testCase.verifyEqual(cumCol(1), 0, 'AbsTol', 1e-12, ...
                'Cumulative Delta-V must start at 0.');
            testCase.verifyGreaterThanOrEqual(cumCol(end), 0, ...
                'Cumulative Delta-V must never go negative.');
            testCase.verifyEqual(remCol(1) - remCol(end), cumCol(end), 'RelTol', 0.02, ...
                'Remaining-capability drop must match cumulative expended (same Isp bookkeeping).');
        end

        %% ---------------- fixtures ----------------
        function [entry, frame] = circularEquatorialEntry(testCase, radius)
            [entry, ~] = testCase.orbitEntry([radius;0;0], [0;sqrt(testCase.kerbin.gm/radius);0], 0);
            frame = testCase.kerbinFrame;
        end

        function [entry, lvdData] = orbitEntry(testCase, rVect, vVect, ut)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.time = ut;
            entry.position = rVect(:);
            entry.velocity = vVect(:);
        end

        function [lvdData, entry] = vacuumEntry(testCase)
            %Entry at 2400 km altitude (no atmosphere) with full tanks.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.position = [0; 0; testCase.kerbin.radius + 2400];
            entry.velocity = [1; 0; 0];
        end

        function [lvdData, entry] = atmoEntry(testCase)
            %Entry at 10 km altitude moving 1 km/s inertially (deep enough
            %for drag, slow enough that lift stays modest).
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.position = [testCase.kerbin.radius + 10; 0; 0];
            entry.velocity = [0; 1; 0];
        end

        function aVectG = directSensedAccelG(~, entry)
            %Independent evaluation of (thrust + drag + lift) / m in g with
            %the same force models the task wires together.
            mass = entry.getTotalVehicleMass();
            ut = entry.time;
            rVect = entry.position(:);
            vVect = entry.velocity(:);
            bodyInfo = entry.centralBody;
            aero = entry.aero;
            attState = entry.attitude;

            tankStates = entry.getAllActiveTankStates();
            stageStates = entry.stageStates;
            lvState = entry.lvState;
            dryMass = entry.getTotalVehicleDryMass();
            if(isempty(tankStates))
                tankStatesMasses = zeros(0,1);
            else
                tankStatesMasses = [tankStates.tankMass]';
            end

            pwrStates = entry.getAllActivePwrStorageStates();
            socs = zeros(1, numel(pwrStates));
            throttle = entry.throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, ...
                dryMass, stageStates, lvState, tankStates, bodyInfo, socs, pwrStates);
            pressure = getPressureAtAltitude(bodyInfo, norm(rVect) - bodyInfo.radius);

            [~, ~, thrustVec] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines( ...
                tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ...
                ut, rVect, vVect, bodyInfo, entry.steeringModel, socs, pwrStates, attState);
            [dragVec, ~, ~] = DragForceModel().getForce(ut, rVect, vVect, mass, bodyInfo, aero, ...
                [], [], [], [], [], [], [], [], [], [], attState, []);
            [liftVec, ~, ~] = LiftForceModel().getForce(ut, rVect, vVect, mass, bodyInfo, aero, ...
                [], [], [], [], [], [], [], [], [], [], attState, []);

            aVectG = (thrustVec(:) + dragVec(:) + liftVec(:)) / mass * 1000 / getG0();
        end

        function value = evalLvd(testCase, entry, taskStr, frame)
            [value, ~] = lvd_getDepVarValueUnit(1, entry, taskStr, [], testCase.celBodyData, false, frame);
        end

        function stnInert = stationInertial(~, grdObj, time)
            parentInertial = grdObj.centralBodyInfo.getBodyCenteredInertialFrame();
            stnGeo = grdObj.getStateAtTime(time);
            stnInert = stnGeo.convertToCartesianElementSet().convertToFrame(parentInertial).convertToCartesianElementSet().rVect(:);
        end

        function stnVel = stationVelFD(testCase, grdObj, time)
            dt = 0.5;
            stnVel = (testCase.stationInertial(grdObj, time+dt) - testCase.stationInertial(grdObj, time-dt)) / (2*dt);
        end

        function [entry, frame, ebody] = earthMuEntry(testCase, rVect, vVect, muE)
            %earthMuEntry State-log entry on an Earth-mu copy of Kerbin so
            %published Earth-centered test vectors apply.  The shared
            %session-cached bodies are read-only (see ksptotTestBodyData),
            %so mu is overridden on a shallow copy, never in place.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            ebody = testCase.copyBodyInfo(testCase.kerbin);
            ebody.gm = muE;
            frame = ebody.getBodyCenteredInertialFrame();
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.centralBody = ebody;
            entry.time = 0;
            entry.position = rVect(:);
            entry.velocity = vVect(:);
        end

        function deg = wrap360(~, degIn)
            deg = rad2deg(AngleZero2Pi(deg2rad(degIn)));
        end

        function verifyAngleEqualDeg(testCase, actualDeg, expectedDeg, absTolDeg, msg)
            delta = abs(angleNegPiToPi(deg2rad(actualDeg - expectedDeg)));
            testCase.verifyLessThanOrEqual(rad2deg(delta), absTolDeg, msg);
        end

        function [latDeg, lonDeg] = evecLatLon(~, rVect, vVect, mu, bodyInfo, sign)
            %evecLatLon Periapsis (+1) or apoapsis (-1) lat/lon straight
            %from the eccentricity vector: no orbital elements anywhere.
            evec = ((dot(vVect,vVect) - mu/norm(rVect))*rVect(:) - dot(rVect,vVect)*vVect(:))/mu;
            ehat = sign * evec(:) / norm(evec);
            [lat, lon] = getLatLongAltFromInertialVect(0, ehat*bodyInfo.radius, bodyInfo);
            latDeg = rad2deg(lat);
            lonDeg = rad2deg(AngleZero2Pi(lon));
        end

        function ref = valladoRv2coe(~, rVect, vVect, mu)
            %valladoRv2coe Independent transcription of D. Vallado,
            %Fundamentals of Astrodynamics and Applications, Algorithm 9
            %(rv2coe), as published in the companion software
            %(github.com/poliastro/vallado-software, matlab/rv2coe.m,
            %citing "vallado 2007, 121, alg 9, ex 2-5").  h/n/e-vector
            %branch structure, kept deliberately stylistically distinct
            %from getKeplerFromState.  Undefined outputs are NaN.
            small = 1e-8; %constmath tolerance
            twopi = 2*pi;
            r = rVect(:); v = vVect(:);
            magr = norm(r); magv = norm(v);

            hbar = cross(r, v);
            magh = norm(hbar);
            nbar = [-hbar(2); hbar(1); 0];
            magn = norm(nbar);
            c1 = magv*magv - mu/magr;
            rdotv = dot(r, v);
            ebar = (c1*r - rdotv*v)/mu;
            ecc = norm(ebar);

            sme = magv*magv*0.5 - mu/magr;
            if(abs(sme) > small)
                a = -mu/(2*sme);
            else
                a = Inf;
            end
            p = magh*magh/mu;

            incl = acos(max(-1, min(1, hbar(3)/magh)));

            if(ecc < small)
                if(incl < small || abs(incl-pi) < small)
                    type = 'ce';
                else
                    type = 'ci';
                end
            else
                type = 'ei';
                if(incl < small || abs(incl-pi) < small)
                    type = 'ee';
                end
            end

            if(magn > small)
                temp = max(-1, min(1, nbar(1)/magn));
                omega = acos(temp);
                if(nbar(2) < 0)
                    omega = twopi - omega;
                end
            else
                omega = NaN;
            end

            if(strcmp(type, 'ei'))
                argp = testCase_valladoAngl(nbar, ebar);
                if(ebar(3) < 0)
                    argp = twopi - argp;
                end
            else
                argp = NaN;
            end

            if(type(1) == 'e')
                nu = testCase_valladoAngl(ebar, r);
                if(rdotv < 0)
                    nu = twopi - nu;
                end
            else
                nu = NaN;
            end

            if(strcmp(type, 'ci'))
                arglat = testCase_valladoAngl(nbar, r);
                if(r(3) < 0)
                    arglat = twopi - arglat;
                end
            else
                arglat = NaN;
            end

            if(ecc > small && strcmp(type, 'ee'))
                temp = max(-1, min(1, ebar(1)/ecc));
                lonper = acos(temp);
                if(ebar(2) < 0)
                    lonper = twopi - lonper;
                end
                if(incl > pi/2)
                    lonper = twopi - lonper;
                end
            else
                lonper = NaN;
            end

            if(magr > small && strcmp(type, 'ce'))
                temp = max(-1, min(1, r(1)/magr));
                truelon = acos(temp);
                if(r(2) < 0)
                    truelon = twopi - truelon;
                end
                if(incl > pi/2)
                    truelon = twopi - truelon;
                end
            else
                truelon = NaN;
            end

            ref = struct('type', type, 'p', p, 'a', a, 'ecc', ecc, ...
                'incl', incl, 'omega', omega, 'argp', argp, 'nu', nu, ...
                'arglat', arglat, 'truelon', truelon, 'lonper', lonper, ...
                'sme', sme, 'magh', magh);
        end
    end
end

function a = testCase_valladoAngl(vec1, vec2)
%testCase_valladoAngl Vallado's angl(): angle between two vectors, [0, pi].
    a = acos(max(-1, min(1, dot(vec1(:), vec2(:)) / (norm(vec1)*norm(vec2)))));
end
