classdef PropagatorTest < KsptotTestCase
    %PropagatorTest LVD event propagators (ForceModelPropagator,
    %SecondOrderGravOnlyPropagator, TwoBodyPropagator).
    %
    % Oracle strategy: ForceModelPropagator (restricted to
    % ForceModelsEnum.Gravity) and TwoBodyPropagator (inherently Keplerian)
    % are driven on the same gravity-only coast and checked both against
    % each other and against refKeplerPropagate, an independent analytic
    % two-body oracle that shares no code with any production propagator.
    % Tolerances follow tests/lvd_tests/IntegratorTest.m's precedent: loose
    % for the general-purpose ODE89 wrapper (it is only being asked to
    % reproduce a two-body orbit, which IntegratorTest already certifies to
    % much tighter tolerances -- the point here is to catch gross wiring
    % mistakes in the propagator classes themselves, e.g. a wrong state
    % decomposition or a dropped term), and tight for the analytic Kepler
    % stepper.
    %
    % SecondOrderGravOnlyPropagator participates in the cross-consistency
    % coast test too, driven by RKN1210 rather than ODE89.  Until the bug 8
    % fix it could not run at all -- both of its branches were broken, in
    % two unrelated ways -- so this file previously pinned the failures.
    % Those regression tests have been replaced by real oracle tests; see
    % the git history of this file for the pinned-failure versions.
    %
    % Hold-down is covered as a dedicated oracle test for both propagators
    % because a coast-vs-Kepler test could never exercise it: the branch
    % integrates in the body-fixed frame and converts back, and it is
    % checked against an independent rigid-rotation oracle built from
    % BodyFixedFrame/BodyCenteredInertialFrame.getRotMatToInertialAtTime
    % (a generic frame utility, not propagator logic).
    %
    % Not covered here (out of phase-1 scope / already covered elsewhere):
    % general integrator accuracy/conservation/event-detection semantics
    % (tests/lvd_tests/IntegratorTest.m), SoI transitions, non-sequential
    % events, and the thrust/aero/tank-flow ODE terms (already covered by
    % tests/lvd_tests/DragThrustLiftSrpForceModelTest.m and
    % tests/lvd_tests/ForceModelTest.m).

    methods(Test)

        function allThreePropagatorsAgreeWithEachOtherAndWithKeplerOnAGravityOnlyCoast(testCase)
            [entry, gmu, r0, v0] = testCase.buildGravityOnlyCoastEntry();

            coe = refRv2Coe(r0, v0, gmu);
            period = 2 * pi * sqrt(coe.sma^3 / gmu);
            dt = period / 4;

            [rExpected, vExpected] = refKeplerPropagate(r0, v0, gmu, dt);

            [~, enumValue] = IntegratorEnum.getIndOfListboxStr('ODE89', true, true);
            firstOrderIntegrator = IntegratorEnum.getIntegratorObjFromEnum(enumValue);

            fmp = ForceModelPropagator();
            fmp.forceModels = ForceModelsEnum.Gravity;
            [~, yFmp] = testCase.callPropagate(fmp, firstOrderIntegrator, [0, dt], entry, dt);

            twoBodyProp = TwoBodyPropagator();
            [~, yTwoBody] = testCase.callPropagate(twoBodyProp, firstOrderIntegrator, [0, dt], entry, dt);

            % SecondOrderGravOnlyPropagator needs a second-order integrator.
            secOrdProp = SecondOrderGravOnlyPropagator();
            secOrdProp.forceModels = ForceModelsEnum.Gravity;
            [~, ySecOrd] = testCase.callPropagate(secOrdProp, RKN1210Integrator(), [0, dt], entry, dt);

            posTol = 1e-3; % km; ODE89 is the loosest of the three here
            velTol = 1e-5; % km/s

            testCase.verifyVectorEqual(yFmp(end, 1:3).', rExpected, posTol, ...
                'ForceModelPropagator (gravity-only) position disagrees with the Kepler solution');
            testCase.verifyVectorEqual(yFmp(end, 4:6).', vExpected, velTol, ...
                'ForceModelPropagator (gravity-only) velocity disagrees with the Kepler solution');

            testCase.verifyVectorEqual(yTwoBody(end, 1:3).', rExpected, 1e-6, ...
                'TwoBodyPropagator position disagrees with the Kepler solution');
            testCase.verifyVectorEqual(yTwoBody(end, 4:6).', vExpected, 1e-8, ...
                'TwoBodyPropagator velocity disagrees with the Kepler solution');

            % RKN12(10) is a very high order Nystrom method on a pure
            % two-body problem, so it should track the analytic solution
            % far more tightly than ODE89 does.
            testCase.verifySize(ySecOrd, [size(ySecOrd, 1), 6], ...
                ['SecondOrderGravOnlyPropagator must return an Nx6 state. A width of 9 means ', ...
                 'its hold-down/normal branch is re-concatenating velocity that propagate() ', ...
                 'already horzcats on at the end.']);
            testCase.verifyVectorEqual(ySecOrd(end, 1:3).', rExpected, 1e-6, ...
                'SecondOrderGravOnlyPropagator position disagrees with the Kepler solution');
            testCase.verifyVectorEqual(ySecOrd(end, 4:6).', vExpected, 1e-8, ...
                'SecondOrderGravOnlyPropagator velocity disagrees with the Kepler solution');

            % Cross-consistency: the propagators must also agree with each
            % other directly, at the loosest tolerance among them (ODE89's).
            testCase.verifyVectorEqual(yFmp(end, 1:3).', yTwoBody(end, 1:3).', posTol, ...
                'ForceModelPropagator and TwoBodyPropagator disagree on the same gravity-only coast');
            testCase.verifyVectorEqual(yFmp(end, 1:3).', ySecOrd(end, 1:3).', posTol, ...
                'ForceModelPropagator and SecondOrderGravOnlyPropagator disagree on the same gravity-only coast');
        end

        function secondOrderGravOnlyPropagatorHoldDownCoRotatesWithTheBody(testCase)
            %SecondOrderGravOnlyPropagator's hold-down branch must rigidly
            %rotate the clamped vehicle with the central body, exactly as
            %ForceModelPropagator's does.
            %
            % Same independent oracle as
            % forceModelPropagatorHoldDownCoRotatesWithTheBody: the ECI/ECEF
            % rotation is rebuilt from the body's own frame objects rather
            % than from the propagator's own conversion round trip.
            %
            % This is a regression test for bug 8. Three separate shape
            % errors used to live in this branch (a 1x3 passed to a
            % conversion requiring 3xN, a 6-element y0 against a 3-element
            % yp0, and an Nx6 repack that propagate() then horzcat'd into
            % Nx9), and behind them a physics error: yp0 was set to the
            % converted body-fixed velocity while odefun returns zero
            % acceleration, so the clamped vehicle coasted in a straight
            % line through the rotating frame and its radius grew without
            % bound. Hence the explicit radius check below.
            [entry, bodyInfo, r0] = testCase.buildHoldDownEntry();

            dt = 600;
            propagator = SecondOrderGravOnlyPropagator();
            [t, y] = testCase.callPropagate(propagator, RKN1210Integrator(), [0, dt], entry, dt);

            testCase.verifySize(y, [size(y, 1), 6], ...
                'SecondOrderGravOnlyPropagator hold-down must return an Nx6 state');

            R0 = testCase.ecefToBciRotMat(bodyInfo, 0);
            Rt = testCase.ecefToBciRotMat(bodyInfo, t(end));
            expected = Rt * (R0.' * r0);

            testCase.verifyVectorEqual(y(end, 1:3).', expected, 1e-9 * norm(expected), ...
                ['SecondOrderGravOnlyPropagator hold-down does not rigidly co-rotate the clamped ', ...
                 'vehicle with the body between t=0 and t=dt']);

            testCase.verifyEqual(norm(y(end, 1:3)), norm(r0), 'RelTol', 1e-12, ...
                ['SecondOrderGravOnlyPropagator hold-down changed the vehicle''s radius. A rigid ', ...
                 'rotation cannot do that; a nonzero yp0 in the body-fixed frame can.']);

            % A point fixed to the ground has inertial velocity omega x r.
            omega = [0; 0; 2*pi / bodyInfo.rotperiod];
            testCase.verifyVectorEqual(y(end, 4:6).', cross(omega, y(end, 1:3).'), 1e-12, ...
                'SecondOrderGravOnlyPropagator hold-down inertial velocity is not omega x r');
        end

        function secondOrderGravOnlyPropagatorHoldDownConvertsEventStatesBackToInertial(testCase)
            %The hold-down branch converts te/ye/ype back out of the body-
            %fixed frame separately from the main t/y/yp block, and that
            %conversion had the same Nx6-repack shape bug. A never-firing
            %termination condition leaves ye empty and skips it entirely,
            %so this test uses one that actually fires mid-propagation.
            [entry, bodyInfo, r0] = testCase.buildHoldDownEntry();

            dt = 600;
            fireAt = 300;

            propagator = SecondOrderGravOnlyPropagator();
            [~, ~, te, ye] = testCase.callPropagate(propagator, RKN1210Integrator(), ...
                [0, dt], entry, dt, EventDurationTermCondition(fireAt));

            testCase.assertNotEmpty(te, ...
                'Fixture is not exercising the test: the termination condition never fired');
            testCase.verifyEqual(te(1), fireAt, 'AbsTol', 1e-6, ...
                'Termination condition fired at the wrong time');

            testCase.verifySize(ye, [numel(te), 6], ...
                ['Hold-down event states must come back as nEvents-by-6 in the inertial frame. ', ...
                 'A width of 9 means ye was repacked as position+velocity before propagate() ', ...
                 'horzcat''d ype onto it.']);

            R0 = testCase.ecefToBciRotMat(bodyInfo, 0);
            Rt = testCase.ecefToBciRotMat(bodyInfo, te(1));
            expected = Rt * (R0.' * r0);

            testCase.verifyVectorEqual(ye(1, 1:3).', expected, 1e-9 * norm(expected), ...
                'Hold-down event position was not converted back to the inertial frame correctly');
        end

        function forceModelPropagatorHoldDownCoRotatesWithTheBody(testCase)
            %ForceModelPropagator's (correct) hold-down implementation must
            %rigidly rotate the held-down vehicle with the central body.
            %
            % Independent oracle: rebuild the ECI/ECEF rotation from the
            % body's own BodyFixedFrame/BodyCenteredInertialFrame objects
            % (a generic frame-kinematics utility, not propagator logic)
            % rather than trusting the propagator's own
            % getFixedFrameVectFromInertialVect/getInertialVectFromFixedFrameVect
            % round trip.
            [entry, bodyInfo, r0] = testCase.buildHoldDownEntry(); %#ok<*PROP>

            fmp = ForceModelPropagator();
            [~, enumValue] = IntegratorEnum.getIndOfListboxStr('ODE89', true, true);
            integrator = IntegratorEnum.getIntegratorObjFromEnum(enumValue);

            dt = 600; % 10 minutes: comfortably nonzero relative to any body's rotation period
            [t, y] = testCase.callPropagate(fmp, integrator, [0, dt], entry, dt);

            R0 = testCase.ecefToBciRotMat(bodyInfo, 0);
            Rt = testCase.ecefToBciRotMat(bodyInfo, t(end));

            rEcef0 = R0' * r0;
            expected = Rt * rEcef0;

            testCase.verifyVectorEqual(y(end, 1:3).', expected, 1e-6 * norm(expected), ...
                ['ForceModelPropagator hold-down does not rigidly co-rotate the held-down vehicle ', ...
                 'with the body between t=0 and t=dt']);
        end
    end

    methods(Access=private)
        function [entry, gmu, r0, v0] = buildGravityOnlyCoastEntry(testCase)
            %buildGravityOnlyCoastEntry A bound, non-degenerate, inclined
            %orbit around the default vehicle's central body, with hold-
            %down disabled and pure point-mass gravity (no oblateness),
            %so all three propagators can be driven on identical physics.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.usenonsphericalgrav = false;
            entry.centralBody = bodyInfo;

            gmu = bodyInfo.gm;

            r0 = (bodyInfo.radius + 100) * normVector([0.8; 0.5; 0.3]);
            vCirc = sqrt(gmu / norm(r0));
            v0 = vCirc * 1.05 * normVector([-0.3; 0.9; 0.2]);

            entry.time = 0;
            entry.position = r0;
            entry.velocity = v0;
            entry.lvState.holdDownEnabled = false;
        end

        function [entry, bodyInfo, r0] = buildHoldDownEntry(testCase)
            %buildHoldDownEntry A vehicle clamped to the surface of the
            %default central body, at rest in the inertial frame.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            bodyInfo = entry.centralBody;
            r0 = (bodyInfo.radius + 50) * normVector([0.9; 0.3; 0.2]);

            entry.time = 0;
            entry.position = r0;
            entry.velocity = [0; 0; 0];
            entry.lvState.holdDownEnabled = true;
        end

        function [t, y, te, ye, ie] = callPropagate(testCase, propagator, integrator, tspan, entry, dt, termCond)
            %callPropagate Drives a propagator through its full production
            %signature. Defaults to a termination condition that cannot
            %fire within tspan, so the propagator simply advances to
            %tspan(end); pass termCond to exercise event output instead.
            if(nargin < 7)
                termCond = EventDurationTermCondition(dt * 100);
            end
            eventTermCondFuncHandle = termCond.getEventTermCondFuncHandle();
            termCondDir = EventTermCondDirectionEnum.NoDir;
            maxT = dt * 1000;
            checkForSoITrans = false;
            nonSeqTermConds = {};
            nonSeqTermCauses = AbstractIntegrationTerminationCause.empty(1, 0);
            minAltitude = -1e9;
            celBodyData = testCase.celBodyData;
            tStartPropTime = tic;
            maxPropTime = Inf;

            [t, y, te, ye, ie] = propagator.propagate(integrator, tspan, entry, ...
                eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, ...
                nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                tStartPropTime, maxPropTime);
        end

        function R_ecef_to_bci = ecefToBciRotMat(~, bodyInfo, ut)
            bff = bodyInfo.getBodyFixedFrame();
            bci = bodyInfo.getBodyCenteredInertialFrame();
            R_ecef_to_global = bff.getRotMatToInertialAtTime(ut);
            R_bci_to_global = bci.getRotMatToInertialAtTime(ut);
            R_ecef_to_bci = R_bci_to_global' * R_ecef_to_global;
        end
    end
end
