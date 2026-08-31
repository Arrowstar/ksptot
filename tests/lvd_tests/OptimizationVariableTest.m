classdef OptimizationVariableTest < KsptotTestCase
    %OptimizationVariableTest Round-trip coverage of AbstractOptimizationVariable subclasses.
    %
    % Every LVD optimization variable is a thin adapter between the
    % optimizer's flat x vector and one or more fields on a "target" data
    % object (a termination condition, an event action, a tank, a steering
    % model, ...).  The adapter has to get four separate things right:
    %
    %   1. getXsForVariable()          reads the target field(s)
    %   2. updateObjWithVarValue(x)    writes the target field(s)
    %   3. getUseTfForVariable()/      selects WHICH slots participate, and
    %      setUseTfForVariable()       therefore how x is packed/unpacked
    %   4. getBndsForVariable()        feeds the base class scaling
    %
    % The classic failure modes here are silent: a variable that reads slot
    % 2 but writes slot 3, a multi-component variable whose packing index
    % desynchronizes when only some components are enabled, or a scale
    % factor applied on read but not on write (or applied inverted).  None
    % of these throw -- they just make the optimizer converge to the wrong
    % answer.  So every check below is a genuine round trip:
    %
    %   * write a known value through the variable, then read the target
    %     object's field DIRECTLY (not through the variable) and compare;
    %   * read the scaled x back and compare against the normalization
    %     formula recomputed by hand in this file;
    %   * push that scaled value back through updateObjWithScaledVarValue
    %     and confirm the target field returns to where it started.
    %
    % The scaling oracle is spelled out once here rather than delegated to
    % production code.  AbstractOptimizationVariable maps [lb, ub] onto
    % [-1, +1] about the bound midpoint:
    %
    %       xS = (x - (lb + ub)/2) / ((ub - lb)/2)
    %       x  = xS * ((ub - lb)/2) + (lb + ub)/2
    %
    % ...except when the bounds are degenerate (ub - lb <= 1E-10), in which
    % case scaling is skipped entirely and xS == x.  Both branches are
    % pinned below.
    %
    % Skipped (documented):
    %   * InitialStateVariable, SetKinematicStateActionVariable --
    %     aggregate wrappers that delegate to a nested element-set variable
    %     plus a time slot; their nested delegates ARE covered here
    %     (Cartesian/Keplerian/Geographic/Universal element set variables),
    %     and the wrappers themselves need a fully wired initial-state
    %     model to construct meaningfully.
    %   * SetGenericQuatInterpSteeringModelActionOptimVar,
    %     SetGenericTabularQuatInterpSteeringModelActionOptimVar,
    %     SetInterpolatedThrottleActionOptimVar,
    %     SetGenericSumOfSinesSteeringModelActionOptimVar,
    %     SetGenericSelectableSteeringModelActionOptimVar --
    %     these wrap interpolant/table objects whose variable count is a
    %     function of user-supplied breakpoint data.  Constructing a
    %     meaningful fixture requires the GUI-side table editors that are
    %     explicitly out of scope for this test package.
    %   * SetAeroSteeringModelActionOptimVar,
    %     SetGenericPolySteeringModelActionOptimVar,
    %     SetGenericLinearTangentSteeringModelActionOptimVar --
    %     structurally identical to SetRPYSteeringModelActionOptimVar
    %     (10-slot poly steering adapters); the shared packing logic is
    %     exercised through the RPY case.  Their getAllBndsForVariable
    %     getAllBndsForVariable is guarded by
    %     checkGetAllBndsReturnsTheUpperBoundNotTheLower.
    %   * The three ~deprecated/ variables (BodyFixedOrbitVariable,
    %     CR3BPOrbitVariable, KeplerianOrbitVariable) -- superseded by the
    %     element set variables and not reachable from current UI.

    properties(TestParameter)
        caseName = { ...
            'EventDurationVariable', ...
            'AltitudeVariable', ...
            'ApoapsisAltitudeVariable', ...
            'PeriapsisAltitudeVariable', ...
            'LatitudeVariable', ...
            'LongitudeVariable', ...
            'TrueAnomalyVariable', ...
            'FlightPathAngleVariable', ...
            'DynPressVariable', ...
            'HeightAboveTerrainVariable', ...
            'AoATermCondVariable', ...
            'BankAngleTermCondVariable', ...
            'PitchAngleTermCondVariable', ...
            'RollAngleTermCondVariable', ...
            'YawAngleTermCondVariable', ...
            'SideSlipAngleTermCondVariable', ...
            'ThrottleTermCondVariable', ...
            'Thr2WghtTermCondVariable', ...
            'T2WThrottleModelVariable', ...
            'TankMassVariable', ...
            'StopwatchValueVariable', ...
            'PluginVariable', ...
            'StageDryMassVariable', ...
            'StageTankInitMassVariable', ...
            'AddMassToTankActionVariable', ...
            'SetKinematicStateTankStateVariable', ...
            'SetKinematicStateEpsStorageStateVariable', ...
            'AddDeltaVActionVariableAllComponents', ...
            'AddDeltaVActionVariableMiddleComponentOnly', ...
            'CartesianElementSetVariableAllComponents', ...
            'CartesianElementSetVariablePartialMask', ...
            'KeplerianElementSetVariableAllComponents', ...
            'KeplerianElementSetVariablePartialMask', ...
            'GeographicElementSetVariableAllComponents', ...
            'GeographicElementSetVariablePartialMask', ...
            'UniversalElementSetVariableAllComponents', ...
            'SetPolyThrottleModelVariableAllComponents', ...
            'SetPolyThrottleModelVariablePartialMask', ...
            'SetRPYSteeringModelVariableAllComponents', ...
            'SetRPYSteeringModelVariablePartialMask', ...
            'ScalingIsCenteredAndHalfWidthNormalized', ...
            'DegenerateBoundsSkipScaling', ...
            'InactiveVariableContributesNothing', ...
            'VariableSetAggregatesInOrder', ...
            'VariableSetScaledUpdateSlicesByVarCount', ...
            'DisplayMetadataFlags', ...
            'GetAllBoundsRoundTripsWhereImplementedCorrectly', ...
            'GetAllBndsUsesTheClassesOwnBoundProperties', ...
            'GetAllBndsReturnsTheUpperBoundNotTheLower', ...
            'NetChargeRateVariableReadsNetChargeRate', ...
            'TotalStateOfChargeVariableReadsTotalStateOfCharge', ...
        };
    end

    methods(Test)
        function optimizationVariablesMatchIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ============================================================
        %  Scalar (single-slot) variables
        %  ============================================================
        %
        %  Each of these owns exactly one target field.  The helper
        %  verifyScalarVariable does the whole round trip; all the case
        %  method has to do is build the target object and name the field
        %  that the variable is supposed to be driving.

        function checkEventDurationVariable(testCase)
            tgt = EventDurationTermCondition(0);
            var = EventDurationOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'duration', 10, 1000, 100, 750, ...
                'EventDurationOptimizationVariable');
        end

        function checkAltitudeVariable(testCase)
            tgt = AltitudeTermCondition(0);
            var = AltitudeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'altitude', 0, 500, 100, 250, ...
                'AltitudeOptimizationVariable');
        end

        function checkApoapsisAltitudeVariable(testCase)
            tgt = ApoapsisAltitudeTermCondition(0);
            var = ApoapsisAltitudeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'apoalt', 0, 1000, 200, 600, ...
                'ApoapsisAltitudeOptimizationVariable');
        end

        function checkPeriapsisAltitudeVariable(testCase)
            tgt = PeriapsisAltitudeTermCondition(0);
            var = PeriapsisAltitudeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'perialt', 0, 1000, 80, 450, ...
                'PeriapsisAltitudeOptimizationVariable');
        end

        function checkLatitudeVariable(testCase)
            %Latitude is stored in radians (getVarsStoredInRad is true for
            %this variable), so bounds and values are radians too.
            tgt = LatitudeTermCondition(0);
            var = LatitudeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'lat', -pi/2, pi/2, 0.3, -0.85, ...
                'LatitudeOptimizationVariable');
        end

        function checkLongitudeVariable(testCase)
            tgt = LongitudeTermCondition(0);
            var = LongitudeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'long', -pi, pi, 1.1, -2.4, ...
                'LongitudeOptimizationVariable');
        end

        function checkTrueAnomalyVariable(testCase)
            tgt = TrueAnomalyTermCondition(0);
            var = TrueAnomalyOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'tru', 0, 2*pi, 1.0, 4.5, ...
                'TrueAnomalyOptimizationVariable');
        end

        function checkFlightPathAngleVariable(testCase)
            tgt = FlightPathAngleTermCondition(0);
            var = FlightPathAngleOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'fpa', -pi/2, pi/2, 0.2, -0.4, ...
                'FlightPathAngleOptimizationVariable');
        end

        function checkDynPressVariable(testCase)
            tgt = DynamicPressureTermCondition(0);
            var = DynPressOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'dynP', 0, 100, 12, 57, ...
                'DynPressOptimizationVariable');
        end

        function checkHeightAboveTerrainVariable(testCase)
            tgt = HeightAboveTerrainCondition(0);
            var = HeightAboveTerrainOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'heightAboveTerrain', 0, 50, 5, 33, ...
                'HeightAboveTerrainOptimizationVariable');
        end

        function checkAoATermCondVariable(testCase)
            tgt = AngleOfAttackTermCondition(0);
            var = AoATermConditionOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetAoA', -30, 30, 5, -12, ...
                'AoATermConditionOptimizationVariable');
        end

        function checkBankAngleTermCondVariable(testCase)
            tgt = BankAngleTermCondition(0);
            var = BankAngleTermCondOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetBankAngle', -180, 180, 30, -95, ...
                'BankAngleTermCondOptimizationVariable');
        end

        function checkPitchAngleTermCondVariable(testCase)
            tgt = PitchTermCondition(0);
            var = PitchAngleTermCondOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetPitchAngle', -90, 90, 20, -45, ...
                'PitchAngleTermCondOptimVar');
        end

        function checkRollAngleTermCondVariable(testCase)
            tgt = RollTermCondition(0);
            var = RollAngleTermCondOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetRollAngle', -180, 180, 15, -160, ...
                'RollAngleTermCondOptimizationVariable');
        end

        function checkYawAngleTermCondVariable(testCase)
            tgt = YawTermCondition(0);
            var = YawAngleTermCondOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetYawAngle', -180, 180, 45, -70, ...
                'YawAngleTermCondOptimVar');
        end

        function checkSideSlipAngleTermCondVariable(testCase)
            tgt = SideSlipAngleTermCondition(0);
            var = SideSlipAngleTermCondOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetSlipAngle', -30, 30, 3, -18, ...
                'SideSlipAngleTermCondOptimVar');
        end

        function checkThrottleTermCondVariable(testCase)
            tgt = ThrottleTermCondition(0);
            var = ThrottleTermCondOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetThrottle', 0, 1, 0.4, 0.85, ...
                'ThrottleTermCondOptimVar');
        end

        function checkThr2WghtTermCondVariable(testCase)
            tgt = SeaLevelThrustToWeightTermCondition(0);
            var = Thr2WghtTermCondOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetTtW', 0.5, 3, 1.2, 2.4, ...
                'Thr2WghtTermCondOptimVar');
        end

        function checkT2WThrottleModelVariable(testCase)
            %T2WThrottleModel's constructor is private; the factory method
            %is the only supported way to build one.
            tgt = T2WThrottleModel.getDefaultThrottleModel();
            var = T2WThrottleModelOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetT2W', 0.5, 3, 1.5, 2.2, ...
                'T2WThrottleModelOptimVar');
        end

        function checkTankMassVariable(testCase)
            [~, tank] = testCase.buildTankFixture();
            tgt = TankMassTermCondition(tank, 0);
            var = TankMassOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'targetMass', 0, 10, 2, 7, ...
                'TankMassOptimizationVariable');
        end

        function checkStopwatchValueVariable(testCase)
            [~, sw] = testCase.buildStopwatchFixture();
            tgt = StopwatchValueTermCondition(sw, 0);
            var = StopwatchValueOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'value', 0, 1000, 120, 640, ...
                'StopwatchValueOptimizationVariable');
        end

        function checkPluginVariable(testCase)
            tgt = LvdPluginOptimVarWrapper();
            tgt.name = 'Round Trip Plugin Var';
            var = PluginOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'value', -5, 5, 1.5, -3.25, ...
                'PluginOptimizationVariable');
        end

        function checkStageDryMassVariable(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stage = lvdData.launchVehicle.stages(1);
            var = StageDryMassOptimizationVariable(stage);
            testCase.verifyScalarVariable(var, stage, 'dryMass', 0.5, 20, 3, 11, ...
                'StageDryMassOptimizationVariable');
        end

        function checkStageTankInitMassVariable(testCase)
            [~, tank] = testCase.buildTankFixture();
            var = StageTankInitMassOptimVar(tank);
            testCase.verifyScalarVariable(var, tank, 'initialMass', 0, 20, 4, 13, ...
                'StageTankInitMassOptimVar');
        end

        function checkAddMassToTankActionVariable(testCase)
            [~, tank] = testCase.buildTankFixture();
            tgt = AddMassToTankAction(tank, 0);
            var = AddMassToTankActionOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'massToAdd', -5, 5, 1, -2.5, ...
                'AddMassToTankActionOptimVar');
        end

        function checkSetKinematicStateTankStateVariable(testCase)
            [~, tank] = testCase.buildTankFixture();
            tgt = SetKinematicStateTankState(tank);
            var = SetKinematicStateTankStateOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'tankStateMassToSet', 0, 10, 2, 6, ...
                'SetKinematicStateTankStateOptimVar');
        end

        function checkSetKinematicStateEpsStorageStateVariable(testCase)
            [~, battery] = testCase.buildBatteryFixture();
            tgt = SetKinematicStateEPStorageState(battery);
            var = SetKinematicStateEpsStorageStateOptimVar(tgt);
            testCase.verifyScalarVariable(var, tgt, 'socToSet', 0, 100, 30, 75, ...
                'SetKinematicStateEpsStorageStateOptimVar');
        end

        %% ============================================================
        %  Multi-component variables
        %  ============================================================
        %
        %  These pack an arbitrary subset of their slots into x.  The
        %  interesting bug class is index desynchronization: production
        %  walks its slots with a running counter `ind` that only advances
        %  when the slot is enabled, so a mismatch between the read order
        %  and the write order only shows up under a PARTIAL mask.  That is
        %  why every multi-component type is exercised twice, once fully
        %  enabled and once with a mask that has holes in it.

        function checkAddDeltaVActionVariableAllComponents(testCase)
            dv = AddDeltaVAction([0;0;0], DeltaVFrameEnum.Inertial, false);
            var = AddDeltaVActionVariable(dv);

            readAll  = @() dv.deltaVVect(:).';
            writeAll = @(v) setDeltaVVect(dv, v);

            testCase.verifyMultiVariable(var, [true true true], readAll, writeAll, ...
                [-1 -1 -1], [1 1 1], [0.1 -0.2 0.3], [-0.45 0.6 -0.75], ...
                'AddDeltaVActionVariable (all three components)');
        end

        function checkAddDeltaVActionVariableMiddleComponentOnly(testCase)
            %Only the Y component participates.  If updateObjWithVarValue
            %mis-tracked its running index it would write x(1) into slot 1
            %or slot 3 instead; the untouched-slot assertions catch that.
            dv = AddDeltaVAction([0;0;0], DeltaVFrameEnum.Inertial, false);
            var = AddDeltaVActionVariable(dv);

            readAll  = @() dv.deltaVVect(:).';
            writeAll = @(v) setDeltaVVect(dv, v);

            testCase.verifyMultiVariable(var, [false true false], readAll, writeAll, ...
                [-1 -1 -1], [1 1 1], [0.1 -0.2 0.3], [-0.45 0.6 -0.75], ...
                'AddDeltaVActionVariable (Y component only)');
        end

        function checkCartesianElementSetVariableAllComponents(testCase)
            elems = CartesianElementSet(0, [700; 0; 0], [0; 2.25; 0], testCase.kerbinFrame);
            var = CartesianElementSetVariable(elems);

            readAll  = @() [elems.rVect(:).' elems.vVect(:).'];
            writeAll = @(v) setCartesianComponents(elems, v);

            testCase.verifyMultiVariable(var, true(1,6), readAll, writeAll, ...
                [-2000 -2000 -2000 -5 -5 -5], [2000 2000 2000 5 5 5], ...
                [700 10 -20 0.1 2.25 -0.3], [850 -40 55 -0.2 1.9 0.45], ...
                'CartesianElementSetVariable (all six components)');
        end

        function checkCartesianElementSetVariablePartialMask(testCase)
            %Rz and Vx enabled only: slots 3 and 4.  A packing bug that
            %reads slot 3 but writes slot 2 shows up immediately.
            elems = CartesianElementSet(0, [700; 0; 0], [0; 2.25; 0], testCase.kerbinFrame);
            var = CartesianElementSetVariable(elems);

            readAll  = @() [elems.rVect(:).' elems.vVect(:).'];
            writeAll = @(v) setCartesianComponents(elems, v);

            testCase.verifyMultiVariable(var, [false false true true false false], ...
                readAll, writeAll, ...
                [-2000 -2000 -2000 -5 -5 -5], [2000 2000 2000 5 5 5], ...
                [700 10 -20 0.1 2.25 -0.3], [850 -40 55 -0.2 1.9 0.45], ...
                'CartesianElementSetVariable (Rz and Vx only)');
        end

        function checkKeplerianElementSetVariableAllComponents(testCase)
            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            var = KeplerianElementSetVariable(elems);

            props = {'sma', 'ecc', 'inc', 'raan', 'arg', 'tru'};
            readAll  = @() readProps(elems, props);
            writeAll = @(v) writeProps(elems, props, v);

            testCase.verifyMultiVariable(var, true(1,6), readAll, writeAll, ...
                [600 0 0 0 0 0], [1200 0.9 pi 2*pi 2*pi 2*pi], ...
                [700 0.01 0.1 0.2 0.3 0.4], [925 0.35 1.2 3.1 5.0 2.2], ...
                'KeplerianElementSetVariable (all six elements)');
        end

        function checkKeplerianElementSetVariablePartialMask(testCase)
            %SMA, inclination and true anomaly only -- slots 1, 3 and 6.
            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            var = KeplerianElementSetVariable(elems);

            props = {'sma', 'ecc', 'inc', 'raan', 'arg', 'tru'};
            readAll  = @() readProps(elems, props);
            writeAll = @(v) writeProps(elems, props, v);

            testCase.verifyMultiVariable(var, [true false true false false true], ...
                readAll, writeAll, ...
                [600 0 0 0 0 0], [1200 0.9 pi 2*pi 2*pi 2*pi], ...
                [700 0.01 0.1 0.2 0.3 0.4], [925 0.35 1.2 3.1 5.0 2.2], ...
                'KeplerianElementSetVariable (SMA, INC, TA only)');
        end

        function checkGeographicElementSetVariableAllComponents(testCase)
            elems = GeographicElementSet(0, 0.1, 0.2, 100, 0.3, 0.4, 2.0, testCase.kerbinFrame);
            var = GeographicElementSetVariable(elems);

            props = {'lat', 'long', 'alt', 'velAz', 'velEl', 'velMag'};
            readAll  = @() readProps(elems, props);
            writeAll = @(v) writeProps(elems, props, v);

            testCase.verifyMultiVariable(var, true(1,6), readAll, writeAll, ...
                [-pi/2 -pi 0 0 -pi/2 0], [pi/2 pi 500 2*pi pi/2 5], ...
                [0.1 0.2 100 0.3 0.4 2.0], [-0.55 -1.9 275 4.1 -0.85 3.4], ...
                'GeographicElementSetVariable (all six elements)');
        end

        function checkGeographicElementSetVariablePartialMask(testCase)
            %Longitude, altitude and velocity magnitude -- slots 2, 3 and 6.
            elems = GeographicElementSet(0, 0.1, 0.2, 100, 0.3, 0.4, 2.0, testCase.kerbinFrame);
            var = GeographicElementSetVariable(elems);

            props = {'lat', 'long', 'alt', 'velAz', 'velEl', 'velMag'};
            readAll  = @() readProps(elems, props);
            writeAll = @(v) writeProps(elems, props, v);

            testCase.verifyMultiVariable(var, [false true true false false true], ...
                readAll, writeAll, ...
                [-pi/2 -pi 0 0 -pi/2 0], [pi/2 pi 500 2*pi pi/2 5], ...
                [0.1 0.2 100 0.3 0.4 2.0], [-0.55 -1.9 275 4.1 -0.85 3.4], ...
                'GeographicElementSetVariable (long, alt, velMag only)');
        end

        function checkUniversalElementSetVariableAllComponents(testCase)
            elems = UniversalElementSet(0, -2.5, 700, 0.1, 0.2, 0.3, 10, testCase.kerbinFrame);
            var = UniversalElementSetVariable(elems);

            props = {'c3', 'rP', 'inc', 'raan', 'arg', 'tau'};
            readAll  = @() readProps(elems, props);
            writeAll = @(v) writeProps(elems, props, v);

            testCase.verifyMultiVariable(var, true(1,6), readAll, writeAll, ...
                [-10 600 0 0 0 -500], [10 1200 pi 2*pi 2*pi 500], ...
                [-2.5 700 0.1 0.2 0.3 10], [-1.25 900 1.4 4.2 1.1 -220], ...
                'UniversalElementSetVariable (all six elements)');
        end

        function checkSetPolyThrottleModelVariableAllComponents(testCase)
            model = ThrottlePolyModel.getDefaultThrottleModel();
            var = SetPolyThrottleModelActionOptimVar(model);

            props = {'constTerm', 'linearTerm', 'accelTerm', 'tOffset'};
            readAll  = @() readProps(model.throttleModel, props);
            writeAll = @(v) writeProps(model.throttleModel, props, v);

            testCase.verifyMultiVariable(var, true(1,4), readAll, writeAll, ...
                [0 -1 -1 -100], [1 1 1 100], ...
                [0.5 0.01 -0.002 0], [0.85 -0.03 0.004 25], ...
                'SetPolyThrottleModelActionOptimVar (all four terms)');
        end

        function checkSetPolyThrottleModelVariablePartialMask(testCase)
            %Constant term and time offset only -- slots 1 and 4, i.e. the
            %first and last slots with two disabled slots between them.
            model = ThrottlePolyModel.getDefaultThrottleModel();
            var = SetPolyThrottleModelActionOptimVar(model);

            props = {'constTerm', 'linearTerm', 'accelTerm', 'tOffset'};
            readAll  = @() readProps(model.throttleModel, props);
            writeAll = @(v) writeProps(model.throttleModel, props, v);

            testCase.verifyMultiVariable(var, [true false false true], readAll, writeAll, ...
                [0 -1 -1 -100], [1 1 1 100], ...
                [0.5 0.01 -0.002 0], [0.85 -0.03 0.004 25], ...
                'SetPolyThrottleModelActionOptimVar (const + time offset only)');
        end

        function checkSetRPYSteeringModelVariableAllComponents(testCase)
            model = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            var = SetRPYSteeringModelActionOptimVar(model);

            [readAll, writeAll] = rpyAccessors(model);

            base = [0.10 0.011 0.0012  0.20 0.021 0.0022  0.30 0.031 0.0032  0];
            newV = [-0.4 -0.02 0.003  0.55 -0.04 0.0011  -0.6 0.05 -0.004  40];

            testCase.verifyMultiVariable(var, true(1,10), readAll, writeAll, ...
                [-pi -0.1 -0.01  -pi -0.1 -0.01  -pi -0.1 -0.01  -100], ...
                [ pi  0.1  0.01   pi  0.1  0.01   pi  0.1  0.01   100], ...
                base, newV, 'SetRPYSteeringModelActionOptimVar (all ten slots)');
        end

        function checkSetRPYSteeringModelVariablePartialMask(testCase)
            %Pitch constant, yaw rate and the shared time offset.  The time
            %offset slot is special: production READS it back from the yaw
            %model but WRITES it to all three angle models, so the read and
            %write paths are asymmetric by design.  Our writeAll mirrors
            %that (writes all three, reads yaw), which is what makes the
            %"unchanged slots stay unchanged" assertion meaningful.
            model = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            var = SetRPYSteeringModelActionOptimVar(model);

            [readAll, writeAll] = rpyAccessors(model);

            base = [0.10 0.011 0.0012  0.20 0.021 0.0022  0.30 0.031 0.0032  0];
            newV = [-0.4 -0.02 0.003  0.55 -0.04 0.0011  -0.6 0.05 -0.004  40];

            mask = [false false false  true false false  false true false  true];

            testCase.verifyMultiVariable(var, mask, readAll, writeAll, ...
                [-pi -0.1 -0.01  -pi -0.1 -0.01  -pi -0.1 -0.01  -100], ...
                [ pi  0.1  0.01   pi  0.1  0.01   pi  0.1  0.01   100], ...
                base, newV, 'SetRPYSteeringModelActionOptimVar (pitch const, yaw rate, tOffset)');

            %The time offset must have landed on ALL THREE angle models,
            %not just the one the getter happens to read from.
            testCase.verifyEqual(model.rollModel.tOffset, model.yawModel.tOffset, ...
                'Roll model time offset did not track the shared time offset variable.');
            testCase.verifyEqual(model.pitchModel.tOffset, model.yawModel.tOffset, ...
                'Pitch model time offset did not track the shared time offset variable.');
        end

        %% ============================================================
        %  Base class scaling and variable set aggregation semantics
        %  ============================================================

        function checkScalingIsCenteredAndHalfWidthNormalized(testCase)
            %The scaled representation must map lb -> -1, the bound
            %midpoint -> 0, and ub -> +1, and the inverse map must undo it
            %exactly.  Bounds are deliberately asymmetric about zero so a
            %"divide by ub" or "divide by (ub-lb)" implementation (both
            %plausible typos) would produce different numbers.
            lb = 200;
            ub = 1000;
            mid = (lb + ub)/2;      %600
            half = (ub - lb)/2;     %400

            tgt = EventDurationTermCondition(0);
            var = EventDurationOptimizationVariable(tgt);
            var.setUseTfForVariable(true);
            var.setBndsForVariable(lb, ub);

            probes = [lb, mid, ub, 350, 875];
            expected = (probes - mid)/half;

            for(i = 1:numel(probes))
                var.updateObjWithVarValue(probes(i));
                [xS, lbS, ubS] = var.getScaledXsForVariable();

                testCase.verifyLessThanOrEqual(abs(xS - expected(i)), 1E-12, ...
                    sprintf('Scaled x for unscaled %g should be %g but was %g.', ...
                            probes(i), expected(i), xS));
                testCase.verifyEqual(lbS, -1, ...
                    'Scaled lower bound must always be -1 for non-degenerate bounds.');
                testCase.verifyEqual(ubS, 1, ...
                    'Scaled upper bound must always be +1 for non-degenerate bounds.');
            end

            %Inverse direction: pushing the scaled value back must restore
            %the unscaled value bit-for-bit up to floating point.
            for(i = 1:numel(probes))
                var.updateObjWithScaledVarValue(expected(i));
                testCase.verifyLessThanOrEqual(abs(tgt.duration - probes(i)), 1E-9, ...
                    sprintf('Scaled write of %g should restore unscaled %g but gave %g.', ...
                            expected(i), probes(i), tgt.duration));
            end
        end

        function checkDegenerateBoundsSkipScaling(testCase)
            %When ub - lb <= 1E-10 the base class refuses to scale (it
            %would divide by ~zero) and passes the raw value through in
            %both directions.  Pin both branches of that guard.
            tgt = EventDurationTermCondition(0);
            var = EventDurationOptimizationVariable(tgt);
            var.setUseTfForVariable(true);
            var.setBndsForVariable(500, 500);

            var.updateObjWithVarValue(500);
            [xS, lbS, ubS] = var.getScaledXsForVariable();

            testCase.verifyEqual(xS, 500, ...
                'Degenerate bounds must leave the value unscaled.');
            testCase.verifyEqual(lbS, 500, ...
                'Degenerate bounds must report the raw lower bound, not -1.');
            testCase.verifyEqual(ubS, 500, ...
                'Degenerate bounds must report the raw upper bound, not +1.');

            var.updateObjWithScaledVarValue(500);
            testCase.verifyEqual(tgt.duration, 500, ...
                'Degenerate-bound scaled write must pass the value through untouched.');

            %Just inside the guard: a gap of 1E-11 is still "degenerate".
            var.setBndsForVariable(500, 500 + 1E-11);
            var.updateObjWithVarValue(500);
            xSNarrow = var.getScaledXsForVariable();
            testCase.verifyEqual(xSNarrow, 500, ...
                'A bound gap of 1E-11 is below the 1E-10 threshold and must not be scaled.');

            %Just outside the guard: a gap of 1E-9 IS scaled.
            var.setBndsForVariable(500, 500 + 1E-9);
            var.updateObjWithVarValue(500);
            xSWide = var.getScaledXsForVariable();
            testCase.verifyEqual(xSWide, -1, ...
                'A bound gap of 1E-9 exceeds the 1E-10 threshold and must scale lb to -1.');
        end

        function checkInactiveVariableContributesNothing(testCase)
            %A variable whose useTf mask is all false must be invisible to
            %the optimizer: no x entries, no bounds, and no slot in the
            %aggregated vector.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            tgt = EventDurationTermCondition(250);
            var = EventDurationOptimizationVariable(tgt);
            var.setUseTfForVariable(false);
            var.setBndsForVariable(10, 1000);

            testCase.verifyEmpty(var.getXsForVariable(), ...
                'Inactive variable reported x entries.');
            testCase.verifyEqual(var.getNumOfVars(), 0, ...
                'Inactive variable reported a nonzero variable count.');
            testCase.verifyEmpty(var.getScaledXsForVariable(), ...
                'Inactive variable reported scaled x entries.');

            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            kepVar = KeplerianElementSetVariable(elems);
            kepVar.setUseTfForVariable(false(1,6));
            kepVar.setBndsForVariable(zeros(1,6), ones(1,6));

            testCase.verifyEqual(kepVar.getNumOfVars(), 0, ...
                'Fully masked-off element set variable reported a nonzero variable count.');

            varSet = lvdData.optimizer.vars;
            varSet.vars = [var, kepVar];

            x = varSet.getTotalScaledXVector();
            testCase.verifyEmpty(x, ...
                'Variable set produced x entries from variables that are all disabled.');

            %The underlying data must be untouched by an update with an
            %empty x vector.
            varSet.updateObjsWithScaledVarValues([]);
            testCase.verifyEqual(tgt.duration, 250, ...
                'Empty scaled update modified an inactive variable''s target.');
        end

        function checkVariableSetAggregatesInOrder(testCase)
            %The set concatenates each variable's contribution in list
            %order, and the bounds vector must line up element-for-element
            %with the x vector.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            durTgt = EventDurationTermCondition(0);
            durVar = EventDurationOptimizationVariable(durTgt);
            durVar.setUseTfForVariable(true);
            durVar.setBndsForVariable(10, 1000);
            durVar.updateObjWithVarValue(505);   %exactly the midpoint -> xS = 0

            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            kepVar = KeplerianElementSetVariable(elems);
            kepVar.setUseTfForVariable([true false false false false true]);
            kepVar.setBndsForVariable([600 0 0 0 0 0], [1200 0.9 pi 2*pi 2*pi 2*pi]);

            varSet = lvdData.optimizer.vars;
            varSet.vars = [durVar, kepVar];

            [x, ~, ~, xUnscaled] = varSet.getTotalScaledXVector();

            testCase.verifyEqual(numel(x), 3, ...
                'Aggregated x should hold 1 duration slot plus 2 Keplerian slots.');
            testCase.verifyVectorEqual(xUnscaled, [505, 700, 0.4], 1E-12, ...
                'Unscaled aggregate is not the concatenation of the per-variable reads in list order.');

            %Hand-computed scaled expectations, one bound pair at a time.
            expX = [ (505 - (10 + 1000)/2)/((1000 - 10)/2), ...
                     (700 - (600 + 1200)/2)/((1200 - 600)/2), ...
                     (0.4 - (0 + 2*pi)/2)/((2*pi - 0)/2) ];
            testCase.verifyVectorEqual(x, expX, 1E-12, ...
                'Aggregated scaled x does not match the per-slot normalization oracle.');

            [lbS, ubS, lbU, ubU] = varSet.getTotalScaledBndsVector();
            testCase.verifyVectorEqual(lbS, [-1 -1 -1], 1E-15, ...
                'Aggregated scaled lower bounds should be all -1.');
            testCase.verifyVectorEqual(ubS, [1 1 1], 1E-15, ...
                'Aggregated scaled upper bounds should be all +1.');
            testCase.verifyVectorEqual(lbU, [10 600 0], 1E-12, ...
                'Aggregated unscaled lower bounds are out of order or wrong.');
            testCase.verifyVectorEqual(ubU, [1000 1200 2*pi], 1E-12, ...
                'Aggregated unscaled upper bounds are out of order or wrong.');
        end

        function checkVariableSetScaledUpdateSlicesByVarCount(testCase)
            %updateObjsWithScaledVarValues walks the flat x vector handing
            %each variable exactly getNumOfVars() entries.  An off-by-one
            %in that slicing would feed the Keplerian variable the duration
            %slot; reading the target objects directly detects it.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            durTgt = EventDurationTermCondition(0);
            durVar = EventDurationOptimizationVariable(durTgt);
            durVar.setUseTfForVariable(true);
            durVar.setBndsForVariable(10, 1000);

            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            kepVar = KeplerianElementSetVariable(elems);
            kepVar.setUseTfForVariable([true false false false false true]);
            kepVar.setBndsForVariable([600 0 0 0 0 0], [1200 0.9 pi 2*pi 2*pi 2*pi]);

            varSet = lvdData.optimizer.vars;
            varSet.vars = [durVar, kepVar];

            %Pick distinguishable scaled values: -0.5, 0, +0.5.
            xS = [-0.5, 0, 0.5];
            varSet.updateObjsWithScaledVarValues(xS);

            expDur = -0.5*((1000 - 10)/2) + (10 + 1000)/2;
            expSma =  0.0*((1200 - 600)/2) + (600 + 1200)/2;
            expTru =  0.5*((2*pi - 0)/2) + (0 + 2*pi)/2;

            testCase.verifyLessThanOrEqual(abs(durTgt.duration - expDur), 1E-9, ...
                sprintf('Duration slot unscaled to %g, expected %g.', durTgt.duration, expDur));
            testCase.verifyLessThanOrEqual(abs(elems.sma - expSma), 1E-9, ...
                sprintf('SMA slot unscaled to %g, expected %g.', elems.sma, expSma));
            testCase.verifyLessThanOrEqual(abs(elems.tru - expTru), 1E-9, ...
                sprintf('True anomaly slot unscaled to %g, expected %g.', elems.tru, expTru));

            %Slots that were masked off must be untouched.
            testCase.verifyEqual(elems.ecc, 0.01, ...
                'Masked-off eccentricity slot was written by the scaled update.');
            testCase.verifyEqual(elems.inc, 0.1, ...
                'Masked-off inclination slot was written by the scaled update.');
            testCase.verifyEqual(elems.raan, 0.2, ...
                'Masked-off RAAN slot was written by the scaled update.');
            testCase.verifyEqual(elems.arg, 0.3, ...
                'Masked-off argument of periapsis slot was written by the scaled update.');

            %The set records the pushed vector as a row for change
            %detection, regardless of the shape it was handed.
            testCase.verifyEqual(varSet.getPendingX(), xS, ...
                'Pending x was not recorded as the row vector that was pushed.');
        end

        function checkDisplayMetadataFlags(testCase)
            %The three display-metadata predicates drive unit conversion in
            %the variable editor.  They are per-slot and are indexed by the
            %FULL slot mask (not the active subset), so their length must
            %match getUseTfForVariable() exactly or the variable set's
            %aggregators throw or silently misalign.

            %Base class default: every slot false, sized to the mask.
            durVar = EventDurationOptimizationVariable(EventDurationTermCondition(0));
            testCase.verifyEqual(durVar.getVarsStoredInRad(), false, ...
                'Duration is stored in seconds, not radians.');
            testCase.verifyEqual(durVar.getVarsDisplayedAsPercents(), false, ...
                'Duration is not a percentage.');
            testCase.verifyEqual(durVar.getVarsDisplayedAsMeters(), false, ...
                'Duration is not a length.');

            %Delta-V components are stored in km/s but shown in m/s.
            dvVar = AddDeltaVActionVariable(AddDeltaVAction([0;0;0], DeltaVFrameEnum.Inertial, false));
            testCase.verifyEqual(dvVar.getVarsDisplayedAsMeters(), [true true true], ...
                'All three delta-V components are stored in km/s and displayed in m/s.');
            testCase.verifyEqual(numel(dvVar.getVarsDisplayedAsMeters()), ...
                numel(dvVar.getUseTfForVariable()), ...
                'Delta-V metadata length must match the slot mask length.');

            %Keplerian: SMA and eccentricity are not angles, the other four are.
            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            kepVar = KeplerianElementSetVariable(elems);
            testCase.verifyEqual(kepVar.getVarsStoredInRad(), ...
                [false false true true true true], ...
                'Keplerian angle slots (INC, RAAN, AOP, TA) must be flagged as radians.');
            testCase.verifyEqual(numel(kepVar.getVarsStoredInRad()), ...
                numel(kepVar.getUseTfForVariable()), ...
                'Keplerian metadata length must match the slot mask length.');

            %Poly throttle: the three polynomial terms are percentages, the
            %time offset is seconds.
            thrVar = SetPolyThrottleModelActionOptimVar(ThrottlePolyModel.getDefaultThrottleModel());
            testCase.verifyEqual(thrVar.getVarsDisplayedAsPercents(), ...
                [true true true false], ...
                'Throttle polynomial terms are percentages; the time offset is not.');
            testCase.verifyEqual(numel(thrVar.getVarsDisplayedAsPercents()), ...
                numel(thrVar.getUseTfForVariable()), ...
                'Throttle metadata length must match the slot mask length.');

            %RPY steering: nine angle terms in radians, time offset is not.
            rpyVar = SetRPYSteeringModelActionOptimVar(RollPitchYawPolySteeringModel.getDefaultSteeringModel());
            testCase.verifyEqual(rpyVar.getVarsStoredInRad(), ...
                [true true true true true true true true true false], ...
                'The nine RPY polynomial terms are radians; the time offset is seconds.');
            testCase.verifyEqual(numel(rpyVar.getVarsStoredInRad()), ...
                numel(rpyVar.getUseTfForVariable()), ...
                'RPY metadata length must match the slot mask length.');

            %The variable set filters metadata through the active mask, so
            %a partially enabled variable contributes only its active flags.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            kepVar.setUseTfForVariable([true false false false false true]);
            kepVar.setBndsForVariable([600 0 0 0 0 0], [1200 0.9 pi 2*pi 2*pi 2*pi]);
            lvdData.optimizer.vars.vars = kepVar;

            %(The set builds its aggregate by concatenating onto an empty
            %DOUBLE, so the result comes back as 0/1 doubles rather than
            %logicals; compare on value, not class.)
            testCase.verifyEqual(logical(lvdData.optimizer.vars.getVarsStoredInRad()), ...
                [false true], ...
                'Variable set should report radians flags only for the ACTIVE slots (SMA, TA).');
        end

        function checkGetAllBoundsRoundTripsWhereImplementedCorrectly(testCase)
            %getAllBndsForVariable returns the bounds for EVERY slot,
            %active or not (the variable editor uses it to populate greyed
            %out rows).  Several classes implement it correctly; those are
            %pinned here as positive assertions so a future refactor of the
            %broken ones cannot regress the working ones.
            dv = AddDeltaVAction([0;0;0], DeltaVFrameEnum.Inertial, false);
            dvVar = AddDeltaVActionVariable(dv);
            dvVar.setUseTfForVariable([true false false]);
            dvVar.setBndsForVariable([-1 -2 -3], [4 5 6]);

            [lb, ub] = dvVar.getAllBndsForVariable();
            testCase.verifyVectorEqual(lb, [-1 -2 -3], 1E-15, ...
                'AddDeltaVActionVariable lost its full lower bound vector.');
            testCase.verifyVectorEqual(ub, [4 5 6], 1E-15, ...
                'AddDeltaVActionVariable lost its full upper bound vector.');

            plugin = LvdPluginOptimVarWrapper();
            plugin.name = 'Bounds Plugin Var';
            pluginVar = PluginOptimizationVariable(plugin);
            pluginVar.setUseTfForVariable(false);
            pluginVar.setBndsForVariable(-7, 9);

            [lb, ub] = pluginVar.getAllBndsForVariable();
            testCase.verifyEqual(lb, -7, ...
                'PluginOptimizationVariable reported the wrong full lower bound.');
            testCase.verifyEqual(ub, 9, ...
                'PluginOptimizationVariable reported the wrong full upper bound.');

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stageVar = StageDryMassOptimizationVariable(lvdData.launchVehicle.stages(1));
            stageVar.setUseTfForVariable(false);
            stageVar.setBndsForVariable(1.5, 12.5);

            [lb, ub] = stageVar.getAllBndsForVariable();
            testCase.verifyEqual(lb, 1.5, ...
                'StageDryMassOptimizationVariable reported the wrong full lower bound.');
            testCase.verifyEqual(ub, 12.5, ...
                'StageDryMassOptimizationVariable reported the wrong full upper bound.');
        end

        %% ============================================================
        %  Regression guards for previously-fixed defects
        %  ============================================================

        function checkGetAllBndsUsesTheClassesOwnBoundProperties(testCase)
            % ---------------------------------------------------------
            % getAllBndsForVariable() must return the full (all-slots) bound
            % pair the variable was given.  For these seven classes the bound
            % properties are named `lb`/`ub` (each declares `lb(1,1) double`
            % and `ub(1,1) double`).
            %
            % All seven used to read `obj.lwrBnd` and `obj.uprBnd` instead.
            % Those names belong to a DIFFERENT family of variables
            % (StageDryMassOptimizationVariable, StageTankInitMassOptimVar,
            % SetKinematicStateTankStateOptimVar and
            % SetKinematicStateEpsStorageStateOptimVar all legitimately
            % declare `lwrBnd`/`uprBnd`), so the bodies were a copy/paste
            % from the wrong donor class and threw
            % MATLAB:noSuchMethodOrField on every call.  The optimizer never
            % calls getAllBndsForVariable -- it uses getBndsForVariable,
            % which was correct throughout -- so only the variable editor UI
            % hit it, which is why it survived so long.
            % ---------------------------------------------------------

            factories = { ...
                @() AltitudeOptimizationVariable(AltitudeTermCondition(0)), ...
                @() ApoapsisAltitudeOptimizationVariable(ApoapsisAltitudeTermCondition(0)), ...
                @() DynPressOptimizationVariable(DynamicPressureTermCondition(0)), ...
                @() HeightAboveTerrainOptimizationVariable(HeightAboveTerrainCondition(0)), ...
                @() NetChargeRateOptimizationVariable(PowerNetChargeRateTermCondition(0)), ...
                @() PeriapsisAltitudeOptimizationVariable(PeriapsisAltitudeTermCondition(0)), ...
                @() TotalStateOfChargeOptimizationVariable(TotalVehicleEpsStateOfChargeTermCondition(0)) };

            names = { 'AltitudeOptimizationVariable', ...
                      'ApoapsisAltitudeOptimizationVariable', ...
                      'DynPressOptimizationVariable', ...
                      'HeightAboveTerrainOptimizationVariable', ...
                      'NetChargeRateOptimizationVariable', ...
                      'PeriapsisAltitudeOptimizationVariable', ...
                      'TotalStateOfChargeOptimizationVariable' };

            for(i = 1:numel(factories))
                var = factories{i}();
                var.setUseTfForVariable(true);
                var.setBndsForVariable(11, 22);

                [lb, ub] = var.getAllBndsForVariable();

                testCase.verifyEqual(lb, 11, sprintf( ...
                    '%s.getAllBndsForVariable returned the wrong lower bound.', names{i}));
                testCase.verifyEqual(ub, 22, sprintf( ...
                    '%s.getAllBndsForVariable returned the wrong upper bound.', names{i}));

                %The active-slot accessor must agree; it always did, and a
                %divergence would mean the two halves have drifted again.
                [activeLb, activeUb] = var.getBndsForVariable();
                testCase.verifyEqual(activeLb, lb, sprintf( ...
                    '%s: the all-slots and active-slot lower bounds disagree.', names{i}));
                testCase.verifyEqual(activeUb, ub, sprintf( ...
                    '%s: the all-slots and active-slot upper bounds disagree.', names{i}));
            end
        end

        function checkGetAllBndsReturnsTheUpperBoundNotTheLower(testCase)
            % ---------------------------------------------------------
            % getAllBndsForVariable() must return `lb = obj.lb; ub = obj.ub;`.
            %
            % In eighteen classes the second line read `obj.lb`, so the UPPER
            % bound came back as a copy of the lower bound.  Unlike the
            % lwrBnd/uprBnd family this failed SILENTLY -- the call succeeded
            % and returned plausible numbers -- which is what makes it worth
            % a standing guard.
            %
            % FORMERLY AFFECTED CALL SITES (paths relative to
            % helper_methods/ksptot_lvd/classes/Optimization/variables/):
            %   @CartesianElementSetVariable/CartesianElementSetVariable.m:63-64
            %   @EventDurationOptimizationVariable/EventDurationOptimizationVariable.m:36-37
            %   @GeographicElementSetVariable/GeographicElementSetVariable.m:63-64
            %   @InitialStateVariable/InitialStateVariable.m:66-67
            %   @KeplerianElementSetVariable/KeplerianElementSetVariable.m:63-64
            %   @SetAeroSteeringModelActionOptimVar/SetAeroSteeringModelActionOptimVar.m:82-83
            %   @SetGenericLinearTangentSteeringModelActionOptimVar/
            %       SetGenericLinearTangentSteeringModelActionOptimVar.m:86-87
            %   @SetGenericPolySteeringModelActionOptimVar/
            %       SetGenericPolySteeringModelActionOptimVar.m:82-83
            %   @SetGenericQuatInterpSteeringModelActionOptimVar/
            %       SetGenericQuatInterpSteeringModelActionOptimVar.m:70-71
            %   @SetKinematicStateActionVariable/SetKinematicStateActionVariable.m:90-91
            %   @SetPolyThrottleModelActionOptimVar/SetPolyThrottleModelActionOptimVar.m:54-55
            %   @SetRPYSteeringModelActionOptimVar/SetRPYSteeringModelActionOptimVar.m:82-83
            %   @StopwatchValueOptimizationVariable/StopwatchValueOptimizationVariable.m:36-37
            %   @T2WThrottleModelOptimVar/T2WThrottleModelOptimVar.m:36-37
            %   @UniversalElementSetVariable/UniversalElementSetVariable.m:63-64
            % plus three deprecated classes with the same defect:
            %   ~deprecated/@BodyFixedOrbitVariable/BodyFixedOrbitVariable.m:63-64
            %   ~deprecated/@CR3BPOrbitVariable/CR3BPOrbitVariable.m:63-64
            %   ~deprecated/@KeplerianOrbitVariable/KeplerianOrbitVariable.m:63-64
            %
            % OBSERVED EFFECT: the variable editor showed an upper bound
            % equal to the lower bound.  If a user then accepted the
            % displayed values, setBndsForVariable stored the degenerate
            % pair, the base class scaling guard (ub - lb <= 1E-10) kicked
            % in, and the variable silently stopped being normalized --
            % wrecking optimizer conditioning.
            % ---------------------------------------------------------

            %--- Scalar members of the family.
            scalarFactories = { ...
                @() EventDurationOptimizationVariable(EventDurationTermCondition(0)), ...
                @() T2WThrottleModelOptimVar(T2WThrottleModel.getDefaultThrottleModel()) };
            scalarNames = { 'EventDurationOptimizationVariable', ...
                            'T2WThrottleModelOptimVar' };

            for(i = 1:numel(scalarFactories))
                var = scalarFactories{i}();
                var.setUseTfForVariable(true);
                var.setBndsForVariable(11, 22);

                %The ACTIVE-slot accessor was always correct, which is why the
                %optimizer itself was unaffected.
                [activeLb, activeUb] = var.getBndsForVariable();
                testCase.verifyEqual(activeLb, 11, sprintf( ...
                    '%s.getBndsForVariable returned the wrong active lower bound.', scalarNames{i}));
                testCase.verifyEqual(activeUb, 22, sprintf( ...
                    '%s.getBndsForVariable returned the wrong active upper bound.', scalarNames{i}));

                [lb, ub] = var.getAllBndsForVariable();
                testCase.verifyEqual(lb, 11, sprintf( ...
                    '%s.getAllBndsForVariable returned the wrong lower bound.', scalarNames{i}));
                testCase.verifyEqual(ub, 22, sprintf( ...
                    ['%s.getAllBndsForVariable returned the wrong upper bound.  An 11 ' ...
                     'here means it has regressed to echoing obj.lb.'], scalarNames{i}));
            end

            %--- A six-slot member: the whole upper bound vector is wrong.
            elems = KeplerianElementSet(0, 700, 0.01, 0.1, 0.2, 0.3, 0.4, testCase.kerbinFrame);
            kepVar = KeplerianElementSetVariable(elems);
            kepVar.setUseTfForVariable(true(1,6));
            lbIn = [600 0 0 0 0 0];
            ubIn = [1200 0.9 pi 2*pi 2*pi 2*pi];
            kepVar.setBndsForVariable(lbIn, ubIn);

            [~, activeUb] = kepVar.getBndsForVariable();
            testCase.verifyVectorEqual(activeUb, ubIn, 1E-15, ...
                'KeplerianElementSetVariable.getBndsForVariable lost the active upper bounds.');

            [lb, ub] = kepVar.getAllBndsForVariable();
            testCase.verifyVectorEqual(lb, lbIn, 1E-15, ...
                'KeplerianElementSetVariable.getAllBndsForVariable returned the wrong lower bounds.');
            testCase.verifyVectorEqual(ub, ubIn, 1E-15, ...
                ['KeplerianElementSetVariable.getAllBndsForVariable returned the wrong ' ...
                 'upper bound vector.  Getting lbIn back means it has regressed to ' ...
                 'echoing the lower bound vector.']);

            %--- A ten-slot member, to show the defect is not size specific.
            rpyVar = SetRPYSteeringModelActionOptimVar(RollPitchYawPolySteeringModel.getDefaultSteeringModel());
            rpyVar.setUseTfForVariable(true(1,10));
            rpyLb = -1*(1:10);
            rpyUb =  2*(1:10);
            rpyVar.setBndsForVariable(rpyLb, rpyUb);

            [lb, ub] = rpyVar.getAllBndsForVariable();
            testCase.verifyVectorEqual(lb, rpyLb, 1E-15, ...
                'SetRPYSteeringModelActionOptimVar.getAllBndsForVariable returned the wrong lower bounds.');
            testCase.verifyVectorEqual(ub, rpyUb, 1E-15, ...
                ['SetRPYSteeringModelActionOptimVar.getAllBndsForVariable returned the ' ...
                 'wrong upper bound vector.']);
        end

        function checkNetChargeRateVariableReadsNetChargeRate(testCase)
            % ---------------------------------------------------------
            % NetChargeRateOptimizationVariable must read the same field it
            % writes: getXsForVariable returns obj.varObj.netChargeRate and
            % updateObjWithVarValue sets it.
            %
            % getXsForVariable used to read `obj.varObj.perialt`, the field
            % belonging to PeriapsisAltitudeTermCondition -- this class is a
            % copy of PeriapsisAltitudeOptimizationVariable with the write
            % updated and the read left behind.  Because
            % PowerNetChargeRateTermCondition has no `perialt` property that
            % was a hard MATLAB:noSuchMethodOrField, thrown by the very first
            % thing an optimization does (OptimizationVariableSet.
            % getTotalScaledXVector building the initial x vector).  Any
            % mission making a net-charge-rate termination condition an
            % optimization variable could not be optimized at all; the write
            % half worked, so the variable could still be created and saved.
            %
            % The identical defect lived in
            % TotalStateOfChargeOptimizationVariable.m:26, guarded by
            % checkTotalStateOfChargeVariableReadsTotalStateOfCharge.  Every
            % other optimization variable in that directory was checked;
            % those two were the only read/write mismatches.
            % ---------------------------------------------------------

            tgt = PowerNetChargeRateTermCondition(0);
            var = NetChargeRateOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'netChargeRate', ...
                -10, 10, -3, 6.5, 'NetChargeRateOptimizationVariable');
        end

        function checkTotalStateOfChargeVariableReadsTotalStateOfCharge(testCase)
            % ---------------------------------------------------------
            % TotalStateOfChargeOptimizationVariable must read the field it
            % writes: getXsForVariable returns obj.varObj.totalStateOfCharge.
            %
            % It used to read `obj.varObj.perialt`, a leftover from
            % PeriapsisAltitudeOptimizationVariable, which this class was
            % copied from -- same defect and same origin as
            % NetChargeRateOptimizationVariable.  Since
            % TotalVehicleEpsStateOfChargeTermCondition has no `perialt`,
            % building the optimizer's initial x vector threw
            % MATLAB:noSuchMethodOrField and missions optimizing against a
            % total-state-of-charge termination condition could not run the
            % optimizer.
            % ---------------------------------------------------------

            tgt = TotalVehicleEpsStateOfChargeTermCondition(0);
            var = TotalStateOfChargeOptimizationVariable(tgt);
            testCase.verifyScalarVariable(var, tgt, 'totalStateOfCharge', ...
                0, 100, 25, 80, 'TotalStateOfChargeOptimizationVariable');
        end

        %% ============================================================
        %  Shared round-trip oracles
        %  ============================================================

        function verifyScalarVariable(testCase, var, targetObj, propName, lb, ub, valA, valB, label)
            %verifyScalarVariable Full round trip for a single-slot variable.
            %
            % targetObj/propName identify the field the variable is
            % supposed to be driving.  Every "did the write land?" check
            % reads that field DIRECTLY rather than going back through the
            % variable, so a variable that reads and writes the same wrong
            % field cannot pass by being consistently wrong.

            %--- Disabled: contributes nothing at all.
            var.setUseTfForVariable(false);
            testCase.verifyEmpty(var.getXsForVariable(), ...
                sprintf('%s: a disabled variable must contribute no x entries.', label));
            testCase.verifyEqual(var.getNumOfVars(), 0, ...
                sprintf('%s: a disabled variable must report zero variables.', label));

            %--- Enabled: bounds go in and come back out unchanged.
            var.setUseTfForVariable(true);
            var.setBndsForVariable(lb, ub);

            testCase.verifyTrue(var.getUseTfForVariable() == true, ...
                sprintf('%s: setUseTfForVariable(true) did not take effect.', label));

            [gotLb, gotUb] = var.getBndsForVariable();
            testCase.verifyEqual(gotLb, lb, ...
                sprintf('%s: lower bound did not survive setBndsForVariable.', label));
            testCase.verifyEqual(gotUb, ub, ...
                sprintf('%s: upper bound did not survive setBndsForVariable.', label));
            testCase.verifyEqual(var.getNumOfVars(), 1, ...
                sprintf('%s: an enabled scalar variable must report exactly one variable.', label));

            %--- Unscaled write must land on the named target field.
            var.updateObjWithVarValue(valA);
            testCase.verifyEqual(targetObj.(propName), valA, ...
                sprintf('%s: updateObjWithVarValue did not set %s.%s to %g.', ...
                        label, class(targetObj), propName, valA));

            %--- ...and the unscaled read must return it.
            testCase.verifyEqual(var.getXsForVariable(), valA, ...
                sprintf('%s: getXsForVariable did not read back the value just written.', label));

            %--- Scaled read matches the normalization oracle recomputed here.
            expScaledA = (valA - (lb + ub)/2) / ((ub - lb)/2);
            [xS, lbS, ubS] = var.getScaledXsForVariable();
            testCase.verifyLessThanOrEqual(abs(xS - expScaledA), 1E-12, ...
                sprintf('%s: scaled x was %g, expected %g for value %g on [%g, %g].', ...
                        label, xS, expScaledA, valA, lb, ub));
            testCase.verifyEqual(lbS, -1, ...
                sprintf('%s: scaled lower bound should be -1.', label));
            testCase.verifyEqual(ubS, 1, ...
                sprintf('%s: scaled upper bound should be +1.', label));

            %--- Scaled write is the exact inverse of the scaled read.  A
            %    scale factor applied in only one direction, or applied
            %    inverted, shows up here as a wrong target value.
            expScaledB = (valB - (lb + ub)/2) / ((ub - lb)/2);
            var.updateObjWithScaledVarValue(expScaledB);
            testCase.verifyLessThanOrEqual(abs(targetObj.(propName) - valB), 1E-9*max(1, abs(valB)), ...
                sprintf('%s: scaled write of %g should have set %s to %g but gave %g.', ...
                        label, expScaledB, propName, valB, targetObj.(propName)));

            %--- Round trip all the way back to the first value.
            var.updateObjWithScaledVarValue(xS);
            testCase.verifyLessThanOrEqual(abs(targetObj.(propName) - valA), 1E-9*max(1, abs(valA)), ...
                sprintf('%s: scaled round trip did not return %s to %g (got %g).', ...
                        label, propName, valA, targetObj.(propName)));
        end

        function verifyMultiVariable(testCase, var, useTf, readAll, writeAll, lbAll, ubAll, baseVals, newVals, label)
            %verifyMultiVariable Full round trip for a multi-slot variable.
            %
            % readAll()/writeAll(v) address ALL slots of the target object
            % directly, in the same slot order the variable uses.  useTf is
            % the full-length activation mask.  The key assertions are that
            % (a) only the masked slots move and (b) the masked values are
            % packed into x in slot order with no index drift.

            m = logical(useTf);
            nActive = sum(m);

            writeAll(baseVals);
            var.setUseTfForVariable(useTf);
            var.setBndsForVariable(lbAll, ubAll);

            testCase.verifyEqual(logical(var.getUseTfForVariable()), m, ...
                sprintf('%s: the activation mask did not survive setUseTfForVariable.', label));
            testCase.verifyEqual(var.getNumOfVars(), nActive, ...
                sprintf('%s: variable count should equal the number of enabled slots (%d).', ...
                        label, nActive));

            [gotLb, gotUb] = var.getBndsForVariable();
            testCase.verifyVectorEqual(gotLb, lbAll(m), 1E-15, ...
                sprintf('%s: active lower bounds are not the masked subset of the full vector.', label));
            testCase.verifyVectorEqual(gotUb, ubAll(m), 1E-15, ...
                sprintf('%s: active upper bounds are not the masked subset of the full vector.', label));

            %--- Read: x is the masked subset in slot order.
            testCase.verifyVectorEqual(var.getXsForVariable(), baseVals(m), 1E-12, ...
                sprintf('%s: getXsForVariable did not return the enabled slots in slot order.', label));

            %--- Write: only the masked slots may move.
            var.updateObjWithVarValue(newVals(m));

            expected = baseVals;
            expected(m) = newVals(m);
            testCase.verifyVectorEqual(readAll(), expected, 1E-12, ...
                sprintf(['%s: after updateObjWithVarValue the target slots do not match. ' ...
                         'Either a value went into the wrong slot or a disabled slot was ' ...
                         'overwritten.'], label));

            %--- Scaled read against the hand-computed normalization.
            lbA = lbAll(m);
            ubA = ubAll(m);
            expScaled = (expected(m) - (lbA + ubA)/2) ./ ((ubA - lbA)/2);

            [xS, lbS, ubS] = var.getScaledXsForVariable();
            testCase.verifyVectorEqual(xS, expScaled, 1E-12, ...
                sprintf('%s: scaled x does not match the per-slot normalization oracle.', label));
            testCase.verifyVectorEqual(lbS, -ones(1, nActive), 1E-15, ...
                sprintf('%s: scaled lower bounds should all be -1.', label));
            testCase.verifyVectorEqual(ubS, ones(1, nActive), 1E-15, ...
                sprintf('%s: scaled upper bounds should all be +1.', label));

            %--- Scaled write inverts the scaled read: push the ORIGINAL
            %    values back through the scaled path and confirm every slot
            %    returns to where it started.
            baseScaled = (baseVals(m) - (lbA + ubA)/2) ./ ((ubA - lbA)/2);
            var.updateObjWithScaledVarValue(baseScaled);
            testCase.verifyVectorEqual(readAll(), baseVals, 1E-9, ...
                sprintf('%s: scaled round trip did not restore the original slot values.', label));
        end

        %% ============================================================
        %  Fixtures
        %  ============================================================

        function [lvdData, tank] = buildTankFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
        end

        function [lvdData, sw] = buildStopwatchFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw = LaunchVehicleStopwatch(lvdData);
            sw.startOn = StopwatchRunningEnum.Running;
            lvdData.launchVehicle.addStopwatch(sw);
        end

        function [lvdData, battery] = buildBatteryFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);

            battery = LaunchVehicleBasicElectricalBattery(stg);
            battery.name = 'Optim Var Test Battery';
            battery.maxCapacity = 100;
            battery.initialStateOfCharge = 50;
            stg.addPwrStorage(battery);
        end
    end
