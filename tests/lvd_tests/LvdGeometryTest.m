classdef LvdGeometryTest < KsptotTestCase
    %LvdGeometryTest LVD geometry primitives (Vectors/Points/Angles/Planes).
    %
    % Each primitive is checked against independently computed vector
    % algebra.  Most tests build their FixedPointInFrame/FixedVectorInFrame
    % inputs and evaluate the primitive under test *within a single frame*
    % (inFrame == the point/vector's own frame), which collapses the
    % primitive's own frame-conversion machinery to the identity and lets
    % the assertion isolate the actual vector/point/angle/plane algebra
    % rather than frame kinematics.  FixedVectorInFrame and FixedPointInFrame
    % additionally get a dedicated cross-frame test that exercises real
    % frame conversion, using only permitted generic utilities
    % (BodyCenteredInertialFrame.getRotMatToInertialAtTime and
    % getPositOfBodyWRTSun) to build the independent oracle rather than
    % trusting the class's own convertToFrame call.
    %
    % Skipped (heavier fixtures, not required by the phase-1 scope, and not
    % pure vector/angle/plane math primitives): VehiclePoint,
    % GroundObjectPoint, TwoBodyPoint, CelestialBodyPoint,
    % LagrangeGeometricPoint, and everything under Geometry/CoordSys.

    methods(Test)

        %% ------------------------------------------------------ Vectors

        function twoPointVectorIsTheDifferenceOfThePoints(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            r1 = [800; -200; 150];
            r2 = [-100; 900; -50];

            p1 = FixedPointInFrame(r1, frame, 'p1', lvdData);
            p2 = FixedPointInFrame(r2, frame, 'p2', lvdData);

            v = TwoPointVector(p1, p2, 'v', lvdData);
            actual = v.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, r2 - r1, 1e-9, ...
                'TwoPointVector is not point2 minus point1');
        end

        function vectorDifferenceVectorIsVector2MinusVector1(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vectA = [3; -4; 5];
            vectB = [-9; 2; 1];

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            diffVect = VectorDifferenceVector(v1, v2, 'diff', lvdData);
            actual = diffVect.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, vectB - vectA, 1e-9, ...
                'VectorDifferenceVector is not vector2 minus vector1');
        end

        function scaledVectorMultipliesByTheScaleFactor(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vect = [2; -3; 6];
            k = -2.5;

            v = FixedVectorInFrame(vect, frame, 'v', lvdData);
            scaled = ScaledVector(v, k, 'scaled', lvdData);
            actual = scaled.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, k * vect, 1e-9, ...
                'ScaledVector does not scale by the scale factor');
        end

        function scaledVectorNormalizesWhenRequested(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vect = [2; -3; 6];

            v = FixedVectorInFrame(vect, frame, 'v', lvdData);
            scaled = ScaledVector(v, 1, 'scaled', lvdData);
            scaled.normVect = true;
            actual = scaled.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, vect / norm(vect), 1e-9, ...
                'ScaledVector with normVect=true is not a unit vector along the input');
        end

        function crossProductVectorMatchesTheCrossProduct(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vectA = [1; 0; 0];
            vectB = [0; 1; 0];

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            cp = CrossProductVector(v1, v2, 'cp', lvdData);
            actual = cp.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, cross(vectA, vectB), 1e-12, ...
                'CrossProductVector does not match vectA x vectB');
        end

        function projectedVectorRejectsTheNormalComponent(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            projInput = [5; 3; -2];
            normInput = [0; 0; 1];

            pv = FixedVectorInFrame(projInput, frame, 'proj', lvdData);
            nv = FixedVectorInFrame(normInput, frame, 'norm', lvdData);

            projected = ProjectedVector(pv, nv, 'projected', lvdData);
            actual = projected.getVectorAtTime(0, [], frame);

            expected = projInput - (dot(projInput, normInput) / norm(normInput)^2) * normInput;

            testCase.verifyVectorEqual(actual, expected, 1e-9, ...
                'ProjectedVector does not reject the component along normVect');
        end

        function fixedVectorInFrameIsUnchangedWhenTheFrameMatches(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vect = [11; -22; 33];
            v = FixedVectorInFrame(vect, frame, 'v', lvdData);

            actual = v.getVectorAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, vect, 1e-9, ...
                'A FixedVectorInFrame changed value when queried in its own frame');
        end

        function fixedVectorInFrameRotatesCorrectlyBetweenBodies(testCase)
            %Independent oracle: compose the two bodies' own BCI rotation
            %matrices (a generic ephemeris/frame utility, not force-model
            %or geometry-primitive logic) rather than trusting
            %FixedVectorInFrame's internal frame composition.
            lvdData = testCase.lvdFixture();
            munFrame = testCase.munFrame();

            vect = [400; -150; 60];

            v = FixedVectorInFrame(vect, testCase.kerbinFrame, 'v', lvdData);
            actual = v.getVectorAtTime(0, [], munFrame);

            R1 = testCase.kerbinFrame.getRotMatToInertialAtTime(0);
            R2 = munFrame.getRotMatToInertialAtTime(0);

            expected = R2' * (R1 * vect);

            testCase.verifyVectorEqual(actual, expected, 1e-9 * norm(expected), ...
                ['FixedVectorInFrame does not rotate correctly between two bodies'' ', ...
                 'BCI frames']);
        end

        %% -------------------------------------------------------- Points

        function fixedPointInFrameIsUnchangedWhenTheFrameMatches(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            rVect = [700; 250; -80];
            p = FixedPointInFrame(rVect, frame, 'p', lvdData);

            actual = p.getPositionAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual.rVect, rVect, 1e-9, ...
                'A FixedPointInFrame changed value when queried in its own frame');
        end

        function fixedPointInFrameConvertsCorrectlyBetweenBodies(testCase)
            %Independent oracle built from the permitted generic utilities
            %getRotMatToInertialAtTime (rotation) and getPositOfBodyWRTSun
            %(translation) rather than the class's own convertToFrame call.
            lvdData = testCase.lvdFixture();
            munFrame = testCase.munFrame();

            rVect = [900; -300; 120];
            p = FixedPointInFrame(rVect, testCase.kerbinFrame, 'p', lvdData);

            t = 0;
            actual = p.getPositionAtTime(t, [], munFrame);

            R1 = testCase.kerbinFrame.getRotMatToInertialAtTime(t);
            R2 = munFrame.getRotMatToInertialAtTime(t);

            kerbinPosWrtSun = getPositOfBodyWRTSun(t, testCase.kerbin, testCase.celBodyData);
            munPosWrtSun    = getPositOfBodyWRTSun(t, testCase.mun,    testCase.celBodyData);

            globalPos = kerbinPosWrtSun + R1 * rVect;
            expected  = R2' * (globalPos - munPosWrtSun);

            testCase.verifyVectorEqual(actual.rVect, expected, 1e-6 * norm(expected), ...
                ['FixedPointInFrame does not convert correctly between two bodies'' ', ...
                 'BCI frames']);
        end

        %% -------------------------------------------------------- Angles

        function twoVectorAngleMatchesTheSignedAngleAboutZ(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vectA = [1; 0; 0];
            vectB = [1; 1; 0] / norm([1; 1; 0]);

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            angleObj = TwoVectorAngle(v1, v2, 'angle', lvdData);
            actual = angleObj.getAngleAtTime(0, [], frame);

            crossAB = cross(vectA, vectB);
            expected = acos(dot(vectA, vectB) / (norm(vectA) * norm(vectB))) * ...
                       sign(dot([0; 0; 1], crossAB));

            testCase.verifyAngleEqual(actual, expected, 1e-9, ...
                'TwoVectorAngle does not match the independently computed signed angle');
        end

        function twoVectorAngleIsNegativeForTheOppositeRotationSense(testCase)
            %Reversing vector order must flip the sign of the signed angle
            %(an independent sanity property of any signed-angle
            %definition, not tied to the source's own formula).
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vectA = [1; 1; 0] / norm([1; 1; 0]);
            vectB = [1; 0; 0];

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            angleObj = TwoVectorAngle(v1, v2, 'angle', lvdData);
            actual = angleObj.getAngleAtTime(0, [], frame);

            testCase.verifyLessThan(actual, 0, ...
                'Reversing the vector order should flip the sign of the signed angle');
        end

        function vectorPlaneAngleMatchesTheArcsineOfTheDotProduct(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vect = [3; 4; 12];
            normalInput = [0; 0; 1];

            origin = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            normalVect = FixedVectorInFrame(normalInput, frame, 'normal', lvdData);
            plane = PointVectorPlane(origin, normalVect, 'plane', lvdData);

            v = FixedVectorInFrame(vect, frame, 'v', lvdData);
            angleObj = VectorPlaneAngle(v, plane, 'angle', lvdData);
            actual = angleObj.getAngleAtTime(0, [], frame);

            expected = asin(abs(dot(vect, normalInput)) / (norm(vect) * norm(normalInput)));

            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-9, ...
                'VectorPlaneAngle does not match asin(|cos(normal, vector)|)');
        end

        %% -------------------------------------------------------- Planes

        function threePointPlaneNormalMatchesTheCrossProductOfTheEdges(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            r1 = [0; 0; 0];
            r2 = [1; 0; 0];
            r3 = [0; 1; 0];

            p1 = FixedPointInFrame(r1, frame, 'p1', lvdData);
            p2 = FixedPointInFrame(r2, frame, 'p2', lvdData);
            p3 = FixedPointInFrame(r3, frame, 'p3', lvdData);

            plane = ThreePointPlane(p1, p2, p3, 'plane', lvdData);
            actual = plane.getPlaneNormVectAtTime(0, [], frame);

            expected = cross(r2 - r1, r3 - r1);
            expected = expected / norm(expected);

            testCase.verifyVectorEqual(actual, expected, 1e-9, ...
                'ThreePointPlane normal does not match the cross product of its edge vectors');
        end

        function pointVectorPlaneNormalIsTheNormalizedInputVector(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            normalInput = [3; -4; 0];

            origin = FixedPointInFrame([10; 20; 30], frame, 'origin', lvdData);
            normalVect = FixedVectorInFrame(normalInput, frame, 'normal', lvdData);

            plane = PointVectorPlane(origin, normalVect, 'plane', lvdData);
            actual = plane.getPlaneNormVectAtTime(0, [], frame);

            testCase.verifyVectorEqual(actual, normalInput / norm(normalInput), 1e-9, ...
                'PointVectorPlane normal is not the normalized input vector');
        end

        %% ---------------------------------------- Added primitives (F6)

        function unitVectorHasUnitLengthAlongTheInput(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vect = [3; -4; 12];
            v = FixedVectorInFrame(vect, frame, 'v', lvdData);
            u = UnitVector(v, 'u', lvdData);

            actual = u.getVectorAtTime(0, [], frame);
            testCase.verifyEqual(norm(actual), 1, 'AbsTol', 1e-12, ...
                'UnitVector output does not have unit length');
            testCase.verifyVectorEqual(actual, vect / norm(vect), 1e-12, ...
                'UnitVector does not point along the input vector');

            %Vector-of-times query keeps one column per time.
            actualMany = u.getVectorAtTime([0 100 200], [], frame);
            testCase.verifySize(actualMany, [3 3], 'UnitVector must return one column per requested time');
            testCase.verifyEqual(vecnorm(actualMany), [1 1 1], 'AbsTol', 1e-12, ...
                'UnitVector columns are not all unit length');
        end

        function unitVectorOfTheZeroVectorIsZero(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            v = FixedVectorInFrame([0; 0; 0], frame, 'v', lvdData);
            u = UnitVector(v, 'u', lvdData);

            actual = u.getVectorAtTime(0, [], frame);
            testCase.verifyEqual(actual, [0; 0; 0], ...
                'UnitVector of the zero vector must be the zero vector, not NaN');
        end

        function vectorSumMatchesTheComponentwiseSumInTwoFrames(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;
            munFrame = testCase.munFrame();

            vectA = [3; -4; 5];
            vectB = [-9; 2; 1];

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);
            sumVect = VectorSumVector(v1, v2, 'sum', lvdData);

            actual = sumVect.getVectorAtTime(0, [], frame);
            testCase.verifyVectorEqual(actual, vectA + vectB, 1e-9, ...
                'VectorSumVector is not vector1 plus vector2 in its own frame');

            R1 = frame.getRotMatToInertialAtTime(0);
            R2 = munFrame.getRotMatToInertialAtTime(0);
            expected = R2' * (R1 * (vectA + vectB));

            actualMun = sumVect.getVectorAtTime(0, [], munFrame);
            testCase.verifyVectorEqual(actualMun, expected, 1e-9 * norm(expected), ...
                'VectorSumVector does not rotate correctly into another body''s BCI frame');
        end

        function twoPlaneAngleMatchesTheDihedralAngleBetweenTheNormals(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            origin = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            makePlane = @(n, name) PointVectorPlane(origin, FixedVectorInFrame(n, frame, [name ' normal'], lvdData), name, lvdData);

            pZ    = makePlane([0; 0; 1],  'z');
            pTilt = makePlane([1; 0; 1],  'tilt');
            pZ2   = makePlane([0; 0; 2],  'z2');
            pX    = makePlane([1; 0; 0],  'x');
            pNegZ = makePlane([0; 0; -1], 'negz');

            angle = @(p1, p2) TwoPlaneAngle(p1, p2, 'angle', lvdData).getAngleAtTime(0, [], frame);

            testCase.verifyEqual(angle(pZ, pTilt), pi/4, 'AbsTol', 1e-12, ...
                'Dihedral angle between z=0 and x+z=0 planes must be 45 deg');
            testCase.verifyEqual(angle(pZ, pZ2), 0, 'AbsTol', 1e-12, ...
                'Parallel planes must have zero dihedral angle');
            testCase.verifyEqual(angle(pZ, pX), pi/2, 'AbsTol', 1e-12, ...
                'Perpendicular planes must have a 90 deg dihedral angle');
            testCase.verifyEqual(angle(pZ, pNegZ), pi, 'AbsTol', 1e-12, ...
                'Anti-parallel normals must give a 180 deg dihedral angle');
        end

        function vectorPlaneIntersectionPointLiesOnBothTheLineAndThePlane(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            o = [0; 0; 2];
            d = [1; 0; -1];
            a = [0; 0; 0];
            n = [0; 0; 1];

            originPt = FixedPointInFrame(o, frame, 'o', lvdData);
            dirVect = FixedVectorInFrame(d, frame, 'd', lvdData);
            plane = PointVectorPlane(FixedPointInFrame(a, frame, 'a', lvdData), ...
                                     FixedVectorInFrame(n, frame, 'n', lvdData), 'plane', lvdData);

            pt = VectorPlaneIntersectionPoint(originPt, dirVect, plane, 'x', lvdData);
            ce = pt.getPositionAtTime(0, [], frame);

            testCase.verifyVectorEqual(ce.rVect, [2; 0; 0], 1e-9, ...
                'Intersection of the line (0,0,2)+t(1,0,-1) with z=0 must be (2,0,0)');
            testCase.verifyEqual(dot(n, ce.rVect - a), 0, 'AbsTol', 1e-9, ...
                'Intersection point is not on the plane');
            testCase.verifyEqual(norm(cross(ce.rVect - o, d)), 0, 'AbsTol', 1e-9, ...
                'Intersection point is not on the line');
            testCase.verifyVectorEqual(ce.vVect, [0; 0; 0], 1e-9, ...
                'A static line and plane must give a zero intersection-point velocity');

            ceMany = pt.getPositionAtTime([0 10 20], [], frame);
            testCase.verifyNumElements(ceMany, 3, 'One element set per requested time expected');
            testCase.verifyVectorEqual([ceMany.rVect], repmat([2; 0; 0], 1, 3), 1e-9, ...
                'Vector-of-times query must reproduce the scalar result at each time');
        end

        function vectorPlaneIntersectionPointIsNaNWhenTheLineIsParallelToThePlane(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            originPt = FixedPointInFrame([0; 0; 2], frame, 'o', lvdData);
            dirVect = FixedVectorInFrame([1; 0; 0], frame, 'd', lvdData);
            plane = PointVectorPlane(FixedPointInFrame([0; 0; 0], frame, 'a', lvdData), ...
                                     FixedVectorInFrame([0; 0; 1], frame, 'n', lvdData), 'plane', lvdData);

            pt = VectorPlaneIntersectionPoint(originPt, dirVect, plane, 'x', lvdData);
            ce = pt.getPositionAtTime(0, [], frame);

            testCase.verifyTrue(all(isnan(ce.rVect)), ...
                'A line parallel to the plane has no intersection; position must be NaN');
        end

        function ephemerisFilePointReproducesTableRowsAndInterpolatesBetweenThem(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            %A cubic in time per component: MATLAB's not-a-knot spline
            %reproduces cubics exactly, so an off-knot query has an
            %independent closed-form answer.
            [times, rv, rvFcn] = testCase.cubicEphemerisTable();

            pt = EphemerisFilePoint('', frame, 'ephem', lvdData);
            pt.setTable(times, rv);

            ceKnots = pt.getPositionAtTime(times, [], frame);
            testCase.verifyEqual([ceKnots.rVect], rv(1:3,:), 'RelTol', 1e-9, 'AbsTol', 1e-9, ...
                'Ephemeris point does not reproduce the table positions at the table epochs');
            testCase.verifyEqual([ceKnots.vVect], rv(4:6,:), 'RelTol', 1e-9, 'AbsTol', 1e-9, ...
                'Ephemeris point does not reproduce the table velocities at the table epochs');

            tMid = 25;
            ceMid = pt.getPositionAtTime(tMid, [], frame);
            rvMid = rvFcn(tMid);
            testCase.verifyEqual([ceMid.rVect; ceMid.vVect], rvMid, 'RelTol', 1e-8, 'AbsTol', 1e-8, ...
                'Spline interpolation between table rows does not match the generating cubic');

            ceBefore = pt.getPositionAtTime(times(1) - 100, [], frame);
            ceAfter = pt.getPositionAtTime(times(end) + 1000, [], frame);
            testCase.verifyEqual(ceBefore.rVect, rv(1:3,1), 'RelTol', 1e-9, 'AbsTol', 1e-9, ...
                'Queries before the table must clamp to the first row');
            testCase.verifyEqual(ceAfter.rVect, rv(1:3,end), 'RelTol', 1e-9, 'AbsTol', 1e-9, ...
                'Queries after the table must clamp to the last row');

            [tMin, tMax] = pt.getTimeSpan();
            testCase.verifyEqual([tMin, tMax], [times(1), times(end)], 'getTimeSpan must report the table span');
        end

        function ephemerisFilePointConvertsIntoAnotherBodyFrame(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;
            munFrame = testCase.munFrame();

            rVect = [900; -300; 120];
            pt = EphemerisFilePoint('', frame, 'ephem', lvdData);
            pt.setTable([0 100], [rVect, rVect; zeros(3,2)]);

            t = 0;
            actual = pt.getPositionAtTime(t, [], munFrame);

            R1 = frame.getRotMatToInertialAtTime(t);
            R2 = munFrame.getRotMatToInertialAtTime(t);
            kerbinPosWrtSun = getPositOfBodyWRTSun(t, testCase.kerbin, testCase.celBodyData);
            munPosWrtSun    = getPositOfBodyWRTSun(t, testCase.mun,    testCase.celBodyData);
            expected = R2' * (kerbinPosWrtSun + R1 * rVect - munPosWrtSun);

            testCase.verifyVectorEqual(actual.rVect, expected, 1e-6 * norm(expected), ...
                'EphemerisFilePoint does not convert its table into another body''s BCI frame');
        end

        function ephemerisCsvReaderHandlesHeadersCommentsAndWhitespace(testCase)
            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath));

            lines = { ...
                'UT,x,y,z,vx,vy,vz,extra', ...
                '# a comment line', ...
                '0, 1, 2, 3, 4, 5, 6, 99', ...
                sprintf('10\t2\t3\t4\t5\t6\t7\t100'), ...
                '', ...
                '20 3 4 5 6 7 8', ...
                '5;9;9;9;9;9;9', ...
                '20 0 0 0 0 0 0'};
            fid = fopen(filePath, 'w');
            fprintf(fid, '%s\n', lines{:});
            fclose(fid);

            [t, rv] = lvd_readEphemerisCsv(filePath);

            testCase.verifyEqual(t, [0 5 10 20], 'Epochs must be sorted and duplicate epochs collapsed');
            testCase.verifyEqual(rv(:,1), [1;2;3;4;5;6], 'Comma-separated row (with trailing extra column) misread');
            testCase.verifyEqual(rv(:,2), [9;9;9;9;9;9], 'Semicolon-separated row misread');
            testCase.verifyEqual(rv(:,3), [2;3;4;5;6;7], 'Tab-separated row misread');
            testCase.verifyEqual(rv(:,4), [3;4;5;6;7;8], 'Duplicate epoch must keep the first occurrence');

            testCase.verifyError(@() lvd_readEphemerisCsv([tempname(), '.csv']), 'lvd_readEphemerisCsv:fileNotFound');

            headerOnly = [tempname(), '.csv'];
            cleanup2 = onCleanup(@() deleteIfExists(headerOnly));
            fid = fopen(headerOnly, 'w');
            fprintf(fid, 'UT,x,y,z,vx,vy,vz\n');
            fclose(fid);
            testCase.verifyError(@() lvd_readEphemerisCsv(headerOnly), 'lvd_readEphemerisCsv:noData');
        end

        function ephemerisFilePointLoadsItsTableFromAFile(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            [times, rv] = testCase.cubicEphemerisTable();
            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath));
            fid = fopen(filePath, 'w');
            fprintf(fid, 'UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms\n');
            fprintf(fid, '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g\n', [times; rv]);
            fclose(fid);

            pt = EphemerisFilePoint(filePath, frame, 'ephem', lvdData);

            testCase.verifyTrue(pt.hasEphemeris(), 'Constructor with a file path must load the table');
            testCase.verifyEqual(pt.times, times, 'RelTol', 1e-15, 'Loaded epochs differ from the written file');
            testCase.verifyEqual(pt.rvVects, rv, 'RelTol', 1e-15, 'Loaded states differ from the written file');
            testCase.verifyEqual(pt.filePath, filePath);
            [~, fName, fExt] = fileparts(filePath);
            testCase.verifySubstring(pt.getListboxStr(), [fName, fExt], 'List box string must show the file name');
            testCase.verifyEqual(pt.getOriginBody(), testCase.kerbin, 'Origin body must come from the ephemeris frame');
            testCase.verifyTrue(pt.canBePlotted());
            testCase.verifyFalse(pt.isVehDependent());
        end

        function newGeometryTypesReportTheirDependencies(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            v3 = FixedVectorInFrame([0; 0; 1], frame, 'v3', lvdData);
            origin = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            other = FixedPointInFrame([1; 1; 1], frame, 'other', lvdData);
            p1 = PointVectorPlane(origin, v3, 'p1', lvdData);
            p2 = PointVectorPlane(origin, v1, 'p2', lvdData);
            p3 = PointVectorPlane(origin, v2, 'p3', lvdData);

            u = UnitVector(v1, 'u', lvdData);
            s = VectorSumVector(v1, v2, 's', lvdData);
            a = TwoPlaneAngle(p1, p2, 'a', lvdData);
            ip = VectorPlaneIntersectionPoint(origin, v3, p1, 'ip', lvdData);
            e = EphemerisFilePoint('', frame, 'e', lvdData);

            testCase.verifyTrue(u.usesGeometricVector(v1));
            testCase.verifyFalse(u.usesGeometricVector(v2));
            testCase.verifyTrue(s.usesGeometricVector(v2));
            testCase.verifyFalse(s.usesGeometricVector(v3));
            testCase.verifyTrue(a.usesGeometricPlane(p1));
            testCase.verifyTrue(a.usesGeometricPlane(p2));
            testCase.verifyFalse(a.usesGeometricPlane(p3));
            testCase.verifyTrue(ip.usesGeometricPoint(origin));
            testCase.verifyFalse(ip.usesGeometricPoint(other));
            testCase.verifyTrue(ip.usesGeometricVector(v3));
            testCase.verifyTrue(ip.usesGeometricPlane(p1));
            testCase.verifyFalse(ip.usesGeometricPlane(p2));
            testCase.verifyFalse(e.usesGeometricRefFrame(CoordSysPointRefFrame.empty(1,0)), ...
                'A body-frame ephemeris point uses no geometric reference frame');

            for obj = {u, s, a, ip, e}
                testCase.verifyFalse(obj{1}.isVehDependent(), ...
                    sprintf('%s built from fixed inputs must not be vehicle dependent', class(obj{1})));
            end

            %Container plumbing: adding the new objects makes their inputs
            %"in use" while the new objects themselves stay deletable.
            geometry = lvdData.geometry;
            geometry.vectors.addVector(v1);
            geometry.vectors.addVector(u);
            geometry.planes.addPlane(p1);
            geometry.points.addPoint(ip);
            geometry.angles.addAngle(a);

            testCase.verifyTrue(lvdData.usesGeometricVector(v1), 'UnitVector in the set must mark its input vector as used');
            testCase.verifyTrue(lvdData.usesGeometricPlane(p1), 'Intersection point / plane angle must mark their plane as used');
            testCase.verifyTrue(lvdData.usesGeometricPoint(origin), 'Intersection point must mark its origin point as used');
            testCase.verifyFalse(u.isInUse(lvdData), 'Nothing references the unit vector itself');
            testCase.verifyFalse(ip.isInUse(lvdData), 'Nothing references the intersection point itself');
            testCase.verifyFalse(a.isInUse(lvdData), 'Nothing references the plane angle itself');
        end

        function newGeometryEnumsAreRegistered(testCase)
            testCase.verifyTrue(all(ismember({'Unit Vector', 'Vector Sum'}, GeometricVectorEnum.getListBoxStr())));
            testCase.verifyEqual(GeometricVectorEnum.getEnumForListboxStr('Unit Vector'), GeometricVectorEnum.UnitVector);
            testCase.verifyEqual(GeometricVectorEnum.getEnumForListboxStr('Vector Sum'), GeometricVectorEnum.VectorSum);

            testCase.verifyTrue(ismember('Angle Between Planes', GeometricAngleEnum.getListBoxStr()));
            testCase.verifyEqual(GeometricAngleEnum.getEnumForListboxStr('Angle Between Planes'), GeometricAngleEnum.AngleBetweenPlanes);

            testCase.verifyTrue(all(ismember({'Vector-Plane Intersection Point', 'Ephemeris File Point'}, GeometricPointEnum.getListBoxStr())));
            testCase.verifyEqual(GeometricPointEnum.getEnumForListboxStr('Vector-Plane Intersection Point'), GeometricPointEnum.VectorPlaneIntersection);
            testCase.verifyEqual(GeometricPointEnum.getEnumForListboxStr('Ephemeris File Point'), GeometricPointEnum.EphemerisFile);

            %Each new type's editor dialog class must exist on the path.
            dialogs = {'lvd_EditUnitVectorGUI_App', 'lvd_EditVectorSumVectorGUI_App', 'lvd_EditTwoPlaneAngleGUI_App', ...
                       'lvd_EditVectorPlaneIntersectionPointGUI_App', 'lvd_EditEphemerisFilePointGUI_App', 'lvd_ExportEphemerisGUI_App'};
            for i = 1:numel(dialogs)
                testCase.verifyEqual(exist(dialogs{i}, 'class'), 8, sprintf('Dialog class %s is missing from the path', dialogs{i}));
            end
        end

        %% ------------------------------ Added primitives (F6, second batch)

        function vectorDotProductAngleIsTheDotProductNotAnAngle(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            vectA = [3; -4; 5];
            vectB = [-9; 2; 1];

            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            d = VectorDotProductAngle(v1, v2, 'd', lvdData);

            testCase.verifyEqual(d.getAngleAtTime(0, [], frame), dot(vectA, vectB), 'AbsTol', 1e-12, ...
                'VectorDotProductAngle must return the raw dot product');
            testCase.verifyTrue(d.isDimensionless(), 'A dot product is not an angle');
            testCase.verifyFalse(TwoVectorAngle(v1, v2, 'a', lvdData).isDimensionless(), ...
                'A real angle must still report itself as one');

            %Unit-vector inputs give the cosine of the angle between them.
            u1 = UnitVector(v1, 'u1', lvdData);
            u2 = UnitVector(v2, 'u2', lvdData);
            cosine = VectorDotProductAngle(u1, u2, 'c', lvdData);
            expectedCos = dot(vectA, vectB) / (norm(vectA) * norm(vectB));
            testCase.verifyEqual(cosine.getAngleAtTime(0, [], frame), expectedCos, 'AbsTol', 1e-12);

            %Batched times.
            vals = d.getAngleAtTime([0 10 20], [], frame);
            testCase.verifyEqual(vals, repmat(dot(vectA, vectB), 1, 3), 'AbsTol', 1e-12);
        end

        function dotProductGraphicalAnalysisValueIsNotConvertedToDegrees(testCase)
            %The GA angle task converts radians to degrees for every real
            %angle; a dimensionless scalar must come through untouched and
            %with no unit.
            [lvdData, entry] = testCase.propagatedFixture();
            frame = testCase.kerbinFrame;

            vectA = [1; 2; 3];
            vectB = [4; 5; 6];
            v1 = FixedVectorInFrame(vectA, frame, 'v1', lvdData);
            v2 = FixedVectorInFrame(vectB, frame, 'v2', lvdData);

            d = VectorDotProductAngle(v1, v2, 'd', lvdData);
            [value, unitStr] = lvd_GeometricAngleTasks(entry, 'Mag', d, frame);
            testCase.verifyEqual(value, dot(vectA, vectB), 'AbsTol', 1e-9);
            testCase.verifyEmpty(unitStr, 'A dot product has no unit');

            a = TwoVectorAngle(v1, v2, 'a', lvdData);
            [angleValue, angleUnit] = lvd_GeometricAngleTasks(entry, 'Mag', a, frame);
            testCase.verifyEqual(angleUnit, 'deg', 'A real angle must still be reported in degrees');
            testCase.verifyEqual(abs(angleValue), rad2deg(acos(dot(vectA, vectB)/(norm(vectA)*norm(vectB)))), 'AbsTol', 1e-9);

            %The constraint that wraps the task follows suit.
            evt = lvdData.script.getEventForInd(1);
            c = GeometricAngleMagConstraint(d, evt, 0, 1);
            testCase.verifyEmpty(c.getConstraintStaticDetails(), 'Dot product constraint must be unitless');
            c2 = GeometricAngleMagConstraint(a, evt, 0, 1);
            testCase.verifyEqual(c2.getConstraintStaticDetails(), 'deg');
        end

        function dotProductIsSkippedByTheThreeDView(testCase)
            %There is no arc to draw for a scalar: the view profile must not
            %build angle plot data for it, while a real angle still gets one.
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            d = VectorDotProductAngle(v1, v2, 'd', lvdData);
            a = TwoVectorAngle(v1, v2, 'a', lvdData);

            profile = lvdData.viewSettings.selViewProfile;
            profile.anglesToPlot = [d, a];
            profile.createAngleData(frame, {}, LaunchVehicleEvent.empty(1,0));

            testCase.verifyEqual(numel(profile.angleData), 1);
            testCase.verifyTrue(profile.angleData(1).angle == a);
        end

        function threePointCoordSystemAxesFollowThePoints(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            o = [100; -50; 20];
            p = o + [2; 0; 0];        %primary axis along +x of the frame
            q = o + [1; 3; 0];        %plane point: plane is the frame's xy plane

            origin = FixedPointInFrame(o, frame, 'origin', lvdData);
            primary = FixedPointInFrame(p, frame, 'primary', lvdData);
            planePt = FixedPointInFrame(q, frame, 'plane', lvdData);

            cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
            R = cs.getCoordSysAtTime(0, [], frame);

            Rin = frame.getRotMatToInertialAtTime(0);
            u = [1; 0; 0];
            w = [0; 0; 1];            %cross(u, q - o) points along +z
            v = cross(w, u);          %+y, toward the plane point

            testCase.verifyEqual(size(R), [3 3]);
            testCase.verifyVectorEqual(R(:,1), Rin*u, 1e-12, 'Primary axis (+X) must point from origin to primary point');
            testCase.verifyVectorEqual(R(:,3), Rin*w, 1e-12, 'Normal axis (+Z) must be normal to the plane of the points');
            testCase.verifyVectorEqual(R(:,2), Rin*v, 1e-12, 'Third axis must complete a right-handed set in the plane');
            testCase.verifyEqual(R'*R, eye(3), 'AbsTol', 1e-12, 'Rotation must be orthonormal');
            testCase.verifyEqual(det(R), 1, 'AbsTol', 1e-12, 'Rotation must be proper');

            %Batched times return one page per time.
            Rb = cs.getCoordSysAtTime([0 5 10], [], frame);
            testCase.verifyEqual(size(Rb), [3 3 3]);
            testCase.verifyEqual(Rb(:,:,2), R, 'AbsTol', 1e-12);
        end

        function threePointCoordSystemHonorsTheAxisAssignment(testCase)
            %A general (rotated) triad with the primary direction mapped to +Y
            %and the plane normal to -X.
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            o = [1; 2; 3];
            dP = [1; 1; 0];
            dQ = [-1; 2; 5];

            origin = FixedPointInFrame(o, frame, 'origin', lvdData);
            primary = FixedPointInFrame(o + dP, frame, 'primary', lvdData);
            planePt = FixedPointInFrame(o + dQ, frame, 'plane', lvdData);

            cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
            cs.primaryAxis = AlignedConstrainedCoordSysAxesEnum.PosY;
            cs.normalAxis = AlignedConstrainedCoordSysAxesEnum.NegX;

            R = cs.getCoordSysAtTime(0, [], frame);
            Rin = frame.getRotMatToInertialAtTime(0);

            u = dP / norm(dP);
            w = cross(dP, dQ);
            w = w / norm(w);

            testCase.verifyVectorEqual(R*[0; 1; 0], Rin*u, 1e-12, 'The +Y coordinate axis must be the primary direction');
            testCase.verifyVectorEqual(R*[-1; 0; 0], Rin*w, 1e-12, 'The -X coordinate axis must be the plane normal');
            testCase.verifyEqual(R'*R, eye(3), 'AbsTol', 1e-12);
            testCase.verifyEqual(det(R), 1, 'AbsTol', 1e-12);

            %The remaining coordinate axis is a x c (here +Y x -X = +Z) and
            %must map onto u x w, which is the in-plane direction pointing
            %AWAY from the plane point (w x u points toward it).
            a = [0; 1; 0];
            c = [-1; 0; 0];
            testCase.verifyVectorEqual(R*cross(a, c), Rin*cross(u, w), 1e-12, ...
                'The third coordinate axis must complete the right-handed set');

            inPlane = dQ - dot(dQ, u)*u;
            testCase.verifyLessThan(dot(R*cross(a, c), Rin*inPlane), 0, ...
                'For this axis assignment the remaining axis points away from the plane point');
        end

        function threePointCoordSystemSurvivesDegeneratePoints(testCase)
            %Coincident or collinear points must still give a proper rotation
            %rather than NaN, matching how AlignedConstrainedCoordSystem falls
            %back for zero-length vectors.
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            o = FixedPointInFrame([0; 0; 0], frame, 'o', lvdData);
            same = FixedPointInFrame([0; 0; 0], frame, 'same', lvdData);
            onLine = FixedPointInFrame([2; 0; 0], frame, 'onLine', lvdData);
            farOnLine = FixedPointInFrame([5; 0; 0], frame, 'farOnLine', lvdData);

            collinear = ThreePointCoordSystem(o, onLine, farOnLine, 'collinear', lvdData);
            Rc = collinear.getCoordSysAtTime(0, [], frame);
            testCase.verifyFalse(any(isnan(Rc(:))));
            testCase.verifyEqual(Rc'*Rc, eye(3), 'AbsTol', 1e-12);
            testCase.verifyEqual(det(Rc), 1, 'AbsTol', 1e-12);

            coincident = ThreePointCoordSystem(o, same, onLine, 'coincident', lvdData);
            Rd = coincident.getCoordSysAtTime(0, [], frame);
            testCase.verifyFalse(any(isnan(Rd(:))));
            testCase.verifyEqual(Rd'*Rd, eye(3), 'AbsTol', 1e-12);
            testCase.verifyEqual(det(Rd), 1, 'AbsTol', 1e-12);
        end

        function threePointCoordSystemMakesAFrameWithTheExistingRefFrameType(testCase)
            %"Frame from three points" = this coordinate system plus its origin
            %point in a CoordSysPointRefFrame.
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            o = [300; 400; 500];
            origin = FixedPointInFrame(o, frame, 'origin', lvdData);
            primary = FixedPointInFrame(o + [0; 0; 7], frame, 'primary', lvdData);
            planePt = FixedPointInFrame(o + [0; 2; 1], frame, 'plane', lvdData);

            cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
            rf = CoordSysPointRefFrame(cs, origin, 'rf', lvdData);

            [posOffset, ~, ~, R] = rf.getRefFrameAtTime(0, [], frame);
            testCase.verifyVectorEqual(posOffset, o, 1e-9, 'The frame origin must be the origin point');
            testCase.verifyVectorEqual(R(:,1), frame.getRotMatToInertialAtTime(0)*[0; 0; 1], 1e-12, ...
                'The frame x axis must point at the primary axis point');
        end

        function secondBatchGeometryTypesReportTheirDependencies(testCase)
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            v3 = FixedVectorInFrame([0; 0; 1], frame, 'v3', lvdData);
            p1 = FixedPointInFrame([0; 0; 0], frame, 'p1', lvdData);
            p2 = FixedPointInFrame([1; 0; 0], frame, 'p2', lvdData);
            p3 = FixedPointInFrame([0; 1; 0], frame, 'p3', lvdData);
            p4 = FixedPointInFrame([9; 9; 9], frame, 'p4', lvdData);

            d = VectorDotProductAngle(v1, v2, 'd', lvdData);
            cs = ThreePointCoordSystem(p1, p2, p3, 'cs', lvdData);

            testCase.verifyTrue(d.usesGeometricVector(v1));
            testCase.verifyTrue(d.usesGeometricVector(v2));
            testCase.verifyFalse(d.usesGeometricVector(v3));
            testCase.verifyFalse(d.usesGeometricPoint(p1));

            testCase.verifyTrue(cs.usesGeometricPoint(p1));
            testCase.verifyTrue(cs.usesGeometricPoint(p2));
            testCase.verifyTrue(cs.usesGeometricPoint(p3));
            testCase.verifyFalse(cs.usesGeometricPoint(p4));
            testCase.verifyFalse(cs.usesGeometricVector(v1));

            testCase.verifyFalse(d.isVehDependent());
            testCase.verifyFalse(cs.isVehDependent());

            geometry = lvdData.geometry;
            geometry.vectors.addVector(v1);
            geometry.points.addPoint(p2);
            geometry.angles.addAngle(d);
            geometry.coordSyses.addCoordSys(cs);

            testCase.verifyTrue(lvdData.usesGeometricVector(v1), 'Dot product in the set must mark its input vector as used');
            testCase.verifyTrue(lvdData.usesGeometricPoint(p2), 'Three point coord sys in the set must mark its points as used');
            testCase.verifyFalse(d.isInUse(lvdData));
            testCase.verifyFalse(cs.isInUse(lvdData));

            %Listbox strings name the inputs.
            testCase.verifyTrue(contains(d.getListboxStr(), 'v1') && contains(d.getListboxStr(), 'v2'));
            testCase.verifyTrue(contains(cs.getListboxStr(), 'p1') && contains(cs.getListboxStr(), 'p3'));
        end

        function secondBatchGeometryEnumsAreRegistered(testCase)
            testCase.verifyTrue(ismember('Dot Product of Two Vectors', GeometricAngleEnum.getListBoxStr()));
            testCase.verifyEqual(GeometricAngleEnum.getEnumForListboxStr('Dot Product of Two Vectors'), GeometricAngleEnum.VectorDotProduct);

            testCase.verifyTrue(ismember('Three Points', GeometricCoordSysEnum.getListBoxStr()));
            testCase.verifyEqual(GeometricCoordSysEnum.getEnumForListboxStr('Three Points'), GeometricCoordSysEnum.ThreePoint);

            dialogs = {'lvd_EditVectorDotProductAngleGUI_App', 'lvd_EditThreePointCoordSysGUI_App'};
            for i = 1:numel(dialogs)
                testCase.verifyEqual(exist(dialogs{i}, 'class'), 8, sprintf('Dialog class %s is missing from the path', dialogs{i}));
            end

            %The browsers that create these types must know about them.
            anglesCode = appdesigner.internal.codegeneration.getAppFileCode(which('lvd_EditGeometricAnglesGUI_App'));
            testCase.verifyTrue(contains(anglesCode, 'GeometricAngleEnum.VectorDotProduct') && contains(anglesCode, 'VectorDotProductAngle('), ...
                'The angle browser must be able to create a dot product');

            coordSysCode = appdesigner.internal.codegeneration.getAppFileCode(which('lvd_EditGeometricCoordSysGUI_App'));
            testCase.verifyTrue(contains(coordSysCode, 'GeometricCoordSysEnum.ThreePoint') && contains(coordSysCode, 'ThreePointCoordSystem('), ...
                'The coordinate system browser must be able to create a three point system');
        end

        %% ---------------------------------------------- Container smoke

        function lvdGeometryStoresAndRetrievesAddedPrimitives(testCase)
            %Not an oracle test: a smoke test that the LvdGeometry container
            %itself (as opposed to the primitives it holds) wires adds/gets
            %through to the underlying sets.
            lvdData = testCase.lvdFixture();
            frame = testCase.kerbinFrame;

            geometry = lvdData.geometry;
            numVectorsBefore = geometry.vectors.getNumVectors();

            v = FixedVectorInFrame([1; 2; 3], frame, 'smoke test vector', lvdData);
            geometry.vectors.addVector(v);

            testCase.verifyEqual(geometry.vectors.getNumVectors(), numVectorsBefore + 1, ...
                'LvdGeometry did not add the new vector to its vector set');

            retrieved = geometry.vectors.getVectorAtInd(numVectorsBefore + 1);
            testCase.verifyEqual(retrieved, v, ...
                'LvdGeometry did not retrieve the same vector object that was just added');

            geometry.vectors.removeVector(v);
            testCase.verifyEqual(geometry.vectors.getNumVectors(), numVectorsBefore, ...
                'LvdGeometry did not remove the vector that was just added');
        end
    end

    methods(Access=private)
        function lvdData = lvdFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function frame = munFrame(testCase)
            frame = testCase.mun.getBodyCenteredInertialFrame();
        end

        function [lvdData, entry] = propagatedFixture(testCase)
            %A default mission put in a 300 km circular orbit and coasted for
            %10 s on the two body propagator, so there is a real state log
            %entry to hand to Graphical Analysis task functions.
            lvdData = testCase.lvdFixture();
            lvdData.initStateModel.orbitModel = ...
                KeplerianElementSet(0, testCase.kerbin.radius + 300, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);

            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(10);
            evt.propagatorObj = evt.twoBodyPropagator;

            stateLog = lvdData.script.executeScript(false, evt, false, false, false, false, false);
            entry = stateLog.entries(end);
        end

        function [times, rv, rvFcn] = cubicEphemerisTable(~)
            %A per-component cubic position history (and its exact
            %derivative as velocity) sampled every 10 s.  Coefficient rows
            %are [c0 c1 c2 c3] for x, y, z.
            c = [ 700,   1.5, -0.02,  1e-4; ...
                 -200,  -0.7,  0.03, -2e-4; ...
                  150,   2.1,  0.01,  5e-5];

            rvFcn = @(t) [c(:,1) + c(:,2)*t + c(:,3)*t.^2 + c(:,4)*t.^3; ...
                          c(:,2) + 2*c(:,3)*t + 3*c(:,4)*t.^2];

            times = 0:10:60;
            rv = zeros(6, numel(times));
            for i = 1:numel(times)
                rv(:,i) = rvFcn(times(i));
            end
        end
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
