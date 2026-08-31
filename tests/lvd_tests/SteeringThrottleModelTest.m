classdef SteeringThrottleModelTest < KsptotTestCase
    %SteeringThrottleModelTest LVD steering models, control frames,
    %steering math models, and throttle models.
    %
    % One parameterized test dispatches (by name, via dynamic method-name
    % dispatch) to a per-type check method -- the same pattern used by
    % EventActionTest.m/EventTerminationConditionTest.m.
    %
    % Oracle strategy
    % ----------------
    % All DCM-producing code under test (steering models, control frames)
    % is compared against DCMs built from scratch with a hand-rolled
    % Rz*Ry*Rx ZYX-Euler composition (Rz/Ry/Rx/eulZYX below) and
    % from-scratch NED/Wind frame axis constructions (nedFrameOracle/
    % windFrameOracle, built from cross products, not by calling any of
    % computeNedFrameInFrame.m/computeWindFrame.m). This was empirically
    % validated (matlab -batch, see task notes) to agree with
    % eul2rotmARH_mex(...,'zyx') to machine precision for a pure Z-axis
    % test rotation.
    %
    % Two tricks are used to make the DCM oracles tractable for arbitrary
    % (possibly rotating) bodies without reimplementing frame-offset math:
    %   1. "Non-rotating body" trick (bodyInfo.rotperiod=Inf,
    %      bodyInfo.rotini=0): collapses the body-fixed frame (BFF) onto
    %      the body-centered-inertial frame (BCI) exactly. Used for the
    %      two steering models whose baseFrame is BFF
    %      (AeroAnglesPolySteeringModel, RollPitchYawPolySteeringModel).
    %   2. "Same cached object" trick (refFrame/baseFrame =
    %      bodyInfo.getBodyCenteredInertialFrame(), the SAME object the
    %      control-frame/steering-model math internally re-derives via the
    %      same call): this makes the base-frame-to-inertial rotation
    %      exactly bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(ut)
    %      (a ut-independent constant matrix) for ANY body, rotating or
    %      not. Used for InertialAeroAnglesPolySteeringModel (whose
    %      baseFrame already is BCI) and every Generic* steering model /
    %      control frame (by explicitly setting refFrame to this object).
    %
    % Both tricks, and the exact Rz/Ry/Rx angle-argument order used by
    % each production function, were confirmed via matlab -batch against
    % the actual production DCM before this file was written (max
    % observed disagreement ~1e-12, floating-point roundoff only).
    %
    % Throttle models are checked against fundamental F=ma physics
    % (T2WThrottleModel, via computeTrueThrustToWeight's own formula
    % gAccel = gm/(radius+altitude)^2*1000 re-derived independently, not
    % called) exploiting the fact that thrust scales exactly linearly with
    % throttle for the default single-engine fixture
    % (LaunchVehicle.createDefaultLaunchVehicle's vacuum thrust curve is
    % exactly 215 kN, minThrottle=0/maxThrottle=1), or against hand-rolled
    % polynomial/linear-interpolation formulas
    % (ThrottlePolyModel/ThrottleInterpolatedModel).
    %
    % Math models (PolynominalTermModel, SumOfPolyTermsModel, SineModel,
    % SumOfSinesModel, PolynominalModel, LinearTangentModel,
    % LinearTangentSelectableModel) are checked against their documented
    % closed-form formulas.
    %
    % Skipped (documented, not silently omitted):
    %   - FitNetModel (one of the four leaf AbstractSteeringMathModel
    %     types selectable inside GenericSelectableSteeringModel): wraps
    %     an opaque trained neural net (feedforwardnet); there is no
    %     independent oracle to compare against short of re-training an
    %     equivalent network, which is out of proportion to the value
    %     added here. Its plumbing (the switch(class(...)) dispatch in
    %     GenericSelectableSteeringModel) is still exercised by the
    %     GenericPoly and LinearTangent branches tested below.
    %   - PoweredExplicitGuidance: confirmed NOT a subclass of
    %     AbstractSteeringModel (< matlab.mixin.SetGet only) and not
    %     referenced anywhere else in the LVD codebase outside its own
    %     file -- an orphaned/legacy implementation of Teren's PEG
    %     algorithm. Out of scope for this steering-model pass.
    %
    % Two genuine production bugs were found while building the
    % LinearTangent-family oracles: both deepCopy() paths constructed the
    % wrong class and threw. They have since been fixed;
    % GenericLinearTangentSteeringModelDeepCopy and
    % GenericSelectableSteeringModelDeepCopy below are the regression
    % guards -- see the header comments on those two check methods.

    properties(TestParameter)
        caseName = {'AeroAnglesPolySteeringModel', 'InertialAeroAnglesPolySteeringModel', ...
            'RollPitchYawPolySteeringModel', 'GenericPolySteeringModel', 'GenericSumOfSinesSteeringModel', ...
            'GenericLinearTangentSteeringModel', 'GenericQuatInterpSteeringModel', ...
            'GenericSelectableSteeringModel', 'GenericTabularQuatInterpSteeringModel', ...
            'InertialControlFrame', 'NedControlFrame', 'WindControlFrame', ...
            'PolynominalTermModel', 'SumOfPolyTermsModel', 'SineModel', 'SumOfSinesModel', ...
            'PolynominalModel', 'LinearTangentModel', 'LinearTangentSelectableModel', ...
            'ThrottlePolyModel', 'ThrottleInterpolatedModel', 'T2WThrottleModel', ...
            'GenericLinearTangentSteeringModelDeepCopy', 'GenericSelectableSteeringModelDeepCopy'};
    end

    methods(Test)
        function steeringThrottleModelMatchesIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ------------------------------------------- Steering models

        function checkAeroAnglesPolySteeringModel(testCase)
            % baseFrame = bodyInfo.getBodyFixedFrame(); non-rotating trick
            % collapses that onto BCI, so the oracle can build the wind
            % frame directly from the raw (BCI) rVect/vVect.
            bodyInfo = testCase.nonRotatingBody();
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            t0 = 100; ut = 137; dt = ut - t0;

            model = AeroAnglesPolySteeringModel.getDefaultSteeringModel();
            model.setT0(t0);
            model.setConstTerms(0.31, -0.22, 0.14);
            model.setLinearTerms(0.004, -0.006, 0.002);

            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            bank = 0.31 + 0.004*dt;
            aoa  = -0.22 - 0.006*dt;
            slip = 0.14 + 0.002*dt;
            Rwind = testCase.windFrameOracle(rVect, vVect);
            expected = Rwind * testCase.eulZYX(slip, aoa, bank);

            testCase.verifyDcmEqual(dcm, expected, ...
                'AeroAnglesPolySteeringModel DCM does not match the independent wind-frame + ZYX-Euler oracle');
            testCase.verifyValidDcm(dcm, 'AeroAnglesPolySteeringModel');
        end

        function checkInertialAeroAnglesPolySteeringModel(testCase)
            % baseFrame = bodyInfo.getBodyCenteredInertialFrame() directly
            % -- no non-rotating trick needed, works on the real (rotating)
            % Kerbin.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            t0 = 50; ut = 95; dt = ut - t0;

            model = InertialAeroAnglesPolySteeringModel.getDefaultSteeringModel();
            model.setT0(t0);
            model.setConstTerms(-0.18, 0.27, -0.09);
            model.setLinearTerms(0.003, 0.001, -0.002);

            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            bank = -0.18 + 0.003*dt;
            aoa  = 0.27 + 0.001*dt;
            slip = -0.09 - 0.002*dt;
            Rwind = testCase.windFrameOracle(rVect, vVect);
            expected = Rwind * testCase.eulZYX(slip, aoa, bank);

            testCase.verifyDcmEqual(dcm, expected, ...
                'InertialAeroAnglesPolySteeringModel DCM does not match the independent wind-frame + ZYX-Euler oracle');
            testCase.verifyValidDcm(dcm, 'InertialAeroAnglesPolySteeringModel');
        end

        function checkRollPitchYawPolySteeringModel(testCase)
            % baseFrame = bodyInfo.getBodyFixedFrame(); non-rotating trick
            % collapses that onto BCI, so the oracle can build the NED
            % frame directly from the raw (BCI) rVect.
            bodyInfo = testCase.nonRotatingBody();
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            t0 = 0; ut = 42; dt = ut - t0;

            model = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            model.setT0(t0);
            model.setConstTerms(0.12, -0.08, 0.27);
            model.setLinearTerms(0.001, 0.0025, -0.0015);

            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            roll  = 0.12 + 0.001*dt;
            pitch = -0.08 + 0.0025*dt;
            yaw   = 0.27 - 0.0015*dt;
            Rned = testCase.nedFrameOracle(rVect);
            expected = Rned * testCase.eulZYX(yaw, pitch, roll);

            testCase.verifyDcmEqual(dcm, expected, ...
                'RollPitchYawPolySteeringModel DCM does not match the independent NED-frame + ZYX-Euler oracle');
            testCase.verifyValidDcm(dcm, 'RollPitchYawPolySteeringModel');
        end

        function checkGenericPolySteeringModel(testCase)
            % Default controlFrame = NedControlFrame(); refFrame set via
            % the "same cached object" BCI trick.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericPolySteeringModel.getDefaultSteeringModel();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();
            t0 = 10; ut = 66; dt = ut - t0;
            model.setT0(t0);
            model.setConstTerms(0.05, 0.20, -0.11); %gamma, beta, alpha
            model.setLinearTerms(0.0009, -0.0004, 0.0012);

            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            gamma = 0.05 + 0.0009*dt; %roll
            beta  = 0.20 - 0.0004*dt; %pitch
            alpha = -0.11 + 0.0012*dt; %yaw
            Rned = testCase.nedFrameOracle(rVect);
            expected = Rned * testCase.eulZYX(alpha, beta, gamma);

            testCase.verifyDcmEqual(dcm, expected, ...
                'GenericPolySteeringModel (NED control frame) DCM does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'GenericPolySteeringModel');
        end

        function checkGenericSumOfSinesSteeringModel(testCase)
            % Default controlFrame = InertialControlFrame(); refFrame set
            % via the BCI trick.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericSumOfSinesSteeringModel.getDefaultSteeringModel();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            model.gammaAngleModel.const = 0.10;
            model.gammaAngleModel.sines(1).amp = 0.05; model.gammaAngleModel.sines(1).period = 50; model.gammaAngleModel.sines(1).phase = 2;
            model.betaAngleModel.const = -0.05;
            model.betaAngleModel.sines(1).amp = 0.03; model.betaAngleModel.sines(1).period = 80; model.betaAngleModel.sines(1).phase = -1;
            model.alphaAngleModel.const = 0.20;
            model.alphaAngleModel.sines(1).amp = -0.02; model.alphaAngleModel.sines(1).period = 30; model.alphaAngleModel.sines(1).phase = 5;

            ut = 37;
            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            gamma = 0.10 + 0.05*sin((2*pi/50)*(ut + 2));
            beta  = -0.05 + 0.03*sin((2*pi/80)*(ut - 1));
            alpha = 0.20 + (-0.02)*sin((2*pi/30)*(ut + 5));
            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(ut);
            expected = R1 * testCase.eulZYX(alpha, beta, gamma);

            testCase.verifyDcmEqual(dcm, expected, ...
                'GenericSumOfSinesSteeringModel (Inertial control frame) DCM does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'GenericSumOfSinesSteeringModel');
        end

        function checkGenericLinearTangentSteeringModel(testCase)
            % Private constructor does NOT set controlFrame -- must set it
            % explicitly. Uses WindControlFrame here (the third control
            % frame, exercised via a steering model rather than directly).
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericLinearTangentSteeringModel.getDefaultSteeringModel();
            model.controlFrame = WindControlFrame();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            t0 = 5; ut = 41; dt = ut - t0;
            model.setT0(t0);
            model.setConstTerms(0.08, -0.14); %gamma, alpha
            model.setLinearTerms(0.0006, 0.0009);
            model.setLinearTangentTerms(0.02, 0.0005, 0.5, -0.001); %a, a_dot, b, b_dot

            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            gamma = 0.08 + 0.0006*dt; %bank
            alpha = -0.14 + 0.0009*dt; %slip
            aVal = 0.02 + 0.0005*dt;
            bVal = 0.5 - 0.001*dt;
            beta = atan(aVal*dt + bVal); %angle of attack
            Rwind = testCase.windFrameOracle(rVect, vVect);
            expected = Rwind * testCase.eulZYX(alpha, beta, gamma);

            testCase.verifyDcmEqual(dcm, expected, ...
                'GenericLinearTangentSteeringModel (Wind control frame) DCM does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'GenericLinearTangentSteeringModel');
        end

        function checkGenericQuatInterpSteeringModel(testCase)
            % Pure Z-axis rotation from 0 to 350 deg: the shortest SLERP
            % arc is -10 deg, NOT the long way through +350/175 deg. This
            % was empirically confirmed via matlab -batch before writing
            % this test (quatinterp at f=0,0.25,0.5,0.75,1 gives exactly
            % 0,-2.5,-5,-7.5,-10 deg).
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericQuatInterpSteeringModel.getDefaultSteeringModel();
            model.controlFrame = InertialControlFrame();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            model.setT0(0);
            model.setDuration(100);
            %setInitAngles/setFinalAngles do NOT update initQuat/finalQuat
            %(a real quirk of this class -- see class file) so those must
            %be set directly here.
            theta0 = 0;
            theta1 = deg2rad(350);
            model.initQuat = angle2quat(theta0, 0, 0, 'ZYX');
            model.finalQuat = angle2quat(theta1, 0, 0, 'ZYX');

            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(0);
            fractions = [0, 0.25, 0.5, 0.75, 1];
            for i = 1:numel(fractions)
                f = fractions(i);
                ut = f * 100;
                dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

                ang = theta0 + f * testCase.shortestArcDelta(theta0, theta1);
                expected = R1 * testCase.Rz(ang);

                testCase.verifyDcmEqual(dcm, expected, sprintf( ...
                    'GenericQuatInterpSteeringModel DCM at f=%.2f does not match the shortest-arc SLERP oracle', f));
                testCase.verifyValidDcm(dcm, sprintf('GenericQuatInterpSteeringModel (f=%.2f)', f));
            end
        end

        function checkGenericSelectableSteeringModel(testCase)
            % Default sel models are all SteerMathModelTypeEnum.GenericPoly
            % (SumOfPolyTermsModel), default controlFrame = InertialControlFrame().
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericSelectableSteeringModel.getDefaultSteeringModel();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            t0 = 0;
            testCase.setSumOfPolyLinear(model.gammaAngleSumPoly, t0, 0.06, 0.002);
            testCase.setSumOfPolyLinear(model.betaAngleSumPoly, t0, -0.10, 0.001);
            testCase.setSumOfPolyLinear(model.alphaAngleSumPoly, t0, 0.22, -0.0015);

            ut = 30;
            dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            gamma = 0.06 + 0.002*ut;
            beta  = -0.10 + 0.001*ut;
            alpha = 0.22 - 0.0015*ut;
            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(ut);
            expected = R1 * testCase.eulZYX(alpha, beta, gamma);

            testCase.verifyDcmEqual(dcm, expected, ...
                'GenericSelectableSteeringModel (GenericPoly branch, Inertial control frame) DCM does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'GenericSelectableSteeringModel');
        end

        function checkGenericTabularQuatInterpSteeringModel(testCase)
            % Two segments, pure Z-axis rotation throughout: 0 -> 350 deg
            % over [0,100] (shortest arc wraps through -10 deg, same as
            % the single-segment quat-interp case), then 350 -> 370 deg
            % over [100,150] (a plain +20 deg step, no wraparound). Also
            % checks exact agreement at both interior/knot points (t=0,
            % t=100, t=150) in addition to the two segment midpoints.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            model.controlFrame = InertialControlFrame();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            model.setT0(0);
            model.setInitAngles(0, 0, 0); %gamma0, beta0, alpha0
            model.setDurations([100; 50]);
            model.setSubsequentAngles([0;0], [0;0], [deg2rad(350); deg2rad(370)]); %gammaAngs, betaAngs, alphaAngs

            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(0);
            testTimes = [0, 50, 100, 125, 150];
            for i = 1:numel(testTimes)
                ut = testTimes(i);
                dcm = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

                if(ut <= 100)
                    theta1 = 0; theta2 = deg2rad(350); f = ut/100;
                else
                    theta1 = deg2rad(350); theta2 = deg2rad(370); f = (ut-100)/50;
                end
                ang = theta1 + f * testCase.shortestArcDelta(theta1, theta2);
                expected = R1 * testCase.Rz(ang);

                testCase.verifyDcmEqual(dcm, expected, sprintf( ...
                    'GenericTabularQuatInterpSteeringModel DCM at ut=%g does not match the shortest-arc SLERP oracle', ut));
                testCase.verifyValidDcm(dcm, sprintf('GenericTabularQuatInterpSteeringModel (ut=%g)', ut));
            end
        end

        %% ------------------------------------------- Control frames

        function checkInertialControlFrame(testCase)
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            refFrame = bodyInfo.getBodyCenteredInertialFrame();
            frame = InertialControlFrame();

            ut = 12345;
            gammaAng = 0.33; betaAng = -0.15; alphaAng = 0.20;
            dcm = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, refFrame);

            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(ut);
            expected = R1 * testCase.eulZYX(alphaAng, betaAng, gammaAng);
            testCase.verifyDcmEqual(dcm, expected, ...
                'InertialControlFrame.computeDcmToInertialFrame does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'InertialControlFrame');

            %Known-axis-alignment case: zero angles => body axes exactly
            %equal the (refFrame-to-inertial) base rotation.
            dcmZero = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, 0, 0, 0, refFrame);
            testCase.verifyDcmEqual(dcmZero, R1, ...
                'InertialControlFrame with all angles zero should exactly equal the base-frame-to-inertial rotation');
        end

        function checkNedControlFrame(testCase)
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            refFrame = bodyInfo.getBodyCenteredInertialFrame();
            frame = NedControlFrame();

            ut = 12345;
            gammaAng = 0.33; betaAng = -0.15; alphaAng = 0.20; %roll, pitch, yaw
            dcm = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, refFrame);

            Rned = testCase.nedFrameOracle(rVect);
            expected = Rned * testCase.eulZYX(alphaAng, betaAng, gammaAng);
            testCase.verifyDcmEqual(dcm, expected, ...
                'NedControlFrame.computeDcmToInertialFrame does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'NedControlFrame');

            %Known-axis-alignment: with zero angles, body Z axis (3rd
            %column) must be the NED "Down" direction, which points
            %exactly at the body center, i.e. -rHat.
            dcmZero = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, 0, 0, 0, refFrame);
            testCase.verifyVectorEqual(dcmZero(:,3), -normVector(rVect), 1e-9, ...
                'NedControlFrame body Z axis (Down) with zero angles does not point at the body center (-rHat)');
        end

        function checkWindControlFrame(testCase)
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);
            refFrame = bodyInfo.getBodyCenteredInertialFrame();
            frame = WindControlFrame();

            ut = 12345;
            gammaAng = 0.33; betaAng = -0.15; alphaAng = 0.20; %bank, AoA, sideslip
            dcm = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, refFrame);

            Rwind = testCase.windFrameOracle(rVect, vVect);
            expected = Rwind * testCase.eulZYX(alphaAng, betaAng, gammaAng);
            testCase.verifyDcmEqual(dcm, expected, ...
                'WindControlFrame.computeDcmToInertialFrame does not match the independent oracle');
            testCase.verifyValidDcm(dcm, 'WindControlFrame');

            %Known-axis-alignment: with zero angles, body X axis (1st
            %column) must point exactly along the velocity direction.
            dcmZero = frame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, 0, 0, 0, refFrame);
            testCase.verifyVectorEqual(dcmZero(:,1), normVector(vVect), 1e-9, ...
                'WindControlFrame body X axis with zero angles does not point along the velocity vector');
        end

        %% ------------------------------------------- Math models

        function checkPolynominalTermModel(testCase)
            t0 = 3; coeff = 2.5; exponent = 2;
            model = PolynominalTermModel(t0, coeff, exponent);
            model.tOffset = 0.5;

            for ut = [3, 10, 25.5]
                dt = (ut - t0) + model.tOffset;
                expected = coeff * dt^exponent;
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-10, ...
                    sprintf('PolynominalTermModel.getValueAtTime does not match coeff*(dt)^exponent at ut=%g', ut));
            end
        end

        function checkSumOfPolyTermsModel(testCase)
            model = SumOfPolyTermsModel(1.5);
            model.terms(1).t0 = 0; model.terms(1).coeff = 0.4; model.terms(1).exponent = 1;
            model.addTerm(PolynominalTermModel(0, 0.02, 2));

            for ut = [0, 5, 12.3]
                expected = 1.5 + 0.4*ut^1 + 0.02*ut^2;
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-9, ...
                    sprintf('SumOfPolyTermsModel.getValueAtTime does not match const + sum(terms) at ut=%g', ut));
            end
        end

        function checkSineModel(testCase)
            model = SineModel(2, 0.3, 2*pi/40, 1.1);
            model.tOffset = 0.25;

            for ut = [2, 15, 44.4]
                dt = (ut - 2) + model.tOffset;
                expected = 0.3 * sin((2*pi/40) * (dt + 1.1));
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-10, ...
                    sprintf('SineModel.getValueAtTime does not match amp*sin(freq*(dt+phase)) at ut=%g', ut));
            end

            %freq/period are linked dependent properties
            testCase.verifyEqual(model.freq, 2*pi/40, 'AbsTol', 1e-12, ...
                'SineModel.freq dependent property does not match 2*pi/period');
        end

        function checkSumOfSinesModel(testCase)
            model = SumOfSinesModel(-0.4);
            model.sines(1).t0 = 0; model.sines(1).amp = 0.1; model.sines(1).period = 20; model.sines(1).phase = 0;
            model.addSine(SineModel(0, 0.05, 2*pi/60, 3));

            for ut = [0, 7.5, 33]
                expected = -0.4 + 0.1*sin((2*pi/20)*ut) + 0.05*sin((2*pi/60)*(ut+3));
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-9, ...
                    sprintf('SumOfSinesModel.getValueAtTime does not match const + sum(sines) at ut=%g', ut));
            end
        end

        function checkPolynominalModel(testCase)
            model = PolynominalModel(5, 1.2, 0.3, -0.02);
            model.tOffset = 0.1;

            for ut = [5, 8, 20]
                dt = (ut - 5) + 0.1;
                expected = 1.2 + dt*0.3 + 0.5*(-0.02)*dt^2;
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-10, ...
                    sprintf('PolynominalModel.getValueAtTime does not match const+linear*dt+0.5*accel*dt^2 at ut=%g', ut));
            end
        end

        function checkLinearTangentModel(testCase)
            model = LinearTangentModel(2, 0.01, 0.002, 0.4, -0.005);
            model.tOffset = 0.5;

            for ut = [2, 10, 27]
                dt = (ut - 2) + 0.5;
                aVal = 0.01 + 0.002*dt;
                bVal = 0.4 - 0.005*dt;
                expected = atan(aVal*dt + bVal);
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-10, ...
                    sprintf('LinearTangentModel.getValueAtTime does not match atan(a_value*dt+b_value) at ut=%g', ut));
            end
        end

        function checkLinearTangentSelectableModel(testCase)
            model = LinearTangentSelectableModel(1, 0.02, -0.001, 0.6, 0.003);
            model.tOffset = -0.2;

            for ut = [1, 6, 19]
                dt = (ut - 1) + (-0.2);
                aVal = 0.02 - 0.001*dt;
                bVal = 0.6 + 0.003*dt;
                expected = atan(aVal*dt + bVal);
                testCase.verifyEqual(model.getValueAtTime(ut), expected, 'AbsTol', 1e-10, ...
                    sprintf('LinearTangentSelectableModel.getValueAtTime does not match atan(a_value*dt+b_value) at ut=%g', ut));
            end
        end

        %% ------------------------------------------- Throttle models

        function checkThrottlePolyModel(testCase)
            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.setT0(10);
            model.setPolyTerms(0.5, 0.02, -0.001);

            for ut = [10, 40, 70]
                dt = ut - 10;
                expected = 0.5 + dt*0.02 + 0.5*(-0.001)*dt^2;
                actual = model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, min(max(expected,0),1), 'AbsTol', 1e-10, ...
                    sprintf('ThrottlePolyModel.getThrottleAtTime does not match the hand-computed polynomial at ut=%g', ut));
            end

            %Clamping endpoints
            modelHigh = ThrottlePolyModel.getDefaultThrottleModel();
            modelHigh.setPolyTerms(5, 0, 0); %constant throttle of 5, must clamp to 1
            testCase.verifyEqual(modelHigh.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 1, ...
                'ThrottlePolyModel did not clamp throttle > 1 to 1');

            modelLow = ThrottlePolyModel.getDefaultThrottleModel();
            modelLow.setPolyTerms(-5, 0, 0); %constant throttle of -5, must clamp to 0
            testCase.verifyEqual(modelLow.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 0, ...
                'ThrottlePolyModel did not clamp throttle < 0 to 0');
        end

        function checkThrottleInterpolatedModel(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            entry.time = 0;
            %Note: LaunchVehicleStateLogEntry.throttle is a Dependent
            %property (derived from entry.throttleModel.getThrottleAtTime)
            %with no set method, so it cannot be assigned directly to seed
            %a fixture value. Bypass the throttleContinuity/entry.throttle
            %read path entirely and seed the initial throttle directly via
            %the plain, settable initThrottle property instead.
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.durations = [10; 10; 10];
            model.throttles = [0.6; 0.3; 0.9];
            model.throttleContinuity = false;
            model.initThrottle = 0.2;
            model.initThrottleModel(entry);

            %Knot points: t=[0,10,20,30], throttle=[0.2,0.6,0.3,0.9]
            knotTimes = [0, 10, 20, 30];
            knotThrottles = [0.2, 0.6, 0.3, 0.9];
            for i = 1:numel(knotTimes)
                actual = model.getThrottleAtTime(knotTimes(i), [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, knotThrottles(i), 'AbsTol', 1e-10, sprintf( ...
                    'ThrottleInterpolatedModel.getThrottleAtTime does not match the knot-point throttle at t=%g', knotTimes(i)));
            end

            %Linear interpolation between knots (default interpolation
            %type), hand-computed rather than via interp1/griddedInterpolant.
            midCases = [5, 0.4; 15, 0.45; 25, 0.6];
            for i = 1:size(midCases,1)
                ut = midCases(i,1);
                idx = find(ut >= knotTimes, 1, 'last');
                f = (ut - knotTimes(idx)) / (knotTimes(idx+1) - knotTimes(idx));
                expected = knotThrottles(idx) + f*(knotThrottles(idx+1) - knotThrottles(idx));
                testCase.verifyEqual(midCases(i,2), expected, 'AbsTol', 1e-10, ...
                    'Test fixture bug: hand-computed midpoint does not match the intended linear interpolation');
                actual = model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-9, sprintf( ...
                    'ThrottleInterpolatedModel.getThrottleAtTime does not match hand-rolled linear interpolation at ut=%g', ut));
            end
        end

        function checkT2WThrottleModel(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, powerStorageStates] = testCase.buildT2WFixture();

            %Vacuum, above-atmosphere altitude: default single-engine
            %vehicle's vacuum thrust curve is exactly 215 kN (Phase 1
            %precedent), and thrust scales exactly linearly with throttle
            %(minThrottle=0/maxThrottle=1 defaults => adjustedThrottle ==
            %throttle), so TW(throttle) = throttle * TWfull exactly, where
            %TWfull is re-derived here from F=ma, NOT via
            %computeTrueThrustToWeight.
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1;0.2;0.3]);
            vVect = [0.5; 1.6; 0.1];
            altitude = norm(rVect) - bodyInfo.radius;
            gAccel = (bodyInfo.gm / ((bodyInfo.radius + altitude)^2)) * 1000;
            totalMassKg = (dryMass + sum(tankMasses)) * 1000;
            TWfull = (215*1000) / (totalMassKg * gAccel);

            %targetT2W <= 0 => throttle = 0
            model0 = T2WThrottleModel.getDefaultThrottleModel();
            model0.targetT2W = 0;
            actual0 = model0.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            testCase.verifyEqual(actual0, 0, 'AbsTol', 1e-12, ...
                'T2WThrottleModel with targetT2W<=0 did not return throttle=0');

            %Target above full-throttle T/W => throttle clamps to 1
            modelHigh = T2WThrottleModel.getDefaultThrottleModel();
            modelHigh.targetT2W = TWfull * 1.5;
            actualHigh = modelHigh.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
            testCase.verifyEqual(actualHigh, 1, 'AbsTol', 1e-12, ...
                'T2WThrottleModel did not clamp to throttle=1 when the target T/W exceeds the full-throttle T/W');

            %Intermediate target => throttle = target/TWfull (linear)
            for frac = [0.25, 0.5, 0.75]
                modelMid = T2WThrottleModel.getDefaultThrottleModel();
                modelMid.targetT2W = frac * TWfull;
                actualMid = modelMid.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);
                testCase.verifyEqual(actualMid, frac, 'AbsTol', 1e-6, sprintf( ...
                    'T2WThrottleModel.getThrottleAtTime does not match target/TWfull for frac=%g', frac));
            end
        end

        %% ------------------------------------------- deepCopy regressions

        function checkGenericLinearTangentSteeringModelDeepCopy(testCase)
            %deepCopy() must return an independent object of the SAME class
            %that steers identically to the original.
            %
            %This method used to construct a GenericPolySteeringModel --
            %copy-pasted from a sibling class and never updated.  That is not
            %merely the wrong class: GenericPolySteeringModel's constructor is
            %methods(Access=private), so calling it from another class threw
            %MATLAB:class:MethodRestricted and deepCopy() was unusable on
            %every code path that copies a linear-tangent steering model.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);

            model = GenericLinearTangentSteeringModel.getDefaultSteeringModel();
            model.controlFrame = WindControlFrame();
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            t0 = 5; ut = 41;
            model.setT0(t0);
            model.setConstTerms(0.08, -0.14);
            model.setLinearTerms(0.0006, 0.0009);
            model.setLinearTangentTerms(0.02, 0.0005, 0.5, -0.001);

            dcmBefore = model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);

            copied = model.deepCopy();

            testCase.verifyClass(copied, 'GenericLinearTangentSteeringModel', ...
                'deepCopy() must return the same class it was called on');
            testCase.verifyFalse(copied == model, ...
                'deepCopy() must return a distinct handle, not the original');

            testCase.verifyDcmEqual(copied.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo), ...
                dcmBefore, 'The deep copy must steer identically to the original');

            %Independence: mutating the copy must leave the original alone.
            %A shallow copy of the angle models would fail here.
            copied.setConstTerms(0.5, 0.5);
            testCase.verifyDcmEqual(model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo), ...
                dcmBefore, 'Mutating the deep copy must not disturb the original model');
        end

        function checkGenericSelectableSteeringModelDeepCopy(testCase)
            %deepCopy() on a selectable steering model must preserve BOTH the
            %selector enums and every unselected math model slot.
            %
            %Two defects lived here.  LinearTangentSelectableModel.deepCopy()
            %constructed a LinearTangentModel (wrong class) and then assigned
            %varA/varADot/varB/varBDot, which that class does not declare, so
            %it threw MATLAB:noPublicFieldForClass -- meaning any copy of a
            %model with a LinearTangent branch selected crashed.  Separately,
            %GenericSelectableSteeringModel.deepCopy() relied on the
            %constructor, which only routes the CURRENTLY SELECTED model into
            %its slot, so the copy silently reverted the other branches to
            %GenericPoly and discarded the user's configuration.
            bodyInfo = testCase.kerbin;
            [rVect, vVect] = testCase.stateFixture(bodyInfo);

            model = GenericSelectableSteeringModel.getDefaultSteeringModel();
            model.betaSelModel = SteerMathModelTypeEnum.LinearTangent;
            model.refFrame = bodyInfo.getBodyCenteredInertialFrame();

            ut = 41;
            copied = model.deepCopy();

            testCase.verifyClass(copied, 'GenericSelectableSteeringModel', ...
                'deepCopy() must return the same class it was called on');
            testCase.verifyFalse(copied == model, ...
                'deepCopy() must return a distinct handle, not the original');

            %The selectors survive...
            testCase.verifyEqual(copied.gammaSelModel, model.gammaSelModel, ...
                'deepCopy() must preserve the gamma selector');
            testCase.verifyEqual(copied.betaSelModel, model.betaSelModel, ...
                'deepCopy() must preserve the beta selector');
            testCase.verifyEqual(copied.alphaSelModel, model.alphaSelModel, ...
                'deepCopy() must preserve the alpha selector');

            %...and so does the selected branch's class, which is what the
            %LinearTangentSelectableModel wrong-class bug destroyed.
            testCase.verifyClass(copied.betaAngleModel, class(model.betaAngleModel), ...
                'deepCopy() must preserve the class of the selected beta angle model');

            %The unselected slots are copied too, not reset to defaults.  A
            %constructor-only copy loses these silently.
            testCase.verifyClass(copied.betaAngleSumPoly, class(model.betaAngleSumPoly), ...
                'deepCopy() must carry the unselected beta sum-of-polynomials slot across');
            testCase.verifyClass(copied.betaAngleSumSines, class(model.betaAngleSumSines), ...
                'deepCopy() must carry the unselected beta sum-of-sines slot across');
            testCase.verifyFalse(copied.betaAngleSumPoly == model.betaAngleSumPoly, ...
                'the unselected slots must be deep copies, not shared handles');

            testCase.verifyDcmEqual(copied.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo), ...
                model.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo), ...
                'The deep copy must steer identically to the original');
        end

        %% ------------------------------------------- Shared fixtures/oracles

        function [lvdData, entry] = buildDefaultEntry(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function bodyInfo = nonRotatingBody(testCase)
            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;
        end

        function [rVect, vVect] = stateFixture(~, bodyInfo)
            rVect = (bodyInfo.radius + 80) * normVector([0.5; -0.6; 0.62]);
            vVect = [0.9; 1.3; -0.4];
        end

        function [lvdData, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, powerStorageStates] = buildT2WFixture(testCase) %#ok<STOUT>

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            bodyInfo = entry.centralBody;
            tankStates = entry.getAllActiveTankStates();
            tankMasses = [tankStates.tankMass];
            dryMass = entry.getTotalVehicleDryMass();
            powerStorageStates = entry.getAllActivePwrStorageStates();
            storageSoCs = [];
            for i = 1:numel(powerStorageStates)
                storageSoCs(i) = powerStorageStates(i).getStateOfCharge(); %#ok<AGROW>
            end
        end

        function setSumOfPolyLinear(~, sumOfPolyModel, t0, const, linearCoeff)
            sumOfPolyModel.const = const;
            sumOfPolyModel.terms(1).t0 = t0;
            sumOfPolyModel.terms(1).coeff = linearCoeff;
            sumOfPolyModel.terms(1).exponent = 1;
        end

        function R = Rz(~, t)
            R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];
        end

        function R = Ry(~, t)
            R = [cos(t) 0 sin(t); 0 1 0; -sin(t) 0 cos(t)];
        end

        function R = Rx(~, t)
            R = [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)];
        end

        function R = eulZYX(testCase, a1, a2, a3)
            R = testCase.Rz(a1) * testCase.Ry(a2) * testCase.Rx(a3);
        end

        function delta = shortestArcDelta(~, theta1, theta2)
            %shortestArcDelta Angular step (in [-pi,pi]) from theta1 to
            %theta2 that quatinterp's shortest-arc SLERP is expected to
            %follow for a single-axis rotation.
            delta = mod(theta2 - theta1 + pi, 2*pi) - pi;
        end

        function R = nedFrameOracle(~, rVect)
            %nedFrameOracle Independent North-East-Down frame construction
            %via cross products (does not call computeNedFrameInFrame.m).
            rHat = normVector(rVect);
            down = -rHat;
            east = normVector(crossARH([0;0;1], rHat));
            north = normVector(crossARH(east, down));
            R = [north, east, down];
        end

        function R = windFrameOracle(~, rVect, vVect)
            %windFrameOracle Independent wind-frame construction via cross
            %products (does not call computeWindFrame.m).
            down = -normVector(rVect);
            windX = normVector(vVect);
            windY = normVector(crossARH(down, windX));
            windZ = normVector(crossARH(windX, windY));
            R = [windX, windY, windZ];
        end

        function verifyDcmEqual(testCase, actual, expected, msg)
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-8, msg);
        end

        function verifyValidDcm(testCase, dcm, label)
            testCase.verifyEqual(dcm*dcm', eye(3), 'AbsTol', 1e-8, ...
                sprintf('%s DCM is not orthonormal (R*R'' ~= I)', label));
            testCase.verifyEqual(det(dcm), 1, 'AbsTol', 1e-8, ...
                sprintf('%s DCM is not a proper rotation (det ~= 1)', label));
        end
    end
end
