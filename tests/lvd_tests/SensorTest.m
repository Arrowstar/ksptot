classdef SensorTest < KsptotTestCase
    %SensorTest Sensor models, steering models and target models.
    %
    % SUBJECT UNDER TEST
    %   helper_methods/ksptot_lvd/classes/Sensors/...
    %       SensorModels/@ConicalSensor, @RectangularSensor, @LvdSensorSet
    %       SensorModels/SensorSteeringModels/@FixedInVehicleFrameSensorSteeringModel
    %       SensorModels/SensorSteeringModels/@FixedInCoordSysSensorSteeringModel
    %       TargetModels/@BodyFixedLatLongGridTargetModel, @PointSensorTargetModel,
    %                    @SensorTargetResults, @LvdSensorTargetSet
    %   helper_methods/ksptot_lvd/classes/StateLog/sensors/@ConicalSensorState,
    %                    @RectangularSensorState
    %
    % INDEPENDENT ORACLE
    %   Every geometric expectation in this file is computed from hand-written
    %   trigonometry at the bottom of the file (refUnitVectorFromRaDec,
    %   refAngleBetween, refRotZ, refRotY, refLatLongAltToEcef).  None of those
    %   helpers call the production routine they are checking:
    %     * refUnitVectorFromRaDec spells out the spherical-to-Cartesian
    %       formula rather than calling sph2cart (which is what production
    %       uses), so a change of convention in production is detectable.
    %     * refAngleBetween uses atan2(|a x b|, a.b) rather than production's
    %       dang().  atan2-of-cross-and-dot is the numerically well-conditioned
    %       form near 0 and pi, which matters because the boundary cases below
    %       differ from the cone edge by only 1e-6 rad.
    %     * refLatLongAltToEcef spells out the spherical body model rather than
    %       calling getrVectEcefFromLatLongAlt.
    %
    % FOV CONTAINMENT: WHAT IS AND IS NOT COVERED HERE
    %   Production decides "is this target in the field of view?" in
    %   AbstractSensor.evaluateSensorTargets by building a triangulated cone
    %   mesh and calling in_polyhedron().  Building that mesh requires
    %   rotm2axang() and roty() (ConicalSensor.getSensorMesh lines 90-91) and
    %   rotx() (both steering models' getSensorDcmToInertial), i.e. the
    %   Robotics System Toolbox and the Phased Array / Aerospace rot* family.
    %   NEITHER IS INSTALLED IN THIS ENVIRONMENT -- which('rotx'), which('roty')
    %   and which('rotm2axang') all return empty, and there is no in-repo
    %   shim (verified: no rotx.m / rotm2axang.m anywhere under the repo root).
    %
    %   So the containment call itself is exercised in
    %   checkConeContainmentAgainstMeshWhenToolboxPresent, which is guarded by
    %   assumeNotEmpty and therefore SKIPS (not fails) here.  It will run and
    %   do real work on a machine that has the toolboxes.
    %
    %   What DOES run unconditionally is checkConeBoundaryGeometry: it feeds
    %   hand-placed targets -- one exactly on the cone edge, one 1e-6 rad
    %   inside, one 1e-6 rad outside, one on the boresight axis, one exactly at
    %   max range and one just beyond -- through the production geometry
    %   pipeline (getOriginInFrame, getSensorBoresightDirection,
    %   target.getTargetPositions) and checks that the angles and ranges those
    %   production outputs imply match the intended geometry to 1e-12 rad.
    %   That is the whole of the FOV computation except the final mesh
    %   point-in-polyhedron test.  A documented skip of the last step beats a
    %   vacuous test of it.
    %
    % SKIPPED (documented)
    %   * ConicalSensor.getSensorMesh / RectangularSensor.getSensorMesh /
    %     AbstractSensor.getObscuringMesh / getObscuredSensorMesh /
    %     evaluateSensorTargets -- blocked on rotm2axang/roty/rotx as above.
    %     Reached only through the assumption-guarded case.
    %   * BodyFixedCircleGridTargetModel -- its constructor calls rotz() in
    %     setGridPointsFromInputs, so it cannot even be built here.
    %   * AbstractSensor.getCircleInSpace / mesh_boolean_fallback /
    %     getTangentCirclePointAndRadius -- Static, Access=protected; not
    %     reachable from a test without subclassing production code.
    %   * openEditDialog on every class -- opens an App Designer GUI.
    %   * SensorTargetResults.getBoresightRelativeAngles -- calls
    %     getSensorDcmToInertial, hence rotx.  Blocked.
    %   * LaunchVehicleSensorReport -- report/formatting code, no geometry.
    %   * Marker/colour accessors (getMarkerShape, getFoundMarkerFaceColor,
    %     ...) -- trivial property returns with no logic.
    %
    % REGRESSION GUARDS
    %   The last three cases below guard defects that were found while
    %   building this file and have since been fixed.  Each carries a comment
    %   block naming the file and the original wrong behaviour, so a
    %   regression is recognisable rather than just "some assertion failed".

    properties(TestParameter)
        caseName = { ...
            'ConicalSensorAngleClamping', ...
            'RectangularSensorAngleClamping', ...
            'VehicleFrameBoresightVector', ...
            'CoordSysBoresightVector', ...
            'ConeBoundaryGeometry', ...
            'ConeContainmentAgainstMeshWhenToolboxPresent', ...
            'LatLongGridTargetPositions', ...
            'PointTargetPositions', ...
            'SensorStateMaxAngle', ...
            'CoverageFractionAndMerge', ...
            'SensorSetManagement', ...
            'RectangularSensorIsInUseTracksReferences', ...
            'TargetSetReturnsTargetEmptyOutOfRange', ...
            'ZeroAngleSensorCanMakeState', ...
        };
    end

    properties(Constant, Access=private)
        GeomTol  = 1e-9;    %km
        AngTol   = 1e-12;   %rad
        ValueTol = 1e-12;
        EdgeEps  = 1e-6;    %rad, cone-edge perturbation
    end

    methods(Test)
        function sensorsMatchIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ------------------------------------------------------------------
        %  Constructor clamping
        %  ------------------------------------------------------------------

        function checkConicalSensorAngleClamping(testCase)
            %ConicalSensor.m lines 39-41 clamp the half-angle to pi/2 (a cone
            %wider than a hemisphere is not representable by the mesh code).
            %The clamp is a strict ">" so pi/2 itself must survive untouched.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            justUnder = pi/2 - 1e-9;
            exactly   = pi/2;
            over      = pi/2 + 1e-9;
            wayOver   = deg2rad(170);

            sUnder = testCase.makeConicalSensor(lvdData, justUnder, 1000);
            sExact = testCase.makeConicalSensor(lvdData, exactly,   1000);
            sOver  = testCase.makeConicalSensor(lvdData, over,      1000);
            sWay   = testCase.makeConicalSensor(lvdData, wayOver,   1000);

            testCase.verifyEqual(sUnder.angle, justUnder, ...
                'Half-angle just below pi/2 must be stored unmodified.');
            testCase.verifyEqual(sExact.angle, exactly, ...
                'Half-angle exactly pi/2 must be stored unmodified (clamp is strict >).');
            testCase.verifyEqual(sOver.angle, pi/2, ...
                'Half-angle just above pi/2 must be clamped down to pi/2.');
            testCase.verifyEqual(sWay.angle, pi/2, ...
                'Half-angle of 170 deg must be clamped down to pi/2.');

            %The clamp must survive into the state object the propagator uses.
            testCase.verifyEqual(sWay.getInitialState().getSensorAngle(), pi/2, ...
                'Clamped half-angle did not propagate into ConicalSensorState.');

            %A negative half-angle is rejected outright by the arguments block.
            testCase.verifyError(@() testCase.makeConicalSensor(lvdData, -1e-12, 1000), ...
                'MATLAB:validators:mustBeGreaterThanOrEqual', ...
                'Negative half-angle should be rejected by the arguments block.');

            %Zero range is rejected (strictly greater than zero).
            testCase.verifyError(@() testCase.makeConicalSensor(lvdData, deg2rad(10), 0), ...
                'MATLAB:validators:mustBeGreaterThan', ...
                'Zero max range should be rejected by the arguments block.');
        end

        function checkRectangularSensorAngleClamping(testCase)
            %RectangularSensor.m lines 41-49 clamp azAngle and decAngle
            %independently at pi/2.  The two are clamped by DIFFERENT code:
            %azAngle has an upper clamp only, decAngle has an if/elseif pair.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            s = testCase.makeRectangularSensor(lvdData, deg2rad(120), deg2rad(30), 500);
            testCase.verifyEqual(s.azAngle, pi/2, 'azAngle above pi/2 must clamp to pi/2.');
            testCase.verifyEqual(s.decAngle, deg2rad(30), 'decAngle below pi/2 must be untouched.');

            s2 = testCase.makeRectangularSensor(lvdData, deg2rad(30), deg2rad(120), 500);
            testCase.verifyEqual(s2.azAngle, deg2rad(30), 'azAngle below pi/2 must be untouched.');
            testCase.verifyEqual(s2.decAngle, pi/2, 'decAngle above pi/2 must clamp to pi/2.');

            s3 = testCase.makeRectangularSensor(lvdData, pi/2, pi/2, 500);
            testCase.verifyEqual([s3.azAngle, s3.decAngle], [pi/2, pi/2], ...
                'Angles exactly at pi/2 must be stored unmodified (both clamps are strict >).');

            st = s.getInitialState();
            testCase.verifyEqual(st.getSensorAzAngle(), pi/2, ...
                'Clamped azAngle did not propagate into RectangularSensorState.');
            testCase.verifyEqual(st.getSensorDecAngle(), deg2rad(30), ...
                'decAngle did not propagate into RectangularSensorState.');
        end

        %% ------------------------------------------------------------------
        %  Steering: boresight direction
        %  ------------------------------------------------------------------

        function checkVehicleFrameBoresightVector(testCase)
            %FixedInVehicleFrameSensorSteeringModel.getBoresightVector maps
            %(rhtAsc, dec) to a unit vector in the VEHICLE body frame and then
            %rotates it to inertial with the supplied attitude dcm:
            %
            %   v_body     = [cos(dec)cos(ra); cos(dec)sin(ra); sin(dec)]
            %   v_inertial = dcm * v_body
            %
            %The oracle spells that out rather than calling sph2cart, so a
            %swap of the az/elev arguments in production would be caught.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            scElem  = CartesianElementSet(0, [8000;0;0], [0;3;0], testCase.kerbinFrame);

            %A deliberately non-symmetric attitude so a transposed dcm, or a
            %dcm applied on the wrong side, produces a different answer.
            dcm = testCase.refRotZ(deg2rad(40)) * testCase.refRotY(deg2rad(-15));

            raDecCases = [ ...
                0,            0;             ... boresight along body +x
                deg2rad(90),  0;             ... along body +y
                0,            pi/2;          ... along body +z (dec singularity)
                0,           -pi/2;          ... along body -z (dec singularity)
                deg2rad(30),  deg2rad(20);   ... general case
                deg2rad(-125), deg2rad(-40)];   %general case, other octant

            for(i = 1:size(raDecCases,1))
                ra  = raDecCases(i,1);
                dec = raDecCases(i,2);

                steer = FixedInVehicleFrameSensorSteeringModel(ra, dec, 0, lvdData);
                sensor = ConicalSensor('S', deg2rad(10), 1000, ...
                    testCase.makeFixedPoint(lvdData, [0;0;0]), steer, lvdData);
                state = sensor.getInitialState();

                actual = sensor.getSensorBoresightDirection(state, 0, scElem, dcm, testCase.kerbinFrame);
                expected = dcm * testCase.refUnitVectorFromRaDec(ra, dec);

                testCase.verifyVectorEqual(actual, expected, testCase.AngTol, ...
                    sprintf('Vehicle-frame boresight wrong for ra=%g deg, dec=%g deg', ...
                            rad2deg(ra), rad2deg(dec)));
                testCase.verifyLessThanOrEqual(abs(norm(actual) - 1), testCase.AngTol, ...
                    'Boresight direction is not a unit vector.');
            end

            %The steering model must declare itself vehicle-dependent: the
            %propagator uses that flag to decide whether the sensor has to be
            %re-evaluated whenever attitude changes.
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            testCase.verifyTrue(steer.isVehDependent(), ...
                'Vehicle-frame steering must report isVehDependent == true.');
        end

        function checkCoordSysBoresightVector(testCase)
            %FixedInCoordSysSensorSteeringModel.getBoresightVector ignores the
            %attitude dcm entirely and instead rotates by the coordinate
            %system's own to-inertial matrix.
            %
            %Two sub-cases:
            %  (a) coord sys parallel to the body-centred INERTIAL frame -- the
            %      rotation is the identity, so the boresight is exactly the
            %      raw (ra, dec) unit vector.  A deliberately weird dcm is
            %      passed in to prove it is ignored.
            %  (b) coord sys parallel to the BODY-FIXED frame of a body frozen
            %      with rotperiod = Inf and rotini = 35.  With no rotation rate
            %      the fixed frame is a constant Rz offset from inertial, so
            %      the expected boresight is Rz(35 deg) * v.
            %
            %      NOTE THE UNITS: bodyInfo.rotini is in DEGREES, not radians.
            %      getBodySpinAngle_alg is fed bodyInfo.rotini and the
            %      superseded inline version it replaced
            %      (helper_methods/.../getBodySpinAngle.m, commented-out body)
            %      spells this out as rotInit = deg2rad(bodyInfo.rotini).
            %      Kerbin has no axial tilt
            %      (bodyRotMatFromGlobalInertialToBodyInertial == eye(3)), so
            %      the body-fixed-to-inertial matrix here is exactly
            %      Rz(deg2rad(rotini)) with no extra frame twist.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            scElem  = CartesianElementSet(0, [8000;0;0], [0;3;0], testCase.kerbinFrame);

            ra  = deg2rad(30);
            dec = deg2rad(20);
            v   = testCase.refUnitVectorFromRaDec(ra, dec);

            weirdDcm = testCase.refRotZ(deg2rad(77)) * testCase.refRotY(deg2rad(11));

            % (a) parallel to inertial
            csInertial = ParallelToFrameCoordSystem(testCase.kerbinFrame, 'inertialCS', lvdData);
            steerA = FixedInCoordSysSensorSteeringModel(ra, dec, 0, csInertial, lvdData);
            sensorA = ConicalSensor('A', deg2rad(10), 1000, ...
                testCase.makeFixedPoint(lvdData, [0;0;0]), steerA, lvdData);
            stateA = sensorA.getInitialState();

            actualA = sensorA.getSensorBoresightDirection(stateA, 0, scElem, weirdDcm, testCase.kerbinFrame);
            testCase.verifyVectorEqual(actualA, v, testCase.AngTol, ...
                'Coord-sys boresight parallel to inertial should equal the raw (ra,dec) unit vector.');

            %Same call with the identity dcm must give an identical answer:
            %that is what "ignores the attitude dcm" means.
            actualAId = sensorA.getSensorBoresightDirection(stateA, 0, scElem, eye(3), testCase.kerbinFrame);
            testCase.verifyVectorEqual(actualAId, actualA, testCase.AngTol, ...
                'Coord-sys steering must not depend on the vehicle attitude dcm.');

            testCase.verifyFalse(steerA.isVehDependent(), ...
                'Steering fixed in a frame-parallel coord sys is not vehicle dependent.');

            % (b) parallel to a frozen body-fixed frame
            rotIniDeg = 35;
            frozen  = testCase.copyBodyInfo(testCase.kerbin);
            frozen.rotperiod = Inf;        %both of these are required for the
            frozen.rotini    = rotIniDeg;  %"non-rotating body" fixture to hold

            csFixed = ParallelToFrameCoordSystem(frozen.getBodyFixedFrame(), 'fixedCS', lvdData);
            steerB  = FixedInCoordSysSensorSteeringModel(ra, dec, 0, csFixed, lvdData);
            sensorB = ConicalSensor('B', deg2rad(10), 1000, ...
                testCase.makeFixedPoint(lvdData, [0;0;0]), steerB, lvdData);
            stateB  = sensorB.getInitialState();

            actualB = sensorB.getSensorBoresightDirection(stateB, 0, scElem, eye(3), testCase.kerbinFrame);
            expectedB = testCase.refRotZ(deg2rad(rotIniDeg)) * v;

            testCase.verifyVectorEqual(actualB, expectedB, 1e-9, ...
                'Boresight in a frozen body-fixed coord sys should be Rz(deg2rad(rotini)) * v.');

            %Convention guard: if rotini were ever read as radians, or the
            %rotation sense flipped, the result would land on Rz(-35 deg)*v
            %instead.  Assert we are NOT there, so a silent sign/unit flip
            %cannot be absorbed by the tolerance above.
            testCase.verifyGreaterThan(norm(actualB - testCase.refRotZ(-deg2rad(rotIniDeg)) * v), 0.1, ...
                'Boresight matches Rz(-rotini)*v: the body-fixed rotation sense has flipped.');

            %Time invariance: with rotperiod = Inf the answer must not drift.
            actualBLater = sensorB.getSensorBoresightDirection(stateB, 1e5, scElem, eye(3), testCase.kerbinFrame);
            testCase.verifyVectorEqual(actualBLater, actualB, 1e-9, ...
                'A frozen body-fixed coord sys must give a time-invariant boresight.');
        end

        %% ------------------------------------------------------------------
        %  Cone field-of-view geometry
        %  ------------------------------------------------------------------

        function checkConeBoundaryGeometry(testCase)
            %The runnable half of the FOV problem (see the header block).
            %
            %Fixture: a conical sensor with half-angle alpha = 25 deg and max
            %range R = 400 km, sitting at a fixed inertial point O, boresight
            %b.  Six point targets are placed at
            %
            %    P = O + d * ( cos(theta)*b + sin(theta)*p )
            %
            %with p a unit vector perpendicular to b, so that the angle
            %between (P - O) and b is EXACTLY theta by construction.  The
            %six (theta, d) pairs bracket both the angular edge and the range
            %edge:
            %
            %   1. theta = 0,             d = R/2     on axis, well inside
            %   2. theta = alpha - 1e-6,  d = R/2     1e-6 rad inside the edge
            %   3. theta = alpha,         d = R/2     exactly on the cone edge
            %   4. theta = alpha + 1e-6,  d = R/2     1e-6 rad outside the edge
            %   5. theta = alpha/2,       d = R       exactly at max range
            %   6. theta = alpha/2,       d = R*1.001 just beyond max range
            %
            %What is asserted: the production geometry pipeline (sensor origin,
            %boresight direction, target positions) reproduces those angles and
            %ranges to 1e-12 rad / 1e-9 km.  Any error in the origin transform,
            %the steering maths or the target position transform moves a
            %boundary case across the edge, which is exactly the failure mode
            %the 1e-6 rad perturbations are sized to catch.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            alpha  = deg2rad(25);
            R      = 400;
            O      = [8000; -1200; 350];
            eps0   = testCase.EdgeEps;

            %Attitude and (ra,dec) chosen so nothing lands on an axis.
            dcm = testCase.refRotZ(deg2rad(40)) * testCase.refRotY(deg2rad(-15));
            ra  = deg2rad(30);
            dec = deg2rad(20);
            b   = dcm * testCase.refUnitVectorFromRaDec(ra, dec);
            b   = b / norm(b);

            %Perpendicular reference direction, built independently of b's
            %components so it stays well conditioned.
            p = cross(b, [0;0;1]);
            p = p / norm(p);

            thetas = [0, alpha - eps0, alpha, alpha + eps0, alpha/2,  alpha/2];
            dists  = [R/2, R/2,        R/2,   R/2,          R,        R*1.001];
            labels = {'on-axis', 'just inside edge', 'exactly on edge', ...
                      'just outside edge', 'exactly at max range', 'just beyond max range'};

            steer  = FixedInVehicleFrameSensorSteeringModel(ra, dec, 0, lvdData);
            origin = testCase.makeFixedPoint(lvdData, O);
            sensor = ConicalSensor('cone', alpha, R, origin, steer, lvdData);
            state  = sensor.getInitialState();

            scElem = CartesianElementSet(0, [8000;0;0], [0;3;0], testCase.kerbinFrame);

            %Production origin and boresight.
            actualOrigin = sensor.getOriginInFrame(0, scElem, testCase.kerbinFrame);
            testCase.verifyVectorEqual(actualOrigin, O, testCase.GeomTol, ...
                'Sensor origin did not round-trip through getOriginInFrame.');

            actualBore = sensor.getSensorBoresightDirection(state, 0, scElem, dcm, testCase.kerbinFrame);
            testCase.verifyVectorEqual(actualBore, b, testCase.AngTol, ...
                'Sensor boresight direction disagrees with the hand-built oracle.');

            for(i = 1:numel(thetas))
                theta = thetas(i);
                d     = dists(i);
                P     = O + d * (cos(theta)*b + sin(theta)*p);

                tgt = PointSensorTargetModel(sprintf('t%u', i), ...
                    testCase.makeFixedPoint(lvdData, P), lvdData);

                actualP = tgt.getTargetPositions(0, scElem, testCase.kerbinFrame);
                testCase.verifyVectorEqual(actualP, P, testCase.GeomTol, ...
                    sprintf('Target position wrong for case "%s".', labels{i}));

                %Angle and range implied by the PRODUCTION outputs.
                los = actualP - actualOrigin;
                actualAngle = testCase.refAngleBetween(actualBore, los);
                actualRange = norm(los);

                %Tolerance note: the angle is reconstructed from a position
                %that was itself built from cos/sin of theta and then pushed
                %through a frame transform, so ~10 ulp of an 8 km-scale
                %coordinate is unavoidable.  1e-10 rad is still four orders of
                %magnitude tighter than the 1e-6 rad edge perturbation, so the
                %boundary cases stay unambiguously on their intended side.
                testCase.verifyLessThanOrEqual(abs(actualAngle - theta), 1e-10, ...
                    sprintf(['Angle from boresight implied by production outputs is %.15g rad, ' ...
                             'expected %.15g rad (case "%s").'], actualAngle, theta, labels{i}));
                testCase.verifyLessThanOrEqual(abs(actualRange - d), testCase.GeomTol, ...
                    sprintf('Range implied by production outputs is %.15g km, expected %.15g km (case "%s").', ...
                            actualRange, d, labels{i}));

                %The verdict an ideal cone test would return.  These are the
                %expectations the mesh path is checked against in the
                %assumption-guarded case below.
                expectedInFov = (theta <= alpha) && (d <= R);
                actualInFov   = (actualAngle <= alpha + testCase.AngTol) && ...
                                (actualRange <= R + testCase.GeomTol);
                testCase.verifyEqual(actualInFov, expectedInFov, ...
                    sprintf('Analytic cone verdict disagrees for case "%s".', labels{i}));
            end

            %getMaxAngle is what the obscuring-mesh culling test uses; for a
            %cone it must be the half-angle itself, clamp included.
            testCase.verifyEqual(state.getMaxAngle(), alpha, ...
                'ConicalSensorState.getMaxAngle must return the half-angle.');
            testCase.verifyEqual(state.getSensorMaxRange(), R, ...
                'ConicalSensorState.getSensorMaxRange must return the configured range.');
        end

        function checkConeContainmentAgainstMeshWhenToolboxPresent(testCase)
            %The mesh-based containment path.  SKIPPED in this environment --
            %see the header block.  Kept (rather than deleted) because it is
            %the only test of AbstractSensor.evaluateSensorTargets and it will
            %do real work wherever the toolboxes exist.
            testCase.assumeNotEmpty(which('rotx'), ...
                'rotx() unavailable; getSensorDcmToInertial cannot run.');
            testCase.assumeNotEmpty(which('roty'), ...
                'roty() unavailable; ConicalSensor.getSensorMesh cannot run.');
            testCase.assumeNotEmpty(which('rotm2axang'), ...
                'rotm2axang() unavailable; ConicalSensor.getSensorMesh cannot run.');
            testCase.assumeNotEmpty(which('in_polyhedron'), ...
                'in_polyhedron() unavailable; containment cannot be evaluated.');
            testCase.assumeNotEmpty(which('sphereMesh'), ...
                'sphereMesh() unavailable; the cone mesh cannot be built.');

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            %Same fixture as checkConeBoundaryGeometry but with generous
            %margins: the cone is approximated by a finite triangulation, so
            %a 1e-6 rad offset from the edge is far below the mesh resolution
            %and would be a meaningless assertion.  1 degree of margin is well
            %outside the discretisation error of a 25 degree cone.
            alpha  = deg2rad(25);
            R      = 400;
            O      = [8000; -1200; 350];
            margin = deg2rad(1);

            dcm = testCase.refRotZ(deg2rad(40)) * testCase.refRotY(deg2rad(-15));
            ra  = deg2rad(30);
            dec = deg2rad(20);
            b   = dcm * testCase.refUnitVectorFromRaDec(ra, dec);
            b   = b / norm(b);
            p   = cross(b, [0;0;1]);
            p   = p / norm(p);

            thetas = [0,      alpha - margin, alpha + margin, alpha/2, alpha/2];
            dists  = [R/2,    R/2,            R/2,            0.9*R,   1.1*R];
            expect = [true,   true,           false,          true,    false];
            labels = {'on-axis inside', '1 deg inside edge', '1 deg outside edge', ...
                      'inside max range', 'outside max range'};

            steer  = FixedInVehicleFrameSensorSteeringModel(ra, dec, 0, lvdData);
            origin = testCase.makeFixedPoint(lvdData, O);
            sensor = ConicalSensor('cone', alpha, R, origin, steer, lvdData);
            state  = sensor.getInitialState();
            scElem = CartesianElementSet(0, [8000;0;0], [0;3;0], testCase.kerbinFrame);

            targets = AbstractSensorTarget.empty(1,0);
            for(i = 1:numel(thetas))
                P = O + dists(i) * (cos(thetas(i))*b + sin(thetas(i))*p);
                targets(i) = PointSensorTargetModel(sprintf('t%u', i), ...
                    testCase.makeFixedPoint(lvdData, P), lvdData);
            end

            %No occulting bodies: this case tests the cone alone.
            results = sensor.evaluateSensorTargets(state, targets, scElem, dcm, ...
                KSPTOT_BodyInfo.empty(1,0), testCase.kerbinFrame);

            testCase.verifyEqual(numel(results), numel(targets), ...
                'evaluateSensorTargets must return one result per target.');

            for(i = 1:numel(results))
                testCase.verifyEqual(logical(results(i).resultsBool), expect(i), ...
                    sprintf('Mesh containment verdict wrong for case "%s".', labels{i}));
            end
        end

        %% ------------------------------------------------------------------
        %  Target models
        %  ------------------------------------------------------------------

        function checkLatLongGridTargetPositions(testCase)
            %BodyFixedLatLongGridTargetModel lays a linspace x linspace grid
            %over the lat/long box and converts each node to body-fixed
            %Cartesian.  KSPTOT bodies are spheres, so the oracle is
            %
            %   r = (R_body + alt) * [cos(lat)cos(long); cos(lat)sin(long); sin(lat)]
            %
            %spelled out in refLatLongAltToEcef.
            %
            %Two things make an ordered comparison wrong: production runs the
            %grid through combvec and then unique(...,'rows'), which both
            %reorders the points and collapses duplicates.  So the comparison
            %below is set-based (sortrows on both sides).
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            frozen = testCase.copyBodyInfo(testCase.kerbin);
            frozen.rotperiod = Inf;   %both required: with these two set the
            frozen.rotini    = 0;     %body-fixed frame coincides with BCI

            nwLong = deg2rad(-20);  nwLat = deg2rad(40);
            seLong = deg2rad(10);   seLat = deg2rad(-5);
            nLong = 4;  nLat = 3;
            alt = 12;

            tgt = BodyFixedLatLongGridTargetModel('grid', frozen, ...
                nwLong, nwLat, seLong, seLat, nLong, nLat, alt, lvdData);

            longs = linspace(min(nwLong,seLong), max(nwLong,seLong), nLong);
            lats  = linspace(min(nwLat,seLat),  max(nwLat,seLat),  nLat);

            expected = zeros(3, nLong*nLat);
            k = 0;
            for(iLat = 1:numel(lats))
                for(iLong = 1:numel(longs))
                    k = k + 1;
                    expected(:,k) = testCase.refLatLongAltToEcef( ...
                        lats(iLat), longs(iLong), alt, frozen.radius);
                end
            end

            testCase.verifyEqual(tgt.getNumberOfTargetPts(), nLong*nLat, ...
                'Grid should contain numPtsLong * numPtsLat distinct points.');

            actualEcef = sortrows(tgt.rVectECEF');
            testCase.verifyVectorEqual(actualEcef(:), reshape(sortrows(expected'), [], 1), 1e-8, ...
                'Body-fixed grid points disagree with the spherical oracle.');

            %With the body frozen at rotini = 0, body-fixed == inertial, so
            %getTargetPositions must be a no-op transform.
            scElem = CartesianElementSet(0, [8000;0;0], [0;3;0], frozen.getBodyCenteredInertialFrame());
            actualIn = tgt.getTargetPositions(1234.5, scElem, frozen.getBodyCenteredInertialFrame());
            testCase.verifyVectorEqual(sortrows(actualIn')', sortrows(tgt.rVectECEF')', 1e-8, ...
                'With rotperiod=Inf and rotini=0 the fixed-frame -> inertial transform must be the identity.');

            %Every grid point must sit at exactly R + alt from the centre.
            radii = vecnorm(tgt.rVectECEF, 2, 1);
            testCase.verifyLessThanOrEqual(max(abs(radii - (frozen.radius + alt))), 1e-8, ...
                'Grid points are not all at radius R_body + altitude.');

            %Degenerate box: a 1x1 grid collapses to a single point.  Which
            %corner it lands on is decided by linspace, not by the target
            %model: linspace(a,b,1) returns b, the STOP value.  Production
            %passes linspace(minLong, maxLong, numPtsLong), so a 1x1 grid ends
            %up on the max-lat / max-long corner, i.e. the NORTH-EAST corner of
            %the box the user drew -- not the north-west corner the property
            %names (nwCornerLat/nwCornerLong) would suggest.  Pinned here
            %because it is surprising and load-bearing for single-point grids.
            single = BodyFixedLatLongGridTargetModel('pt', frozen, ...
                nwLong, nwLat, seLong, seLat, 1, 1, alt, lvdData);
            testCase.verifyEqual(single.getNumberOfTargetPts(), 1, ...
                'A 1x1 grid must produce exactly one point.');
            testCase.verifyVectorEqual(single.rVectECEF, ...
                testCase.refLatLongAltToEcef(max(nwLat,seLat), max(nwLong,seLong), alt, frozen.radius), ...
                1e-8, 'A 1x1 grid must land on the max-lat/max-long corner (linspace(a,b,1) returns b).');
        end

        function checkPointTargetPositions(testCase)
            %PointSensorTargetModel delegates to its geometric point.  The
            %interesting part is that it must report exactly one target point
            %and label it with the point's name.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            P = [1234.5; -678.9; 42];
            pt = testCase.makeFixedPoint(lvdData, P);
            pt.setName('MyPoint');

            tgt = PointSensorTargetModel('tracker', pt, lvdData);
            scElem = CartesianElementSet(0, [8000;0;0], [0;3;0], testCase.kerbinFrame);

            testCase.verifyEqual(tgt.getNumberOfTargetPts(), 1, ...
                'A point target has exactly one target point.');
            testCase.verifyVectorEqual(tgt.getTargetPositions(0, scElem, testCase.kerbinFrame), P, ...
                testCase.GeomTol, 'Point target position did not round-trip.');
            testCase.verifyVectorEqual(tgt.getTargetPositions(9999, scElem, testCase.kerbinFrame), P, ...
                testCase.GeomTol, 'A frame-fixed point target must be time invariant.');
            testCase.verifyEqual(char(tgt.getTargetPtLabelStrs()), 'MyPoint', ...
                'Point target label must be the geometric point name.');
        end

        %% ------------------------------------------------------------------
        %  State objects and results bookkeeping
        %  ------------------------------------------------------------------

        function checkSensorStateMaxAngle(testCase)
            %getMaxAngle is the culling radius used by getObscuringMesh.  For a
            %rectangle it is max(az, dec) -- the half-diagonal would be the
            %geometrically correct bound, but max() is conservative in the
            %sense the culling code needs only if az == dec.  Pin the actual
            %contract: max of the two, both orderings, and the tie.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            sAzBig = testCase.makeRectangularSensor(lvdData, deg2rad(40), deg2rad(10), 500);
            testCase.verifyEqual(sAzBig.getInitialState().getMaxAngle(), deg2rad(40), ...
                'getMaxAngle must return azAngle when it is the larger.');

            sDecBig = testCase.makeRectangularSensor(lvdData, deg2rad(10), deg2rad(40), 500);
            testCase.verifyEqual(sDecBig.getInitialState().getMaxAngle(), deg2rad(40), ...
                'getMaxAngle must return decAngle when it is the larger.');

            sTie = testCase.makeRectangularSensor(lvdData, deg2rad(25), deg2rad(25), 500);
            testCase.verifyEqual(sTie.getInitialState().getMaxAngle(), deg2rad(25), ...
                'getMaxAngle must return the common value when az == dec.');

            %Setters must be visible through the getters (the event actions
            %SetRectangularlSensorAzAngleAction etc. drive these at run time).
            st = sTie.getInitialState();
            st.setSensorAzAngle(deg2rad(60));
            testCase.verifyEqual(st.getMaxAngle(), deg2rad(60), ...
                'getMaxAngle must reflect a runtime azAngle change.');
            st.setSensorMaxRange(123);
            testCase.verifyEqual(st.getSensorMaxRange(), 123, ...
                'setSensorMaxRange did not take effect.');
            st.setSensorActiveState(false);
            testCase.verifyFalse(st.getSensorActiveState(), ...
                'setSensorActiveState did not take effect.');

            %AbstractSensorState is Copyable; a copy must be independent,
            %otherwise a SetSensorActiveStateAction in one branch of the
            %script would leak into another.
            cp = copy(st);
            cp.setSensorActiveState(true);
            testCase.verifyFalse(st.getSensorActiveState(), ...
                'copy() of a sensor state is not independent of the original.');

            %Conical: getMaxAngle is just the half-angle, and the setter path.
            cs = testCase.makeConicalSensor(lvdData, deg2rad(12), 700);
            cst = cs.getInitialState();
            cst.setSensorAngle(deg2rad(33));
            testCase.verifyEqual(cst.getMaxAngle(), deg2rad(33), ...
                'ConicalSensorState.getMaxAngle must track setSensorAngle.');
        end

        function checkCoverageFractionAndMerge(testCase)
            %SensorTargetResults.getCoverageFraction is sum(bool)/numel(bool),
            %evaluated element-wise over an ARRAY of results objects.
            %mergeResults ORs together, per target, the boolean vectors of
            %every sensor that saw it.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            sensorA = testCase.makeConicalSensor(lvdData, deg2rad(10), 500);
            sensorB = testCase.makeConicalSensor(lvdData, deg2rad(20), 500);
            tgt = PointSensorTargetModel('t', testCase.makeFixedPoint(lvdData, [1;2;3]), lvdData);

            rVects = [1 2 3; 4 5 6; 7 8 9; 10 11 12];

            rA = SensorTargetResults(sensorA, tgt, 0, [0;0;0], ...
                logical([1;0;1;1]), rVects, testCase.kerbinFrame);
            rB = SensorTargetResults(sensorB, tgt, 0, [0;0;0], ...
                logical([0;1;0;0]), rVects, testCase.kerbinFrame);
            rNone = SensorTargetResults(sensorA, tgt, 0, [0;0;0], ...
                false(4,1), rVects, testCase.kerbinFrame);
            rAll = SensorTargetResults(sensorA, tgt, 0, [0;0;0], ...
                true(4,1), rVects, testCase.kerbinFrame);

            testCase.verifyEqual(rA.getCoverageFraction(), 0.75, 'AbsTol', testCase.ValueTol, ...
                '3 of 4 points visible must give a coverage fraction of 0.75.');
            testCase.verifyEqual(rNone.getCoverageFraction(), 0, 'AbsTol', testCase.ValueTol, ...
                'No visible points must give a coverage fraction of 0.');
            testCase.verifyEqual(rAll.getCoverageFraction(), 1, 'AbsTol', testCase.ValueTol, ...
                'All points visible must give a coverage fraction of 1.');

            %Array form: one fraction per element, in order.
            resultArr = [rA, rB, rNone, rAll];
            fracs = resultArr.getCoverageFraction();
            testCase.verifyVectorEqual(fracs, [0.75, 0.25, 0, 1], testCase.ValueTol, ...
                'getCoverageFraction over an array must return one value per element in order.');

            %mergeResults: A saw points 1,3,4; B saw point 2; the union is all
            %four, so the merged coverage is 1.
            merged = SensorTargetResults.mergeResults([rA, rB]);
            testCase.verifyEqual(numel(merged), 1, ...
                'Two results for the same target must merge into one.');
            testCase.verifyEqual(logical(merged.resultsBool), true(4,1), ...
                'mergeResults must OR the per-sensor visibility vectors.');
            testCase.verifyEqual(merged.getCoverageFraction(), 1, 'AbsTol', testCase.ValueTol, ...
                'Merged coverage of complementary sensors must be 1.');

            %Two DIFFERENT targets must stay separate.
            tgt2 = PointSensorTargetModel('t2', testCase.makeFixedPoint(lvdData, [9;9;9]), lvdData);
            rC = SensorTargetResults(sensorA, tgt2, 0, [0;0;0], ...
                logical([1;0;0;0]), rVects, testCase.kerbinFrame);
            merged2 = SensorTargetResults.mergeResults([rA, rB, rC]);
            testCase.verifyEqual(numel(merged2), 2, ...
                'Results for two distinct targets must not be merged together.');

            %Same frame in, same rVects out (no transform applied).
            [bool, rv] = rA.getTargetResultsInFrame(testCase.kerbinFrame);
            testCase.verifyEqual(logical(bool), logical([1;0;1;1]), ...
                'getTargetResultsInFrame must pass the boolean vector through.');
            testCase.verifyVectorEqual(rv(:), rVects(:), testCase.GeomTol, ...
                'getTargetResultsInFrame must not move points when the frame is unchanged.');
        end

        function checkSensorSetManagement(testCase)
            %LvdSensorSet / LvdSensorTargetSet are plain ordered containers.
            %The bounds behaviour of getSensorAtInd is the part with logic.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            s1 = testCase.makeConicalSensor(lvdData, deg2rad(10), 500);
            s1.name = 'Alpha';
            s2 = testCase.makeRectangularSensor(lvdData, deg2rad(10), deg2rad(20), 500);
            s2.name = 'Beta';

            set = lvdData.sensors;
            testCase.verifyEmpty(set.sensors, 'A default LvdData must start with no sensors.');

            set.addSensor(s1);
            set.addSensor(s2);
            testCase.verifyEqual(numel(set.sensors), 2, 'addSensor did not append.');

            testCase.verifyTrue(set.getSensorAtInd(1) == s1, 'Index 1 must return the first sensor added.');
            testCase.verifyTrue(set.getSensorAtInd(2) == s2, 'Index 2 must return the second sensor added.');
            testCase.verifyEmpty(set.getSensorAtInd(0), 'Index 0 must return an empty sensor array.');
            testCase.verifyEmpty(set.getSensorAtInd(3), 'Index past the end must return an empty sensor array.');
            testCase.verifyEmpty(set.getSensorAtInd(-1), 'Negative index must return an empty sensor array.');

            testCase.verifyEqual(set.getIndsForSensors([s2, s1]), [2 1], ...
                'getIndsForSensors must report positions in the order asked, not stored order.');
            testCase.verifyEqual(set.getListboxStr(), {'Alpha', 'Beta'}, ...
                'Listbox strings must be the sensor names in storage order.');

            set.removeSensor(s1);
            testCase.verifyEqual(numel(set.sensors), 1, 'removeSensor did not shrink the set.');
            testCase.verifyTrue(set.getSensorAtInd(1) == s2, 'Wrong sensor survived removeSensor.');

            %Target set, same contract.
            tgtSet = lvdData.sensorTgts;
            t1 = PointSensorTargetModel('t1', testCase.makeFixedPoint(lvdData, [1;0;0]), lvdData);
            t2 = PointSensorTargetModel('t2', testCase.makeFixedPoint(lvdData, [0;1;0]), lvdData);
            tgtSet.addTarget(t1);
            tgtSet.addTarget(t2);

            testCase.verifyTrue(tgtSet.getPointAtInd(2) == t2, 'Target index 2 must return the second target.');
            testCase.verifyEqual(tgtSet.getIndsForTarget([t2, t1]), [2 1], ...
                'getIndsForTarget must report positions in the order asked.');
            tgtSet.removeTarget(t1);
            testCase.verifyEqual(numel(tgtSet.targets), 1, 'removeTarget did not shrink the set.');
        end

        %% ------------------------------------------------------------------
        %  Regression guards for previously-fixed defects
        %  ------------------------------------------------------------------

        function checkRectangularSensorIsInUseTracksReferences(testCase)
            %isInUse(lvdData) must report whether any part of the mission
            %script references this sensor, so the GUI can refuse to delete a
            %sensor that is still wired to an event action or termination
            %condition.  Both sensor types must answer identically.
            %
            %RectangularSensor.isInUse used to be hardcoded "tf = false;"
            %(RectangularSensor.m:144) while ConicalSensor correctly delegated
            %to lvdData.usesSensor.  The effect was that a rectangular sensor
            %still referenced by a SetSensorActiveStateAction reported "not in
            %use", so deleting it left the action holding a dangling handle.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            conical = testCase.makeConicalSensor(lvdData, deg2rad(10), 500);
            rect    = testCase.makeRectangularSensor(lvdData, deg2rad(10), deg2rad(20), 500);
            lvdData.sensors.addSensor(conical);
            lvdData.sensors.addSensor(rect);

            %Nothing references either sensor yet.
            testCase.verifyFalse(conical.isInUse(lvdData), ...
                'An unreferenced conical sensor must report isInUse == false.');
            testCase.verifyFalse(rect.isInUse(lvdData), ...
                'An unreferenced rectangular sensor must report isInUse == false.');

            %Now wire BOTH sensors into event 1 via an action that implements
            %usesSensor (SetSensorActiveStateAction.usesSensor, line 72-74:
            %  tf = obj.sensor == sensor).
            evt = lvdData.script.getEventForInd(1);
            evt.addAction(SetSensorActiveStateAction(conical, false));
            evt.addAction(SetSensorActiveStateAction(rect, false));

            %The plumbing itself works for both -- LvdData.usesSensor finds
            %them.  This proves the fixture is not the problem.
            testCase.verifyTrue(lvdData.usesSensor(conical), ...
                'Fixture broken: LvdData.usesSensor should see the conical sensor.');
            testCase.verifyTrue(lvdData.usesSensor(rect), ...
                'Fixture broken: LvdData.usesSensor should see the rectangular sensor.');

            testCase.verifyTrue(conical.isInUse(lvdData), ...
                'A referenced conical sensor must report isInUse == true.');
            testCase.verifyTrue(rect.isInUse(lvdData), ...
                ['A referenced rectangular sensor must report isInUse == true.  ' ...
                 'A false here means RectangularSensor.isInUse has regressed to a ' ...
                 'hardcoded false instead of delegating to lvdData.usesSensor.']);
        end

        function checkTargetSetReturnsTargetEmptyOutOfRange(testCase)
            %LvdSensorTargetSet.getPointAtInd, when handed an out-of-range
            %index, must return an empty array of the TARGET type so the caller
            %can assign it straight into an AbstractSensorTarget property to
            %clear it.
            %
            %It used to return AbstractSensor.empty(1,0) -- copy/pasted from
            %LvdSensorSet.getSensorAtInd, where the sensor type IS correct.
            %Assigning the result into a target-typed property then raised
            %MATLAB:class:NoConversionDefined instead of clearing it.  The
            %in-range branch was unaffected, which is why it survived normal
            %GUI use.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tgtSet = lvdData.sensorTgts;
            tgtSet.addTarget(PointSensorTargetModel('t1', ...
                testCase.makeFixedPoint(lvdData, [1;0;0]), lvdData));

            inRange = tgtSet.getPointAtInd(1);
            testCase.verifyTrue(isa(inRange, 'AbstractSensorTarget'), ...
                'The in-range branch must return an AbstractSensorTarget.');

            outOfRange = tgtSet.getPointAtInd(2);
            testCase.verifyEmpty(outOfRange, ...
                'An out-of-range index must return an empty array.');
            testCase.verifyEqual(class(outOfRange), 'AbstractSensorTarget', ...
                ['The out-of-range empty must be of the target type.  ' ...
                 '''AbstractSensor'' here means LvdSensorTargetSet.getPointAtInd has ' ...
                 'regressed to returning the sensor-typed empty.']);

            %The point of returning the right type: the empty can be stored
            %back into the target-typed property to clear it.
            set(tgtSet, 'targets', outOfRange);
            testCase.verifyEmpty(tgtSet.targets, ...
                'Assigning the out-of-range empty into targets must clear the property.');
        end

        function checkZeroAngleSensorCanMakeState(testCase)
            %A sensor constructor and the sensor state it produces must agree
            %on the legal range of the beam angles.  Both constructors accept
            %zero (mustBeGreaterThanOrEqual), so a zero-angle degenerate
            %pencil-beam sensor must be able to produce its initial state.
            %
            %The two used to disagree: ConicalSensorState declared
            %angle{mustBeGreaterThan(angle,0)} on the PROPERTY even though its
            %own ctor argument used mustBeGreaterThanOrEqual, and
            %RectangularSensorState did the same for azAngle/decAngle.  A
            %zero-angle sensor could therefore be created and saved, and the
            %mission then threw deep inside getInitialState() at run time --
            %far from the GUI field that accepted it.  Resolved in favour of
            %the permissive bound, matching the constructors.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            zeroCone = testCase.makeConicalSensor(lvdData, 0, 500);
            testCase.verifyEqual(zeroCone.angle, 0, ...
                'The ConicalSensor constructor accepts a zero half-angle.');

            coneState = zeroCone.getInitialState();
            testCase.verifyClass(coneState, 'ConicalSensorState', ...
                ['A zero-angle conical sensor must produce its state.  An error here ' ...
                 'means ConicalSensorState has regressed to a strict mustBeGreaterThan ' ...
                 'on the angle property, disagreeing with its own constructor.']);
            testCase.verifyEqual(coneState.angle, 0, ...
                'The zero half-angle must survive into the sensor state.');

            zeroRect = testCase.makeRectangularSensor(lvdData, 0, deg2rad(10), 500);
            testCase.verifyEqual(zeroRect.azAngle, 0, ...
                'The RectangularSensor constructor accepts a zero azAngle.');

            rectState = zeroRect.getInitialState();
            testCase.verifyClass(rectState, 'RectangularSensorState', ...
                ['A zero-azAngle rectangular sensor must produce its state.  An error ' ...
                 'here means RectangularSensorState has regressed to a strict ' ...
                 'mustBeGreaterThan on azAngle/decAngle.']);
            testCase.verifyEqual(rectState.azAngle, 0, ...
                'The zero azAngle must survive into the sensor state.');
            testCase.verifyEqual(rectState.decAngle, deg2rad(10), 'RelTol', 1e-12, ...
                'The nonzero decAngle must survive into the sensor state.');
        end

        %% ------------------------------------------------------------------
        %  Fixture builders
        %  ------------------------------------------------------------------

        function pt = makeFixedPoint(testCase, lvdData, rVect)
            pt = FixedPointInFrame(rVect(:), testCase.kerbinFrame, 'p', lvdData);
        end

        function sensor = makeConicalSensor(testCase, lvdData, angle, range)
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('cone', angle, range, ...
                testCase.makeFixedPoint(lvdData, [0;0;0]), steer, lvdData);
        end

        function sensor = makeRectangularSensor(testCase, lvdData, azAngle, decAngle, range)
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = RectangularSensor('rect', azAngle, decAngle, range, ...
                testCase.makeFixedPoint(lvdData, [0;0;0]), steer, lvdData);
        end

        %% ------------------------------------------------------------------
        %  Independent oracles -- deliberately do NOT call production helpers
        %  ------------------------------------------------------------------

        function v = refUnitVectorFromRaDec(~, ra, dec)
            %Spherical (right ascension, declination) to a Cartesian unit
            %vector, written out rather than delegating to sph2cart (which is
            %what the production steering models use).  Declination is
            %measured up from the xy-plane, right ascension eastward from +x.
            v = [cos(dec)*cos(ra); cos(dec)*sin(ra); sin(dec)];
        end

        function ang = refAngleBetween(~, a, b)
            %Angle between two vectors via atan2(|a x b|, a.b).  Deliberately
            %NOT dang() -- production uses dang, so reusing it would make the
            %oracle circular.  The atan2 form is also the one that stays
            %accurate for the ~1e-6 rad separations used by the cone-edge
            %cases, where an acos(dot) formulation loses half its digits.
            a = a(:);
            b = b(:);
            ang = atan2(norm(cross(a,b)), dot(a,b));
        end

        function M = refRotZ(~, theta)
            %Right-handed rotation about +z, active convention.
            M = [cos(theta), -sin(theta), 0;
                 sin(theta),  cos(theta), 0;
                 0,           0,          1];
        end

        function M = refRotY(~, theta)
            %Right-handed rotation about +y, active convention.
            M = [ cos(theta), 0, sin(theta);
                  0,          1, 0;
                 -sin(theta), 0, cos(theta)];
        end

        function r = refLatLongAltToEcef(~, lat, long, alt, bodyRadius)
            %Spherical body model: KSP bodies have no flattening, so the
            %geodetic and geocentric latitudes coincide and the radius is
            %simply R_body + altitude.  Written out rather than calling
            %getrVectEcefFromLatLongAlt, which is the production routine under
            %test here.
            r = (bodyRadius + alt) * [cos(lat)*cos(long); cos(lat)*sin(long); sin(lat)];
        end
    end
end
