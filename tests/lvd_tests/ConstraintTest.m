classdef ConstraintTest < KsptotTestCase
    %ConstraintTest Coverage of the AbstractConstraint subclass family.
    %
    % Every LVD constraint is a two-stage adapter sitting between the state
    % log and the optimizer's [c, ceq] vectors:
    %
    %   stage 1 (per-subclass)  pick a state log entry out of the state log
    %                           and reduce it to a scalar `value`
    %   stage 2 (shared)        AbstractConstraint.computeCAndCeqValues
    %                           turns (value, valueStateComp) into c/ceq
    %                           according to evalType/stateCompType, then
    %                           divides both by normFact
    %
    % Both stages fail silently when they are wrong.  A subclass that grabs
    % the FIRST state log entry of an event where it should grab the LAST
    % still returns a plausible number; a sign flip in the state-comparison
    % branch still returns a plausible number; forgetting to divide by
    % normFact only shows up as slow optimizer convergence.  So the checks
    % below never compare a constraint against another call into the same
    % production path -- they compare it against arithmetic spelled out in
    % this file.
    %
    % The c/ceq oracle, written out once here so the tests do not have to
    % consult AbstractConstraint to know what to expect:
    %
    %   evalType == FixedBounds
    %       lb ~= ub :  c = [lb - value, value - ub] / normFact,  ceq = []
    %       lb == ub :  c = [],  ceq = (value - ub) / normFact
    %   evalType == StateComparison
    %       Equals      :  c = [],                              ceq = (value - valueStateComp)/normFact
    %       GreaterThan :  c = (valueStateComp - value)/normFact, ceq = []
    %       LessThan    :  c = (value - valueStateComp)/normFact, ceq = []
    %
    % The ground object azimuth/elevation/range oracle is a hand-written
    % spherical NED construction (see refGroundObjAzElRange below).  It
    % deliberately does NOT call computeNedFrame, getAzElRngFromNedPosition
    % or lvd_GrdObjTasks, which are exactly the production helpers the
    % constraints under test go through.
    %
    % ThrottleConstraint is used as the carrier for all of the shared
    % computeCAndCeqValues semantics cases.  That is deliberate: its
    % `value` is exactly 100*throttle, and throttle is directly settable on
    % a state log entry via the constant term of its polynomial throttle
    % model.  That makes `value` a dial the test turns, so every c/ceq
    % assertion is pure arithmetic on a number the test chose.
    %
    % Skipped (documented):
    %   * PluginConstraint -- requires a compiled/registered LVD plugin
    %     object and a populated plugin set; the plugin execution path is
    %     out of scope for this package for the same reason the GUI is.
    %   * TwoBodyImpactPointLatitude / TwoBodyImpactPointLongitude /
    %     TwoBodyImpactPointTime -- these numerically root-solve a
    %     two-body impact trajectory.  An independent oracle would mean
    %     reimplementing a Kepler propagator plus the impact root find in
    %     the test file, which is a larger and more fragile piece of
    %     mathematics than the code it would be checking.
    %   * AngleOfAttack / BankAngle / SideSlipAngle / Pitch / Roll / Yaw /
    %     InertialAngleOfAttack / InertialBankAngle / InertialSideSlipAngle
    %     -- these are all thin `lvd_AttitudeTasks(entry, '<name>', frame)`
    %     wrappers with identical structure; the attitude task math itself
    %     is covered by the steering model tests.  Their shared
    %     entry-selection and c/ceq behaviour is what this file tests, and
    %     that is exercised through the Throttle carrier.
    %   * CalculusCalculationValueConstraint -- the calculus state objects
    %     and their getValueAtTime interpolation already have dedicated
    %     coverage in StateLogCalculusElectricalTest.
    %   * GeometricAngleMagConstraint -- needs a fully wired
    %     AbstractGeometricAngle (two vectors plus a plane); the vector
    %     side of the same adapter is covered by the
    %     GeometricVector{X,Y,Z,Mag} cases.

    properties(TestParameter)
        caseName = { ...
            'FixedBoundsProduceTwoSidedInequality', ...
            'CoincidentBoundsProduceEqualityConstraint', ...
            'NormFactDividesInequalityOutputs', ...
            'NormFactDividesEqualityOutputs', ...
            'StateComparisonEqualsFormsCeqDifference', ...
            'StateComparisonGreaterThanFlipsSubtractionOrder', ...
            'StateComparisonLessThanKeepsSubtractionOrder', ...
            'EventNodeSelectsFirstOrLastEntryOfEvent', ...
            'StateCompNodeSelectsFirstOrLastEntryOfCompEvent', ...
            'ThrottleConstraintReportsPercentAndStaticDetails', ...
            'GroundObjectAzimuthMatchesNedOracle', ...
            'GroundObjectElevationMatchesNedOracle', ...
            'GroundObjectRangeMatchesNedOracle', ...
            'GroundObjectConstraintsAgreeAcrossSeveralGeometries', ...
            'TankMassConstraintReadsTheNamedTank', ...
            'TankMassFlowRateIsZeroWithEnginesOff', ...
            'StopwatchValueConstraintReadsStopwatchState', ...
            'ExtremumValueConstraintReadsExtremaState', ...
            'CumPwrStorageStateOfChargeSumsAllStorages', ...
            'GenericMAConstraintAltitudeMatchesRadiusMinusBodyRadius', ...
            'GeometricVectorConstraintsReadComponentsAndMagnitude', ...
            'TotalThrustAndThrustToWeightVanishWithEnginesOff', ...
            'ThrustToWeightMatchesHandComputedSeaLevelRatio', ...
            'EventDeltaVExpendedMatchesTsiolkovskyRatio', ...
            'ConstraintMetadataAndBoundsAccessors', ...
            'UsesEventTracksBothEventsInStateComparison', ...
            'ConstraintSetSkipsInactiveConstraintsAndKeepsOrder', ...
            'BodyAngularVelStateComparisonAssignsValueStateComp', ...
        };
    end

    properties(Constant, Access=private)
        %Tolerances.  Position/geometry work is done in km on a 600 km
        %body, so 1e-9 km (1 micron) is far tighter than anything the
        %frame machinery can perturb but still safe against round off.
        GeomTol  = 1e-9;
        AngTol   = 1e-9;
        ValueTol = 1e-10;
    end

    methods(Test)
        function constraintsMatchIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ---------------------------------------------------------------
        %  computeCAndCeqValues semantics (shared base class behaviour)
        %  ---------------------------------------------------------------

        function checkFixedBoundsProduceTwoSidedInequality(testCase)
            %FixedBounds with lb ~= ub must emit TWO inequalities and no
            %equality.  With value = 50, lb = 10, ub = 90 the pair is
            %[lb - value, value - ub] = [-40, -40]: both satisfied, both
            %40 units of slack away from their respective bound.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0.50);
            stateLog = testCase.makeLog(fx, entry);

            const = ThrottleConstraint(fx.evt1, 10, 90);
            [c, ceq, value, lwrBnd, uprBnd, type, eventNum, valueStateComp] = ...
                const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(value, 50, 'AbsTol', testCase.ValueTol, ...
                'ThrottleConstraint value must be 100*throttle');
            testCase.verifyEqual(c(:)', [10 - 50, 50 - 90], 'AbsTol', testCase.ValueTol, ...
                'FixedBounds must emit [lb - value, value - ub]');
            testCase.verifyEmpty(ceq, ...
                'FixedBounds with distinct bounds must not emit an equality constraint');
            testCase.verifyEqual(lwrBnd, 10, 'AbsTol', testCase.ValueTol, ...
                'reported lower bound must be the constraint lb');
            testCase.verifyEqual(uprBnd, 90, 'AbsTol', testCase.ValueTol, ...
                'reported upper bound must be the constraint ub');
            testCase.verifyEqual(type, 'Throttle', ...
                'reported constraint type string is wrong');
            testCase.verifyEqual(eventNum, 1, ...
                'reported event number must be the constrained event''s number');
            testCase.verifyTrue(isnan(valueStateComp), ...
                'valueStateComp must be NaN when evalType is FixedBounds');
        end

        function checkCoincidentBoundsProduceEqualityConstraint(testCase)
            %When lb == ub the constraint degenerates to an equality and
            %the inequality output must be EMPTY, not a pair of equal and
            %opposite numbers.  Emitting both would double count the
            %constraint in the optimizer's Jacobian.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0.50);
            stateLog = testCase.makeLog(fx, entry);

            const = ThrottleConstraint(fx.evt1, 40, 40);
            [c, ceq, value] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEmpty(c, ...
                'lb == ub must produce no inequality constraints');
            testCase.verifyEqual(ceq, value - 40, 'AbsTol', testCase.ValueTol, ...
                'lb == ub must produce ceq = value - ub');
            testCase.verifyEqual(ceq, 10, 'AbsTol', testCase.ValueTol, ...
                'equality residual for value 50 against bound 40 must be 10');
        end

        function checkNormFactDividesInequalityOutputs(testCase)
            %normFact is the optimizer-facing scale factor.  It must divide
            %c (and ceq), and must NOT touch the reported raw `value` or
            %the reported bounds -- those are what the GUI shows the user
            %in physical units.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0.50);
            stateLog = testCase.makeLog(fx, entry);

            const = ThrottleConstraint(fx.evt1, 10, 90);
            const.setScaleFactor(4);

            testCase.verifyEqual(const.getScaleFactor(), 4, 'AbsTol', testCase.ValueTol, ...
                'setScaleFactor/getScaleFactor did not round trip');

            [c, ceq, value, lwrBnd, uprBnd] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(c(:)', [-40, -40]/4, 'AbsTol', testCase.ValueTol, ...
                'inequality outputs must be divided by normFact');
            testCase.verifyEmpty(ceq, 'no equality expected here');
            testCase.verifyEqual(value, 50, 'AbsTol', testCase.ValueTol, ...
                'the reported raw value must NOT be scaled by normFact');
            testCase.verifyEqual([lwrBnd, uprBnd], [10, 90], 'AbsTol', testCase.ValueTol, ...
                'the reported bounds must NOT be scaled by normFact');
        end

        function checkNormFactDividesEqualityOutputs(testCase)
            %Same scaling rule on the lb == ub branch.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0.50);
            stateLog = testCase.makeLog(fx, entry);

            const = ThrottleConstraint(fx.evt1, 40, 40);
            const.setScaleFactor(8);

            [c, ceq] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEmpty(c, 'no inequality expected on the equality branch');
            testCase.verifyEqual(ceq, 10/8, 'AbsTol', testCase.ValueTol, ...
                'equality output must be divided by normFact');
        end

        function checkStateComparisonEqualsFormsCeqDifference(testCase)
            %State comparison mode ignores lb/ub entirely and compares the
            %constrained event's value against a second event's value.
            %Equals -> ceq = value - valueStateComp, c empty.
            [stateLog, fx] = testCase.buildTwoEventThrottleLog(0.50, 0.20);

            const = ThrottleConstraint(fx.evt1, 999, -999); %bounds must be ignored
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;

            [c, ceq, value, ~, ~, ~, ~, valueStateComp] = ...
                const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(value, 50, 'AbsTol', testCase.ValueTol, ...
                'primary value must come from the constrained event');
            testCase.verifyEqual(valueStateComp, 20, 'AbsTol', testCase.ValueTol, ...
                'comparison value must come from the state comparison event');
            testCase.verifyEmpty(c, 'Equals comparison must not emit inequalities');
            testCase.verifyEqual(ceq, 30, 'AbsTol', testCase.ValueTol, ...
                'Equals comparison must emit ceq = value - valueStateComp');
        end

        function checkStateComparisonGreaterThanFlipsSubtractionOrder(testCase)
            %"value >= valueStateComp" is fed to the optimizer in the
            %standard c <= 0 form as c = valueStateComp - value.  Getting
            %this backwards silently inverts the constraint, so the sign
            %is asserted explicitly rather than just the magnitude.
            [stateLog, fx] = testCase.buildTwoEventThrottleLog(0.50, 0.20);

            const = ThrottleConstraint(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;

            [c, ceq] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEmpty(ceq, 'GreaterThan comparison must not emit an equality');
            testCase.verifyEqual(c, 20 - 50, 'AbsTol', testCase.ValueTol, ...
                'GreaterThan must emit c = valueStateComp - value');
            testCase.verifyLessThan(c, 0, ...
                'value 50 >= comparison 20 is satisfied, so c must be negative');
        end

        function checkStateComparisonLessThanKeepsSubtractionOrder(testCase)
            %"value <= valueStateComp" -> c = value - valueStateComp.  Here
            %the relation is VIOLATED (50 is not <= 20), so c must come out
            %positive; that is the half of the sign convention the
            %GreaterThan case above cannot see.
            [stateLog, fx] = testCase.buildTwoEventThrottleLog(0.50, 0.20);

            const = ThrottleConstraint(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;

            [c, ceq] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEmpty(ceq, 'LessThan comparison must not emit an equality');
            testCase.verifyEqual(c, 50 - 20, 'AbsTol', testCase.ValueTol, ...
                'LessThan must emit c = value - valueStateComp');
            testCase.verifyGreaterThan(c, 0, ...
                'value 50 <= comparison 20 is violated, so c must be positive');
        end

        %% ---------------------------------------------------------------
        %  Which state log entry gets picked
        %  ---------------------------------------------------------------

        function checkEventNodeSelectsFirstOrLastEntryOfEvent(testCase)
            %An event owns many state log entries.  eventNode decides
            %whether the constraint reads the first or the last of them.
            %The fixture gives event 1 three entries with three DIFFERENT
            %throttles and puts an event-2 entry after them, so a
            %"last entry in the whole log" bug would return 99, not 90.
            fx = testCase.buildFixture();
            e1a = testCase.makeEntry(fx, fx.evt1, 0);   testCase.setThrottle(e1a, 0.10);
            e1b = testCase.makeEntry(fx, fx.evt1, 10);  testCase.setThrottle(e1b, 0.40);
            e1c = testCase.makeEntry(fx, fx.evt1, 20);  testCase.setThrottle(e1c, 0.90);
            e2a = testCase.makeEntry(fx, fx.evt2, 30);  testCase.setThrottle(e2a, 0.99);
            stateLog = testCase.makeLog(fx, [e1a, e1b, e1c, e2a]);

            const = ThrottleConstraint(fx.evt1, 0, 100);

            const.eventNode = ConstraintStateComparisonNodeEnum.FinalState;
            [~, ~, finalValue] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(finalValue, 90, 'AbsTol', testCase.ValueTol, ...
                'FinalState must read the LAST entry belonging to the constrained event');

            const.eventNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, initialValue] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(initialValue, 10, 'AbsTol', testCase.ValueTol, ...
                'InitialState must read the FIRST entry belonging to the constrained event');
        end

        function checkStateCompNodeSelectsFirstOrLastEntryOfCompEvent(testCase)
            %stateCompNode is a separate knob from eventNode and selects
            %within the comparison event.  Holding the primary node fixed
            %isolates it.
            fx = testCase.buildFixture();
            e1a = testCase.makeEntry(fx, fx.evt1, 0);   testCase.setThrottle(e1a, 0.50);
            e2a = testCase.makeEntry(fx, fx.evt2, 10);  testCase.setThrottle(e2a, 0.20);
            e2b = testCase.makeEntry(fx, fx.evt2, 20);  testCase.setThrottle(e2b, 0.70);
            stateLog = testCase.makeLog(fx, [e1a, e2a, e2b]);

            const = ThrottleConstraint(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;

            const.stateCompNode = ConstraintStateComparisonNodeEnum.FinalState;
            [~, ~, value, ~, ~, ~, ~, compFinal] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, 50, 'AbsTol', testCase.ValueTol, ...
                'primary value must not move when stateCompNode changes');
            testCase.verifyEqual(compFinal, 70, 'AbsTol', testCase.ValueTol, ...
                'stateCompNode = FinalState must read the last entry of the comparison event');

            const.stateCompNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, ~, ~, ~, ~, ~, compInitial] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(compInitial, 20, 'AbsTol', testCase.ValueTol, ...
                'stateCompNode = InitialState must read the first entry of the comparison event');
        end

        %% ---------------------------------------------------------------
        %  Per-subclass value extraction
        %  ---------------------------------------------------------------

        function checkThrottleConstraintReportsPercentAndStaticDetails(testCase)
            %The stored throttle is a 0..1 fraction but the constraint (and
            %its declared bound limits) work in percent.  A missing factor
            %of 100 here would put every throttle constraint 100x out of
            %scale without ever throwing.
            fx = testCase.buildFixture();
            for(frac = [0, 0.25, 0.6, 1])
                entry = testCase.makeEntry(fx, fx.evt1, 0);
                testCase.setThrottle(entry, frac);
                stateLog = testCase.makeLog(fx, entry);

                const = ThrottleConstraint(fx.evt1, 0, 100);
                [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);

                testCase.verifyEqual(value, 100*frac, 'AbsTol', testCase.ValueTol, ...
                    sprintf('throttle fraction %g must be reported as %g percent', frac, 100*frac));
            end

            const = ThrottleConstraint(fx.evt1, 0, 100);
            [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = const.getConstraintStaticDetails();
            testCase.verifyEqual(unit, '%', 'throttle constraint unit must be percent');
            testCase.verifyEqual(lbLim, 0, 'throttle lower bound limit must be 0 percent');
            testCase.verifyEqual(ubLim, 100, 'throttle upper bound limit must be 100 percent');
            testCase.verifyTrue(usesLbUb, 'throttle constraint uses lb/ub');
            testCase.verifyFalse(usesCelBody, 'throttle constraint does not use a reference celestial body');
            testCase.verifyFalse(usesRefSc, 'throttle constraint does not use a reference spacecraft');
        end

        function checkGroundObjectAzimuthMatchesNedOracle(testCase)
            [prod, ref] = testCase.evalGroundObjTriple(deg2rad(10), deg2rad(25), 0, ...
                                                       800, deg2rad(20), deg2rad(40));
            testCase.verifyEqual(prod.az, ref.az, 'AbsTol', testCase.AngTol, ...
                'GroundObjAzConstraint azimuth disagrees with the hand-built NED oracle');
        end

        function checkGroundObjectElevationMatchesNedOracle(testCase)
            [prod, ref] = testCase.evalGroundObjTriple(deg2rad(10), deg2rad(25), 0, ...
                                                       800, deg2rad(20), deg2rad(40));
            testCase.verifyEqual(prod.el, ref.el, 'AbsTol', testCase.AngTol, ...
                'GroundObjElConstraint elevation disagrees with the hand-built NED oracle');
        end

        function checkGroundObjectRangeMatchesNedOracle(testCase)
            [prod, ref] = testCase.evalGroundObjTriple(deg2rad(10), deg2rad(25), 0, ...
                                                       800, deg2rad(20), deg2rad(40));
            testCase.verifyEqual(prod.rng, ref.rng, 'AbsTol', testCase.GeomTol, ...
                'GroundObjRangeConstraint range disagrees with the hand-built NED oracle');

            %Range is frame-independent, so it must also equal the plain
            %Euclidean distance between the two positions.  This is a
            %second, even simpler oracle for the same number.
            testCase.verifyEqual(prod.rng, norm(ref.rSc - ref.rStn), 'AbsTol', testCase.GeomTol, ...
                'range must be the Euclidean distance between station and vehicle');
        end

        function checkGroundObjectConstraintsAgreeAcrossSeveralGeometries(testCase)
            %One geometry can accidentally agree (e.g. an equatorial
            %station hides latitude sign errors, a station directly under
            %the vehicle hides azimuth errors entirely).  These five cover
            %both hemispheres, both signs of longitude difference, a
            %non-zero station altitude, and a near-overhead pass.
            cases = { ...
                {deg2rad( 10), deg2rad( 25), 0.0,  800, deg2rad( 20), deg2rad( 40), 'northeast look'}, ...
                {deg2rad(-35), deg2rad(140), 0.5,  900, deg2rad( 10), deg2rad(100), 'southern station, westward look'}, ...
                {deg2rad( 60), deg2rad(-70), 2.0, 1500, deg2rad(-15), deg2rad( 10), 'high latitude station, cross equator'}, ...
                {deg2rad(  0), deg2rad(  0), 0.0,  700, deg2rad(  0), deg2rad(  0), 'directly overhead, equatorial'}, ...
                {deg2rad( 45), deg2rad( 90), 0.25, 610, deg2rad( 44), deg2rad( 91), 'low pass, nearly local'} ...
            };

            for(i = 1:numel(cases))
                cs = cases{i};
                [prod, ref] = testCase.evalGroundObjTriple(cs{1}, cs{2}, cs{3}, cs{4}, cs{5}, cs{6});
                label = cs{7};

                testCase.verifyEqual(prod.rng, ref.rng, 'AbsTol', testCase.GeomTol, ...
                    sprintf('range mismatch (%s)', label));
                testCase.verifyEqual(prod.el, ref.el, 'AbsTol', testCase.AngTol, ...
                    sprintf('elevation mismatch (%s)', label));

                %Azimuth is undefined when the vehicle is exactly at the
                %local zenith (the horizontal projection is the zero
                %vector).  atan2(0,0) is 0 in both the oracle and the
                %production code, so the comparison is still well defined,
                %but comparing modulo 360 keeps a legitimate 0/360
                %wraparound from being reported as a 360 degree error.
                testCase.verifyEqual(mod(prod.az - ref.az + 180, 360) - 180, 0, ...
                    'AbsTol', testCase.AngTol, ...
                    sprintf('azimuth mismatch (%s)', label));
            end
        end

        function checkTankMassConstraintReadsTheNamedTank(testCase)
            %With two tanks present, the constraint has to select by tank
            %identity, not by position in the tank state array.  The two
            %masses are set to clearly distinguishable values so a
            %"first tank always" bug cannot pass.
            [lvdData, template, tank1, tank2] = testCase.buildTwoTankTemplate();
            fx = testCase.fixtureFromLvdData(lvdData, template);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            tankStates = entry.getAllTankStates();
            state1 = tankStates([tankStates.tank] == tank1);
            state2 = tankStates([tankStates.tank] == tank2);
            state1.tankMass = 2.75;
            state2.tankMass = 6.125;

            stateLog = testCase.makeLog(fx, entry);

            const1 = TankMassConstraint(tank1, fx.evt1, 0, 10);
            [~, ~, value1] = const1.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value1, 2.75, 'AbsTol', testCase.ValueTol, ...
                'TankMassConstraint must report the mass of ITS tank (tank 1)');

            const2 = TankMassConstraint(tank2, fx.evt1, 0, 10);
            [~, ~, value2] = const2.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value2, 6.125, 'AbsTol', testCase.ValueTol, ...
                'TankMassConstraint must report the mass of ITS tank (tank 2)');

            testCase.verifyTrue(const1.usesTank(tank1), ...
                'usesTank must be true for the tank the constraint targets');
            testCase.verifyFalse(const1.usesTank(tank2), ...
                'usesTank must be false for an unrelated tank');
        end

        function checkTankMassFlowRateIsZeroWithEnginesOff(testCase)
            %Mass flow rate out of a tank is engine driven.  At zero
            %throttle -- and with no tank-to-tank connections in the stock
            %vehicle -- the only physically admissible answer is exactly
            %zero.  A non-zero result would mean the throttle is not
            %reaching the engine model at all.
            fx = testCase.buildFixture();
            tank = fx.lvdData.launchVehicle.stages(1).tanks(1);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0);
            stateLog = testCase.makeLog(fx, entry);

            const = TankMassFlowRateConstraint(tank, fx.evt1, -1, 1);
            [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, 0, 'AbsTol', 1e-12, ...
                'tank mass flow rate must be exactly zero with the engine shut down');

            %...and strictly negative (propellant leaving the tank) once the
            %engine is lit.  The magnitude depends on the engine model, but
            %the SIGN is a pure physical invariant the test can assert.
            entryOn = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entryOn, 1);
            stateLogOn = testCase.makeLog(fx, entryOn);
            [~, ~, valueOn] = const.evalConstraint(stateLogOn, testCase.celBodyData);
            testCase.verifyLessThan(valueOn, 0, ...
                'tank mass flow rate must be negative (mass leaving) at full throttle');
        end

        function checkStopwatchValueConstraintReadsStopwatchState(testCase)
            [lvdData, template, sw] = testCase.buildStopwatchTemplate();
            fx = testCase.fixtureFromLvdData(lvdData, template);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            swStates = entry.getAllStopwatchStates();
            testCase.assertNotEmpty(swStates, 'fixture failed to attach a stopwatch state');
            swState = swStates([swStates.stopwatch] == sw);
            swState.value = 123.5;

            stateLog = testCase.makeLog(fx, entry);

            const = StopwatchValueConstraint(fx.evt1, 0, 1000);
            const.stopwatch = sw;
            [c, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(value, 123.5, 'AbsTol', testCase.ValueTol, ...
                'StopwatchValueConstraint must report the stopwatch state value verbatim');
            testCase.verifyEqual(c(:)', [0 - 123.5, 123.5 - 1000], 'AbsTol', testCase.ValueTol, ...
                'stopwatch constraint c pair is wrong');
            testCase.verifyTrue(const.usesStopwatch(sw), ...
                'usesStopwatch must report the targeted stopwatch');
        end

        function checkExtremumValueConstraintReadsExtremaState(testCase)
            [lvdData, template, ex] = testCase.buildExtremumTemplate();
            fx = testCase.fixtureFromLvdData(lvdData, template);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            exStates = entry.getAllExtremaStates();
            testCase.assertNotEmpty(exStates, 'fixture failed to attach an extrema state');
            exState = exStates([exStates.extrema] == ex);
            exState.value = 4321;

            stateLog = testCase.makeLog(fx, entry);

            const = ExtremumValueConstraint(fx.evt1, 0, 1e6);
            const.extremum = ex;
            [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(value, 4321, 'AbsTol', testCase.ValueTol, ...
                'ExtremumValueConstraint must report the extrema state value verbatim');
            testCase.verifyTrue(const.usesExtremum(ex), ...
                'usesExtremum must report the targeted extremum');
        end

        function checkCumPwrStorageStateOfChargeSumsAllStorages(testCase)
            %"Cumulative" means the SUM over every active storage, not the
            %first one and not the mean.  Two batteries with clearly
            %different charges make all three interpretations distinct.
            [lvdData, template, batteries] = testCase.buildTwoBatteryTemplate();
            fx = testCase.fixtureFromLvdData(lvdData, template);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            storStates = entry.getAllActivePwrStorageStates();
            testCase.assertEqual(numel(storStates), 2, ...
                'fixture must produce exactly two power storage states');

            charges = [30, 45];
            for(i = 1:numel(storStates))
                storStates(i).setStateOfCharge(charges(i));
            end

            stateLog = testCase.makeLog(fx, entry);

            const = CumPwrStorageStateOfChargeConstraint(fx.evt1, 0, 1000);
            [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(value, sum(charges), 'AbsTol', testCase.ValueTol, ...
                'cumulative state of charge must be the SUM over all active storages');
            testCase.verifyNotEqual(value, charges(1), ...
                'cumulative state of charge must not be just the first storage');
            testCase.verifyNotEqual(value, mean(charges), ...
                'cumulative state of charge must not be the mean');

            testCase.assertNotEmpty(batteries, 'fixture must return its batteries');
        end

        function checkGenericMAConstraintAltitudeMatchesRadiusMinusBodyRadius(testCase)
            %GenericMAConstraint routes through the shared Mission
            %Architect graph analysis task list.  'Altitude' has a trivial
            %closed form -- |r| minus the body radius -- so it is checked
            %against arithmetic on the position the test itself installed.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            entry.position = [900; 1200; 0];   %|r| = 1500 km exactly (3-4-5)
            entry.velocity = [0; 2; 0.5];
            stateLog = testCase.makeLog(fx, entry);

            const = GenericMAConstraint('Altitude', fx.evt1, 0, 1e6, ...
                struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value, ~, ~, type] = const.evalConstraint(stateLog, testCase.celBodyData);

            expected = 1500 - entry.centralBody.radius;
            testCase.verifyEqual(value, expected, 'AbsTol', 1e-8, ...
                'GenericMAConstraint(''Altitude'') must be |r| - bodyRadius');
            testCase.verifyEqual(type, 'Altitude', ...
                'GenericMAConstraint must report its constraintType string as the type');
        end

        function checkGeometricVectorConstraintsReadComponentsAndMagnitude(testCase)
            %A FixedVectorInFrame evaluated in the very frame it is defined
            %in must come back untouched.  Using the 3-4-12-13 Pythagorean
            %quadruple makes the magnitude exact in floating point, and
            %makes all three components distinct so an X/Y/Z mix-up cannot
            %hide.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            stateLog = testCase.makeLog(fx, entry);

            frame = entry.centralBody.getBodyCenteredInertialFrame();
            vect = [3; 4; 12];
            geoVect = FixedVectorInFrame(vect, frame, 'Test Vector', fx.lvdData);

            consts = { GeometricVectorXConstraint(geoVect, fx.evt1, -100, 100), ...
                       GeometricVectorYConstraint(geoVect, fx.evt1, -100, 100), ...
                       GeometricVectorZConstraint(geoVect, fx.evt1, -100, 100), ...
                       GeometricVectorMagConstraint(geoVect, fx.evt1, -100, 100) };
            expected = [vect(1), vect(2), vect(3), 13];
            labels   = {'X component', 'Y component', 'Z component', 'magnitude'};

            for(i = 1:numel(consts))
                const = consts{i};
                const.frame = frame;
                [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(value, expected(i), 'AbsTol', testCase.GeomTol, ...
                    sprintf('geometric vector %s constraint returned the wrong number', labels{i}));
            end
        end

        function checkTotalThrustAndThrustToWeightVanishWithEnginesOff(testCase)
            %Zero throttle is the one thrust value the test can assert with
            %no engine model knowledge at all, and it is also the value a
            %"throttle never reaches the engine" bug would break first.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0);
            stateLog = testCase.makeLog(fx, entry);

            thrustConst = TotalThrustConstraint(fx.evt1, 0, 1e6);
            [~, ~, thrust] = thrustConst.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(thrust, 0, 'AbsTol', 1e-12, ...
                'total thrust must be exactly zero with the engine shut down');

            t2wConst = ThrustToWeightConstraint(fx.evt1, 0, 10);
            [~, ~, t2w] = t2wConst.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(t2w, 0, 'AbsTol', 1e-12, ...
                'thrust to weight must be exactly zero with the engine shut down');

            %...and both must be strictly positive at full throttle, which
            %rules out the degenerate "always returns zero" implementation
            %that would otherwise satisfy the assertions above.
            entryOn = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entryOn, 1);
            stateLogOn = testCase.makeLog(fx, entryOn);
            [~, ~, thrustOn] = thrustConst.evalConstraint(stateLogOn, testCase.celBodyData);
            [~, ~, t2wOn]    = t2wConst.evalConstraint(stateLogOn, testCase.celBodyData);
            testCase.verifyGreaterThan(thrustOn, 0, ...
                'total thrust must be positive at full throttle');
            testCase.verifyGreaterThan(t2wOn, 0, ...
                'thrust to weight must be positive at full throttle');
        end

        function checkThrustToWeightMatchesHandComputedSeaLevelRatio(testCase)
            %Sea level thrust-to-weight is
            %
            %     T/W = thrust / (mass * gSurface),  gSurface = gm/R^2 * 1000
            %
            %with thrust in kN and mass in mT (the 1000s in the two unit
            %conversions cancel, which is exactly the kind of thing worth
            %pinning).  The mass is known independently: the test sets both
            %tank masses itself and the stock stage dry mass is read
            %straight off the stage object, never through the constraint.
            %
            %The thrust term is taken from TotalThrustConstraint -- a
            %DIFFERENT class -- rather than recomputed here.  Reproducing
            %the engine deck (vacuum/sea-level Isp blending against the
            %atmospheric pressure model) in the test file would be a bigger
            %and less trustworthy piece of code than the one line under
            %test.  What this case actually pins is the RATIO formula and
            %its units, not the engine model.
            fx = testCase.buildFixture();
            stage = fx.lvdData.launchVehicle.stages(1);

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 1);

            tankStates = entry.getAllTankStates();
            testCase.assertEqual(numel(tankStates), 1, 'stock vehicle should have one tank');
            tankStates(1).tankMass = 3.5;

            stateLog = testCase.makeLog(fx, entry);

            [~, ~, thrust] = TotalThrustConstraint(fx.evt1, 0, 1e6).evalConstraint(stateLog, testCase.celBodyData);
            [~, ~, t2w]    = ThrustToWeightConstraint(fx.evt1, 0, 10).evalConstraint(stateLog, testCase.celBodyData);

            bodyInfo = entry.centralBody;
            gSurface = (bodyInfo.gm / bodyInfo.radius^2) * 1000;      %m/s^2
            massMt   = stage.dryMass + 3.5;                            %mT
            expected = thrust / (massMt * gSurface);

            testCase.verifyGreaterThan(thrust, 0, ...
                'full throttle must produce positive thrust for this check to mean anything');
            testCase.verifyEqual(t2w, expected, 'RelTol', 1e-12, ...
                'thrust to weight does not match thrust/(mass*gSurface)');

            %Halving the vehicle mass must exactly double T/W.  That is a
            %scaling law the constraint cannot satisfy by accident if it
            %reads the wrong mass.
            entryLight = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entryLight, 1);
            lightTankStates = entryLight.getAllTankStates();
            lightTankStates(1).tankMass = 3.5 - massMt/2;
            stateLogLight = testCase.makeLog(fx, entryLight);
            [~, ~, t2wLight] = ThrustToWeightConstraint(fx.evt1, 0, 10).evalConstraint(stateLogLight, testCase.celBodyData);

            testCase.verifyEqual(t2wLight, 2*t2w, 'RelTol', 1e-9, ...
                'halving the vehicle mass must double the sea level thrust to weight ratio');
        end

        function checkEventDeltaVExpendedMatchesTsiolkovskyRatio(testCase)
            %Delta-V expended is accumulated pairwise between consecutive
            %entries of the event, using the rocket equation with an
            %effective Isp derived from the thrust and mass flow at the
            %FIRST entry of each pair:
            %
            %     dv = (thrust / |mdot|) * ln(m1 / m2)
            %
            %Three answers here are exactly known without any engine
            %knowledge at all:
            %
            %  (a) a single-entry event has no pair to integrate over -> 0
            %  (b) an event whose mass never drops has nothing expended -> 0
            %  (c) for two burns that START from the SAME first entry, the
            %      thrust/|mdot| factor is identical, so the RATIO of the
            %      two delta-Vs must be exactly ln(m1/m2a) / ln(m1/m2b) --
            %      masses the test sets itself.
            %
            %(c) is the real oracle: it pins the rocket-equation form and
            %the mass bookkeeping without reimplementing the engine deck.
            fx = testCase.buildFixture();
            dryMassMt = fx.lvdData.launchVehicle.stages(1).dryMass;

            single = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(single, 1);
            [~, ~, valueSingle] = EventDeltaVExpendedConstraint(fx.evt1, 0, 1e6) ...
                .evalConstraint(testCase.makeLog(fx, single), testCase.celBodyData);
            testCase.verifyEqual(valueSingle, 0, 'AbsTol', 1e-12, ...
                'a single-entry event cannot have expended any delta-V');

            coastA = testCase.makeEntry(fx, fx.evt1, 0);   testCase.setThrottle(coastA, 0);
            coastB = testCase.makeEntry(fx, fx.evt1, 60);  testCase.setThrottle(coastB, 0);
            coastC = testCase.makeEntry(fx, fx.evt1, 120); testCase.setThrottle(coastC, 0);
            [~, ~, valueCoast] = EventDeltaVExpendedConstraint(fx.evt1, 0, 1e6) ...
                .evalConstraint(testCase.makeLog(fx, [coastA, coastB, coastC]), testCase.celBodyData);
            testCase.verifyEqual(valueCoast, 0, 'AbsTol', 1e-12, ...
                'a coasting (zero throttle) event cannot have expended any delta-V');

            propStart = 4;
            propEndA  = 3;
            propEndB  = 2;
            dvA = testCase.evalBurnDeltaV(fx, propStart, propEndA);
            dvB = testCase.evalBurnDeltaV(fx, propStart, propEndB);

            testCase.verifyGreaterThan(dvA, 0, ...
                'a full throttle event that burns propellant must report positive delta-V');
            testCase.verifyGreaterThan(dvB, dvA, ...
                'burning more propellant from the same start must expend more delta-V');

            m1  = dryMassMt + propStart;
            m2a = dryMassMt + propEndA;
            m2b = dryMassMt + propEndB;
            expectedRatio = log(m1/m2a) / log(m1/m2b);

            testCase.verifyEqual(dvA/dvB, expectedRatio, 'RelTol', 1e-9, ...
                'expended delta-V does not scale as ln(m1/m2) between the two burns');

            %A pair whose mass INCREASES must contribute nothing: the
            %rocket equation is only applied when totalMass1 > totalMass2.
            dvBackwards = testCase.evalBurnDeltaV(fx, 3, 4);
            testCase.verifyEqual(dvBackwards, 0, 'AbsTol', 1e-12, ...
                'a pair whose vehicle mass increases must expend no delta-V');
        end

        %% ---------------------------------------------------------------
        %  Metadata and set-level aggregation
        %  ---------------------------------------------------------------

        function checkConstraintMetadataAndBoundsAccessors(testCase)
            fx = testCase.buildFixture();

            const = ThrottleConstraint(fx.evt1, 15, 85);
            [lb, ub] = const.getBounds();
            testCase.verifyEqual([lb, ub], [15, 85], 'AbsTol', testCase.ValueTol, ...
                'getBounds must return the constructed bounds');

            testCase.verifyEqual(const.getConstraintType(), 'Throttle', ...
                'getConstraintType returned the wrong string');
            testCase.verifyEqual(const.getName(), 'Throttle - Event 1', ...
                'getName must be "<type> - Event <n>"');
            testCase.verifySameHandle(const.getConstraintEvent(), fx.evt1, ...
                'getConstraintEvent must return the constrained event handle');
            testCase.verifyTrue(const.active, ...
                'constraints must default to active');

            %Event 2 was appended to the script after event 1, so its
            %number -- and therefore the generated name -- must be 2.
            const2 = ThrottleConstraint(fx.evt2, 0, 100);
            testCase.verifyEqual(const2.getName(), 'Throttle - Event 2', ...
                'getName must track the event''s position in the script');

            %A ground object constraint reports its own type/unit metadata
            %through the same base class interface.
            [lvdData, template, grdObj] = testCase.buildGroundObjTemplate( ...
                deg2rad(10), deg2rad(25), 0);
            fx2 = testCase.fixtureFromLvdData(lvdData, template);
            azConst = GroundObjAzConstraint(grdObj, fx2.evt1, 0, 360);
            testCase.verifyEqual(azConst.getConstraintType(), 'Ground Object Azimuth', ...
                'ground object azimuth constraint type string is wrong');
            [unit, lbLim, ubLim] = azConst.getConstraintStaticDetails();
            testCase.verifyEqual(unit, 'deg', 'ground object azimuth unit must be degrees');
            testCase.verifyEqual([lbLim, ubLim], [-360, 360], ...
                'ground object azimuth bound limits must span +/- 360 degrees');
            testCase.verifyTrue(azConst.usesGroundObj(grdObj), ...
                'usesGroundObj must report the targeted ground object');
        end

        function checkUsesEventTracksBothEventsInStateComparison(testCase)
            %usesEvent drives "can this event be deleted?" in the GUI and
            %"does this constraint need event N propagated?" in the
            %optimizer.  In state comparison mode the constraint depends on
            %TWO events, and both must be reported.
            fx = testCase.buildFixture();

            const = ThrottleConstraint(fx.evt1, 0, 100);
            testCase.verifyTrue(const.usesEvent(fx.evt1), ...
                'usesEvent must be true for the constrained event');
            testCase.verifyFalse(const.usesEvent(fx.evt2), ...
                'usesEvent must be false for an unrelated event in FixedBounds mode');

            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            testCase.verifyTrue(const.usesEvent(fx.evt1), ...
                'usesEvent must still be true for the constrained event');
            testCase.verifyTrue(const.usesEvent(fx.evt2), ...
                'usesEvent must be true for the state comparison event too');
        end

        function checkConstraintSetSkipsInactiveConstraintsAndKeepsOrder(testCase)
            %ConstraintSet flattens each constraint's c/ceq into one long
            %vector and records which constraint each slot came from.  A
            %deactivated constraint must vanish completely -- it must not
            %contribute a slot, and it must not shift the bookkeeping
            %indices of the constraints after it.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            testCase.setThrottle(entry, 0.50);
            stateLog = testCase.makeLog(fx, entry);

            cSet = fx.lvdData.optimizer.constraints;

            constA = ThrottleConstraint(fx.evt1, 10, 90);   %2 inequalities
            constB = ThrottleConstraint(fx.evt1, 20, 80);   %2 inequalities
            constC = ThrottleConstraint(fx.evt1, 50, 50);   %1 equality
            cSet.addConstraint(constA);
            cSet.addConstraint(constB);
            cSet.addConstraint(constC);

            testCase.verifyEqual(cSet.getNumConstraints(), 3, ...
                'ConstraintSet did not record all three constraints');

            [c, ceq, value] = cSet.evalConstraints([], false, [], false, stateLog);

            testCase.verifyEqual(c(:)', [10 - 50, 50 - 90, 20 - 50, 50 - 80], ...
                'AbsTol', testCase.ValueTol, ...
                'ConstraintSet must concatenate inequality outputs in constraint order');
            testCase.verifyEqual(ceq(:)', 50 - 50, 'AbsTol', testCase.ValueTol, ...
                'ConstraintSet must concatenate equality outputs after them');
            testCase.verifyEqual(value(:)', [50, 50, 50], 'AbsTol', testCase.ValueTol, ...
                'ConstraintSet must report one raw value per constraint');

            %Deactivate the middle constraint: its two inequality slots must
            %disappear and nothing else may change.
            constB.active = false;
            [c2, ceq2, value2] = cSet.evalConstraints([], false, [], false, stateLog);

            testCase.verifyEqual(c2(:)', [10 - 50, 50 - 90], 'AbsTol', testCase.ValueTol, ...
                'an inactive constraint must contribute no inequality slots');
            testCase.verifyEqual(ceq2(:)', 0, 'AbsTol', testCase.ValueTol, ...
                'deactivating one constraint must not disturb the others'' equality output');
            testCase.verifyEqual(numel(value2), 2, ...
                'an inactive constraint must contribute no raw value slot');
        end

        %% ---------------------------------------------------------------
        %  Regression guards for previously-fixed defects
        %  ---------------------------------------------------------------

        function checkBodyAngularVelStateComparisonAssignsValueStateComp(testCase)
            %In ConstraintEvalTypeEnum.StateComparison mode each of the four
            %angular velocity constraints must evaluate the SAME angular rate
            %task on the comparison event's state log entry and store the
            %result in valueStateComp, the way ThrottleConstraint and
            %GroundObjAzConstraint do.
            %
            %All four used to discard the return value -- the
            %"valueStateComp = " on the left hand side was simply missing at
            %line 65 of each file, even though the immediately preceding
            %lines build stateLogEntryStateComp and convert its element set
            %into the primary entry's inertial frame.  Line 70 then passed
            %the never-assigned variable into computeCAndCeqValues, so MATLAB
            %raised "Unrecognized function or variable 'valueStateComp'" and
            %the constraint could not be evaluated at all in state comparison
            %mode; the optimization aborted the moment a user selected it
            %(ConstraintSet.m:138 is on the optimizer hot path).  FixedBounds
            %mode was unaffected -- line 67 assigns NaN -- which is why the
            %default evalType hid this.
            %
            %WHY THIS GUARD READS SOURCE RATHER THAN RUNNING THE CONSTRAINT:
            %lvd_AttitudeRateTasks calls rotm2quat, which ships with the
            %Robotics System Toolbox and is NOT installed in this
            %environment.  Every angular rate constraint therefore dies
            %before it can reach line 65.  A purely runtime check would pass
            %vacuously here by asserting the missing toolbox instead of the
            %assignment.  The source assertion is toolbox independent and
            %fails the instant somebody drops the assignment again; the
            %runtime consequence is additionally probed below, but only on a
            %machine where rotm2quat is available.
            classNames = { 'BodyAngularVelXConstraint', ...
                           'BodyAngularVelYConstraint', ...
                           'BodyAngularVelZConstraint', ...
                           'TotalBodyAngularVelConstraint' };

            for(i = 1:numel(classNames))
                className = classNames{i};
                classFile = which(className);
                testCase.assertNotEmpty(classFile, ...
                    sprintf('could not locate the source file for %s', className));

                lines = strsplit(fileread(classFile), newline);

                compBranchLines = find(contains(lines, 'lvd_AttitudeRateTasks(stateLogEntryStateComp'));
                testCase.assertEqual(numel(compBranchLines), 1, ...
                    sprintf(['%s should contain exactly one lvd_AttitudeRateTasks call on the ' ...
                             'state comparison entry'], className));

                compLine = strtrim(lines{compBranchLines});
                testCase.verifyTrue(startsWith(compLine, 'valueStateComp = lvd_AttitudeRateTasks('), ...
                    sprintf(['%s line %d must capture the state comparison angular rate into ' ...
                             'valueStateComp.  A bare "lvd_AttitudeRateTasks(...)" call means the ' ...
                             'assignment has been dropped again and StateComparison mode is broken. ' ...
                             'Line reads: %s'], className, compBranchLines, compLine));

                %The FixedBounds branch assigns it too; that is precisely why
                %the defect was invisible under the default evalType.
                testCase.verifyTrue(any(contains(lines, 'valueStateComp = NaN;')), ...
                    sprintf(['%s should still assign valueStateComp = NaN on the FixedBounds ' ...
                             'branch'], className));
            end

            %Runtime confirmation, only where the toolbox allows it.
            if(isempty(which('rotm2quat')))
                return;
            end

            fx = testCase.buildFixture();
            e1 = testCase.makeEntry(fx, fx.evt1, 0);
            e2 = testCase.makeEntry(fx, fx.evt2, 100);
            stateLog = testCase.makeLog(fx, [e1, e2]);
            frame = e1.centralBody.getBodyCenteredInertialFrame();

            for(i = 1:numel(classNames))
                className = classNames{i};
                const = feval(className, fx.evt1, -1, 1);
                const.frame = frame;

                const.evalType = ConstraintEvalTypeEnum.StateComparison;
                const.stateCompEvent = fx.evt2;
                const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;

                [c, ceq] = const.evalConstraint(stateLog, testCase.celBodyData);

                %Equals comparison => the constraint is an equality on the
                %difference of the two events' rates, so ceq must be a real
                %finite number and c must be empty.  An "Unrecognized
                %function or variable 'valueStateComp'" error here is the
                %original defect returning.
                testCase.verifyEmpty(c, sprintf( ...
                    '%s in Equals StateComparison mode must produce no inequality value', className));
                testCase.verifyTrue(isscalar(ceq) && isreal(ceq) && not(isnan(ceq)), sprintf( ...
                    ['%s must produce a real, finite equality value from the two events'' ' ...
                     'angular rates; got %s'], className, mat2str(ceq)));
            end
        end

        %% ---------------------------------------------------------------
        %  Shared fixtures
        %  ---------------------------------------------------------------

        function fx = buildFixture(testCase)
            %buildFixture Stock vehicle plus a two-event script.
            %
            % Event 2 exists purely so state comparison and event selection
            % cases have a second event to point at; nothing is propagated
            % here, the tests synthesize their own state log entries.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            template = lvdData.initStateModel.getInitialStateLogEntry();
            fx = testCase.fixtureFromLvdData(lvdData, template);
        end

        function fx = fixtureFromLvdData(~, lvdData, template)
            %fixtureFromLvdData Wraps an already-built LvdData (plus its
            %state log entry template) into the standard two-event fixture
            %the checks below expect.
            evt1 = lvdData.script.getEventForInd(1);

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(100);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            fx = struct('lvdData', lvdData, 'template', template, ...
                        'evt1', evt1, 'evt2', evt2);
        end

        function entry = makeEntry(~, fx, event, time)
            %makeEntry One independent state log entry tagged to an event.
            %
            % Everything in LVD is a handle class, so each entry has to be
            % a deep copy -- otherwise setting the throttle on "entry 3"
            % would silently set it on entries 1 and 2 as well and every
            % entry-selection assertion in this file would pass vacuously.
            entry = fx.template.deepCopy();
            entry.event = event;
            entry.time = time;
        end

        function stateLog = makeLog(~, fx, entries)
            stateLog = LaunchVehicleStateLog(fx.lvdData);
            stateLog.appendStateLogEntries(entries);
        end

        function setThrottle(testCase, entry, frac)
            %setThrottle Drives the entry's throttle to a known fraction.
            %
            % A FRESH throttle model is installed rather than mutating the
            % existing one.  LaunchVehicleStateLogEntry.deepCopy classifies
            % steeringModel and throttleModel as "stuff that does not
            % change" and copies the HANDLES
            % (@LaunchVehicleStateLogEntry/LaunchVehicleStateLogEntry.m
            % lines 270-271), so every entry deep copied from one template
            % shares a single throttle model object.  Writing through
            % entry.throttleModel.throttleModel.constTerm would therefore
            % change the throttle of every other entry in the fixture too,
            % and the entry-selection cases below would pass vacuously
            % because all the candidate entries would read alike.
            %
            % The stock model is a polynomial in time, so setting the
            % constant term and leaving every other coefficient at zero
            % makes the throttle exactly `frac` at all times.
            testCase.assertClass(entry.throttleModel, 'ThrottlePolyModel', ...
                'setThrottle assumes the stock polynomial throttle model');

            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.throttleModel.constTerm = frac;
            entry.throttleModel = model;

            testCase.assertEqual(entry.throttle, frac, 'AbsTol', 1e-12, ...
                'setThrottle failed to move the entry throttle');
        end

        function [stateLog, fx] = buildTwoEventThrottleLog(testCase, frac1, frac2)
            %buildTwoEventThrottleLog One entry on each event, each with its
            %own throttle, giving values 100*frac1 and 100*frac2.
            fx = testCase.buildFixture();
            e1 = testCase.makeEntry(fx, fx.evt1, 0);
            e2 = testCase.makeEntry(fx, fx.evt2, 100);
            testCase.setThrottle(e1, frac1);
            testCase.setThrottle(e2, frac2);
            stateLog = testCase.makeLog(fx, [e1, e2]);
        end

        function dv = evalBurnDeltaV(testCase, fx, propStart, propEnd)
            %evalBurnDeltaV Two-entry full-throttle burn whose tank mass
            %drops from propStart to propEnd, evaluated through
            %EventDeltaVExpendedConstraint.
            %
            % deepCopy DOES give each entry its own stage states (and
            % therefore its own tank states), so the two masses really are
            % independent -- unlike the throttle model, see setThrottle.
            burnA = testCase.makeEntry(fx, fx.evt1, 0);
            burnB = testCase.makeEntry(fx, fx.evt1, 60);
            testCase.setThrottle(burnA, 1);
            testCase.setThrottle(burnB, 1);

            statesA = burnA.getAllTankStates();
            statesB = burnB.getAllTankStates();
            statesA(1).tankMass = propStart;
            statesB(1).tankMass = propEnd;

            [~, ~, dv] = EventDeltaVExpendedConstraint(fx.evt1, 0, 1e6) ...
                .evalConstraint(testCase.makeLog(fx, [burnA, burnB]), testCase.celBodyData);
        end

        function [lvdData, template, tank1, tank2] = buildTwoTankTemplate(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            stg.addTank(tank2);

            lvdData.initStateModel.clearAllTankStatesAndRegenerate();
            template = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, template, sw] = buildStopwatchTemplate(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw = LaunchVehicleStopwatch(lvdData);
            sw.startOn = StopwatchRunningEnum.Running;
            sw.startValue = 0;
            lvdData.launchVehicle.addStopwatch(sw);

            template = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, template, ex] = buildExtremumTemplate(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            ex = LaunchVehicleExtrema(lvdData);
            ex.quantStr = 'Altitude';
            ex.unitStr = 'km';
            ex.frame = testCase.kerbin.getBodyCenteredInertialFrame();
            ex.type = LaunchVehicleExtremaTypeEnum.Maximum;
            lvdData.launchVehicle.addExtremum(ex);

            template = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, template, batteries] = buildTwoBatteryTemplate(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            stgState = lvdData.initStateModel.stageStates(1);

            batteries = LaunchVehicleBasicElectricalBattery.empty(1,0);
            for(i = 1:2)
                battery = LaunchVehicleBasicElectricalBattery(stg);
                battery.name = sprintf('Test Battery %d', i);
                battery.maxCapacity = 100;
                battery.initialStateOfCharge = 10*i;
                stg.addPwrStorage(battery);
                stgState.addPowerStorageState(battery.createDefaultInitialState(stgState));

                batteries(end+1) = battery; %#ok<AGROW>
            end

            template = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, template, grdObj, bodyInfo] = buildGroundObjTemplate(testCase, lat, long, alt)
            %buildGroundObjTemplate Stock vehicle around a NON-ROTATING copy
            %of Kerbin, carrying a single fixed ground station.
            %
            % Non-rotating-body trick: rotperiod = Inf AND rotini = 0 makes
            % the body fixed frame numerically identical to the body
            % centered inertial frame at every epoch.  Without it the
            % oracle below would have to reproduce the body spin angle
            % model as well, which is a separate piece of production code
            % with its own tests.  With it, the station's inertial position
            % is just the spherical (lat, long, alt) point, which is
            % something the test can write down directly.
            %
            % Both properties must be set: getBodySpinAngle_alg adds
            % deg2rad(rotini) even when rotperiod is infinite.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;

            bodyFixedFrame = bodyInfo.getBodyFixedFrame();
            stnElems = GeographicElementSet(0, lat, long, alt, 0, 0, 0, bodyFixedFrame);
            wayPt = LaunchVehicleGroundObjectWayPt(stnElems, 0);
            grdObj = LaunchVehicleGroundObject('Test Station', 'test station', 0, wayPt);
            lvdData.groundObjs.addGroundObj(grdObj);

            template = lvdData.initStateModel.getInitialStateLogEntry();
            template.centralBody = bodyInfo;
        end

        function [prod, ref] = evalGroundObjTriple(testCase, lat, long, alt, scRadius, scLat, scLong)
            %evalGroundObjTriple Runs the three ground object constraints
            %against one geometry and returns both the production numbers
            %and the independently computed oracle.
            [lvdData, template, grdObj, bodyInfo] = testCase.buildGroundObjTemplate(lat, long, alt);
            fx = testCase.fixtureFromLvdData(lvdData, template);

            rSc = scRadius * [cos(scLat)*cos(scLong); cos(scLat)*sin(scLong); sin(scLat)];

            entry = testCase.makeEntry(fx, fx.evt1, 0);
            entry.centralBody = bodyInfo;
            entry.position = rSc;
            entry.velocity = [0; 0; 0];
            stateLog = testCase.makeLog(fx, entry);

            [~, ~, azVal]  = GroundObjAzConstraint(grdObj, fx.evt1, 0, 360) ...
                .evalConstraint(stateLog, testCase.celBodyData);
            [~, ~, elVal]  = GroundObjElConstraint(grdObj, fx.evt1, -90, 90) ...
                .evalConstraint(stateLog, testCase.celBodyData);
            [~, ~, rngVal] = GroundObjRangeConstraint(grdObj, fx.evt1, 0, 1e6) ...
                .evalConstraint(stateLog, testCase.celBodyData);

            prod = struct('az', azVal, 'el', elVal, 'rng', rngVal);
            ref = testCase.refGroundObjAzElRange(bodyInfo.radius, lat, long, alt, rSc);
        end

        function ref = refGroundObjAzElRange(~, bodyRadius, lat, long, alt, rSc)
            %refGroundObjAzElRange Independent look-angle oracle.
            %
            % This is written out from the definitions rather than by
            % calling computeNedFrame / getAzElRngFromNedPosition, which is
            % the pair of helpers lvd_GrdObjTasks (and therefore the three
            % ground object constraints) actually goes through.
            %
            % The body is spherical in LVD's geographic conversion, so a
            % station at geodetic-equals-geocentric latitude phi, longitude
            % lambda and altitude h sits at
            %
            %     rStn = (R + h) * [cos(phi)cos(lambda);
            %                       cos(phi)sin(lambda);
            %                       sin(phi)]
            %
            % The local topocentric triad, expressed in the same (inertial,
            % because the body is non-rotating) axes:
            %
            %     Up    = [ cos(phi)cos(lambda);  cos(phi)sin(lambda);  sin(phi)]
            %     North = [-sin(phi)cos(lambda); -sin(phi)sin(lambda);  cos(phi)]
            %     East  = [-sin(lambda);           cos(lambda);         0       ]
            %     Down  = -Up
            %
            % Projecting the station-to-vehicle vector onto that triad
            % gives the NED coordinates, from which
            %
            %     range     = |rel|
            %     elevation = atan2(Up.rel, hypot(North.rel, East.rel))
            %     azimuth   = atan2(East.rel, North.rel), wrapped to [0, 2pi)
            %
            % Azimuth is measured clockwise from local north and elevation
            % positive above the local horizon, matching the convention the
            % LVD GUI documents.  Both are returned in degrees and the
            % range in km, which is what the constraints report.
            rStn = (bodyRadius + alt) * [cos(lat)*cos(long); cos(lat)*sin(long); sin(lat)];

            up    = [ cos(lat)*cos(long);  cos(lat)*sin(long);  sin(lat)];
            north = [-sin(lat)*cos(long); -sin(lat)*sin(long);  cos(lat)];
            east  = [-sin(long);           cos(long);           0       ];

            rel = rSc(:) - rStn;

            n = dot(north, rel);
            e = dot(east,  rel);
            u = dot(up,    rel);

            horiz = hypot(n, e);

            ref = struct();
            ref.rStn = rStn;
            ref.rSc  = rSc(:);
            ref.rng  = norm(rel);
            ref.el   = rad2deg(atan2(u, horiz));
            ref.az   = rad2deg(mod(atan2(e, n), 2*pi));
        end
    end
end
