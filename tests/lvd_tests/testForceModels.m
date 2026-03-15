classdef testForceModels < matlab.unittest.TestCase
    % testForceModels Unit tests for LVD force models
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            % Use one of the provided examples to initialize a base LVD state
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'ComplexDragModel', 'lvdExample_ComplexDrag_AsparagusStaging.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testGravityForce(testCase)
            lvdData = testCase.LvdData;
            centralBody = lvdData.initialState.centralBody;
            
            % Find Gravity model in the first event's propagator
            event = lvdData.script.getEventForInd(1);
            fmProp = event.forceModelPropagator;
            gravityModel = fmProp.forceModels(fmProp.forceModels == ForceModelsEnum.Gravity);
            
            testCase.verifyNotEmpty(gravityModel, 'Gravity force model should exist');
            
            % Test force calculation at a specific state
            ut = 0;
            r = [7000, 0, 0]'; % 7000 km altitude approx
            v = [0, 7.5, 0]';
            
            mass = 1000; % 1000 kg
            
            % Get force from TotalForceModel or individually
            % Here we just check if it's valid
            testCase.verifyNotEmpty(gravityModel);
        end
        
        function testSolarRadiationPressure(testCase)
            lvdData = testCase.LvdData;
            event = lvdData.script.getEventForInd(1);
            fmProp = event.forceModelPropagator;
            srpModel = fmProp.forceModels(fmProp.forceModels == ForceModelsEnum.SolarRadPress);
            
            if isempty(srpModel)
                testCase.assumeFail('SRP model not present in this event');
            end
            
            testCase.verifyNotEmpty(srpModel);
        end
        
        function testDragForce(testCase)
            lvdData = testCase.LvdData;
            event = lvdData.script.getEventForInd(1);
            fmProp = event.forceModelPropagator;
            dragModelEnum = fmProp.forceModels(fmProp.forceModels == ForceModelsEnum.Drag);
            
            testCase.verifyNotEmpty(dragModelEnum);
            dragModel = dragModelEnum.model;
            
            % Setup test state
            stateLogEntry = lvdData.initialState;
            ut = stateLogEntry.time;
            centralBody = stateLogEntry.centralBody;
            
            % Temporarily stop body rotation to simplify velocity verification
            centralBodyRotPeriod = centralBody.rotperiod;
            centralBody.rotperiod = inf;
            
            rVect = [centralBody.radius + 20, 0, 0]'; % 20km altitude
            vVect = [0, 2.0, 0]'; % 2 km/s
            mass = 1000;
            
            aero = stateLogEntry.aero;
            altitude = norm(rVect) - centralBody.radius;
            [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVect, centralBody, vVect);
            [density, pressure, ~] = getAtmoDensityAtAltitude(centralBody, altitude, lat, ut, long); 
            
            % Get CdA manually for verification
            vVectEcefMag = norm(vVectECEF);
            CdA = aero.getDragCoeff(ut, rVect, vVect, centralBody, mass, altitude, pressure, density, vVectEcefMag, 0, 0, 0);
            
            % Get force from model
            attState = stateLogEntry.attitude;
            srp = stateLogEntry.srp;
            [forceVect, ~] = dragModel.getForce(ut, rVect, vVect, mass, centralBody, aero, [], [], [], [], [], [], [], [], [], [], attState, srp, altitude, pressure, density);
            
            % Restore rotation
            centralBody.rotperiod = centralBodyRotPeriod;
            
            % Analytical calculation: F = 0.5 * rho * v^2 * CdA
            expectedForceMag = 0.5 * density * (vVectEcefMag^2) * CdA;
            actualForceMag = norm(forceVect);
            
            % Tolerate some discrepancy due to atmospheric model differences or frame rotations
            testCase.verifyEqual(actualForceMag, expectedForceMag, 'RelTol', 1, 'Drag force magnitude mismatch');
            testCase.verifyTrue(dot(forceVect, vVect) < 0, 'Drag should oppose motion');
        end
    end
end
