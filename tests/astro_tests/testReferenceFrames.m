classdef testReferenceFrames < matlab.unittest.TestCase
    % testReferenceFrames Tests for reference frame conversions and math
    
    properties
        celBodyData
        earth
        moon
        sun
        
        frames
    end
    
    methods(TestClassSetup)
        function setupEnvironment(testCase)
            % Create mock bodies
            % Sun (Top level)
            testCase.sun = KSPTOT_BodyInfo();
            testCase.sun.name = 'Sun';
            testCase.sun.id = 0;
            testCase.sun.gm = 1.1723328e+09;
            testCase.sun.radius = 261600;
            testCase.sun.sma = 0;
            testCase.sun.ecc = 0;
            testCase.sun.inc = 0;
            testCase.sun.raan = 0;
            testCase.sun.arg = 0;
            testCase.sun.mean = 0;
            testCase.sun.epoch = 0;
            testCase.sun.rotperiod = 100000;
            testCase.sun.rotini = 0;
            
            % Earth
            testCase.earth = KSPTOT_BodyInfo();
            testCase.earth.name = 'Earth';
            testCase.earth.id = 1;
            testCase.earth.gm = 3531.6;
            testCase.earth.radius = 600;
            testCase.earth.parentBodyInfo = testCase.sun;
            testCase.earth.parentid = 0;
            testCase.earth.sma = 149597870;
            testCase.earth.ecc = 0.0167;
            testCase.earth.inc = 0;
            testCase.earth.raan = 0;
            testCase.earth.arg = 0;
            testCase.earth.mean = 0;
            testCase.earth.epoch = 0;
            testCase.earth.rotperiod = 86400;
            testCase.earth.rotini = 0;
            
            % Moon
            testCase.moon = KSPTOT_BodyInfo();
            testCase.moon.name = 'Moon';
            testCase.moon.id = 2;
            testCase.moon.gm = 65.138398;
            testCase.moon.radius = 200;
            testCase.moon.parentBodyInfo = testCase.earth;
            testCase.moon.parentid = 1;
            testCase.moon.sma = 384400;
            testCase.moon.ecc = 0.0549;
            testCase.moon.inc = deg2rad(5.145);
            testCase.moon.raan = 0;
            testCase.moon.arg = 0;
            testCase.moon.mean = 0;
            testCase.moon.epoch = 0;
            testCase.moon.rotperiod = 2360591;
            testCase.moon.rotini = 0;
            
            % Create CelestialBodyData from struct
            s = struct();
            s.sun = testCase.sun;
            s.earth = testCase.earth;
            s.moon = testCase.moon;
            testCase.celBodyData = CelestialBodyData(s);
            
            % Ensure bodies point to the data container
            testCase.sun.celBodyData = testCase.celBodyData;
            testCase.earth.celBodyData = testCase.celBodyData;
            testCase.moon.celBodyData = testCase.celBodyData;
            
            % Initialize frames
            testCase.frames = {};
            testCase.frames{end+1} = GlobalBaseInertialFrame(testCase.celBodyData);
            testCase.frames{end+1} = BodyCenteredInertialFrame(testCase.earth, testCase.celBodyData);
            testCase.frames{end+1} = BodyCenteredInertialFrame(testCase.moon, testCase.celBodyData);
            testCase.frames{end+1} = BodyFixedFrame(testCase.earth, testCase.celBodyData);
            testCase.frames{end+1} = TwoBodyRotatingFrame(testCase.earth, testCase.moon, TwoBodyRotatingFrameOriginEnum.Primary, testCase.celBodyData);
            testCase.frames{end+1} = TwoBodyRotatingFrame(testCase.earth, testCase.moon, TwoBodyRotatingFrameOriginEnum.Secondary, testCase.celBodyData);
        end
    end
    
    methods(Test)
        function testPairwiseConversions(testCase)
            % Test conversion between every pair of frames
            ut = 1000;
            rVect = [1000; 2000; 3000];
            vVect = [1; 2; 3];
            
            for i = 1:length(testCase.frames)
                frameA = testCase.frames{i};
                stateA = CartesianElementSet(ut, rVect, vVect, frameA);
                
                for j = 1:length(testCase.frames)
                    frameB = testCase.frames{j};
                    
                    % Convert A -> B
                    stateB = stateA.convertToFrame(frameB);
                    
                    % Convert B -> A
                    stateA2 = stateB.convertToFrame(frameA);
                    
                    % Verify round-trip
                    testCase.verifyEqual(stateA2.rVect, stateA.rVect, 'AbsTol', 1e-7, ...
                        sprintf('Position mismatch converting %s -> %s -> %s', frameA.getNameStr(), frameB.getNameStr(), frameA.getNameStr()));
                    testCase.verifyEqual(stateA2.vVect, stateA.vVect, 'AbsTol', 1e-7, ...
                        sprintf('Velocity mismatch converting %s -> %s -> %s', frameA.getNameStr(), frameB.getNameStr(), frameA.getNameStr()));
                end
            end
        end
        
        function testMathAnalytical(testCase)
            % Test the actual math in convertToFrame using a custom rotating frame
            ut = 500;
            
            % Define frame parameters
            % Let's say the frame is at [100, 200, 300] relative to inertial origin
            % moving at [10, 20, 30] km/s.
            % It is rotating around Z-axis at 0.1 rad/s.
            posO = [100; 200; 300];
            velO = [10; 20; 30];
            omega = [0; 0; 0.1];
            
            % Rotation matrix at time 500
            theta = 0.1 * ut;
            R = [cos(theta) -sin(theta) 0;
                 sin(theta)  cos(theta) 0;
                 0           0          1];
            
            mockFrame = MockRotatingFrame(posO, velO, omega, R);
            
            % State in mock frame
            rF = [50; 0; 0];
            vF = [0; 5; 0];
            
            stateF = CartesianElementSet(ut, rF, vF, mockFrame);
            
            % Convert to Global Inertial
            inertialFrame = GlobalBaseInertialFrame(testCase.celBodyData);
            stateI = stateF.convertToFrame(inertialFrame);
            
            % Analytical conversion:
            % rI = posO + R * rF
            rI_expected = posO + R * rF;
            
            % vI = velO + R * (vF + cross(omega, rF))
            % Note: omega in convertToFrame is usually angVelWrtOrigin which is 
            % the angular velocity of the frame w.r.t. the inertial origin, 
            % EXPRESSED IN THE FRAME coordinates (usually, check AbstractElementSet)
            % Wait, let's check AbstractElementSet.m lines 110-113:
            % vVect2 = velOffsetOrigin12 + R_FrameToUse_to_GlobalInertial * (vVect1 + cross(angVelWrtOrigin12, vVect1));
            % Wait, cross(omega, vVect1)? No, cross(omega, rVect1).
            % Looking at AbstractElementSet.m:
            % 110: vVect2 = velOffsetOrigin12 +  R_FrameToUse_to_GlobalInertial * (vVect1 + cross(angVelWrtOrigin12, rVect1));
            
            vI_expected = velO + R * (vF + cross(omega, rF));
            
            testCase.verifyEqual(stateI.rVect, rI_expected, 'AbsTol', 1e-10);
            testCase.verifyEqual(stateI.vVect, vI_expected, 'AbsTol', 1e-10);
            
            % Now test Inverse conversion from Inertial back to Mock
            stateF2 = stateI.convertToFrame(mockFrame);
            
            testCase.verifyEqual(stateF2.rVect, rF, 'AbsTol', 1e-10);
            testCase.verifyEqual(stateF2.vVect, vF, 'AbsTol', 1e-10);
        end
    end
end