end

%% ================================================================
%  File-local slot accessors
%  ================================================================
%
% These exist so the multi-component checks can hand verifyMultiVariable a
% pair of "read every slot / write every slot" function handles without
% routing through any production packing code.

function v = readProps(obj, propNames)
    v = zeros(1, numel(propNames));
    for(i = 1:numel(propNames))
        v(i) = obj.(propNames{i});
    end
end

function writeProps(obj, propNames, vals)
    for(i = 1:numel(propNames))
        obj.(propNames{i}) = vals(i);
    end
end

function setDeltaVVect(dvAction, vals)
    dvAction.deltaVVect = reshape(vals, 3, 1);
end

function setCartesianComponents(elems, vals)
    elems.rVect = reshape(vals(1:3), 3, 1);
    elems.vVect = reshape(vals(4:6), 3, 1);
end

function [readAll, writeAll] = rpyAccessors(model)
    %Slot order matches SetRPYSteeringModelActionOptimVar:
    %   1-3  roll  const / linear / accel
    %   4-6  pitch const / linear / accel
    %   7-9  yaw   const / linear / accel
    %   10   shared time offset
    %
    %Slot 10 is deliberately asymmetric: production reads it from the yaw
    %model but writes it to all three, so the mirror here does the same.
    readAll  = @() readRpy(model);
    writeAll = @(v) writeRpy(model, v);
end

function v = readRpy(model)
    v = [model.rollModel.constTerm,  model.rollModel.linearTerm,  model.rollModel.accelTerm, ...
         model.pitchModel.constTerm, model.pitchModel.linearTerm, model.pitchModel.accelTerm, ...
         model.yawModel.constTerm,   model.yawModel.linearTerm,   model.yawModel.accelTerm, ...
         model.yawModel.tOffset];
end

function writeRpy(model, v)
    model.rollModel.constTerm   = v(1);
    model.rollModel.linearTerm  = v(2);
    model.rollModel.accelTerm   = v(3);

    model.pitchModel.constTerm  = v(4);
    model.pitchModel.linearTerm = v(5);
    model.pitchModel.accelTerm  = v(6);

    model.yawModel.constTerm    = v(7);
    model.yawModel.linearTerm   = v(8);
    model.yawModel.accelTerm    = v(9);

    model.rollModel.tOffset  = v(10);
    model.pitchModel.tOffset = v(10);
    model.yawModel.tOffset   = v(10);
end
