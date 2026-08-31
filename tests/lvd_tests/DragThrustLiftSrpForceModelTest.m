classdef DragThrustLiftSrpForceModelTest < KsptotTestCase
    %DragThrustLiftSrpForceModelTest LVD Drag, Lift, Thrust, and SRP force models.
    %
    % Each model is checked against independently re-derived closed-form
    % physics rather than against a stored value or the model's own helper
    % objects.
    %
    % Drag: uses ConstantDragCoeffModel (CdA is just a fixed number) so the
    % test can compare directly to -1/2*rho*v^2*CdA without re-deriving any
    % Cd curve.  DragCoeffModel wraps that with a globalDragMultiplier that
    % defaults to 0.8, so the fixture pins it to 1 to keep the oracle a pure
    % textbook drag equation.  Drag's coefficient model does not use total
    % angle of attack, so the real (rotating) Kerbin body is used directly.
    %
    % Lift: uses the library's default CylindricalLiftModel(1,1).  Its
    % ClS depends on totalAoA, which in turn depends on the body-fixed
    % frame lining up with the body-centered-inertial frame.  That only
    % holds exactly when the body does not rotate at all, i.e.
    % rotperiod = Inf *and* rotini = 0 (getBodySpinAngle_alg.m adds
    % deg2rad(rotini) even when rotperiod is infinite).  Under that
    % condition totalAoA collapses to acos(dot(normalize(vVect), bodyX)),
    % which is re-derived here from scratch (not by calling
    % computeAeroAnglesFromFrameBodyAxes).  The lift-coefficient curve
    % control points are transcribed once from LiftCoefficientCurves.m and
    % evaluated independently with a from-scratch clamped interp1 call
    % (griddedInterpolant vs. interp1: same textbook linear interpolation,
    % different code path).
    %
    % Thrust: LaunchVehicle.createDefaultLaunchVehicle's single-engine
    % vehicle has a vacuum thrust curve control point of exactly 215 kN at
    % 0 kPa, and a body-frame thrust vector of [1;0;0].  Above the
    % atmosphere the ambient pressure is exactly zero, so with the
    % throttle pinned to a constant 1 the expected force is exactly
    % dcm * (215*[1;0;0]/1000) mT*km/s^2 -- no curve evaluation needed on
    % the test side at all.
    %
    % SRP: SphericalSolarRadiationPressureModel detours through the Sun's
    % own body-centered-inertial frame before rotating the force into the
    % target body's BCI frame.  Composing those two rotations shows the
    % Sun-frame rotation cancels out exactly, so the oracle below works
    % entirely in "global inertial" axes (the common axes underlying every
    % body's BCI frame) and only performs the one physically-meaningful
    % final rotation.  A near-surface point on the far side of Kerbin from
    % the Sun is used to independently exercise the eclipse/line-of-sight
    % cutoff (force must be exactly zero).

    methods(Test)

        %% ------------------------------------------------------- Drag

        function dragForceMatchesHalfRhoVSquaredCdA(testCase)
            bodyInfo = testCase.kerbin;

            aero = LaunchVehicleAeroState();
            CdA = 2.5; %m^2, arbitrary fixed drag area
            aero.dragCoeffModel.dragCoeffObj = ConstantDragCoeffModel(CdA);
            aero.dragCoeffModel.globalDragMultiplier = 1; %strip DragCoeffModel's default 0.8 fudge factor

            ut = 0;
            altitude = 10; %km, comfortably inside Kerbin's atmosphere
            rVect = (bodyInfo.radius + altitude) * normVector([1; 0.4; 0.2]);
            vVect = [0.4; -1.6; 0.3]; %km/s

            forceVect = testCase.callAeroForce(DragForceModel(), rVect, vVect, aero, ...
                LaunchVehicleAttitudeState(), bodyInfo);

            [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
            density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long);

            vVectECEFMag = norm(vVectECEF);
            Fd = -(1/2) * density * vVectECEFMag^2 * CdA;

            R_ecef_to_bci = testCase.ecefToBciRotMat(bodyInfo, ut);
            expected = R_ecef_to_bci * (Fd * normVector(vVectECEF));

            testCase.verifyVectorEqual(forceVect, expected, 1e-9 * norm(expected), ...
                'Drag force does not match -1/2*rho*v^2*CdA along the ECEF relative wind');
        end

        function dragForceIsZeroAboveTheAtmosphere(testCase)
            bodyInfo = testCase.kerbin;
            aero = LaunchVehicleAeroState();
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 50) * normVector([1; 0.2; 0.3]);

            forceVect = testCase.callAeroForce(DragForceModel(), rVect, [0.5; 1.5; 0.2], aero, ...
                LaunchVehicleAttitudeState(), bodyInfo);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'Drag is non-zero above the sensible atmosphere');
        end

        %% ------------------------------------------------------- Lift

        function liftForceMatchesClosedFormCylindricalModel(testCase)
            %Non-rotating-body trick: rotperiod = Inf AND rotini = 0 makes
            %the body-fixed frame coincide exactly with the body-centered
            %inertial frame, which is what collapses totalAoA down to a
            %plain dot product between velocity and body-X.
            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;

            aero = LaunchVehicleAeroState(); %default liftCoeffObj = CylindricalLiftModel(1,1)

            ut = 0;
            altitude = 10; %km, inside the atmosphere
            rVect = (bodyInfo.radius + altitude) * normVector([0.6; -0.3; 0.7]);
            vVect = [1; 1.7320508075688772; 0]; %60 deg off +X, |v| = 2 km/s

            attState = LaunchVehicleAttitudeState(eye(3)); %bodyX = [1;0;0]

            forceVect = testCase.callAeroForce(LiftForceModel(), rVect, vVect, aero, attState, bodyInfo);

            bodyX = attState.bodyX;
            totalAoA = acos(dot(normVector(vVect), bodyX));

            [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
            [density, pressureKPA] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long);

            cylinderLength = 1;
            cylinderRadius = 1;
            circleArea = pi * cylinderRadius^2;
            flatPlateArea = cylinderLength * 2 * cylinderRadius;
            area = cos(totalAoA) * circleArea + sin(totalAoA) * flatPlateArea;

            %Control points transcribed from LiftCoefficientCurves.m,
            %evaluated here with a from-scratch clamped interp1 call
            %rather than the source's griddedInterpolant object.
            giLiftX = [0, 0.309017, 0.5877852, 0.7071068, 0.8910065, 1];
            giLiftY = [0, 0.5877852, 0.9510565, 1, 0.809017, 0];
            machX = [0.3, 0.8, 1, 5, 25];
            machY = [0.167, 0.167, 0.125, 0.0625, 0.05];

            giLift = testCase.clampedInterp1(giLiftX, giLiftY, sin(totalAoA));

            vVectECEFMag = norm(vVectECEF);
            speedSound = sqrt(1.4 * (pressureKPA * 1000) / density); %m/s
            machNum = (vVectECEFMag * 1000) / speedSound;
            machLift = testCase.clampedInterp1(machX, machY, machNum);

            ClS = giLift * machLift * area;
            FL = (1/2) * density * vVectECEFMag^2 * ClS;

            %Non-rotating-body trick => ECEF frame coincides with BCI, so
            %no extra rotation is needed for the direction either.
            v1 = cross(vVectECEF, bodyX);
            liftDir = normVector(cross(v1, bodyX));
            expected = FL * liftDir;

            testCase.verifyVectorEqual(forceVect, expected, 1e-6 * max(norm(expected), 1e-12), ...
                'Lift force does not match the closed-form cylindrical lift model');
        end

        function liftForceIsZeroAboveTheAtmosphere(testCase)
            bodyInfo = testCase.kerbin;
            aero = LaunchVehicleAeroState();
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 50) * normVector([1; 0.2; 0.3]);

            forceVect = testCase.callAeroForce(LiftForceModel(), rVect, [0.5; 1.5; 0.2], aero, ...
                LaunchVehicleAttitudeState(), bodyInfo);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'Lift is non-zero above the sensible atmosphere');
        end

        %% ----------------------------------------------------- Thrust

        function thrustForceMatchesVacuumThrustCurve(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            throttleModel.setPolyTerms(1, 0, 0); %constant full throttle

            bodyInfo = entry.centralBody;
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1; 0.2; 0.3]); %vacuum: pressure = 0
            vVect = [0.5; 1.6; 0.1];
            dcm = testCase.arbitraryRotationMatrix();
            attState = LaunchVehicleAttitudeState(dcm);

            tankStates = entry.getAllActiveTankStates();
            tankStatesMasses = [tankStates.tankMass];
            dryMass = entry.getTotalVehicleDryMass();
            powerStorageStates = entry.getAllActivePwrStorageStates();

            forceVect = ThrustForceModel().getForce(0, rVect, vVect, [], bodyInfo, [], ...
                throttleModel, entry.steeringModel, tankStates, entry.stageStates, entry.lvState, ...
                dryMass, tankStatesMasses, [], [], powerStorageStates, attState, []);

            %LaunchVehicle.createDefaultLaunchVehicle's single engine has a
            %ThrustPressureCurve control point of exactly (0 kPa, 215 kN),
            %and LaunchVehicleEngine's default bodyFrameThrustVect is
            %[1;0;0]; both are re-derived from source, not assumed.
            vacThrustKN = 215;
            bodyFrameThrustVect = [1; 0; 0];
            expected = dcm * ((vacThrustKN * bodyFrameThrustVect) / 1000); %kN -> mT*km/s^2

            testCase.verifyVectorEqual(forceVect, expected, 1e-9 * norm(expected), ...
                'Thrust force does not match the vacuum thrust curve rotated into the vehicle attitude');
        end

        function thrustForceIsZeroWithZeroThrottle(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            throttleModel = ThrottlePolyModel.getDefaultThrottleModel();
            throttleModel.setPolyTerms(0, 0, 0); %zero throttle

            bodyInfo = entry.centralBody;
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1; 0.2; 0.3]);
            vVect = [0.5; 1.6; 0.1];
            attState = LaunchVehicleAttitudeState(testCase.arbitraryRotationMatrix());

            tankStates = entry.getAllActiveTankStates();
            tankStatesMasses = [tankStates.tankMass];
            dryMass = entry.getTotalVehicleDryMass();
            powerStorageStates = entry.getAllActivePwrStorageStates();

            forceVect = ThrustForceModel().getForce(0, rVect, vVect, [], bodyInfo, [], ...
                throttleModel, entry.steeringModel, tankStates, entry.stageStates, entry.lvState, ...
                dryMass, tankStatesMasses, [], [], powerStorageStates, attState, []);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'Thrust force is non-zero at zero throttle');
        end

        %% --------------------------------------------------------- SRP

        function srpForceMatchesInverseSquareLawWhenSunIsVisible(testCase)
            bodyInfo = testCase.kerbin;
            ut = 0;

            [R1, kerbinPosWrtSun, dirToSunInBCI] = testCase.sunDirectionInBci(bodyInfo, ut);

            rVect = (bodyInfo.radius + 50) * dirToSunInBCI; %near-surface, facing the sun
            vVect = [0; 1; 0];

            srp = LaunchVehicleSolarRadPressState(); %defaults: 1367 W/m^2 @ 1 AU, cR=1, area=1 m^2
            steeringModel = TestIdentitySteeringModel();

            forceVect = testCase.callSrp(rVect, vVect, srp, steeringModel, bodyInfo);

            scPosGlobal = kerbinPosWrtSun + R1 * rVect;
            rSun2ScNormMeter = norm(scPosGlobal) * 1000;

            refSolarFlux = 1367;
            solarFluxRefDist = 13599840.256;
            cR = 1;
            area = 1;
            speedOfLight = 299792458;

            sunPower = 4 * pi * (solarFluxRefDist * 1000)^2 * refSolarFlux;
            solarFlux = sunPower / (4 * pi * rSun2ScNormMeter^2);
            pSF = solarFlux / speedOfLight;
            fSRMagMtKm = pSF * cR * area / 1e6;

            expected = fSRMagMtKm * (R1' * normVector(scPosGlobal));

            testCase.verifyVectorEqual(forceVect, expected, 1e-6 * norm(expected), ...
                'SRP force does not match the inverse-square spherical model when the sun is visible');
        end

        function srpForceIsZeroWhenTheBodyBlocksTheSun(testCase)
            bodyInfo = testCase.kerbin;
            ut = 0;

            [~, ~, dirToSunInBCI] = testCase.sunDirectionInBci(bodyInfo, ut);

            rVect = -(bodyInfo.radius + 50) * dirToSunInBCI; %near-surface, opposite the sun
            vVect = [0; 1; 0];

            srp = LaunchVehicleSolarRadPressState();
            steeringModel = TestIdentitySteeringModel();

            forceVect = testCase.callSrp(rVect, vVect, srp, steeringModel, bodyInfo);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'SRP force is non-zero when Kerbin itself blocks the line of sight to the sun');
        end
    end

    methods(Access=private)

        function [forceVect, tankMdots, ecStgDots] = callAeroForce(testCase, model, rVect, vVect, aero, attState, bodyInfo) %#ok<INUSL>
            mass = 10;
            [forceVect, tankMdots, ecStgDots] = model.getForce(0, rVect, vVect, mass, bodyInfo, aero, ...
                [], [], [], [], [], [], [], [], [], [], attState, []);
        end

        function forceVect = callSrp(testCase, rVect, vVect, srp, steeringModel, bodyInfo) %#ok<INUSL>
            mass = 10;
            forceVect = SolarRadPressForceModel().getForce(0, rVect, vVect, mass, bodyInfo, ...
                [], [], steeringModel, [], [], [], [], [], [], [], [], [], srp);
        end

        function R_ecef_to_bci = ecefToBciRotMat(testCase, bodyInfo, ut) %#ok<INUSL>
            bff = bodyInfo.getBodyFixedFrame();
            bci = bodyInfo.getBodyCenteredInertialFrame();

            R_ecef_to_global = bff.getRotMatToInertialAtTime(ut);
            R_bci_to_global = bci.getRotMatToInertialAtTime(ut);

            R_ecef_to_bci = R_bci_to_global' * R_ecef_to_global;
        end

        function [R1, bodyPosWrtSun, dirToSunInBci] = sunDirectionInBci(testCase, bodyInfo, ut)
            R1 = bodyInfo.getBodyCenteredInertialFrame().getRotMatToInertialAtTime(ut);
            bodyPosWrtSun = getPositOfBodyWRTSun(ut, bodyInfo, testCase.celBodyData);
            dirToSunInBci = normVector(R1' * (-bodyPosWrtSun));
        end

        function yq = clampedInterp1(~, x, y, xq)
            %clampedInterp1 Linear interpolation with nearest-value
            %extrapolation, mirroring griddedInterpolant(x,y,'linear',
            %'nearest') using a different MATLAB library function.
            xqClamped = min(max(xq, x(1)), x(end));
            yq = interp1(x, y, xqClamped, 'linear');
        end

        function R = arbitraryRotationMatrix(~)
            %arbitraryRotationMatrix A fixed, non-trivial orthonormal DCM
            %(composition of two axis rotations) used to confirm that the
            %thrust force is actually rotated by the vehicle attitude
            %rather than left in the body frame.
            theta = deg2rad(35);
            phi = deg2rad(-20);

            Rz = [cos(theta), -sin(theta), 0; sin(theta), cos(theta), 0; 0, 0, 1];
            Rx = [1, 0, 0; 0, cos(phi), -sin(phi); 0, sin(phi), cos(phi)];

            R = Rz * Rx;
        end
    end
end
