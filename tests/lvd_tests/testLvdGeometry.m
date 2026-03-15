classdef testLvdGeometry < matlab.unittest.TestCase
    % testLvdGeometry Unit tests for LVD geometry components
    
    properties
        LvdData
        BaseFrame
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            % Load an example to get valid lvdData and celBodyData
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_ElecPowerExample.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
            
            % Use top-level BCI frame as a base for tests
            topBody = testCase.LvdData.celBodyData.getTopLevelBody();
            testCase.BaseFrame = topBody.getBodyCenteredInertialFrame();
        end
    end
    
    methods(Test)
        function testTwoPointVector(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            p1Pos = [1; 0; 0];
            p2Pos = [0; 1; 0];
            
            p1 = FixedPointInFrame(p1Pos, frame, 'P1', lvdData);
            p2 = FixedPointInFrame(p2Pos, frame, 'P2', lvdData);
            
            v12 = TwoPointVector(p1, p2, 'V12', lvdData);
            
            time = 0;
            vehElemSet = []; % Not needed for fixed points
            
            actualVect = v12.getVectorAtTime(time, vehElemSet, frame);
            expectedVect = p2Pos - p1Pos;
            
            testCase.verifyEqual(actualVect, expectedVect, 'AbsTol', 1e-12);
        end
        
        function testCrossProductVector(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            v1Dir = [1; 0; 0];
            v2Dir = [0; 1; 0];
            
            v1 = FixedVectorInFrame(v1Dir, frame, 'V1', lvdData);
            v2 = FixedVectorInFrame(v2Dir, frame, 'V2', lvdData);
            
            vCross = CrossProductVector(v1, v2, 'VCross', lvdData);
            
            actualVect = vCross.getVectorAtTime(0, [], frame);
            expectedVect = cross(v1Dir, v2Dir);
            
            testCase.verifyEqual(actualVect, expectedVect, 'AbsTol', 1e-12);
        end
        
        function testProjectedVector(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            vToProjDir = [1; 1; 1];
            vOntoDir = [1; 0; 0];
            
            vToProj = FixedVectorInFrame(vToProjDir, frame, 'VToProj', lvdData);
            vOnto = FixedVectorInFrame(vOntoDir, frame, 'VOnto', lvdData);
            
            vProj = ProjectedVector(vToProj, vOnto, 'VProj', lvdData);
            
            actualVect = vProj.getVectorAtTime(0, [], frame);
            % ProjectedVector in LVD is projection onto the PLANE normal to vOnto
            % (1,1,1) projected onto plane normal to (1,0,0) is (0,1,1)
            expectedVect = [0; 1; 1];
            
            testCase.verifyEqual(actualVect, expectedVect, 'AbsTol', 1e-12);
        end
        
        function testVectorDifferenceVector(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            v1Dir = [3; 4; 5];
            v2Dir = [1; 1; 1];
            
            v1 = FixedVectorInFrame(v1Dir, frame, 'V1', lvdData);
            v2 = FixedVectorInFrame(v2Dir, frame, 'V2', lvdData);
            
            vDiff = VectorDifferenceVector(v1, v2, 'VDiff', lvdData);
            
            actualVect = vDiff.getVectorAtTime(0, [], frame);
            % VectorDifferenceVector is vector2 - vector1
            expectedVect = v2Dir - v1Dir;
            
            testCase.verifyEqual(actualVect, expectedVect, 'AbsTol', 1e-12);
        end
        
        function testCelestialBodyPoint(testCase)
            lvdData = testCase.LvdData;
            cbd = lvdData.celBodyData;
            sun = cbd.getTopLevelBody();
            frame = sun.getBodyCenteredInertialFrame();
            
            pSun = CelestialBodyPoint(sun, 'SunPt');
            
            % Position of Sun in Sun BCI frame should be [0;0;0]
            actualPos = pSun.getPositionAtTime(0, [], frame);
            testCase.verifyEqual(actualPos.rVect, [0;0;0], 'AbsTol', 1e-10);
        end
        
        function testTwoVectorAngle(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            v1Dir = [1; 0; 0];
            v2Dir = [0; 1; 0];
            
            v1 = FixedVectorInFrame(v1Dir, frame, 'V1', lvdData);
            v2 = FixedVectorInFrame(v2Dir, frame, 'V2', lvdData);
            
            ang = TwoVectorAngle(v1, v2, 'Ang', lvdData);
            
            actualAngle = ang.getAngleAtTime(0, [], frame);
            expectedAngle = pi/2;
            
            testCase.verifyEqual(actualAngle, expectedAngle, 'AbsTol', 1e-12);
        end
        
        function testThreePointPlane(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            % XY Plane
            p1 = FixedPointInFrame([0;0;0], frame, 'P1', lvdData);
            p2 = FixedPointInFrame([1;0;0], frame, 'P2', lvdData);
            p3 = FixedPointInFrame([0;1;0], frame, 'P3', lvdData);
            
            plane = ThreePointPlane(p1, p2, p3, 'Plane', lvdData);
            
            actualNorm = plane.getPlaneNormVectAtTime(0, [], frame);
            expectedNorm = [0;0;1];
            
            testCase.verifyEqual(actualNorm, expectedNorm, 'AbsTol', 1e-12);
        end
        
        function testPointVectorPlane(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            p = FixedPointInFrame([0;0;0], frame, 'P', lvdData);
            v = FixedVectorInFrame([0;0;1], frame, 'V', lvdData);
            
            plane = PointVectorPlane(p, v, 'Plane', lvdData);
            
            actualNorm = plane.getPlaneNormVectAtTime(0, [], frame);
            expectedNorm = [0;0;1];
            
            testCase.verifyEqual(actualNorm, expectedNorm, 'AbsTol', 1e-12);
        end
        
        function testVectorPlaneAngle(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            % XY Plane
            p = FixedPointInFrame([0;0;0], frame, 'P', lvdData);
            normV = FixedVectorInFrame([0;0;1], frame, 'NormV', lvdData);
            plane = PointVectorPlane(p, normV, 'Plane', lvdData);
            
            % Vector at 45 deg to plane
            vDir = [1; 0; 1];
            v = FixedVectorInFrame(vDir, frame, 'V', lvdData);
            
            ang = VectorPlaneAngle(v, plane, 'Ang', lvdData);
            
            % Angle between (1,0,1) and XY plane should be 45 deg = pi/4
            actualAngle = ang.getAngleAtTime(0, [], frame);
            expectedAngle = pi/4;
            
            testCase.verifyEqual(actualAngle, expectedAngle, 'AbsTol', 1e-12);
        end
        
        function testAlignedConstrainedCoordSystem(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            % Align X with (1,0,0), Constrain Z with (0,1,0)
            % This should result in a coordinate system where:
            % X_new = (1,0,0)
            % Z_new = (0,1,0) (approx, ortho to X)
            % Y_new = Z_new x X_new = (0,1,0) x (1,0,0) = (0,0,-1)
            
            vAlign = FixedVectorInFrame([1;0;0], frame, 'AlignX', lvdData);
            vConstrain = FixedVectorInFrame([0;1;0], frame, 'ConstrainZ', lvdData);
            
            cs = AlignedConstrainedCoordSystem(vAlign, AlignedConstrainedCoordSysAxesEnum.PosX, ...
                                               vConstrain, AlignedConstrainedCoordSysAxesEnum.PosZ, ...
                                               'CS', lvdData);
            
            % Rotation matrix from CoordSys to Frame
            R_cs_to_frame = cs.getCoordSysAtTime(0, [], frame);
            
            % Column 1 is X axis in Frame: [1;0;0]
            testCase.verifyEqual(R_cs_to_frame(:,1), [1;0;0], 'AbsTol', 1e-12);
            % Column 3 is Z axis in Frame: [0;1;0]
            testCase.verifyEqual(R_cs_to_frame(:,3), [0;1;0], 'AbsTol', 1e-12);
            % Column 2 is Y axis in Frame: [0;0;-1]
            testCase.verifyEqual(R_cs_to_frame(:,2), [0;0;-1], 'AbsTol', 1e-12);
        end
        
        function testCoordSysPointRefFrame(testCase)
            lvdData = testCase.LvdData;
            frame = testCase.BaseFrame;
            
            % Origin at (10, 20, 30)
            pOrigin = FixedPointInFrame([10;20;30], frame, 'Origin', lvdData);
            
            % Identity coordinate system (Aligned X-X, Constrained Z-Z)
            vX = FixedVectorInFrame([1;0;0], frame, 'vX', lvdData);
            vZ = FixedVectorInFrame([0;0;1], frame, 'vZ', lvdData);
            cs = AlignedConstrainedCoordSystem(vX, AlignedConstrainedCoordSysAxesEnum.PosX, ...
                                               vZ, AlignedConstrainedCoordSysAxesEnum.PosZ, ...
                                               'CS', lvdData);
            
            refFrame = CoordSysPointRefFrame(cs, pOrigin, 'RefFrame', lvdData);
            
            [posOffset, velOffset, ~, rotMat] = refFrame.getRefFrameAtTime(0, [], frame);
            
            testCase.verifyEqual(posOffset, [10;20;30], 'AbsTol', 1e-12);
            testCase.verifyEqual(velOffset, [0;0;0], 'AbsTol', 1e-12);
            testCase.verifyEqual(rotMat, eye(3), 'AbsTol', 1e-12);
        end
    end
end
