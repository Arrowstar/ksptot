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
    % Every concrete constraint class registered in ConstraintEnum has at
    % least one value check against an independent oracle here, and the
    % registry itself is swept (ConstraintEnumRegistryIsCompleteAnd-
    % Constructible) so a class added later without a registration -- or
    % a registration whose default constructor is broken -- fails here.
    % The less obvious oracles:
    %
    %   * Attitude angles (pitch/roll/yaw, bank/AoA/sideslip and their
    %     inertial forms) are checked by composing the body DCM FORWARD
    %     from chosen angles on a hand-built NED or wind triad, installing
    %     it with TestFixedDcmSteeringModel, and requiring the constraint to
    %     return the chosen angles.  No Euler extraction is shared with
    %     production.  The body-fixed wind is v - omega x r, written in
    %     inertial axes, so the body spin angle model is never needed.
    %   * Body angular rates use a rigid rotation dcm(t) = R(u, w t) * D0,
    %     whose body-frame rate is exactly w * D0' * u.  These need
    %     rotm2quat (Robotics System Toolbox) and are assumption-filtered
    %     where it is not installed.
    %   * Two-body impact point: Kepler's equation in closed form -- the
    %     impact is the descending crossing of r = R, nu* = 2pi -
    %     acos((p/R - 1)/e), reached after mod(M(nu*) - M0, 2pi)/n, and the
    %     longitude is rotated by the body spin angle at impact.
    %   * GenericMAConstraint quantities are checked against the
    %     Keplerian elements the test used to BUILD the state (refCoe2Rv),
    %     not against a state -> elements conversion.
    %   * Sun geometry (solar beta, sun phase) takes the body's position
    %     relative to the Sun from getPositOfBodyWRTSun as an input; the
    %     ephemeris is not under test, the geometry built on it is.
    %   * Thrust-derived quantities (sensed acceleration, remaining delta-V)
    %     take thrust and Isp from the engine's own vacuum performance
    %     (getVacThrust/getVacIsp) and check the formula and the mass
    %     bookkeeping layered on top of them.

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
            'EventDurationSignedAndAbsoluteValues', ...
            'EventDurationStateComparisonAgainstOtherEvent', ...
            'ConstraintMetadataAndBoundsAccessors', ...
            'UsesEventTracksBothEventsInStateComparison', ...
            'ConstraintSetSkipsInactiveConstraintsAndKeepsOrder', ...
            'BodyAngularVelStateComparisonAssignsValueStateComp', ...
            'EulerAngleConstraintsRecoverComposedAttitude', ...
            'AeroAngleConstraintsUseBodyFixedRelativeWind', ...
            'InertialAeroAngleConstraintsUseInertialVelocity', ...
            'AttitudeConstraintsStateComparisonReadsCompEntryAttitude', ...
            'BodyAngularVelConstraintsMatchRigidRotationOracle', ...
            'TwoBodyImpactPointConstraintsMatchKeplerOracle', ...
            'TwoBodyImpactPointConstraintsReportSentinelsWithoutImpact', ...
            'CalculusCalculationValueConstraintReadsNamedCalc', ...
            'CalculusCalculationStateComparisonUsesCompEventCalcState', ...
            'GeometricAngleMagConstraintSignedAngleAbsValueAndDotProduct', ...
            'PluginConstraintEvaluatesPluginCodeOnEachEntry', ...
            'GenericMAConstraintOrbitalQuantitiesMatchElementOracle', ...
            'GenericMAConstraintHyperbolicQuantitiesMatchAsymptoteOracle', ...
            'GenericMAConstraintBodyFixedFrameQuantitiesMatchSpinOracle', ...
            'GenericMAConstraintHeightAboveTerrainSubtractsHeightMap', ...
            'GenericMAConstraintSensedAccelAndRemainingDeltaV', ...
            'GenericMAConstraintCumulativeDeltaVAccumulatesAcrossEvents', ...
            'GenericMAConstraintSunGeometryQuantities', ...
            'GenericMAConstraintStateComparisonConvertsCompEntryToFrame', ...
            'AttitudeRateAndImpactTypeStringsAndStaticDetails', ...
            'ConstraintEnumRegistryIsCompleteAndConstructible', ...
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

        function checkEventDurationSignedAndAbsoluteValues(testCase)
            %Event duration is (last entry time) - (first entry time) of
            %the constrained event only.  Entries of other events in the
            %log must not leak in, and a backwards event must come out
            %negative for the signed constraint and positive for |.|.
            fx = testCase.buildFixture();

            single = testCase.makeEntry(fx, fx.evt1, 42);
            singleLog = testCase.makeLog(fx, single);
            [~, ~, vS] = EventDurationConstraint(fx.evt1, -1e6, 1e6).evalConstraint(singleLog, testCase.celBodyData);
            [~, ~, vA] = EventAbsDurationConstraint(fx.evt1, 0, 1e6).evalConstraint(singleLog, testCase.celBodyData);
            testCase.verifyEqual([vS, vA], [0, 0], ...
                'a single-entry event must have zero duration');

            %Forward: evt1 at t = 10, 25, 70 (duration 60) with evt2
            %entries at 200 and 500 that must be ignored.
            fwd = [testCase.makeEntry(fx, fx.evt1, 10), testCase.makeEntry(fx, fx.evt1, 25), ...
                   testCase.makeEntry(fx, fx.evt1, 70), testCase.makeEntry(fx, fx.evt2, 200), ...
                   testCase.makeEntry(fx, fx.evt2, 500)];
            fwdLog = testCase.makeLog(fx, fwd);

            [c, ceq, value] = EventDurationConstraint(fx.evt1, 0, 100).evalConstraint(fwdLog, testCase.celBodyData);
            testCase.verifyEqual(value, 60, 'AbsTol', testCase.ValueTol, ...
                'signed duration of a forward event must be last - first entry time');
            testCase.verifyEqual(c(:)', [0 - 60, 60 - 100], 'AbsTol', testCase.ValueTol);
            testCase.verifyEmpty(ceq);

            [~, ~, value] = EventAbsDurationConstraint(fx.evt1, 0, 100).evalConstraint(fwdLog, testCase.celBodyData);
            testCase.verifyEqual(value, 60, 'AbsTol', testCase.ValueTol, ...
                'absolute duration of a forward event must equal the signed duration');

            %Backward: evt1 at t = 70, 25, 10 (duration -60).
            bwd = [testCase.makeEntry(fx, fx.evt1, 70), testCase.makeEntry(fx, fx.evt1, 25), ...
                   testCase.makeEntry(fx, fx.evt1, 10)];
            bwdLog = testCase.makeLog(fx, bwd);

            [c, ~, value] = EventDurationConstraint(fx.evt1, -100, 0).evalConstraint(bwdLog, testCase.celBodyData);
            testCase.verifyEqual(value, -60, 'AbsTol', testCase.ValueTol, ...
                'signed duration of a backward event must be negative');
            testCase.verifyEqual(c(:)', [-100 - (-60), -60 - 0], 'AbsTol', testCase.ValueTol);

            [~, ceq, value] = EventAbsDurationConstraint(fx.evt1, 60, 60).evalConstraint(bwdLog, testCase.celBodyData);
            testCase.verifyEqual(value, 60, 'AbsTol', testCase.ValueTol, ...
                'absolute duration of a backward event must be positive');
            testCase.verifyEqual(ceq, 0, 'AbsTol', testCase.ValueTol, ...
                'lb == ub must emit the equality (value - ub)');

            %Metadata, defaults and GUI registration.
            sCon = EventDurationConstraint.getDefaultConstraint([], []);
            aCon = EventAbsDurationConstraint.getDefaultConstraint([], []);
            testCase.verifyClass(sCon, 'EventDurationConstraint');
            testCase.verifyClass(aCon, 'EventAbsDurationConstraint');
            testCase.verifyEqual(sCon.getConstraintType(), 'Event Duration');
            testCase.verifyEqual(aCon.getConstraintType(), 'Event Duration (Absolute Value)');
            [unitS, lbLimS, ubLimS] = sCon.getConstraintStaticDetails();
            [unitA, lbLimA, ubLimA] = aCon.getConstraintStaticDetails();
            testCase.verifyEqual({unitS, lbLimS, ubLimS}, {'sec', -Inf, Inf});
            testCase.verifyEqual({unitA, lbLimA, ubLimA}, {'sec', 0, Inf});

            [~, enumS] = ConstraintEnum.getIndForName('Event Duration');
            [~, enumA] = ConstraintEnum.getIndForName('Event Duration (Absolute Value)');
            testCase.verifyEqual(enumS.class, 'EventDurationConstraint');
            testCase.verifyEqual(enumA.class, 'EventAbsDurationConstraint');
        end

        function checkEventDurationStateComparisonAgainstOtherEvent(testCase)
            %State comparison must evaluate the SAME duration quantity on
            %stateCompEvent.  evt1 runs forward 60 s (10 -> 70), evt2 runs
            %backward 90 s (160 -> 70): signed -90, absolute 90.
            fx = testCase.buildFixture();
            entries = [testCase.makeEntry(fx, fx.evt1, 10), testCase.makeEntry(fx, fx.evt1, 70), ...
                       testCase.makeEntry(fx, fx.evt2, 160), testCase.makeEntry(fx, fx.evt2, 100), ...
                       testCase.makeEntry(fx, fx.evt2, 70)];
            stateLog = testCase.makeLog(fx, entries);

            sCon = EventDurationConstraint(fx.evt1, 0, 0);
            sCon.evalType = ConstraintEvalTypeEnum.StateComparison;
            sCon.stateCompEvent = fx.evt2;
            sCon.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;
            [c, ceq, value, ~, ~, ~, ~, valueStateComp] = sCon.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [60, -90], 'AbsTol', testCase.ValueTol, ...
                'signed state comparison must read the signed duration of both events');
            testCase.verifyEqual(c, -90 - 60, 'AbsTol', testCase.ValueTol, ...
                'GreaterThan must emit valueStateComp - value');
            testCase.verifyEmpty(ceq);

            aCon = EventAbsDurationConstraint(fx.evt1, 0, 0);
            aCon.evalType = ConstraintEvalTypeEnum.StateComparison;
            aCon.stateCompEvent = fx.evt2;
            aCon.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;
            aCon.setScaleFactor(10);
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = aCon.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [60, 90], 'AbsTol', testCase.ValueTol, ...
                'absolute state comparison must read |duration| of both events');
            testCase.verifyEqual(c, (60 - 90)/10, 'AbsTol', testCase.ValueTol, ...
                'LessThan must emit (value - valueStateComp)/normFact');

            aCon.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
            [c, ceq] = aCon.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEmpty(c);
            testCase.verifyEqual(ceq, (60 - 90)/10, 'AbsTol', testCase.ValueTol);

            testCase.verifyTrue(aCon.usesEvent(fx.evt1) && aCon.usesEvent(fx.evt2), ...
                'state comparison duration constraint must report using both events');
            aCon.evalType = ConstraintEvalTypeEnum.FixedBounds;
            testCase.verifyFalse(aCon.usesEvent(fx.evt2), ...
                'fixed-bounds duration constraint must not claim the comparison event');
        end

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
        %  Attitude angle constraints
        %  ---------------------------------------------------------------

        function checkEulerAngleConstraintsRecoverComposedAttitude(testCase)
            %Roll/pitch/yaw are the 3-2-1 (z-y-x) Euler angles of the body
            %axes relative to the local North-East-Down triad.  The oracle
            %runs that definition FORWARD,
            %
            %   dcm = [N E D] * Rz(yaw) * Ry(pitch) * Rx(roll),
            %
            %from angles the test picked, and the constraints must hand
            %them back.  Pitch is reported in [-90, 90]; roll and yaw are
            %wrapped to [0, 360), so a negative input comes back as
            %360 + angle.
            %
            %Each attitude is evaluated at two epochs.  N, E and D are fixed
            %by the position and the spin pole alone, so body rotation
            %between the epochs must not move the answer even though the
            %production path goes through the body-fixed frame.
            fx = testCase.buildFixture();
            cases = { ...
                {[700; 200; 300],    [ 110,  20, -30], 'northern hemisphere, negative yaw'}, ...
                {[-300; -650; -400], [ -45, -60, 200], 'southern hemisphere, negative roll'}, ...
                {[50; 790; 20],      [  10,  85,  90], 'pitch near +90'}, ...
                {[640; -150; -320],  [ 250, -15, 135], 'roll beyond 180'} ...
            };

            for(i = 1:numel(cases))
                cs = cases{i};
                rVect = cs{1};
                rpy = cs{2};
                dcm = refNedTriad(rVect) * refRz(deg2rad(rpy(3))) * refRy(deg2rad(rpy(2))) * refRx(deg2rad(rpy(1)));

                for(ut = [0, 4321])
                    entry = testCase.makeAttitudeEntry(fx, fx.evt1, ut, rVect, [0.3; 1.9; -0.2], dcm);
                    stateLog = testCase.makeLog(fx, entry);

                    [~, ~, roll]  = RollAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);
                    [~, ~, pitch] = PitchAngleConstraint(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
                    [~, ~, yaw]   = YawAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);

                    label = sprintf('(%s, ut = %g)', cs{3}, ut);
                    testCase.verifyEqual(pitch, rpy(2), 'AbsTol', testCase.AngTol, ['PitchAngleConstraint ' label]);
                    testCase.verifyEqual(roll, mod(rpy(1), 360), 'AbsTol', testCase.AngTol, ['RollAngleConstraint ' label]);
                    testCase.verifyEqual(yaw, mod(rpy(3), 360), 'AbsTol', testCase.AngTol, ['YawAngleConstraint ' label]);
                end
            end
        end

        function checkAeroAngleConstraintsUseBodyFixedRelativeWind(testCase)
            %Bank / angle of attack / sideslip are the 3-2-1 angles of the
            %body axes relative to the WIND triad:
            %
            %   x = unit(vRel),  z = unit(component of "down" normal to x),
            %   y = z cross x,
            %
            %so dcm = W * Rz(sideslip) * Ry(aoa) * Rx(bank).  The
            %non-inertial constraints use the velocity relative to the
            %rotating body, vRel = v - omega x r, which is spelled out here
            %in inertial axes.  The stock body rotates, and the geometry is
            %chosen so that omega x r turns the wind by several degrees, so
            %using the inertial velocity instead could not pass.
            fx = testCase.buildFixture();
            [rVect, vVect, vRel, ut] = testCase.aeroGeometry(fx);
            W = refWindTriad(rVect, vRel);

            cases = { [130, -12, -25], [-60, 35, 10], [200, -70, 170], [15, 2, -3] }; %[bank, aoa, sideslip]
            for(i = 1:numel(cases))
                ang = cases{i};
                dcm = W * refRz(deg2rad(ang(3))) * refRy(deg2rad(ang(2))) * refRx(deg2rad(ang(1)));
                entry = testCase.makeAttitudeEntry(fx, fx.evt1, ut, rVect, vVect, dcm);
                stateLog = testCase.makeLog(fx, entry);

                [~, ~, bank] = BankAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, aoa]  = AngleOfAttackConstraint(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, beta] = SideSlipAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);

                label = sprintf('(bank %g, aoa %g, sideslip %g)', ang(1), ang(2), ang(3));
                testCase.verifyEqual(aoa, ang(2), 'AbsTol', testCase.AngTol, ['AngleOfAttackConstraint ' label]);
                testCase.verifyEqual(bank, mod(ang(1), 360), 'AbsTol', testCase.AngTol, ['BankAngleConstraint ' label]);
                testCase.verifyEqual(beta, mod(ang(3), 360), 'AbsTol', testCase.AngTol, ['SideSlipAngleConstraint ' label]);
            end
        end

        function checkInertialAeroAngleConstraintsUseInertialVelocity(testCase)
            %Same wind-triad construction, but on the INERTIAL velocity.
            %The second half proves the two families really are
            %different: on an attitude composed on the inertial wind, the
            %body-fixed angle of attack must NOT equal the composed one.
            fx = testCase.buildFixture();
            [rVect, vVect, ~, ut] = testCase.aeroGeometry(fx);
            W = refWindTriad(rVect, vVect);

            cases = { [130, -12, -25], [-60, 35, 10], [300, 50, 95] }; %[bank, aoa, sideslip]
            for(i = 1:numel(cases))
                ang = cases{i};
                dcm = W * refRz(deg2rad(ang(3))) * refRy(deg2rad(ang(2))) * refRx(deg2rad(ang(1)));
                entry = testCase.makeAttitudeEntry(fx, fx.evt1, ut, rVect, vVect, dcm);
                stateLog = testCase.makeLog(fx, entry);

                [~, ~, bank] = InertialBankAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, aoa]  = InertialAngleOfAttackConstraint(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, beta] = InertialSideSlipAngleConstraint(fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);

                label = sprintf('(bank %g, aoa %g, sideslip %g)', ang(1), ang(2), ang(3));
                testCase.verifyEqual(aoa, ang(2), 'AbsTol', testCase.AngTol, ['InertialAngleOfAttackConstraint ' label]);
                testCase.verifyEqual(bank, mod(ang(1), 360), 'AbsTol', testCase.AngTol, ['InertialBankAngleConstraint ' label]);
                testCase.verifyEqual(beta, mod(ang(3), 360), 'AbsTol', testCase.AngTol, ['InertialSideSlipAngleConstraint ' label]);

                [~, ~, aoaBodyFixed] = AngleOfAttackConstraint(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyGreaterThan(abs(aoaBodyFixed - ang(2)), 1, ...
                    ['body-fixed and inertial angle of attack must differ on a rotating body ' label]);
            end
        end

        function checkAttitudeConstraintsStateComparisonReadsCompEntryAttitude(testCase)
            %In StateComparison mode each attitude constraint must evaluate
            %the SAME angle on the comparison event's entry.  The expected
            %comparison value is the FixedBounds value of the same class on
            %a log holding only that state; the FixedBounds path is pinned
            %to the composed-angle oracles above, so this pins the
            %comparison branch (deepCopy, frame conversion, which entry it
            %reads) to the same verified quantity.
            fx = testCase.buildFixture();
            rA = [700; 200; 300];   vA = [0.25; 0.6; 0.3];
            rB = [-300; 500; -450]; vB = [0.9; -0.1; 0.4];
            dcmA = refNedTriad(rA) * refRz(deg2rad(40))  * refRy(deg2rad(15))  * refRx(deg2rad(70));
            dcmB = refNedTriad(rB) * refRz(deg2rad(250)) * refRy(deg2rad(-35)) * refRx(deg2rad(160));

            eA = testCase.makeAttitudeEntry(fx, fx.evt1, 0, rA, vA, dcmA);
            eB = testCase.makeAttitudeEntry(fx, fx.evt2, 500, rB, vB, dcmB);
            stateLog = testCase.makeLog(fx, [eA, eB]);
            logB = testCase.makeLog(fx, testCase.makeAttitudeEntry(fx, fx.evt1, 500, rB, vB, dcmB));

            classNames = {'PitchAngleConstraint', 'RollAngleConstraint', 'YawAngleConstraint', ...
                          'BankAngleConstraint', 'AngleOfAttackConstraint', 'SideSlipAngleConstraint', ...
                          'InertialBankAngleConstraint', 'InertialAngleOfAttackConstraint', 'InertialSideSlipAngleConstraint'};
            for(i = 1:numel(classNames))
                className = classNames{i};
                [~, ~, valueA] = feval(className, fx.evt1, -360, 360).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, valueB] = feval(className, fx.evt1, -360, 360).evalConstraint(logB, testCase.celBodyData);

                const = feval(className, fx.evt1, 0, 0);
                const.evalType = ConstraintEvalTypeEnum.StateComparison;
                const.stateCompEvent = fx.evt2;
                const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
                [c, ceq, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);

                testCase.verifyGreaterThan(abs(valueA - valueB), 1, ...
                    sprintf('%s: fixture attitudes must give distinguishable angles', className));
                testCase.verifyEqual(value, valueA, 'AbsTol', testCase.AngTol, ...
                    sprintf('%s: primary value must come from the constrained event', className));
                testCase.verifyEqual(valueStateComp, valueB, 'AbsTol', testCase.AngTol, ...
                    sprintf('%s: comparison value must be the same angle on the comparison entry', className));
                testCase.verifyEmpty(c, sprintf('%s: Equals must not emit inequalities', className));
                testCase.verifyEqual(ceq, valueA - valueB, 'AbsTol', testCase.AngTol, ...
                    sprintf('%s: Equals must emit value - valueStateComp', className));
                testCase.verifyTrue(const.usesEvent(fx.evt2), ...
                    sprintf('%s: must report using the comparison event', className));
            end
        end

        function checkBodyAngularVelConstraintsMatchRigidRotationOracle(testCase)
            %A body spinning at a constant rate w about the inertial unit
            %axis u, starting from attitude D0, has dcm(t) = R(u, w t) * D0.
            %Its angular velocity expressed in BODY axes is exactly
            %w * D0' * u, and its magnitude is |w|.  D0 is not the identity,
            %so a rate reported in inertial axes (w * u) cannot pass.  The
            %two events spin about different axes at different rates (one
            %negative), so the comparison branch is also checked.
            testCase.assumeNotEmpty(which('rotm2quat'), ...
                'lvd_AttitudeRateTasks needs rotm2quat (Robotics System Toolbox), which is not installed.');

            fx = testCase.buildFixture();
            u1 = [1; 2; 2]/3;   w1 = deg2rad(4);
            u2 = [0; -0.6; 0.8]; w2 = deg2rad(-1.5);
            D1 = refAxAng([0; 0; 1], deg2rad(35)) * refAxAng([1; 0; 0], deg2rad(-20));
            D2 = refAxAng([0; 1; 0], deg2rad(50));

            e1 = testCase.makeEntry(fx, fx.evt1, 50);
            e1.steeringModel = TestFixedDcmSteeringModel(@(t) refAxAng(u1, w1*(t - 50)) * D1);
            e2 = testCase.makeEntry(fx, fx.evt2, 80);
            e2.steeringModel = TestFixedDcmSteeringModel(@(t) refAxAng(u2, w2*(t - 80)) * D2);
            stateLog = testCase.makeLog(fx, [e1, e2]);
            frame = e1.centralBody.getBodyCenteredInertialFrame();

            rate1 = rad2deg(w1) * (D1' * u1);
            rate2 = rad2deg(w2) * (D2' * u2);
            expected1 = [rate1; norm(rate1)];
            expected2 = [rate2; norm(rate2)];

            classNames = {'BodyAngularVelXConstraint', 'BodyAngularVelYConstraint', ...
                          'BodyAngularVelZConstraint', 'TotalBodyAngularVelConstraint'};
            for(i = 1:numel(classNames))
                const = feval(classNames{i}, fx.evt1, -100, 100);
                const.frame = frame;
                [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(value, expected1(i), 'AbsTol', 1e-7, ...
                    sprintf('%s does not match the rigid rotation oracle', classNames{i}));

                const.evalType = ConstraintEvalTypeEnum.StateComparison;
                const.stateCompEvent = fx.evt2;
                const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
                [~, ceq, ~, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(valueStateComp, expected2(i), 'AbsTol', 1e-7, ...
                    sprintf('%s comparison value must be the comparison event''s rate', classNames{i}));
                testCase.verifyEqual(ceq, expected1(i) - expected2(i), 'AbsTol', 1e-7, ...
                    sprintf('%s Equals must emit value - valueStateComp', classNames{i}));
            end
        end

        %% ---------------------------------------------------------------
        %  Two-body impact point
        %  ---------------------------------------------------------------

        function checkTwoBodyImpactPointConstraintsMatchKeplerOracle(testCase)
            %The three impact constraints coast the current conic to its
            %next DESCENDING crossing of the body radius.  The oracle
            %(refTwoBodyImpact) does that in closed form: true anomaly
            %nu* = 2pi - acos((p/R - 1)/e), time mod(M(nu*) - M0, 2pi)/n,
            %impact point from refCoe2Rv, longitude rotated into the
            %body-fixed frame by the spin angle at impact.  The cases cover
            %a start on the ascending leg (the coast passes apoapsis first),
            %a start on the descending leg, a retrograde orbit and non-zero
            %epochs (which move the impact longitude).
            fx = testCase.buildFixture();
            bodyInfo = fx.template.centralBody;
            R = bodyInfo.radius;

            cases = { ...
                {R + 200, 0.5,  30,  40,  60, 150, 1000, 'ascending leg, prograde'}, ...
                {R + 150, 0.6,  75, 200, 300, 230,    0, 'descending leg, high inclination'}, ...
                {800,     0.3, 140, 310,  25, 120, 7500, 'retrograde'} ...
            };
            refs = cell(size(cases));
            for(i = 1:numel(cases))
                cs = cases{i};
                [entry, refs{i}] = testCase.makeImpactEntry(fx, fx.evt1, bodyInfo, cs{:});
                stateLog = testCase.makeLog(fx, entry);
                ref = refs{i};
                label = cs{8};

                testCase.assertEqual(norm(ref.rImpact), R, 'AbsTol', 1e-9, ...
                    'oracle self-check: the impact point must lie on the surface');

                [~, ~, tImpact] = TwoBodyImpactPointTime(fx.evt1, 0, 1e5).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, latImpact] = TwoBodyImpactPointLatitude(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
                [~, ~, lonImpact] = TwoBodyImpactPointLongitude(fx.evt1, 0, 360).evalConstraint(stateLog, testCase.celBodyData);

                testCase.verifyEqual(tImpact, ref.dt, 'AbsTol', 1e-6, ['time to impact (' label ')']);
                testCase.verifyEqual(latImpact, ref.lat, 'AbsTol', 1e-8, ['impact latitude (' label ')']);
                testCase.verifyWrappedDegEqual(lonImpact, ref.lon, 1e-8, ['impact longitude (' label ')']);
            end

            %State comparison: case 1 on event 1, case 2 on event 2.
            e1 = testCase.makeImpactEntry(fx, fx.evt1, bodyInfo, cases{1}{:});
            e2 = testCase.makeImpactEntry(fx, fx.evt2, bodyInfo, cases{2}{:});
            stateLog = testCase.makeLog(fx, [e1, e2]);

            const = TwoBodyImpactPointTime(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [refs{1}.dt, refs{2}.dt], 'AbsTol', 1e-6, ...
                'time-to-impact comparison must evaluate each event''s own trajectory');
            testCase.verifyEqual(c, refs{2}.dt - refs{1}.dt, 'AbsTol', 1e-6, ...
                'GreaterThan must emit valueStateComp - value');

            const = TwoBodyImpactPointLatitude(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            [~, ~, ~, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, refs{2}.lat, 'AbsTol', 1e-8, ...
                'impact latitude comparison value is wrong');
        end

        function checkTwoBodyImpactPointConstraintsReportSentinelsWithoutImpact(testCase)
            %A conic whose periapsis clears the surface never impacts.  The
            %constraints then substitute fixed sentinels so the optimizer
            %still sees a real number: 1e99 s for the time, 1000 deg for
            %latitude and longitude (outside both valid ranges).
            fx = testCase.buildFixture();
            gmu = fx.template.centralBody.gm;
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            entry.position = [800; 0; 0];
            entry.velocity = sqrt(gmu/800) * [0; cosd(30); sind(30)];  %circular, 200 km up
            stateLog = testCase.makeLog(fx, entry);

            [c, ~, tImpact] = TwoBodyImpactPointTime(fx.evt1, 0, 100).evalConstraint(stateLog, testCase.celBodyData);
            [~, ~, latImpact] = TwoBodyImpactPointLatitude(fx.evt1, -90, 90).evalConstraint(stateLog, testCase.celBodyData);
            [~, ~, lonImpact] = TwoBodyImpactPointLongitude(fx.evt1, 0, 360).evalConstraint(stateLog, testCase.celBodyData);

            testCase.verifyEqual(tImpact, 1e99, 'non-impacting time to impact must be the 1e99 sentinel');
            testCase.verifyEqual(latImpact, 1000, 'non-impacting impact latitude must be the 1000 sentinel');
            testCase.verifyEqual(lonImpact, 1000, 'non-impacting impact longitude must be the 1000 sentinel');
            testCase.verifyEqual(c(:)', [0 - 1e99, 1e99 - 100], ...
                'the sentinel must flow through to c like any other value');

            %...and the same sentinel on the comparison side.
            e1 = testCase.makeImpactEntry(fx, fx.evt1, fx.template.centralBody, fx.template.centralBody.radius + 200, 0.5, 30, 40, 60, 150, 1000);
            e2 = entry.deepCopy();
            e2.event = fx.evt2;
            e2.time = 2000;
            const = TwoBodyImpactPointLongitude(fx.evt1, 0, 0);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(testCase.makeLog(fx, [e1, e2]), testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, 1000, 'non-impacting comparison entry must give the sentinel');
            testCase.verifyEqual(c, value - 1000, 'AbsTol', 1e-9, 'LessThan must emit value - valueStateComp');
        end

        %% ---------------------------------------------------------------
        %  Calculus, geometric angle and plugin constraints
        %  ---------------------------------------------------------------

        function checkCalculusCalculationValueConstraintReadsNamedCalc(testCase)
            %Altitude is exactly 100 + 0.3 t on event 1 (t = 0..30) and
            %109 - 0.4 (t - 30) on event 2 (t = 30..50).  So the derivative
            %is 0.3 / -0.4 km/s, and the integral -- whose constant chains
            %across events the way propagation sets it up -- is
            %
            %   evt1 end : int_0^30 (100 + 0.3t) dt       = 3135 km*s
            %   evt2 end : 3135 + int_30^50 (...) dt      = 3135 + 2100
            %
            %Both calculus objects are present, so the constraint must
            %pick its own by identity.
            [fx, stateLog, intCalc, derivCalc] = testCase.buildCalculusLog();

            intConst = CalculusCalculationValueConstraint(fx.evt1, -1e6, 1e6);
            intConst.calculusCalc = intCalc;
            derivConst = CalculusCalculationValueConstraint(fx.evt1, -1e6, 1e6);
            derivConst.calculusCalc = derivCalc;

            nodes = [ConstraintStateComparisonNodeEnum.FinalState, ConstraintStateComparisonNodeEnum.InitialState];
            events = [fx.evt1, fx.evt2];
            expInt   = [3135, 0; 3135 + 2100, 3135];   %rows: event, cols: node
            expDeriv = [0.3, 0.3; -0.4, -0.4];
            for(i = 1:2)
                for(j = 1:2)
                    intConst.event = events(i);     intConst.eventNode = nodes(j);
                    derivConst.event = events(i);   derivConst.eventNode = nodes(j);
                    [~, ~, intValue] = intConst.evalConstraint(stateLog, testCase.celBodyData);
                    [~, ~, derivValue] = derivConst.evalConstraint(stateLog, testCase.celBodyData);
                    label = sprintf('event %d, %s', i, nodes(j).name);
                    testCase.verifyEqual(intValue, expInt(i,j), 'AbsTol', 1e-6, ['integral value (' label ')']);
                    testCase.verifyEqual(derivValue, expDeriv(i,j), 'AbsTol', 1e-8, ['derivative value (' label ')']);
                end
            end

            testCase.verifyTrue(intConst.usesCalculusCalc(intCalc), 'usesCalculusCalc must report its own calc');
            testCase.verifyFalse(intConst.usesCalculusCalc(derivCalc), 'usesCalculusCalc must not report another calc');
            testCase.verifyEqual(intConst.getConstraintType(), 'Calculus Calculation Value');

            [unitInt, lbLim, ubLim] = intConst.getConstraintStaticDetails();
            unitDeriv = derivConst.getConstraintStaticDetails();
            testCase.verifyEqual({unitInt, unitDeriv}, {'km*s', 'km/s'}, ...
                'calculus constraint unit must come from the calculus object (integral of km, derivative of km)');
            testCase.verifyEqual([lbLim, ubLim], [-Inf, Inf]);
        end

        function checkCalculusCalculationStateComparisonUsesCompEventCalcState(testCase)
            %Each event owns its own calculus state, sampled only over that
            %event's time span (no extrapolation).  The comparison value
            %must therefore come from the COMPARISON entry's calculus
            %state.  Evaluating the primary event's state at the comparison
            %entry's time gives NaN for a derivative and throws "Integral
            %value is NaN" for an integral as soon as the comparison event
            %lies outside the primary event's span.
            [fx, stateLog, intCalc, derivCalc] = testCase.buildCalculusLog();

            const = CalculusCalculationValueConstraint(fx.evt1, 0, 0);
            const.calculusCalc = derivCalc;
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;
            [c, ceq, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [0.3, -0.4], 'AbsTol', 1e-8, ...
                'derivative comparison must read each event''s own calculus state');
            testCase.verifyEqual(c, -0.4 - 0.3, 'AbsTol', 1e-8, 'GreaterThan must emit valueStateComp - value');
            testCase.verifyEmpty(ceq);

            const.calculusCalc = intCalc;
            const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
            [~, ceq, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [3135, 5235], 'AbsTol', 1e-6, ...
                'integral comparison must read each event''s own calculus state');
            testCase.verifyEqual(ceq, 3135 - 5235, 'AbsTol', 1e-6);

            const.stateCompNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, ~, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, 3135, 'AbsTol', 1e-6, ...
                'stateCompNode = InitialState must read the integral at the comparison event start');
        end

        function checkGeometricAngleMagConstraintSignedAngleAbsValueAndDotProduct(testCase)
            %TwoVectorAngle reports the angle between two vectors, signed by
            %the right-hand rule about +z (sign of (v1 x v2) . z).  The
            %oracle values are plain acosd(dot) on unit vectors.
            %
            %The second group has (v1 x v2) perpendicular to z, where that
            %sign is zero.  The angle there must keep its magnitude; with a
            %bare sign() it collapsed to exactly 0 degrees for perfectly
            %ordinary 90 degree pairs.
            fx = testCase.buildFixture();
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            stateLog = testCase.makeLog(fx, entry);
            frame = entry.centralBody.getBodyCenteredInertialFrame();
            vec = @(x) FixedVectorInFrame(x, frame, 'Test Vector', fx.lvdData);

            signedPairs = { ...
                {[1; 0; 0], [cosd(40); sind(40); 0],  40}, ...
                {[cosd(40); sind(40); 0], [1; 0; 0], -40}, ...
                {[1; 2; 3], [-2; 1; 0.5], acosd(dot([1;2;3], [-2;1;0.5])/(norm([1;2;3])*norm([-2;1;0.5])))} ...
            };
            for(i = 1:numel(signedPairs))
                pr = signedPairs{i};
                angle = TwoVectorAngle(vec(pr{1}), vec(pr{2}), 'Test Angle', fx.lvdData);
                const = GeometricAngleMagConstraint(angle, fx.evt1, -360, 360);
                const.frame = frame;
                [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(value, pr{3}, 'AbsTol', testCase.AngTol, ...
                    sprintf('signed two-vector angle for %s, %s', mat2str(pr{1}', 4), mat2str(pr{2}', 4)));

                const.useAbsValue = true;
                [~, ~, absValue] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(absValue, abs(pr{3}), 'AbsTol', testCase.AngTol, ...
                    'useAbsValue must report the magnitude');
            end

            horizontalCrossPairs = { {[1; 0; 1], [1; 0; -1]}, {[1; 1; 0], [0; 0; -1]}, {[0; 3; 4], [0; 4; -3]} };
            for(i = 1:numel(horizontalCrossPairs))
                pr = horizontalCrossPairs{i};
                angle = TwoVectorAngle(vec(pr{1}), vec(pr{2}), 'Test Angle', fx.lvdData);
                const = GeometricAngleMagConstraint(angle, fx.evt1, -360, 360);
                const.frame = frame;
                [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(abs(value), 90, 'AbsTol', testCase.AngTol, ...
                    sprintf(['the 90 deg angle between %s and %s (cross product normal to z) ' ...
                             'must not collapse to %g'], mat2str(pr{1}'), mat2str(pr{2}'), value));
            end

            angle = TwoVectorAngle(vec([1; 0; 0]), vec([0; 1; 0]), 'Test Angle', fx.lvdData);
            other = TwoVectorAngle(vec([1; 0; 0]), vec([0; 0; 1]), 'Other Angle', fx.lvdData);
            const = GeometricAngleMagConstraint(angle, fx.evt1, -360, 360);
            testCase.verifyEqual(const.getConstraintStaticDetails(), 'deg', 'a true angle is reported in degrees');
            testCase.verifyTrue(const.usesGeometricAngle(angle), 'usesGeometricAngle must report its angle');
            testCase.verifyFalse(const.usesGeometricAngle(other), 'usesGeometricAngle must not report another angle');

            %A dot product "angle" is dimensionless: reported raw, not
            %converted to degrees, and with an empty unit.
            dotAngle = VectorDotProductAngle(vec([1; 2; 3]), vec([4; -5; 6]), 'Test Dot', fx.lvdData);
            const = GeometricAngleMagConstraint(dotAngle, fx.evt1, -100, 100);
            const.frame = frame;
            [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, 1*4 + 2*(-5) + 3*6, 'AbsTol', 1e-12, ...
                'dot product angle must be the raw dot product');
            testCase.verifyEqual(const.getConstraintStaticDetails(), '', 'dot product angle is dimensionless');

            %Fixed vectors do not depend on the vehicle, so a comparison
            %against another event must give an identical value.
            e2 = testCase.makeEntry(fx, fx.evt2, 100);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            [~, ceq, ~, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(testCase.makeLog(fx, [entry, e2]), testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, 12, 'AbsTol', 1e-12);
            testCase.verifyEqual(ceq, 0, 'AbsTol', 1e-12);
        end

        function checkPluginConstraintEvaluatesPluginCodeOnEachEntry(testCase)
            %The plugin code sees the selected state log entry and the
            %event it belongs to.  value = 2*t + 1000*eventNum identifies
            %both, so the oracle is plain arithmetic on the fixture times.
            %On the comparison side the plugin must see the COMPARISON
            %event: passing the primary event there means any plugin that
            %reads `event` computes against the wrong one.
            fx = testCase.buildFixture();
            plugin = LvdPlugin();
            plugin.pluginName = 'Test Constraint Plugin';
            plugin.pluginCode = "value = 2*stateLogEntry.time + 1000*event.getEventNum();";
            fx.lvdData.plugins.addPlugin(plugin);
            otherPlugin = LvdPlugin();

            entries = [testCase.makeEntry(fx, fx.evt1, 10), testCase.makeEntry(fx, fx.evt1, 30), ...
                       testCase.makeEntry(fx, fx.evt2, 50), testCase.makeEntry(fx, fx.evt2, 70)];
            stateLog = testCase.makeLog(fx, entries);
            numValidationOutputs = numel(fx.lvdData.validation.outputs);

            const = PluginConstraint(plugin, fx.evt1, 0, 5000);
            [c, ceq, value] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, 2*30 + 1000, 'AbsTol', 1e-12, 'FinalState plugin value');
            testCase.verifyEqual(c(:)', [0 - 1060, 1060 - 5000], 'AbsTol', 1e-12);
            testCase.verifyEmpty(ceq);

            const.eventNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, 2*10 + 1000, 'AbsTol', 1e-12, 'InitialState plugin value');

            const.eventNode = ConstraintStateComparisonNodeEnum.FinalState;
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, 2*70 + 2000, 'AbsTol', 1e-12, ...
                'comparison plugin value must see the comparison entry AND the comparison event');
            testCase.verifyEqual(c, value - valueStateComp, 'AbsTol', 1e-12);

            const.stateCompNode = ConstraintStateComparisonNodeEnum.InitialState;
            [~, ~, ~, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(valueStateComp, 2*50 + 2000, 'AbsTol', 1e-12, ...
                'stateCompNode = InitialState must read the first comparison entry');

            testCase.verifyEqual(numel(fx.lvdData.validation.outputs), numValidationOutputs, ...
                'a working plugin must not record validation errors');
            testCase.verifyTrue(const.usesPlugin(plugin), 'usesPlugin must report its plugin');
            testCase.verifyFalse(const.usesPlugin(otherPlugin), 'usesPlugin must not report another plugin');
            testCase.verifyEqual(const.getConstraintType(), 'Plugin Value');
        end

        %% ---------------------------------------------------------------
        %  GenericMAConstraint quantities
        %  ---------------------------------------------------------------

        function checkGenericMAConstraintOrbitalQuantitiesMatchElementOracle(testCase)
            %Every orbital/kinematic quantity in ConstraintEnum is checked
            %against the elements the test used to BUILD the state, in the
            %default (central body inertial) frame.  Latitude, longitude
            %and velocity az/el are therefore INERTIAL-frame geographic
            %quantities here; the body-fixed versions are the next case.
            %Periapsis/apoapsis lat/lon are always body-fixed, regardless of
            %frame, so they are rotated by the spin angle at ut.
            fx = testCase.buildFixture();
            bodyInfo = fx.template.centralBody;
            gmu = bodyInfo.gm;
            R = bodyInfo.radius;

            sma = 900; ecc = 0.15; inc = 35; raan = 50; arg = 70; tru = 120; ut = 2000;
            [rVect, vVect] = refCoe2Rv(sma, ecc, deg2rad(inc), deg2rad(raan), deg2rad(arg), deg2rad(tru), gmu);
            entry = testCase.makeEntry(fx, fx.evt1, ut);
            entry.position = rVect;
            entry.velocity = vVect;
            tankStates = entry.getAllTankStates();
            tankStates(1).tankMass = 3.25;
            stateLog = testCase.makeLog(fx, entry);

            eccAnom = 2*atan(sqrt((1 - ecc)/(1 + ecc)) * tand(tru/2));
            meanAnom = mod(eccAnom - ecc*sin(eccAnom), 2*pi);
            meanMotion = sqrt(gmu/sma^3);
            ned = refNedTriad(rVect);
            vNed = ned' * vVect;
            pHat = refPerifocalAxes(deg2rad(inc), deg2rad(raan), deg2rad(arg)) * [1; 0; 0];
            spin = deg2rad(bodyInfo.rotini) + 2*pi*ut/bodyInfo.rotperiod;
            pHatBf = refRz(spin)' * pHat;

            rows = { ...
                'Universal Time',               ut,                                         1e-12; ...
                'Position Vector (X)',          rVect(1),                                   1e-9; ...
                'Position Vector (Y)',          rVect(2),                                   1e-9; ...
                'Position Vector (Z)',          rVect(3),                                   1e-9; ...
                'Velocity Vector (X)',          vVect(1),                                   1e-12; ...
                'Velocity Vector (Y)',          vVect(2),                                   1e-12; ...
                'Velocity Vector (Z)',          vVect(3),                                   1e-12; ...
                'Position Vector Magnitude',    norm(rVect),                                1e-9; ...
                'Velocity Vector Magnitude',    norm(vVect),                                1e-12; ...
                'Semi-major Axis',              sma,                                        1e-7; ...
                'Eccentricity',                 ecc,                                        1e-11; ...
                'Inclination',                  inc,                                        1e-8; ...
                'Right Asc. of the Asc. Node',  raan,                                       1e-8; ...
                'Argument of Periapsis',        arg,                                        1e-8; ...
                'True Anomaly',                 tru,                                        1e-8; ...
                'Mean Anomaly',                 rad2deg(meanAnom),                          1e-8; ...
                'Orbital Period',               2*pi/meanMotion,                            1e-7; ...
                'Radius of Periapsis',          sma*(1 - ecc),                              1e-7; ...
                'Radius of Apoapsis',           sma*(1 + ecc),                              1e-7; ...
                'Altitude of Periapsis',        sma*(1 - ecc) - R,                          1e-7; ...
                'Altitude of Apoapsis',         sma*(1 + ecc) - R,                          1e-7; ...
                'Equinoctial H1',               ecc*cosd(arg + raan),                       1e-11; ...
                'Equinoctial K1',               ecc*sind(arg + raan),                       1e-11; ...
                'Equinoctial H2',               tand(inc/2)*cosd(raan),                     1e-11; ...
                'Equinoctial K2',               tand(inc/2)*sind(raan),                     1e-11; ...
                'Flight Path Angle',            atan2d(ecc*sind(tru), 1 + ecc*cosd(tru)),   1e-8; ...
                'Longitude (East)',             mod(atan2d(rVect(2), rVect(1)), 360),      1e-9; ...
                'Latitude (North)',             asind(rVect(3)/norm(rVect)),                1e-9; ...
                'Altitude',                     norm(rVect) - R,                            1e-9; ...
                'Velocity Azimuth',             mod(atan2d(vNed(2), vNed(1)), 360),        1e-9; ...
                'Velocity Elevation',           asind(-vNed(3)/norm(vVect)),                1e-9; ...
                'Surface Velocity',             hypot(vNed(1), vNed(2)),                    1e-10; ...
                'Vertical Velocity',            -vNed(3),                                   1e-10; ...
                'Longitudinal Drift Rate',      (meanMotion - 2*pi/bodyInfo.rotperiod)*3600*180/pi, 1e-7; ...
                'C3 Energy',                    -gmu/sma,                                   1e-10; ...
                'Specific Orbital Energy',      -gmu/(2*sma),                               1e-10; ...
                'Specific Angular Momentum',    sqrt(gmu*sma*(1 - ecc^2)),                  1e-8; ...
                'Seconds Past Periapsis',       meanAnom/meanMotion,                        1e-6; ...
                'Argument of Latitude',         mod(arg + tru, 360),                        1e-8; ...
                'True Longitude',               mod(raan + arg + tru, 360),                 1e-8; ...
                'Periapsis Latitude (North)',   asind(pHatBf(3)),                           1e-8; ...
                'Periapsis Longitude (East)',   mod(atan2d(pHatBf(2), pHatBf(1)), 360),    1e-8; ...
                'Apoapsis Latitude (North)',    -asind(pHatBf(3)),                          1e-8; ...
                'Apoapsis Longitude (East)',    mod(atan2d(-pHatBf(2), -pHatBf(1)), 360),  1e-8; ...
                'Total Spacecraft Mass',        fx.lvdData.launchVehicle.stages(1).dryMass + 3.25, 1e-12; ...
            };
            testCase.verifyGenericMARows(rows, fx.evt1, stateLog, []);

            [~, ~, bodyId] = testCase.makeGenericMA('Central Body ID', fx.evt1).evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(bodyId, bodyInfo.id, 'Central Body ID must be the entry''s central body id');
        end

        function checkGenericMAConstraintHyperbolicQuantitiesMatchAsymptoteOracle(testCase)
            %The outbound asymptote of a hyperbola sits at the limiting true
            %anomaly nu_inf = acos(-1/e).  Its inertial direction is
            %cos(nu_inf) P + sin(nu_inf) Q in the perifocal axes P, Q, and the
            %excess speed is sqrt(-mu/a) = sqrt(C3).
            fx = testCase.buildFixture();
            gmu = fx.template.centralBody.gm;

            sma = -500; ecc = 1.8; inc = 20; raan = 100; arg = 30; tru = 40;
            [rVect, vVect] = refCoe2Rv(sma, ecc, deg2rad(inc), deg2rad(raan), deg2rad(arg), deg2rad(tru), gmu);
            entry = testCase.makeEntry(fx, fx.evt1, 0);
            entry.position = rVect;
            entry.velocity = vVect;
            stateLog = testCase.makeLog(fx, entry);

            pqw = refPerifocalAxes(deg2rad(inc), deg2rad(raan), deg2rad(arg));
            truInf = acos(-1/ecc);
            oHat = pqw * [cos(truInf); sin(truInf); 0];

            rows = { ...
                'Semi-major Axis',                              sma,                                1e-7; ...
                'Eccentricity',                                 ecc,                                1e-10; ...
                'Inclination',                                  inc,                                1e-8; ...
                'C3 Energy',                                    -gmu/sma,                           1e-10; ...
                'Specific Orbital Energy',                      -gmu/(2*sma),                       1e-10; ...
                'Hyperbolic Velocity Unit Vector X',            oHat(1),                            1e-10; ...
                'Hyperbolic Velocity Unit Vector Y',            oHat(2),                            1e-10; ...
                'Hyperbolic Velocity Unit Vector Z',            oHat(3),                            1e-10; ...
                'Hyperbolic Velocity Vector Right Ascension',   mod(atan2d(oHat(2), oHat(1)), 360), 1e-8; ...
                'Hyperbolic Velocity Vector Declination',       asind(oHat(3)),                     1e-8; ...
                'Hyperbolic Velocity Magnitude',                sqrt(-gmu/sma),                     1e-10; ...
            };
            testCase.verifyGenericMARows(rows, fx.evt1, stateLog, []);
        end

        function checkGenericMAConstraintBodyFixedFrameQuantitiesMatchSpinOracle(testCase)
            %With the constraint frame set to the body-fixed frame, the same
            %quantity names must be evaluated on the rotating-frame state:
            %
            %   r_bf = Rz(theta)' r,    v_bf = Rz(theta)' (v - omega x r),
            %   theta = rotini + 2 pi ut / rotperiod.
            %
            %The inertial longitude differs from the body-fixed one by
            %exactly theta, which is checked too so a frame that is
            %silently ignored cannot pass.
            fx = testCase.buildFixture();
            bodyInfo = fx.template.centralBody;
            R = bodyInfo.radius;
            ut = 2000;
            [rVect, vVect] = refCoe2Rv(900, 0.15, deg2rad(35), deg2rad(50), deg2rad(70), deg2rad(120), bodyInfo.gm);
            entry = testCase.makeEntry(fx, fx.evt1, ut);
            entry.position = rVect;
            entry.velocity = vVect;
            stateLog = testCase.makeLog(fx, entry);

            spin = deg2rad(bodyInfo.rotini) + 2*pi*ut/bodyInfo.rotperiod;
            omega = [0; 0; 2*pi/bodyInfo.rotperiod];
            rBf = refRz(spin)' * rVect;
            vBf = refRz(spin)' * (vVect - cross(omega, rVect));
            vNed = refNedTriad(rBf)' * vBf;

            rows = { ...
                'Position Vector (X)',          rBf(1),                                 1e-9; ...
                'Position Vector (Y)',          rBf(2),                                 1e-9; ...
                'Position Vector (Z)',          rBf(3),                                 1e-9; ...
                'Velocity Vector (X)',          vBf(1),                                 1e-12; ...
                'Velocity Vector (Y)',          vBf(2),                                 1e-12; ...
                'Velocity Vector (Z)',          vBf(3),                                 1e-12; ...
                'Position Vector Magnitude',    norm(rBf),                              1e-9; ...
                'Velocity Vector Magnitude',    norm(vBf),                              1e-12; ...
                'Longitude (East)',             mod(atan2d(rBf(2), rBf(1)), 360),      1e-9; ...
                'Latitude (North)',             asind(rBf(3)/norm(rBf)),                1e-9; ...
                'Altitude',                     norm(rBf) - R,                          1e-9; ...
                'Velocity Azimuth',             mod(atan2d(vNed(2), vNed(1)), 360),    1e-9; ...
                'Velocity Elevation',           asind(-vNed(3)/norm(vBf)),              1e-9; ...
                'Surface Velocity',             hypot(vNed(1), vNed(2)),                1e-10; ...
                'Vertical Velocity',            -vNed(3),                               1e-10; ...
            };
            testCase.verifyGenericMARows(rows, fx.evt1, stateLog, bodyInfo.getBodyFixedFrame());

            [~, ~, lonInertial] = testCase.makeGenericMA('Longitude (East)', fx.evt1).evalConstraint(stateLog, testCase.celBodyData);
            bfConst = testCase.makeGenericMA('Longitude (East)', fx.evt1);
            bfConst.frame = bodyInfo.getBodyFixedFrame();
            [~, ~, lonBodyFixed] = bfConst.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyWrappedDegEqual(lonInertial - lonBodyFixed, rad2deg(spin), 1e-9, ...
                'inertial minus body-fixed longitude must be the body spin angle');
        end

        function checkGenericMAConstraintHeightAboveTerrainSubtractsHeightMap(testCase)
            %Height above terrain = altitude - h(lat, lon), with lat/lon in
            %the BODY-FIXED frame and lon in [-pi, pi].  A copy of the body
            %gets a planar height map h = 0.5 + 0.2 lat + 0.1 lon km;
            %bilinear interpolation of corner samples of a plane is exact,
            %so the oracle is the plane itself.
            fx = testCase.buildFixture();
            bodyInfo = testCase.copyBodyInfo(fx.template.centralBody);
            latGrid = [-pi/2, pi/2];
            lonGrid = [-pi, pi];
            h = @(lat, lon) 0.5 + 0.2*lat + 0.1*lon;
            [latPts, lonPts] = ndgrid(latGrid, lonGrid);
            bodyInfo.heightMapCache = griddedInterpolant({latGrid, lonGrid}, h(latPts, lonPts));

            positions = {[-500; -400; 350], [620; 90; -100], [-50; 600; 400]};
            for(i = 1:numel(positions))
                ut = 1500*i;
                rVect = positions{i};
                entry = testCase.makeEntry(fx, fx.evt1, ut);
                entry.centralBody = bodyInfo;
                entry.position = rVect;
                entry.velocity = [0.1; 0.5; -0.2];
                stateLog = testCase.makeLog(fx, entry);

                spin = deg2rad(bodyInfo.rotini) + 2*pi*ut/bodyInfo.rotperiod;
                rBf = refRz(spin)' * rVect;
                lat = asin(rBf(3)/norm(rBf));
                lon = atan2(rBf(2), rBf(1));
                expected = norm(rVect) - bodyInfo.radius - h(lat, lon);

                [~, ~, value] = testCase.makeGenericMA('Height Above Terrain', fx.evt1).evalConstraint(stateLog, testCase.celBodyData);
                testCase.verifyEqual(value, expected, 'AbsTol', 1e-9, ...
                    sprintf('height above terrain at %s', mat2str(rVect')));
            end
        end

        function checkGenericMAConstraintSensedAccelAndRemainingDeltaV(testCase)
            %Above the atmosphere the only sensed force is thrust, which
            %acts along body +X.  So, for ANY attitude,
            %
            %   total = axial = T/(m g0),  normal = 0,
            %
            %with T and Isp the engine's own vacuum figures and m the dry
            %plus tank mass the test set.  Remaining delta-V is the rocket
            %equation capability g0 Isp ln(m_wet/m_dry), independent of the
            %throttle, and zero once the engine is flagged inactive.
            fx = testCase.buildFixture();
            stage = fx.lvdData.launchVehicle.stages(1);
            engine = stage.engines(1);
            g0 = 9.80665;
            tankMass = 3.5;
            mWet = stage.dryMass + tankMass;
            mDry = stage.dryMass;
            dcm = refRz(0.7) * refRx(0.4) * refRy(-1.1);

            entryOn = testCase.makeAttitudeEntry(fx, fx.evt1, 0, [900; 1200; 0], [0; 2; 0.5], dcm);
            testCase.setThrottle(entryOn, 1);
            tankStates = entryOn.getAllTankStates();
            tankStates(1).tankMass = tankMass;
            logOn = testCase.makeLog(fx, entryOn);
            testCase.assertEqual(getPressureAtAltitude(entryOn.centralBody, 900), 0, ...
                'fixture must be above the atmosphere so only thrust is sensed');

            expectedAccel = engine.getVacThrust() / (mWet * g0);
            testCase.verifyEqual(testCase.genericValue('Sensed Acceleration (Total)', fx.evt1, logOn), expectedAccel, 'RelTol', 1e-12, ...
                'total sensed acceleration must be T/(m g0)');
            testCase.verifyEqual(testCase.genericValue('Sensed Acceleration (Axial)', fx.evt1, logOn), expectedAccel, 'RelTol', 1e-12, ...
                'thrust along body +X is all axial');
            testCase.verifyEqual(testCase.genericValue('Sensed Acceleration (Normal)', fx.evt1, logOn), 0, 'AbsTol', 1e-12, ...
                'thrust along body +X has no normal component');

            expectedDv = g0 * engine.getVacIsp() * log(mWet/mDry) / 1000;
            testCase.verifyEqual(testCase.genericValue('Remaining Delta-V Capability', fx.evt1, logOn), expectedDv, 'RelTol', 1e-12, ...
                'remaining delta-V must be g0 Isp ln(m_wet/m_dry)');

            entryOff = testCase.makeAttitudeEntry(fx, fx.evt1, 0, [900; 1200; 0], [0; 2; 0.5], dcm);
            testCase.setThrottle(entryOff, 0);
            tankStates = entryOff.getAllTankStates();
            tankStates(1).tankMass = tankMass;
            logOff = testCase.makeLog(fx, entryOff);
            for(name = {'Sensed Acceleration (Total)', 'Sensed Acceleration (Axial)', 'Sensed Acceleration (Normal)'})
                testCase.verifyEqual(testCase.genericValue(name{1}, fx.evt1, logOff), 0, 'AbsTol', 1e-12, ...
                    [name{1} ' must be zero on a vacuum coast']);
            end
            testCase.verifyEqual(testCase.genericValue('Remaining Delta-V Capability', fx.evt1, logOff), expectedDv, 'RelTol', 1e-12, ...
                'remaining delta-V capability must not depend on the throttle');

            engineStates = entryOff.getAllEngineStates();
            engineStates(1).active = false;
            testCase.verifyEqual(testCase.genericValue('Remaining Delta-V Capability', fx.evt1, logOff), 0, ...
                'remaining delta-V must be zero with no active engine');
        end

        function checkGenericMAConstraintCumulativeDeltaVAccumulatesAcrossEvents(testCase)
            %Cumulative delta-V integrates the WHOLE log up to the selected
            %node: finite burns (dt > 0) via the rocket equation, plus
            %same-time entries via |v2 - v1| (impulsive delta-V).  The
            %finite pieces are cross-checked against
            %EventDeltaVExpendedConstraint (oracle-checked above); the
            %impulsive piece is a velocity jump of exactly 0.3 km/s.
            %
            %   evt1:  A t=0 prop 4  -> B t=60 prop 3            (dv1)
            %   evt2:  C = B (same time, state)  -> D t=120 prop 2 (dv2)
            %          E t=120, v = v_D + [0.1 -0.2 0.2]          (+0.3)
            fx = testCase.buildFixture();
            A = testCase.makeBurnEntry(fx, fx.evt1, 0, 4);
            B = testCase.makeBurnEntry(fx, fx.evt1, 60, 3);
            C = testCase.makeBurnEntry(fx, fx.evt2, 60, 3);
            D = testCase.makeBurnEntry(fx, fx.evt2, 120, 2);
            E = testCase.makeBurnEntry(fx, fx.evt2, 120, 2);
            E.velocity = D.velocity + [0.1; -0.2; 0.2];
            stateLog = testCase.makeLog(fx, [A, B, C, D, E]);

            [~, ~, dv1] = EventDeltaVExpendedConstraint(fx.evt1, 0, 1e6).evalConstraint(testCase.makeLog(fx, [A, B]), testCase.celBodyData);
            [~, ~, dv2] = EventDeltaVExpendedConstraint(fx.evt2, 0, 1e6).evalConstraint(testCase.makeLog(fx, [C, D]), testCase.celBodyData);
            testCase.assertGreaterThan([dv1, dv2], 0, 'fixture burns must expend delta-V');

            final = ConstraintStateComparisonNodeEnum.FinalState;
            initial = ConstraintStateComparisonNodeEnum.InitialState;
            cases = { fx.evt1, initial, 0,               'event 1 start'; ...
                      fx.evt1, final,   dv1,             'event 1 end'; ...
                      fx.evt2, initial, dv1,             'event 2 start'; ...
                      fx.evt2, final,   dv1 + dv2 + 0.3, 'event 2 end, including the impulse' };
            %Evaluated last-to-first as well, because the task memoizes
            %prefixes and random access must not read a stale one.
            for(order = {1:4, 4:-1:1})
                for(i = order{1})
                    const = testCase.makeGenericMA('Cumulative Delta-V Expended', cases{i,1});
                    const.eventNode = cases{i,2};
                    [~, ~, value] = const.evalConstraint(stateLog, testCase.celBodyData);
                    testCase.verifyEqual(value, cases{i,3}, 'AbsTol', 1e-10, ['cumulative delta-V at ' cases{i,4}]);
                end
            end

            const = testCase.makeGenericMA('Cumulative Delta-V Expended', fx.evt1);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.LessThan;
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [dv1, dv1 + dv2 + 0.3], 'AbsTol', 1e-10, ...
                'cumulative delta-V comparison must integrate up to the comparison node');
            testCase.verifyEqual(c, value - valueStateComp, 'AbsTol', 1e-12);
        end

        function checkGenericMAConstraintSunGeometryQuantities(testCase)
            %Solar beta angle: the angle between the Sun direction and the
            %orbit plane, which this implementation reports UNSIGNED,
            %|asin(h_hat . s_hat)|.  Sun phase angle: the angle at the
            %spacecraft between the directions to the Sun and to the
            %central body center.  Both take the body's position relative
            %to the Sun from the ephemeris as an input.
            fx = testCase.buildFixture();
            bodyInfo = fx.template.centralBody;
            for(ut = [2000, 9.2e6])
                [rVect, vVect] = refCoe2Rv(900, 0.15, deg2rad(35), deg2rad(50), deg2rad(70), deg2rad(120), bodyInfo.gm);
                entry = testCase.makeEntry(fx, fx.evt1, ut);
                entry.position = rVect;
                entry.velocity = vVect;
                stateLog = testCase.makeLog(fx, entry);

                bodyWrtSun = getPositOfBodyWRTSun(ut, bodyInfo, testCase.celBodyData);
                bodyWrtSun = bodyWrtSun(:);
                hHat = cross(rVect, vVect) / norm(cross(rVect, vVect));
                sHat = -bodyWrtSun / norm(bodyWrtSun);
                scWrtSun = bodyWrtSun + rVect;
                scToSun = -scWrtSun;
                scToBody = -rVect;

                expectedBeta = abs(asind(dot(hHat, sHat)));
                expectedPhase = acosd(dot(scToSun, scToBody) / (norm(scToSun)*norm(scToBody)));

                testCase.verifyEqual(testCase.genericValue('Solar Beta Angle', fx.evt1, stateLog), expectedBeta, 'AbsTol', 1e-8, ...
                    sprintf('solar beta angle at ut = %g', ut));
                testCase.verifyEqual(testCase.genericValue('Sun Phase Angle', fx.evt1, stateLog), expectedPhase, 'AbsTol', 1e-8, ...
                    sprintf('sun phase angle at ut = %g', ut));
            end
        end

        function checkGenericMAConstraintStateComparisonConvertsCompEntryToFrame(testCase)
            %The comparison entry is converted into the constraint's frame
            %before the quantity is evaluated.  With the comparison entry
            %orbiting the Mun, its distance in the KERBIN-centered frame is
            %|r_mun/kerbin + r_sc/mun|, not |r_sc/mun|.
            fx = testCase.buildFixture();
            kerbin = fx.template.centralBody;
            [rA, vA] = refCoe2Rv(900, 0.15, deg2rad(35), deg2rad(50), deg2rad(70), deg2rad(120), kerbin.gm);
            eA = testCase.makeEntry(fx, fx.evt1, 3000);
            eA.position = rA;
            eA.velocity = vA;

            rB = [300; -150; 80];
            eB = testCase.makeEntry(fx, fx.evt2, 3000);
            eB.centralBody = testCase.mun;
            eB.position = rB;
            eB.velocity = [0.1; 0.3; -0.05];
            stateLog = testCase.makeLog(fx, [eA, eB]);

            munWrtKerbin = getPositOfBodyWRTSun(3000, testCase.mun, testCase.celBodyData) - ...
                           getPositOfBodyWRTSun(3000, kerbin, testCase.celBodyData);
            expectedComp = norm(munWrtKerbin(:) + rB);

            const = testCase.makeGenericMA('Position Vector Magnitude', fx.evt1);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
            [c, ceq, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, norm(rA), 'AbsTol', 1e-9);
            testCase.verifyEqual(valueStateComp, expectedComp, 'RelTol', 1e-10, ...
                'comparison entry must be converted into the constraint frame first');
            testCase.verifyEmpty(c);
            testCase.verifyEqual(ceq, value - valueStateComp, 'AbsTol', 1e-6);

            %Same-body comparison of an element: SMA 900 vs 1100.
            [rC, vC] = refCoe2Rv(1100, 0.05, deg2rad(10), deg2rad(80), deg2rad(20), deg2rad(300), kerbin.gm);
            eC = testCase.makeEntry(fx, fx.evt2, 3500);
            eC.position = rC;
            eC.velocity = vC;
            const = testCase.makeGenericMA('Semi-major Axis', fx.evt1);
            const.evalType = ConstraintEvalTypeEnum.StateComparison;
            const.stateCompEvent = fx.evt2;
            const.stateCompType = ConstraintStateComparisonTypeEnum.GreaterThan;
            const.setScaleFactor(100);
            [c, ~, value, ~, ~, ~, ~, valueStateComp] = const.evalConstraint(testCase.makeLog(fx, [eA, eC]), testCase.celBodyData);
            testCase.verifyEqual([value, valueStateComp], [900, 1100], 'AbsTol', 1e-7);
            testCase.verifyEqual(c, (1100 - 900)/100, 'AbsTol', 1e-9, ...
                'GreaterThan must emit (valueStateComp - value)/normFact');
        end

        %% ---------------------------------------------------------------
        %  Metadata and registry
        %  ---------------------------------------------------------------

        function checkAttitudeRateAndImpactTypeStringsAndStaticDetails(testCase)
            %Type strings feed constraint names and the GUI list; unit and
            %bound limits feed the edit dialog.  Pinned for every class
            %whose value checks above do not already cover them.
            fx = testCase.buildFixture();
            rows = { ...
                'PitchAngleConstraint',            'Pitch Angle',                  'deg',   -90,  90; ...
                'RollAngleConstraint',             'Roll Angle',                   'deg',  -360, 360; ...
                'YawAngleConstraint',              'Yaw Angle',                    'deg',  -360, 360; ...
                'BankAngleConstraint',             'Bank Angle',                   'deg',  -360, 360; ...
                'AngleOfAttackConstraint',         'Angle of Attack',              'deg',   -90,  90; ...
                'SideSlipAngleConstraint',         'Side Slip Angle',              'deg',  -360, 360; ...
                'InertialBankAngleConstraint',     'Inertial Bank Angle',          'deg',  -360, 360; ...
                'InertialAngleOfAttackConstraint', 'Inertial Angle of Attack',     'deg',   -90,  90; ...
                'InertialSideSlipAngleConstraint', 'Inertial Side Slip Angle',     'deg',  -360, 360; ...
                'BodyAngularVelXConstraint',       'Body X-axis Angular Velocity', 'deg/s', -Inf, Inf; ...
                'BodyAngularVelYConstraint',       'Body Y-axis Angular Velocity', 'deg/s', -Inf, Inf; ...
                'BodyAngularVelZConstraint',       'Body Z-axis Angular Velocity', 'deg/s', -Inf, Inf; ...
                'TotalBodyAngularVelConstraint',   'Total Body Angular Velocity',  'deg/s', -Inf, Inf; ...
                'TwoBodyImpactPointTime',          'Two-Body Time To Impact',      'sec',  -Inf, Inf; ...
                'TwoBodyImpactPointLatitude',      'Two-Body Impact Latitude',     'degN',  -90,  90; ...
                'TwoBodyImpactPointLongitude',     'Two-Body Impact Longitude',    'degE',    0, 360; ...
            };
            for(i = 1:size(rows, 1))
                className = rows{i,1};
                const = feval(className, fx.evt2, 1, 2);
                [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = const.getConstraintStaticDetails();
                testCase.verifyEqual(const.getConstraintType(), rows{i,2}, [className ' type string']);
                testCase.verifyEqual(const.getName(), [rows{i,2} ' - Event 2'], [className ' name']);
                testCase.verifyEqual(unit, rows{i,3}, [className ' unit']);
                testCase.verifyEqual([lbLim, ubLim], [rows{i,4}, rows{i,5}], [className ' bound limits']);
                testCase.verifyTrue(usesLbUb, [className ' uses lb/ub']);
                testCase.verifyFalse(usesCelBody || usesRefSc, [className ' uses no reference body or spacecraft']);
                [lb, ub] = const.getBounds();
                testCase.verifyEqual([lb, ub], [1, 2], [className ' getBounds']);
                testCase.verifySameHandle(const.getConstraintEvent(), fx.evt2, [className ' getConstraintEvent']);
                testCase.verifyFalse(const.usesEvent(fx.evt1), [className ' must not claim an unrelated event']);
            end
        end

        function checkConstraintEnumRegistryIsCompleteAndConstructible(testCase)
            %ConstraintEnum is how the GUI offers constraints.  Every row
            %must name a real class whose getDefaultConstraint builds an
            %instance of it, list names must be unique (the GUI looks rows
            %up by name), and every concrete AbstractConstraint subclass on
            %disk must be registered, so a new constraint cannot be left
            %unreachable from the GUI.
            fx = testCase.buildFixture();
            members = enumeration('ConstraintEnum');
            names = {members.name};
            testCase.verifyEqual(numel(unique(names)), numel(names), 'ConstraintEnum names must be unique');

            for(i = 1:numel(members))
                m = members(i);
                testCase.verifyEqual(exist(m.class, 'class'), 8, sprintf('%s: class %s does not exist', m.name, m.class));
                con = feval([m.class '.getDefaultConstraint'], m.constructorInput1, fx.lvdData);
                testCase.verifyClass(con, m.class, sprintf('%s: default constraint has the wrong class', m.name));
                type = con.getConstraintType();
                testCase.verifyTrue(ischar(type) && ~isempty(type), sprintf('%s: empty type string', m.name));

                [~, found] = ConstraintEnum.getIndForName(m.name);
                testCase.verifyEqual(found, m, sprintf('%s: getIndForName does not round trip', m.name));

                if(strcmp(m.class, 'GenericMAConstraint'))
                    testCase.verifyEqual(type, m.constructorInput1, sprintf('%s: GenericMA type must be its quantity', m.name));
                    [unit, lbLim, ubLim] = con.getConstraintStaticDetails();
                    testCase.verifyClass(unit, 'char', sprintf('%s: unit', m.name));
                    testCase.verifyLessThanOrEqual(lbLim, ubLim, sprintf('%s: bound limits', m.name));
                end
            end

            constraintFolder = fileparts(fileparts(which('AbstractConstraint')));
            listing = dir(fullfile(constraintFolder, '@*'));
            registered = unique({members.class});
            for(i = 1:numel(listing))
                className = listing(i).name(2:end);
                mc = meta.class.fromName(className);
                if(isempty(mc) || mc.Abstract || ~ismember('AbstractConstraint', superclasses(className)))
                    continue;
                end
                testCase.verifyTrue(ismember(className, registered), ...
                    sprintf('%s is a concrete constraint but is not registered in ConstraintEnum', className));
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
            tank2.capacity = 9;
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

        function entry = makeAttitudeEntry(testCase, fx, event, time, rVect, vVect, dcm)
            %makeAttitudeEntry Entry at a given state whose attitude is
            %exactly `dcm` (body-to-inertial).
            entry = testCase.makeEntry(fx, event, time);
            entry.position = rVect;
            entry.velocity = vVect;
            entry.steeringModel = TestFixedDcmSteeringModel(dcm);
        end

        function [rVect, vVect, vRel, ut] = aeroGeometry(~, fx)
            %aeroGeometry Shared aero-angle state: a slow vehicle so that
            %the body rotation term omega x r (~0.2 km/s here) turns the
            %relative wind well away from the inertial velocity.
            bodyInfo = fx.template.centralBody;
            rVect = [700; 200; 300];
            vVect = [0.25; 0.6; 0.3];
            ut = 321;
            omega = [0; 0; 2*pi/bodyInfo.rotperiod];
            vRel = vVect - cross(omega, rVect);
        end

        function [entry, ref] = makeImpactEntry(testCase, fx, event, bodyInfo, sma, ecc, incDeg, raanDeg, argDeg, truDeg, ut, ~)
            %makeImpactEntry Entry on the given conic plus the closed-form
            %impact oracle for it.
            [rVect, vVect] = refCoe2Rv(sma, ecc, deg2rad(incDeg), deg2rad(raanDeg), deg2rad(argDeg), deg2rad(truDeg), bodyInfo.gm);
            entry = testCase.makeEntry(fx, event, ut);
            entry.position = rVect;
            entry.velocity = vVect;
            ref = refTwoBodyImpact(sma, ecc, deg2rad(incDeg), deg2rad(raanDeg), deg2rad(argDeg), deg2rad(truDeg), ut, bodyInfo);
        end

        function entry = makeBurnEntry(testCase, fx, event, time, propMass)
            %makeBurnEntry Full-throttle entry with a prescribed tank mass.
            entry = testCase.makeEntry(fx, event, time);
            testCase.setThrottle(entry, 1);
            tankStates = entry.getAllTankStates();
            tankStates(1).tankMass = propMass;
        end

        function [fx, stateLog, intCalc, derivCalc] = buildCalculusLog(testCase)
            %buildCalculusLog Two events whose altitude is piecewise linear
            %(see checkCalculusCalculationValueConstraintReadsNamedCalc),
            %carrying an integral and a derivative of 'Altitude'.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            frame = testCase.kerbin.getBodyCenteredInertialFrame();

            intCalc = LaunchVehicleIntegralCalc(lvdData);
            intCalc.frame = frame;
            intCalc.quantStr = 'Altitude';
            lvdData.launchVehicle.addCalculusCalcObj(intCalc);

            derivCalc = LaunchVehicleDerivativeCalc(lvdData);
            derivCalc.frame = frame;
            derivCalc.quantStr = 'Altitude';
            lvdData.launchVehicle.addCalculusCalcObj(derivCalc);

            template = lvdData.initStateModel.getInitialStateLogEntry();
            fx = testCase.fixtureFromLvdData(lvdData, template);

            e1 = LaunchVehicleStateLogEntry.empty(1,0);
            for(t = [0, 10, 20, 30])
                e1(end+1) = testCase.makeAltitudeEntry(fx, fx.evt1, t, 100 + 0.3*t); %#ok<AGROW>
            end
            e2 = LaunchVehicleStateLogEntry.empty(1,0);
            for(t = [30, 40, 50])
                e2(end+1) = testCase.makeAltitudeEntry(fx, fx.evt2, t, 109 - 0.4*(t - 30)); %#ok<AGROW>
            end

            testCase.populateEventCalcStates(e1, LaunchVehicleStateLogEntry.empty(1,0));
            testCase.populateEventCalcStates(e2, e1(end));
            stateLog = testCase.makeLog(fx, [e1, e2]);
        end

        function entry = makeAltitudeEntry(testCase, fx, event, time, altitudeKm)
            %+x axis placement keeps norm(position) exact (see
            %StateLogCalculusElectricalTest.makeEntry).
            entry = testCase.makeEntry(fx, event, time);
            entry.position = [fx.template.centralBody.radius + altitudeKm; 0; 0];
            entry.velocity = [0; 0; 0.001];
        end

        function populateEventCalcStates(~, entries, prevEventLastEntry)
            %populateEventCalcStates Mirrors what propagation does at the
            %end of each event (LaunchVehicleStateLogEntry, after the
            %extrema update): ONE set of calculus states shared by the
            %event's entries, sampled over that event only, with the
            %integral constant carried over from the previous event.
            states = entries(1).calcObjStates.copy();
            for(k = 1:numel(states))
                states(k).createDataFromStates(entries);
                if(states(k).calcObj.type == CalculusCalculationEnum.Integral && ~isempty(prevEventLastEntry))
                    states(k).constant = prevEventLastEntry.calcObjStates(k).getValueAtTime(prevEventLastEntry.time);
                end
            end
            for(i = 1:numel(entries))
                entries(i).calcObjStates = states;
            end
        end

        function const = makeGenericMA(~, type, event)
            const = GenericMAConstraint(type, event, -1e9, 1e9, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
        end

        function value = genericValue(testCase, type, event, stateLog)
            [~, ~, value] = testCase.makeGenericMA(type, event).evalConstraint(stateLog, testCase.celBodyData);
        end

        function verifyGenericMARows(testCase, rows, event, stateLog, frame)
            %verifyGenericMARows rows = {type, expected, absTol; ...}.
            %An empty frame leaves the constraint on its default (central
            %body inertial) frame.
            for(i = 1:size(rows, 1))
                const = testCase.makeGenericMA(rows{i,1}, event);
                if(~isempty(frame))
                    const.frame = frame;
                end
                lastwarn('');
                [~, ~, value, ~, ~, type] = const.evalConstraint(stateLog, testCase.celBodyData);
                [warnMsg, ~] = lastwarn();
                testCase.verifyEmpty(warnMsg, sprintf('%s raised a warning: %s', rows{i,1}, warnMsg));
                testCase.verifyEqual(type, rows{i,1}, 'GenericMAConstraint must report its quantity as its type');
                testCase.verifyEqual(value, rows{i,2}, 'AbsTol', rows{i,3}, sprintf('GenericMAConstraint(''%s'')', rows{i,1}));
            end
        end

        function verifyWrappedDegEqual(testCase, actual, expected, absTol, msg)
            %verifyWrappedDegEqual Degree comparison modulo 360, so a
            %legitimate 0/360 wrap is not reported as a 360 degree error.
            testCase.verifyEqual(mod(actual - expected + 180, 360) - 180, 0, 'AbsTol', absTol, ...
                sprintf('%s (actual %.12g, expected %.12g)', msg, actual, expected));
        end
    end
end

%% -----------------------------------------------------------------------
%  Reference math.  Written from the definitions; none of these call the
%  production rotation, frame or element helpers the constraints use.
%  -----------------------------------------------------------------------

function R = refRx(a)
    R = [1, 0, 0; 0, cos(a), -sin(a); 0, sin(a), cos(a)];
end

function R = refRy(a)
    R = [cos(a), 0, sin(a); 0, 1, 0; -sin(a), 0, cos(a)];
end

function R = refRz(a)
    R = [cos(a), -sin(a), 0; sin(a), cos(a), 0; 0, 0, 1];
end

function R = refAxAng(u, theta)
    %Rodrigues rotation by theta about the unit axis u.
    u = u(:) / norm(u);
    K = [0, -u(3), u(2); u(3), 0, -u(1); -u(2), u(1), 0];
    R = cos(theta)*eye(3) + sin(theta)*K + (1 - cos(theta))*(u*u');
end

function NED = refNedTriad(rVect)
    %Columns are local North, East, Down at rVect on a sphere spinning
    %about +z, in the same axes as rVect.
    lat = asin(rVect(3)/norm(rVect));
    lon = atan2(rVect(2), rVect(1));
    north = [-sin(lat)*cos(lon); -sin(lat)*sin(lon); cos(lat)];
    east  = [-sin(lon); cos(lon); 0];
    down  = -[cos(lat)*cos(lon); cos(lat)*sin(lon); sin(lat)];
    NED = [north, east, down];
end

function W = refWindTriad(rVect, vVect)
    %Columns are the wind axes: x along the velocity, z the part of local
    %"down" normal to it (Gram-Schmidt), y completing the right hand set.
    x = vVect(:) / norm(vVect);
    down = -rVect(:) / norm(rVect);
    z = down - dot(down, x)*x;
    z = z / norm(z);
    y = cross(z, x);
    W = [x, y, z];
end

function PQW = refPerifocalAxes(inc, raan, arg)
    %Columns are the perifocal P (to periapsis), Q, W (orbit normal) axes.
    PQW = refRz(raan) * refRx(inc) * refRz(arg);
end

function ref = refTwoBodyImpact(sma, ecc, inc, raan, arg, tru0, ut0, bodyInfo)
    %refTwoBodyImpact Closed-form descending impact with the body sphere.
    gmu = bodyInfo.gm;
    R = bodyInfo.radius;
    p = sma*(1 - ecc^2);
    truImpact = 2*pi - acos((p/R - 1)/ecc);
    meanMotion = sqrt(gmu/sma^3);

    ref.dt = mod(refMeanFromTrue(truImpact, ecc) - refMeanFromTrue(tru0, ecc), 2*pi) / meanMotion;
    ref.rImpact = refCoe2Rv(sma, ecc, inc, raan, arg, truImpact, gmu);

    spin = deg2rad(bodyInfo.rotini) + 2*pi*(ut0 + ref.dt)/bodyInfo.rotperiod;
    ref.lat = asind(ref.rImpact(3)/norm(ref.rImpact));
    ref.lon = rad2deg(mod(atan2(ref.rImpact(2), ref.rImpact(1)) - spin, 2*pi));
end

function M = refMeanFromTrue(tru, ecc)
    E = 2*atan(sqrt((1 - ecc)/(1 + ecc)) * tan(tru/2));
    M = E - ecc*sin(E);
end
