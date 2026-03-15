classdef testSRP < matlab.unittest.TestCase
    % testSRP Unit tests for Solar Radiation Pressure force model
    
    properties
        LvdData
    end
    
    methods(TestClassSetup)
        function loadExampleData(testCase)
            examplePath = fullfile(fileparts(mfilename('fullpath')), '..', '..', 'examples', 'LaunchVehicleDesigner', 'lvdExample_SolarSailOrbitRaising.mat');
            data = load(examplePath);
            testCase.LvdData = data.lvdData;
        end
    end
    
    methods(Test)
        function testSolarRadiationPressure(testCase)
            lvdData = testCase.LvdData;
            % Find SRP model in the first event's propagator
            event = lvdData.script.getEventForInd(1);
            fmProp = event.forceModelPropagator;
            srpModelEnum = fmProp.forceModels(fmProp.forceModels == ForceModelsEnum.SolarRadPress);
            
            testCase.verifyNotEmpty(srpModelEnum, 'SRP model should exist in this example');
            
            srpModel = srpModelEnum.model;
            
            % Setup a state for SRP test
            stateLogEntry = lvdData.initialState;
            ut = stateLogEntry.time;
            centralBody = stateLogEntry.centralBody;
            rVect = [centralBody.radius + 500, 0, 0]'; 
            vVect = [0, 7.5, 0]';
            
            mass = stateLogEntry.getTotalVehicleMass();
            
            % Elements needed for getForce call (21 arguments)
            aero = stateLogEntry.aero;
            throttleModel = stateLogEntry.throttleModel;
            steeringModel = stateLogEntry.steeringModel;
            tankStates = stateLogEntry.getAllActiveTankStates();
            stageStates = stateLogEntry.stageStates;
            lvState = stateLogEntry.lvState;
            dryMass = stateLogEntry.getTotalVehicleDryMass();
            tankStatesMasses = zeros(size(tankStates));
            for i=1:length(tankStates)
                tankStatesMasses(i) = tankStates(i).tankMass;
            end
            thirdBodyGravity = stateLogEntry.thirdBodyGravity;
            pwrStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = zeros(size(pwrStorageStates));
            for i=1:length(pwrStorageStates)
                storageSoCs(i) = pwrStorageStates(i).getStateOfCharge();
            end
            
            srp = stateLogEntry.srp;
            altitude = norm(rVect) - centralBody.radius;
            pressure = 0;
            density = 0;
            
            % attState can be empty or mocked
            attState = []; 
            
            % Call getForce (21 arguments after obj)
            % ut, rVect, vVect, mass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, grav3Body, storageSoCs, powerStorageStates, attState, srp, altitude, pressure, density
            [forceVect, ~, ~] = srpModel.getForce(ut, rVect, vVect, mass, centralBody, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity, storageSoCs, pwrStorageStates, attState, srp, altitude, pressure, density);
            
            testCase.verifyClass(forceVect, 'double', 'Force should be a double array');
            testCase.verifySize(forceVect, [3, 1], 'Force should be 3x1');
            
            % In a solar sail example, force should be non-zero
            testCase.verifyTrue(norm(forceVect) > 0, 'SRP force should be non-zero for a solar sail');
        end
    end
end
