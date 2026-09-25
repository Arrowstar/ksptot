classdef TabulatedLiftModelTest < KsptotTestCase
    %TabulatedLiftModelTest D4 user-tabulated Cl*S(Mach,AoA,sideslip) lift model.
    %
    % CSV rows: mach, AoA_deg, sideslip_deg, ClS_m2 (no header), mirroring
    % KosDragCoeffientModel storage (sortrows [3 2 1], unique axes,
    % griddedInterpolant linear/nearest). ClS is stored directly.

    methods(Test)
        function tableLoadsAxesAndInterpolates(testCase)
            f = testCase.writeLiftCsv([0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                                       1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0]);
            model = UserTabulatedLiftModel(f);

            testCase.verifyEqual(model.machNum, [0;1], 'AbsTol', 0, 'Mach axis mismatch');
            testCase.verifyEqual(rad2deg(model.aoa), [0;10], 'AbsTol', 1e-12, 'AoA axis mismatch');
            testCase.verifyEqual(rad2deg(model.sideslip), [0;5], 'AbsTol', 1e-12, 'Sideslip axis mismatch');

            %node-exact lookups through the interpolant
            testCase.verifyEqual(model.giClS(0, 0, 0), 1.0, 'AbsTol', 1e-12, 'Node lookup failed');
            testCase.verifyEqual(model.giClS(1, deg2rad(10), deg2rad(5)), 8.0, 'AbsTol', 1e-12, 'Node lookup failed');

            %midpoint of a linear table interpolates linearly
            testCase.verifyEqual(model.giClS(0.5, deg2rad(5), deg2rad(2.5)), 4.5, 'AbsTol', 1e-9, ...
                'Midpoint interpolation does not match linear blend');
        end

        function constantTableGivesConstantClSThroughLiftForce(testCase)
            %Non-rotating-body trick (same as DragThrustLiftSrpForceModelTest):
            %rotperiod = Inf AND rotini = 0 collapses ECEF onto BCI.
            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;

            ClSConst = 3.0;
            f = testCase.writeLiftCsv([0 0 0 ClSConst; 0 0 5 ClSConst; 0 10 0 ClSConst; 0 10 5 ClSConst; ...
                                       1 0 0 ClSConst; 1 0 5 ClSConst; 1 10 0 ClSConst; 1 10 5 ClSConst]);
            aero = LaunchVehicleAeroState();
            aero.liftCoeffModel.liftCoeffObj = UserTabulatedLiftModel(f);

            ut = 0;
            altitude = 10; %km, inside the atmosphere
            rVect = (bodyInfo.radius + altitude) * normVector([0.6; -0.3; 0.7]);
            vVect = [1; 1.7320508075688772; 0]; %60 deg off +X, |v| = 2 km/s
            attState = LaunchVehicleAttitudeState(eye(3)); %bodyX = [1;0;0]

            forceVect = testCase.callLiftForce(rVect, vVect, aero, attState, bodyInfo);

            [lat, long, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
            density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long);

            vVectECEFMag = norm(vVectECEF);
            FL = (1/2) * density * vVectECEFMag^2 * ClSConst;

            %ECEF == BCI here, so no frame rotation is needed for the direction.
            bodyX = attState.bodyX;
            liftDir = normVector(cross(cross(vVectECEF, bodyX), bodyX));
            expected = FL * liftDir;

            testCase.verifyVectorEqual(forceVect, expected, 1e-6 * max(norm(expected), 1e-12), ...
                'Tabulated lift force does not match 1/2*rho*v^2*ClS along the lift direction');
        end

        function zeroDensityGivesZeroClS(testCase)
            f = testCase.writeLiftCsv([0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                                       1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0]);
            model = UserTabulatedLiftModel(f);

            bodyInfo = testCase.kerbin;
            attState = LaunchVehicleAttitudeState(eye(3));
            rVect = (bodyInfo.radius + 10) * normVector([1; 0.2; 0.3]);
            vVect = [0.5; 1.5; 0.2];

            [ClS, ~] = model.getLiftCoeffAndDir(0, rVect, vVect, bodyInfo, 10, 10, 101, 0, [0;0;0], attState);

            testCase.verifyEqual(ClS, 0, 'AbsTol', 0, 'ClS must be zero when density is zero');
        end

        function liftForceIsZeroAboveTheAtmosphere(testCase)
            f = testCase.writeLiftCsv([0 0 0 2.0; 0 0 5 2.0; 0 10 0 2.0; 0 10 5 2.0; ...
                                       1 0 0 4.0; 1 0 5 4.0; 1 10 0 4.0; 1 10 5 4.0]);
            aero = LaunchVehicleAeroState();
            aero.liftCoeffModel.liftCoeffObj = UserTabulatedLiftModel(f);

            bodyInfo = testCase.kerbin;
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 50) * normVector([1; 0.2; 0.3]);

            forceVect = testCase.callLiftForce(rVect, [0.5; 1.5; 0.2], aero, ...
                LaunchVehicleAttitudeState(), bodyInfo);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'Tabulated lift is non-zero above the sensible atmosphere');
        end

        function defaultContainerCarriesTabularModel(testCase)
            aero = LaunchVehicleAeroState();
            testCase.verifyFalse(isempty(aero.liftCoeffModel.tabularLiftModel), ...
                'LiftCoeffModel must always carry a tabular lift model (loadobj backfill)');
            testCase.verifyTrue(isa(aero.liftCoeffModel.tabularLiftModel, 'UserTabulatedLiftModel'), ...
                'Tabular slot has the wrong class');
        end

        function shuffledCsvRowsLoadIdentically(testCase)
            rows = [0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                    1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0];
            model = UserTabulatedLiftModel(testCase.writeLiftCsv(rows));
            shuffled = UserTabulatedLiftModel(testCase.writeLiftCsv(rows([5 2 8 1 6 3 7 4], :)));

            %reshape() assumes Mach-major/AoA-middle/sideslip-minor order, so
            %the sortrows step in createGriddedInterpFromFile is load-bearing.
            testCase.verifyEqual(shuffled.machNum, model.machNum, 'AbsTol', 0, 'Shuffled rows changed the Mach axis');
            testCase.verifyEqual(shuffled.giClS(0.5, deg2rad(5), deg2rad(2.5)), 4.5, 'AbsTol', 1e-9, ...
                'Shuffled rows changed the interpolation');
        end

        function extrapolationSnapsToNearestNode(testCase)
            rows = [0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                    1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0];
            model = UserTabulatedLiftModel(testCase.writeLiftCsv(rows));

            %griddedInterpolant "nearest" extrapolation returns the nearest
            %grid-node value (not a per-dimension clamp + interpolate), so
            %out-of-envelope flight holds the edge node.  Mach dominates the
            %distance, making these queries unambiguous.
            testCase.verifyEqual(model.giClS(99, 0, 0), 5.0, 'AbsTol', 0, ...
                'High-side Mach must hold the Mach-1 edge node');
            testCase.verifyEqual(model.giClS(-1, deg2rad(10), deg2rad(5)), 4.0, 'AbsTol', 0, ...
                'Low-side Mach must hold the Mach-0 edge node');
        end

        function emptyModelEvaluatesToZeroClS(testCase)
            %Selecting the model but picking no file must propagate safely.
            model = UserTabulatedLiftModel('');

            bodyInfo = testCase.kerbin;
            attState = LaunchVehicleAttitudeState(eye(3));
            rVect = (bodyInfo.radius + 10) * normVector([1; 0.2; 0.3]);

            [ClS, liftDir] = model.getLiftCoeffAndDir(0, rVect, [0.5; 1.5; 0.2], bodyInfo, 10, 10, 101, 1, [0.4; -0.1; 0.2], attState);

            testCase.verifyEqual(ClS, 0, 'AbsTol', 0, 'Empty table must give ClS = 0');
            testCase.verifyEqual(norm(liftDir), 1, 'AbsTol', 1e-12, 'Lift direction must stay a unit vector');
        end

        function attitudeChangeMovesTheTableLookup(testCase)
            %All table nodes differ, so any change in the resolved
            %(Mach, AoA, sideslip) moves the lookup.  Proves attitude flows
            %into the table end to end.  Non-rotating-body trick makes the
            %geometry exact (cf. constantTableGivesConstantClSThroughLiftForce).
            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;

            rows = [0 0 0 1.0; 0 0 5 2.0; 0 10 0 3.0; 0 10 5 4.0; ...
                    1 0 0 5.0; 1 0 5 6.0; 1 10 0 7.0; 1 10 5 8.0];
            model = UserTabulatedLiftModel(testCase.writeLiftCsv(rows));

            attState = LaunchVehicleAttitudeState(eye(3)); %bodyX = [1;0;0]
            rVect = (bodyInfo.radius + 10) * normVector([0.6; -0.3; 0.7]);

            [ClSAligned, ~] = model.getLiftCoeffAndDir(0, rVect, [2; 0; 0], bodyInfo, 10, 10, 101, 1, [1; 0; 0], attState);
            [ClSOff, ~] = model.getLiftCoeffAndDir(0, rVect, [2; 0.8; 0.6], bodyInfo, 10, 10, 101, 1, [1; 0; 0], attState);

            testCase.verifyGreaterThan(abs(ClSOff - ClSAligned), 0.1, ...
                'An off-axis attitude must move the table lookup');
        end

        function validatorWarnsOnZeroTabularTable(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.propagatorObj = evt.forceModelPropagator;
            evt.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Lift];
            lvdData.stateLog.clearStateLog();

            aero = lvdData.initStateModel.aero;
            zeroRows = [0 0 0 0; 0 0 5 0; 0 10 0 0; 0 10 5 0; ...
                        1 0 0 0; 1 0 5 0; 1 10 0 0; 1 10 5 0];
            aero.liftCoeffModel.tabularLiftModel = UserTabulatedLiftModel(testCase.writeLiftCsv(zeroRows));
            aero.liftCoeffModel.liftCoeffObj = aero.liftCoeffModel.tabularLiftModel;

            validator = ZeroAreaLiftModelValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'zero-area'));

            liveRows = zeroRows;
            liveRows(:,4) = 2.0;
            aero.liftCoeffModel.tabularLiftModel = UserTabulatedLiftModel(testCase.writeLiftCsv(liveRows));
            aero.liftCoeffModel.liftCoeffObj = aero.liftCoeffModel.tabularLiftModel;
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);
        end
    end

    methods(Access=private)
        function f = writeLiftCsv(testCase, rows) %#ok<INUSL>
            f = [tempname(), '.csv'];
            writematrix(rows, f);
        end

        function forceVect = callLiftForce(testCase, rVect, vVect, aero, attState, bodyInfo) %#ok<INUSL>
            forceVect = LiftForceModel().getForce(0, rVect, vVect, 10, bodyInfo, aero, ...
                [], [], [], [], [], [], [], [], [], [], attState, []);
        end
    end
end
