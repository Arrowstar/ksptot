classdef testLvdConstraints < matlab.unittest.TestCase
    % testLvdConstraints Unit tests for LVD constraint mathematical verification
    
    properties
        LvdData
        StateLog % LaunchVehicleStateLog
        StateLogEntry % LaunchVehicleStateLogEntry
    end
    
    methods(TestClassSetup)
        function setupData(testCase)
            % Load example strictly for the LVD superstructure (bodies, etc)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_MunarLanding.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
            lvdData = testCase.LvdData;
            
            % Synthesize a deterministic state
            cb = lvdData.initialState.centralBody;
            event = lvdData.script.getEventForInd(1);
            
            testCase.StateLogEntry = LaunchVehicleStateLogEntry();
            testCase.StateLogEntry.time = 1000; % UT
            testCase.StateLogEntry.position = [7000; 0; 0]; % km
            testCase.StateLogEntry.velocity = [0; 7.5; 0]; % km/s
            testCase.StateLogEntry.centralBody = cb;
            testCase.StateLogEntry.event = event;
            
            % Setup a minimal LV state
            testCase.StateLogEntry.lvState = LaunchVehicleState(lvdData.launchVehicle);
            
            % Setup stages and tanks for mass testing
            numStages = lvdData.launchVehicle.getNumStages();
            stgStates = LaunchVehicleStageState.empty(0, numStages);
            for i = 1:numStages
                lvStage = lvdData.launchVehicle.getStageForInd(i);
                stgStates(i) = LaunchVehicleStageState(lvStage);
                stgStates(i).active = true;
                
                % Add tanks with dummy mass
                for j = 1:length(lvStage.tanks)
                    tank = lvStage.tanks(j);
                    tState = LaunchVehicleTankState(stgStates(i));
                    tState.tank = tank;
                    tState.tankMass = 10.0; % 10 mT
                    stgStates(i).addTankState(tState);
                end
                
                % Add engines with dummy active state
                for j = 1:length(lvStage.engines)
                    engine = lvStage.engines(j);
                    eState = LaunchVehicleEngineState(stgStates(i));
                    eState.engine = engine;
                    eState.active = true;
                    stgStates(i).addEngineState(eState);
                end
            end
            testCase.StateLogEntry.stageStates = stgStates;
            
            % Setup steering model for angular testing
            % Steering angles are stored as RADIANS internally in the steering model
            sm = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            sm.setT0(1000);
            sm.setConstTerms(deg2rad(10), deg2rad(20), deg2rad(30)); % Roll=10, Pitch=20, Yaw=30 deg
            testCase.StateLogEntry.steeringModel = sm;
            
            % Setup Throttle Model
            throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            throttleModel.setT0(1000);
            throttleModel.setPolyTerms(0.5, 0, 0); % 50% throttle
            testCase.StateLogEntry.throttleModel = throttleModel;
            
            % Wrap in a StateLog
            testCase.StateLog = LaunchVehicleStateLog(lvdData);
            testCase.StateLog.appendStateLogEntries(testCase.StateLogEntry);
        end
    end
    
    methods(Test)
        function testPositionVelocityMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            stateLogEntry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            % Altitude
            expectedAlt = 7000 - stateLogEntry.centralBody.radius;
            constr = GenericMAConstraint(ConstraintEnum.Altitude.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedAlt, 'AbsTol', 1e-8);
            
            % Velocity Mag
            expectedVel = 7.5;
            constr = GenericMAConstraint(ConstraintEnum.VelVectMag.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedVel, 'AbsTol', 1e-8);
            
            % Radius
            expectedRadius = 7000;
            constr = GenericMAConstraint(ConstraintEnum.PosVectMag.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedRadius, 'AbsTol', 1e-8);
        end
        
        function testOrbitalElementMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            mu = entry.centralBody.gm;
            r = norm(entry.position);
            v = norm(entry.velocity);
            
            % Semi-major axis
            expectedSMA = 1 / (2/r - v^2/mu);
            constr = GenericMAConstraint(ConstraintEnum.SMA.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedSMA, 'AbsTol', 1e-8);
            
            % Eccentricity
            h = cross(entry.position, entry.velocity);
            e_vec = cross(entry.velocity, h)/mu - entry.position/r;
            expectedEcc = norm(e_vec);
            constr = GenericMAConstraint(ConstraintEnum.Ecc.name, event, 0, 1, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedEcc, 'AbsTol', 1e-8);
        end
        
        function testAngularOrientationMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            event = lvdData.script.getEventForInd(1);
            
            % These should match the constant terms (10, 20, 30) after the deg2rad fix
            % Pitch
            constr = PitchAngleConstraint(event, 0, 90);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, 20, 'AbsTol', 1e-6);
            
            % Roll
            constr = RollAngleConstraint(event, 0, 360);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, 10, 'AbsTol', 1e-6);
            
            % Yaw
            constr = YawAngleConstraint(event, 0, 360);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, 30, 'AbsTol', 1e-6);
        end
        
        function testMassMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            event = lvdData.script.getEventForInd(1);
            
            % Calculate expected total mass
            expectedDryMass = entry.getTotalVehicleDryMass();
            expectedPropMass = entry.getTotalVehiclePropMass();
            expectedTotalMass = expectedDryMass + expectedPropMass;
            
            % Total Mass Constraint
            constr = GenericMAConstraint(ConstraintEnum.TotalScMass.name, event, 0, 1000, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, expectedTotalMass, 'AbsTol', 1e-8);
            
            % Verify it's not zero
            testCase.verifyGreaterThan(value, 0);
        end
        
        function testGeometricConstraintsMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            event = lvdData.script.getEventForInd(1);
            
            % Vector Magnitude
            p1 = FixedPointInFrame([0; 0; 0], entry.centralBody.getBodyCenteredInertialFrame(), 'Origin', lvdData);
            p2 = FixedPointInFrame([1; 1; 1], entry.centralBody.getBodyCenteredInertialFrame(), 'Point', lvdData);
            vector = TwoPointVector(p1, p2, 'V', lvdData);
            
            expectedMag = sqrt(3);
            constr = GeometricVectorMagConstraint(vector, event, 0, 10);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, expectedMag, 'AbsTol', 1e-8);
        end
        
        function testCartesianMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            % PosX, PosY, PosZ
            constr = GenericMAConstraint(ConstraintEnum.PosX.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.position(1), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.PosY.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.position(2), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.PosZ.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.position(3), 'AbsTol', 1e-8);
            
            % VelX, VelY, VelZ
            constr = GenericMAConstraint(ConstraintEnum.VelX.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.velocity(1), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.VelY.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.velocity(2), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.VelZ.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, entry.velocity(3), 'AbsTol', 1e-8);
        end
        
        function testExtendedKeplerianMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            kepler = entry.getCartesianElementSetRepresentation().convertToKeplerianElementSet();
            
            expectedInc = rad2deg(kepler.inc);
            constr = GenericMAConstraint(ConstraintEnum.Inc.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedInc, 'AbsTol', 1e-8);
            
            expectedRAAN = rad2deg(kepler.raan);
            constr = GenericMAConstraint(ConstraintEnum.RAAN.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedRAAN, 'AbsTol', 1e-8);
            
            expectedArgPeri = rad2deg(kepler.arg);
            constr = GenericMAConstraint(ConstraintEnum.ArgPeri.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedArgPeri, 'AbsTol', 1e-8);
            
            expectedTrueAnom = rad2deg(kepler.tru);
            constr = GenericMAConstraint(ConstraintEnum.TrueAnom.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedTrueAnom, 'AbsTol', 1e-8);
        end
        
        function testGeographicMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            rVect = entry.position;
            vVect = entry.velocity;
            bodyInfo = entry.centralBody;
            
            geoElem = entry.getCartesianElementSetRepresentation().convertToGeographicElementSet();
            lat  = geoElem.lat;
            long = geoElem.long;
            rMag = norm(rVect);
            vMag = norm(vVect);
            fpa = asin(dot(rVect, vVect) / (rMag * vMag));
            
            constr = GenericMAConstraint(ConstraintEnum.Latitude.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, rad2deg(lat), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.Longitude.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, rad2deg(long), 'AbsTol', 1e-8);
            
            constr = GenericMAConstraint(ConstraintEnum.FlightPathAngle.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, rad2deg(fpa), 'AbsTol', 1e-8);
        end
        
        function testEnergyHyperbolicMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            celBodyData = lvdData.celBodyData;
            event = lvdData.script.getEventForInd(1);
            
            % C3 Energy
            r = norm(entry.position);
            v = norm(entry.velocity);
            mu = entry.centralBody.gm;
            expectedC3 = v^2 - 2*mu/r;
            
            constr = GenericMAConstraint(ConstraintEnum.C3Energy.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedC3, 'AbsTol', 1e-8);
            
            expectedHyperV = sqrt(expectedC3);
            constr = GenericMAConstraint(ConstraintEnum.HyperVelMag.name, event, 0, 100, [], [], KSPTOT_BodyInfo.empty(1,0));
            [~, ~, value] = constr.evalConstraint(stateLog, celBodyData);
            testCase.verifyEqual(value, expectedHyperV, 'AbsTol', 1e-8);
        end
        
        function testAeroAttitudeMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            event = lvdData.script.getEventForInd(1);
            
            ut = entry.time;
            rVect = entry.position;
            vVect = entry.velocity;
            bodyInfo = entry.centralBody;
            
            [bankAng, angOfAttack, angOfSideslip, ~] = entry.attitude.getAeroAngles(ut, rVect, vVect, bodyInfo);
            
            constr = AngleOfAttackConstraint(event, 0, 90);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(angOfAttack), 'AbsTol', 1e-8);
            
            constr = BankAngleConstraint(event, 0, 360);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(bankAng), 'AbsTol', 1e-8);
            
            constr = SideSlipAngleConstraint(event, 0, 90);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(angOfSideslip), 'AbsTol', 1e-8);
            
            [inertBankAng, inertAngOfAttack, inertAngOfSideslip] = entry.attitude.getInertialAeroAngles(ut, rVect, vVect, bodyInfo);
            
            constr = InertialAngleOfAttackConstraint(event, 0, 90);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(inertAngOfAttack), 'AbsTol', 1e-8);
            
            constr = InertialBankAngleConstraint(event, 0, 360);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(inertBankAng), 'AbsTol', 1e-8);
            
            constr = InertialSideSlipAngleConstraint(event, 0, 90);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, rad2deg(inertAngOfSideslip), 'AbsTol', 1e-8);
        end
        
        function testPropulsionMath(testCase)
            lvdData = testCase.LvdData;
            stateLog = testCase.StateLog;
            entry = testCase.StateLogEntry;
            event = lvdData.script.getEventForInd(1);
            
            ut = entry.time;
            rVect = entry.position;
            vVect = entry.velocity;
            bodyInfo = entry.centralBody;
            
            mass = entry.getTotalVehicleMass();
            expectedThrottleRaw = entry.throttleModel.getThrottleAtTime(ut, rVect, vVect, mass);
            expectedThrottlePct = expectedThrottleRaw * 100;
            
            constr = ThrottleConstraint(event, 0, 100);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, expectedThrottlePct, 'AbsTol', 1e-8);
            
            % We don't need body rotation for total thrust
            expectedThrust = TotalThrustConstraint.getTotalThrust(entry);
            
            constr = TotalThrustConstraint(event, 0, 1000);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, expectedThrust, 'AbsTol', 1e-8);
            
            g0 = 9.80665 / 1000;
            expectedT2W = expectedThrust / (mass * g0);
            
            constr = ThrustToWeightConstraint(event, 0, 1000);
            [~, ~, value] = constr.evalConstraint(stateLog, lvdData.celBodyData);
            testCase.verifyEqual(value, expectedT2W, 'AbsTol', 1e-8);
        end
    end
end
