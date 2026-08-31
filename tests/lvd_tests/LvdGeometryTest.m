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
    end
end
