classdef CameraMathTest < KsptotTestCase
    %CameraMathTest The pure camera geometry behind the LVD 3-D view chase
    %camera and camera scripts (F8): spherical offsets, slerp, easing,
    %shortest-arc angle blending and DCM re-orthonormalisation.

    methods(Test)

        %% ------------------------------------------------ spherical offsets

        function sphericalOffsetRoundTrips(testCase)
            center = [100, -200, 50];
            cases = [  0,   0, 10;
                      45,  20, 50;
                    -135, -60, 7.5;
                     170,  89, 3;
                     -10, -89, 3;
                     359,   0, 1];
            for i = 1:size(cases,1)
                az = cases(i,1); el = cases(i,2); r = cases(i,3);
                pos = LvdCameraMath.sphericalOffset(center, az, el, r);
                testCase.verifyEqual(norm(pos - center), r, 'AbsTol', 1e-12, 'Range must be preserved.');

                [az2, el2, r2] = LvdCameraMath.cartesianToSpherical(pos - center);
                testCase.verifyEqual(r2, r, 'AbsTol', 1e-12);
                testCase.verifyEqual(el2, el, 'AbsTol', 1e-9);
                testCase.verifyAngleEqual(deg2rad(az2), deg2rad(az), 1e-9, 'Azimuth round trip');
            end
        end

        function sphericalOffsetAxesConvention(testCase)
            %az from +X toward +Y, el from the XY plane toward +Z
            testCase.verifyVectorEqual(LvdCameraMath.sphericalOffset([0 0 0], 0, 0, 1), [1 0 0], 1e-12, 'az=0,el=0 is +X');
            testCase.verifyVectorEqual(LvdCameraMath.sphericalOffset([0 0 0], 90, 0, 1), [0 1 0], 1e-12, 'az=90 is +Y');
            testCase.verifyVectorEqual(LvdCameraMath.sphericalOffset([0 0 0], 0, 90, 1), [0 0 1], 1e-12, 'el=90 is +Z');
        end

        function cartesianToSphericalOfZeroIsSafe(testCase)
            [az, el, r] = LvdCameraMath.cartesianToSpherical([0 0 0]);
            testCase.verifyEqual([az el r], [0 0 0]);
        end

        %% ------------------------------------------------------ chase pose

        function chasePoseLooksAtTheVehicle(testCase)
            vehPos = [7000; 100; -30];
            pose = LvdCameraMath.chasePose(vehPos, 30, 15, 25, 12);

            testCase.verifyVectorEqual(pose.target, vehPos', 1e-12, 'Target is the vehicle');
            testCase.verifyEqual(norm(pose.position - pose.target), 25, 'AbsTol', 1e-12, 'Range is honoured');
            testCase.verifyEqual(pose.viewAngle, 12);
            testCase.verifyEqual(norm(pose.up), 1, 'AbsTol', 1e-12, 'Up is unit');
            testCase.verifySize(pose.position, [1 3]);
        end

        function chasePoseIsEmptyForUnknownVehiclePosition(testCase)
            testCase.verifyEmpty(LvdCameraMath.chasePose(NaN(3,1), 0, 0, 1, NaN));
            testCase.verifyEmpty(LvdCameraMath.chasePose([], 0, 0, 1, NaN));
        end

        function defaultUpIsNeverParallelToTheSightLine(testCase)
            dirs = [1 0 0; 0 1 0; 0 0 1; 0 0 -1; 0.01 0 1; 1 1 1; -3 2 -7];
            for i = 1:size(dirs,1)
                d = dirs(i,:) / norm(dirs(i,:));
                up = LvdCameraMath.defaultUpForSightLine(d);
                testCase.verifyEqual(norm(up), 1, 'AbsTol', 1e-12);
                testCase.verifyLessThan(abs(dot(up, d)), cosd(2.0), ...
                    sprintf('Up must not be (nearly) parallel to the sight line %s', mat2str(dirs(i,:))));
            end
            testCase.verifyEqual(LvdCameraMath.defaultUpForSightLine([1 0 0]), [0 0 1], 'Horizontal sight line uses +Z up');
            testCase.verifyEqual(LvdCameraMath.defaultUpForSightLine([0 0 -1]), [0 1 0], 'Vertical sight line falls back to +Y up');
        end

        %% ------------------------------------------------------ track pose

        function trackPoseSitsAtTheAnchorAndLooksAtTheVehicle(testCase)
            %trackPose is the inverse framing of chasePose: the position is
            %the fixed anchor and the target tracks the vehicle.
            anchor = [1000; -200; 50];
            veh = [1200; 300; 80];
            pose = LvdCameraMath.trackPose(anchor, veh, 14);

            testCase.verifyVectorEqual(pose.position, anchor', 1e-12, 'Camera sits at the anchor');
            testCase.verifyVectorEqual(pose.target, veh', 1e-12, 'Target is the vehicle');
            testCase.verifyEqual(pose.viewAngle, 14);
            testCase.verifyEqual(norm(pose.up), 1, 'AbsTol', 1e-12, 'Up is unit');
            testCase.verifyLessThan(abs(dot(pose.up, (veh-anchor)/norm(veh-anchor))), cosd(2.0), ...
                'Up must not be (nearly) parallel to the sight line');
            testCase.verifySize(pose.position, [1 3]);
        end

        function trackPoseAcceptsRowOrColumnAndKeepsNaNViewAngle(testCase)
            p1 = LvdCameraMath.trackPose([10 0 0], [0 0 0], NaN);
            p2 = LvdCameraMath.trackPose([10;0;0], [0;0;0], NaN);
            testCase.verifyVectorEqual(p1.position, [10 0 0], 1e-12);
            testCase.verifyVectorEqual(p1.target, [0 0 0], 1e-12);
            testCase.verifyEqual(p1.up, [0 0 1], 'Horizontal sight line uses +Z up');
            testCase.verifyTrue(isnan(p1.viewAngle), 'NaN view angle is preserved');
            testCase.verifyVectorEqual(p2.position, p1.position, 1e-12, 'Column input matches row input');
        end

        function trackPoseIsEmptyForBadOrCoincidentPoints(testCase)
            testCase.verifyEmpty(LvdCameraMath.trackPose([], [0 0 0], NaN), 'Empty anchor');
            testCase.verifyEmpty(LvdCameraMath.trackPose([1 2 3], [], NaN), 'Empty target');
            testCase.verifyEmpty(LvdCameraMath.trackPose([NaN 0 0], [0 0 0], NaN), 'Non-finite anchor');
            testCase.verifyEmpty(LvdCameraMath.trackPose([1 2 3], [Inf 0 0], NaN), 'Non-finite target');
            testCase.verifyEmpty(LvdCameraMath.trackPose([5 5 5], [5 5 5], 10), 'Coincident points have no sight line');
        end

        %% ----------------------------------------------------------- slerp

        function slerpEndpointsAreExactAndMidpointIsEquiangular(testCase)
            a = [1 0 0];
            b = [0 1 0];
            testCase.verifyVectorEqual(LvdCameraMath.slerp(a, b, 0), a, 1e-12, 's=0');
            testCase.verifyVectorEqual(LvdCameraMath.slerp(a, b, 1), b, 1e-12, 's=1');

            m = LvdCameraMath.slerp(a, b, 0.5);
            testCase.verifyEqual(norm(m), 1, 'AbsTol', 1e-12, 'Midpoint is unit');
            testCase.verifyEqual(acos(dot(m,a)), acos(dot(m,b)), 'AbsTol', 1e-12, 'Midpoint is equiangular');
            testCase.verifyEqual(acos(dot(m,a)), pi/4, 'AbsTol', 1e-12);
        end

        function slerpNormalizesItsInputs(testCase)
            m = LvdCameraMath.slerp([5 0 0], [0 0 0.2], 0.5);
            testCase.verifyVectorEqual(m, [1 0 1]/sqrt(2), 1e-12, 'Magnitudes are ignored');
        end

        function slerpParallelReturnsFirstVector(testCase)
            a = [0 0.6 0.8];
            testCase.verifyVectorEqual(LvdCameraMath.slerp(a, 2*a, 0.37), a, 1e-12);
        end

        function slerpAntiparallelStaysUnitAndReachesTheOtherEnd(testCase)
            a = [0 0 1];
            b = [0 0 -1];
            for s = [0.25 0.5 0.75]
                v = LvdCameraMath.slerp(a, b, s);
                testCase.verifyEqual(norm(v), 1, 'AbsTol', 1e-12);
                testCase.verifyEqual(acos(max(-1,min(1,dot(v,a)))), s*pi, 'AbsTol', 1e-9, 'Angle from a grows linearly');
            end
            testCase.verifyVectorEqual(LvdCameraMath.slerp(a, b, 1), b, 1e-9);
        end

        %% ---------------------------------------------------------- easing

        function smoothStepIsSymmetricMonotoneAndPinned(testCase)
            e = @(s) LvdCameraMath.ease(s, LvdCameraEasingEnum.SmoothStep);
            testCase.verifyEqual(e(0), 0);
            testCase.verifyEqual(e(1), 1);
            testCase.verifyEqual(e(0.5), 0.5, 'AbsTol', 1e-15);

            s = linspace(0, 1, 101);
            vals = arrayfun(e, s);
            testCase.verifyTrue(all(diff(vals) >= 0), 'SmoothStep is monotone');
            testCase.verifyEqual(vals + fliplr(vals), ones(size(vals)), 'AbsTol', 1e-14, 'e(s)+e(1-s) == 1');
            testCase.verifyLessThan(e(0.25), 0.25, 'Eases in slowly');
        end

        function linearEasingIsIdentityAndClamps(testCase)
            testCase.verifyEqual(LvdCameraMath.ease(0.3, LvdCameraEasingEnum.Linear), 0.3);
            testCase.verifyEqual(LvdCameraMath.ease(-2, LvdCameraEasingEnum.Linear), 0);
            testCase.verifyEqual(LvdCameraMath.ease(7, LvdCameraEasingEnum.SmoothStep), 1);
        end

        %% ------------------------------------------------- angle blending

        function blendAngleTakesTheShortestArc(testCase)
            testCase.verifyEqual(LvdCameraMath.blendAngleDeg(350, 10, 0.5), 360, 'AbsTol', 1e-9, '350 -> 10 passes through 0/360');
            testCase.verifyEqual(LvdCameraMath.blendAngleDeg(10, 350, 0.5), 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(LvdCameraMath.blendAngleDeg(0, 90, 0.5), 45, 'AbsTol', 1e-12);
            testCase.verifyEqual(LvdCameraMath.blendAngleDeg(0, 90, 0), 0);
            testCase.verifyEqual(LvdCameraMath.blendAngleDeg(0, 90, 1), 90, 'AbsTol', 1e-12);
        end

        %% ---------------------------------------------------- pose blending

        function blendPosesLerpsAndSlerps(testCase)
            pA = LvdCameraMath.makePose([0 0 0], [10 0 0], [0 0 1], 10);
            pB = LvdCameraMath.makePose([2 4 6], [10 20 0], [0 1 0], 30);
            m = LvdCameraMath.blendPoses(pA, pB, 0.5);
            testCase.verifyVectorEqual(m.position, [1 2 3], 1e-12);
            testCase.verifyVectorEqual(m.target, [10 10 0], 1e-12);
            testCase.verifyVectorEqual(m.up, [0 1 1]/sqrt(2), 1e-12);
            testCase.verifyEqual(m.viewAngle, 20, 'AbsTol', 1e-12);
        end

        function blendPosesInheritsAViewAngleFromTheDefinedSide(testCase)
            pA = LvdCameraMath.makePose([0 0 0], [1 0 0], [0 0 1], NaN);
            pB = LvdCameraMath.makePose([0 0 0], [1 0 0], [0 0 1], 25);
            testCase.verifyEqual(LvdCameraMath.blendPoses(pA, pB, 0.1).viewAngle, 25);
            testCase.verifyEqual(LvdCameraMath.blendPoses(pB, pA, 0.9).viewAngle, 25);
            testCase.verifyTrue(isnan(LvdCameraMath.blendPoses(pA, pA, 0.5).viewAngle));
        end

        %% ------------------------------------------------ orthonormalise

        function orthonormalizeDcmRepairsDrift(testCase)
            rng(7);
            Rtrue = eul2rotmARH([0.3, -0.7, 1.1], 'ZYX');
            Rbad = Rtrue + 1e-2*(rand(3) - 0.5);

            R = LvdCameraMath.orthonormalizeDcm(Rbad);
            testCase.verifyEqual(R'*R, eye(3), 'AbsTol', 1e-12, 'Result is orthonormal');
            testCase.verifyEqual(det(R), 1, 'AbsTol', 1e-12, 'Result is a proper rotation');
            testCase.verifyLessThan(norm(R - Rtrue, 'fro'), norm(Rbad - Rtrue, 'fro'), 'Result is closer to the truth than the input');
            testCase.verifyEqual(LvdCameraMath.orthonormalizeDcm(Rtrue), Rtrue, 'AbsTol', 1e-14, 'An exact rotation is a fixed point');
        end

        function orthonormalizeDcmFixesReflectionsAndNaNs(testCase)
            reflection = diag([1 1 -1]);
            R = LvdCameraMath.orthonormalizeDcm(reflection);
            testCase.verifyEqual(det(R), 1, 'AbsTol', 1e-12, 'A reflection is mapped to a rotation');
            testCase.verifyEqual(LvdCameraMath.orthonormalizeDcm(NaN(3)), eye(3), 'NaN input degrades to identity');
        end

        %% ------------------------------------------------------ axes I/O

        function applyPoseToAxesAndReadBack(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);
            plot3(hAx, [0 1], [0 1], [0 1]);

            pose = LvdCameraMath.makePose([5 6 7], [0.5 0.5 0.5], [0 0 1], 15);
            LvdCameraMath.applyPoseToAxes(pose, hAx);

            back = LvdCameraMath.poseFromAxes(hAx);
            testCase.verifyVectorEqual(back.position, pose.position, 1e-12);
            testCase.verifyVectorEqual(back.target, pose.target, 1e-12);
            testCase.verifyVectorEqual(back.up, pose.up, 1e-12);
            testCase.verifyEqual(back.viewAngle, 15, 'AbsTol', 1e-12);
            testCase.verifyEqual(hAx.CameraPositionMode, 'manual');

            %NaN view angle leaves the axes' angle alone
            pose2 = LvdCameraMath.makePose([1 1 1], [0 0 0], [0 0 1], NaN);
            LvdCameraMath.applyPoseToAxes(pose2, hAx);
            testCase.verifyEqual(hAx.CameraViewAngle, 15, 'AbsTol', 1e-12);
            LvdCameraMath.applyPoseToAxes([], hAx);
            testCase.verifyVectorEqual(hAx.CameraPosition, [1 1 1], 1e-12, 'Empty pose is a no-op');
        end
    end
end
