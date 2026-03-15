classdef testLvdSensors < matlab.unittest.TestCase
    % testLvdSensors Unit tests for LVD Sensor and Visibility logic
    
    properties
        LvdData
        BaseFrame
        VehicleElemSet
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            % Load an example to get valid lvdData
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_ElecPowerExample.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
            
            % Setup a base inertial frame
            topBody = testCase.LvdData.celBodyData.getTopLevelBody();
            testCase.BaseFrame = topBody.getBodyCenteredInertialFrame();
            
            % Nominal vehicle element set
            testCase.VehicleElemSet = CartesianElementSet(0, [7000; 0; 0], [0; 7.5; 0], testCase.BaseFrame);
        end
    end
    
    methods(Test)
        function testFixedInVehicleFrameSteering(testCase)
            lvdData = testCase.LvdData;
            scElem = testCase.VehicleElemSet;
            frame = testCase.BaseFrame;
            
            % Identity DCM (Vehicle = Inertial for test)
            dcm = eye(3); 
            
            % Point boresight along Vehicle +X (RA=0, Dec=0)
            ra = 0;
            dec = 0;
            roll = 0;
            steering = FixedInVehicleFrameSensorSteeringModel(ra, dec, roll, lvdData);
            
            % Boresight in inertial should be [1;0;0] since DCM is identity
            actualBore = steering.getBoresightVector(0, scElem, dcm, frame);
            testCase.verifyEqual(actualBore, [1; 0; 0], 'AbsTol', 1e-12);
            
            % Rotate vehicle 90 deg about Z
            % R_v2i = [0 -1 0; 1 0 0; 0 0 1]
            dcmRot = [0, -1, 0; 1, 0, 0; 0, 0, 1];
            actualBoreRot = steering.getBoresightVector(0, scElem, dcmRot, frame);
            % [0 -1 0; 1 0 0; 0 0 1] * [1;0;0] = [0;1;0]
            testCase.verifyEqual(actualBoreRot, [0; 1; 0], 'AbsTol', 1e-12);
        end
        
        function testFixedInCoordSysSteering(testCase)
            lvdData = testCase.LvdData;
            scElem = testCase.VehicleElemSet;
            frame = testCase.BaseFrame;
            
            % Use a coordinate system that is rotated 90 deg from inertial
            vX = FixedVectorInFrame([0; 1; 0], frame, 'vX', lvdData); % CS X is Inertial Y
            vZ = FixedVectorInFrame([0; 0; 1], frame, 'vZ', lvdData); % CS Z is Inertial Z
            cs = AlignedConstrainedCoordSystem(vX, AlignedConstrainedCoordSysAxesEnum.PosX, ...
                                               vZ, AlignedConstrainedCoordSysAxesEnum.PosZ, ...
                                               'CS', lvdData);
            
            % Boresight along CS +X (RA=0, Dec=0)
            ra = 0;
            dec = 0;
            roll = 0;
            steering = FixedInCoordSysSensorSteeringModel(ra, dec, roll, cs, lvdData);
            
            % Boresight in inertial should be Inertial Y: [0;1;0]
            actualBore = steering.getBoresightVector(0, scElem, eye(3), frame);
            testCase.verifyEqual(actualBore, [0; 1; 0], 'AbsTol', 1e-12);
        end
        
        function testConicalSensorVisibility(testCase)
            lvdData = testCase.LvdData;
            scElem = testCase.VehicleElemSet;
            frame = testCase.BaseFrame;
            
            % Origin at [0,0,0]
            origin = FixedPointInFrame([0;0;0], frame, 'Origin', lvdData);
            % Steering along +X (RA=0, Dec=0)
            steering = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            
            % 10 deg half-angle sensor, 1000km range
            sensor = ConicalSensor('TestSensor', deg2rad(10), 1000, origin, steering, lvdData);
            sensorState = sensor.getInitialState();
            
            % Target 1: Inside cone (on boresight)
            p1 = FixedPointInFrame([500; 0; 0], frame, 'P1', lvdData);
            t1 = PointSensorTargetModel('T1', p1, lvdData);
            
            % Target 2: Outside cone (angle too large)
            p2 = FixedPointInFrame([500; 500; 0], frame, 'P2', lvdData);
            t2 = PointSensorTargetModel('T2', p2, lvdData);
            
            % Target 3: Outside cone (range too large)
            p3 = FixedPointInFrame([2000; 0; 0], frame, 'P3', lvdData);
            t3 = PointSensorTargetModel('T3', p3, lvdData);
            
            targets = [t1, t2, t3];
            [results, ~, ~] = sensor.evaluateSensorTargets(sensorState, targets, scElem, eye(3), KSPTOT_BodyInfo.empty(1,0), frame);
            
            testCase.verifyTrue(results(1).resultsBool, 'Target 1 should be visible');
            testCase.verifyFalse(results(2).resultsBool, 'Target 2 should be outside FOV');
            testCase.verifyFalse(results(3).resultsBool, 'Target 3 should be out of range');
        end
        
        function testConicalOccultation(testCase)
            lvdData = testCase.LvdData;
            scElem = testCase.VehicleElemSet;
            frame = testCase.BaseFrame;
            
            % Origin at [0,0,0]
            origin = FixedPointInFrame([0;0;0], frame, 'Origin', lvdData);
            steering = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('TestSensor', deg2rad(10), 10000, origin, steering, lvdData);
            sensorState = sensor.getInitialState();
            
            % Target at [5000, 0, 0]
            pTarget = FixedPointInFrame([5000; 0; 0], frame, 'Target', lvdData);
            target = PointSensorTargetModel('Target', pTarget, lvdData);
            
            % Occulting body in between at [2500, 0, 0] with radius 1000km
            % We'll hijack a body from the data and temporarily modify its radius if needed,
            % but it's safer to just move it or use its real radius.
            body = lvdData.celBodyData.getTopLevelBody(); 
            % Note: BodyCenter is usually at [0,0,0] for the top level body in its own frame.
            % Let's use a "fake" body position by using a different frame or just checking logic.
            % evaluateSensorTargets uses bodyInfo.getBodyCenteredInertialFrame() to get position.
            % This is tricky in a unit test because we can't easily move celestial bodies.
            
            % Alternative: Use a target that is definitely behind the body's real position.
            % If the body is at [0,0,0] and we are at [-5000, 0, 0], and target is at [5000, 0, 0].
            
            scElemOcc = CartesianElementSet(0, [-5000; 0; 0], [0;0;0], frame);
            originOcc = FixedPointInFrame([-5000; 0; 0], frame, 'Origin', lvdData);
            sensor = ConicalSensor('TestSensor', deg2rad(10), 20000, originOcc, steering, lvdData);
            sensorState = sensor.getInitialState();
            
            % Body at [0,0,0] (Top level body)
            % Body radius is already set in test case setup or data.
            % We will ensure it blocks the line of sight.
            body.radius = 1000; 
            
            [results, ~, ~] = sensor.evaluateSensorTargets(sensorState, target, scElemOcc, eye(3), body, frame);
            
            testCase.verifyFalse(results(1).resultsBool, 'Target should be occulted by the body');
            
            % Move target further to the side to clear the body 
            % Body radius 1000 at 5000km dist => half-angle ~11.3 deg.
            % Target at [5000; 2000; 0] from origin [-5000;0;0] => 10000 dist, 2000 height => angle ~11.3 deg.
            % Let's use 3000 height to be safe: angle ~16.7 deg.
            sensorState.angle = deg2rad(60);
            pClear = FixedPointInFrame([5000; 3000; 0], frame, 'Clear', lvdData);
            targetClear = PointSensorTargetModel('Clear', pClear, lvdData);
            
            [results, ~, ~] = sensor.evaluateSensorTargets(sensorState, targetClear, scElemOcc, eye(3), body, frame);
            
            [~, ~, ~, angleFromBoresight] = results(1).getBoresightRelativeAngles(sensorState, scElemOcc, eye(3));
            fprintf('Angle from boresight: %f deg (sensor half-angle: %f deg)\n', rad2deg(angleFromBoresight), rad2deg(sensorState.angle));
            
            testCase.verifyTrue(results(1).resultsBool, 'Target should be visible when not occulted');
        end
    end
end
