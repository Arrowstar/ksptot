classdef KeplerSolverTest < KsptotTestCase
    %KeplerSolverTest Kepler's equation and anomaly conversions.
    %
    % Verifies the elliptical and hyperbolic Kepler solvers by substituting
    % the returned anomaly back into Kepler's equation, and checks that the
    % anomaly conversion helpers are mutually inverse.

    properties(TestParameter)
        ellipticEcc  = struct('circular', 0, 'low', 0.05, 'moderate', 0.4, ...
                              'high', 0.85, 'veryHigh', 0.95, 'extreme', 0.99);
        hyperbolicEcc = struct('barely', 1.01, 'low', 1.2, 'moderate', 2.0, ...
                               'high', 5.0);
        meanAnomDeg  = struct('zero', 0, 'small', 7, 'quarter', 90, ...
                              'nearPi', 179, 'atPi', 180, 'past', 250, ...
                              'nearFull', 359);
    end

    methods(Test)

        function solveKeplerSatisfiesEllipticEquation(testCase, ellipticEcc, meanAnomDeg)
            %E - e*sin(E) must equal M.

            meanAnom = deg2rad(meanAnomDeg);

            eccAnom = solveKepler(meanAnom, ellipticEcc);

            residual = angleNegPiToPi((eccAnom - ellipticEcc * sin(eccAnom)) - meanAnom);

            testCase.verifyLessThan(abs(residual), 1e-9, sprintf( ...
                'Kepler residual %g rad for ecc = %g, M = %g deg (E = %g rad)', ...
                residual, ellipticEcc, meanAnomDeg, eccAnom));
        end

        function solveKeplerSatisfiesHyperbolicEquation(testCase, hyperbolicEcc)
            %e*sinh(H) - H must equal M.

            for(meanAnom = [-4, -1, -0.05, 0.05, 0.5, 1, 4, 12]) %#ok<*NO4LP>
                hypAnom = solveKepler(meanAnom, hyperbolicEcc);

                residual = (hyperbolicEcc * sinh(hypAnom) - hypAnom) - meanAnom;

                testCase.verifyLessThan(abs(residual), 1e-8 * max(1, abs(meanAnom)), sprintf( ...
                    'Hyperbolic Kepler residual %g for ecc = %g, M = %g (H = %g)', ...
                    residual, hyperbolicEcc, meanAnom, hypAnom));
            end
        end

        function keplerSolverTerminates(testCase, ellipticEcc)
            %The Newton iteration must converge rather than hang.
            %
            % keplerEq() has no iteration cap, so a non-converging case would
            % spin forever.  Bounding the wall time turns that into a
            % failure.  The bound is deliberately generous: these solves take
            % milliseconds even at extreme eccentricity, so the assertion is
            % a non-termination watchdog, not a performance test, and must
            % not flake on a loaded CI machine.

            meanAnoms = linspace(0, 2 * pi, 73);

            startTime = tic;
            for(i = 1:numel(meanAnoms))
                solveKepler(meanAnoms(i), ellipticEcc);
            end
            elapsed = toc(startTime);

            testCase.verifyLessThan(elapsed, 60, sprintf( ...
                'Solving %d Kepler problems at ecc = %g took %.1f s', ...
                numel(meanAnoms), ellipticEcc, elapsed));
        end

        function trueToMeanToTrueRoundTrips(testCase, ellipticEcc)
            %tru -> M -> tru must be the identity for closed orbits.

            for(truDeg = 0:20:340)
                tru = deg2rad(truDeg);

                meanAnom = computeMeanFromTrueAnom(tru, ellipticEcc);
                truBack  = computeTrueAnomFromMean(meanAnom, ellipticEcc);

                testCase.verifyAngleEqual(truBack, tru, 1e-7, sprintf( ...
                    'tru->M->tru failed at ecc = %g, tru = %d deg (M = %g rad, got %g deg)', ...
                    ellipticEcc, truDeg, meanAnom, rad2deg(truBack)));
            end
        end

        function trueToEccentricToTrueRoundTrips(testCase, ellipticEcc)
            %tru -> E -> tru must be the identity.

            for(truDeg = 0:20:340)
                tru = deg2rad(truDeg);

                [~, eccAnom] = computeMeanFromTrueAnom(tru, ellipticEcc);
                truBack = computeTrueAnomFromEccAnom(eccAnom, ellipticEcc);

                testCase.verifyAngleEqual(truBack, tru, 1e-9, sprintf( ...
                    'tru->E->tru failed at ecc = %g, tru = %d deg', ellipticEcc, truDeg));
            end
        end

        function eccentricAnomalyOutputRangeIsConsistent(testCase)
            %computeMeanFromTrueAnom must return E on [0, 2*pi) and M on
            %[0, 2*pi), independent of how the input true anomaly is
            %represented: nu and nu + 2*pi must give identical outputs.

            ecc = 0.3;

            for(truDeg = [30, 200, 330])
                truLow  = deg2rad(truDeg);
                truHigh = truLow + 2 * pi;

                [meanLow, eccAnomLow]   = computeMeanFromTrueAnom(truLow,  ecc);
                [meanHigh, eccAnomHigh] = computeMeanFromTrueAnom(truHigh, ecc);

                msg = sprintf('at tru = %g deg vs the same angle plus 2*pi', truDeg);

                testCase.verifyEqual(eccAnomHigh, eccAnomLow, 'AbsTol', 1e-12, sprintf( ...
                    'eccentric anomaly is not periodic in the input: %g vs %g rad %s', ...
                    eccAnomLow, eccAnomHigh, msg));
                testCase.verifyEqual(meanHigh, meanLow, 'AbsTol', 1e-12, sprintf( ...
                    'mean anomaly is not periodic in the input: %g vs %g rad %s', ...
                    meanLow, meanHigh, msg));

                testCase.verifyGreaterThanOrEqual(eccAnomHigh, 0, sprintf( ...
                    'eccentric anomaly %g rad outside [0, 2*pi) %s', eccAnomHigh, msg));
                testCase.verifyLessThan(eccAnomHigh, 2 * pi, sprintf( ...
                    'eccentric anomaly %g rad outside [0, 2*pi) %s', eccAnomHigh, msg));

                testCase.verifyGreaterThanOrEqual(meanHigh, 0, sprintf( ...
                    'mean anomaly %g rad outside [0, 2*pi) %s', meanHigh, msg));
                testCase.verifyLessThan(meanHigh, 2 * pi, sprintf( ...
                    'mean anomaly %g rad outside [0, 2*pi) %s', meanHigh, msg));
            end
        end

        function trueToHyperbolicToTrueRoundTrips(testCase, hyperbolicEcc)
            %tru -> H -> tru must be the identity within the asymptotes.

            limit = acos(-1 / hyperbolicEcc);

            for(frac = [-0.9, -0.5, -0.1, 0.1, 0.5, 0.9])
                tru = frac * limit;

                hypAnom = computeHyperAFromTrueAnom(tru, hyperbolicEcc);
                truBack = computeTrueAnomFromHypAnom(hypAnom, hyperbolicEcc);

                testCase.verifyLessThan(abs(truBack - tru), 1e-8, sprintf( ...
                    'tru->H->tru failed at ecc = %g, tru = %g rad (H = %g)', ...
                    hyperbolicEcc, tru, hypAnom));
            end
        end

        function hyperbolicMeanRoundTrips(testCase, hyperbolicEcc)
            %tru -> M -> tru for hyperbolic orbits.

            limit = acos(-1 / hyperbolicEcc);

            for(frac = [-0.8, -0.3, 0.3, 0.8])
                tru = frac * limit;

                meanAnom = computeMeanFromTrueAnom(tru, hyperbolicEcc);
                truBack  = computeTrueAnomFromMean(meanAnom, hyperbolicEcc);

                testCase.verifyLessThan(abs(truBack - tru), 1e-7, sprintf( ...
                    'hyperbolic tru->M->tru failed at ecc = %g, tru = %g rad', ...
                    hyperbolicEcc, tru));
            end
        end

        function meanAnomalyIsMonotonicInTrueAnomaly(testCase, ellipticEcc)
            %M must increase monotonically with tru over one revolution.

            testCase.assumeGreaterThan(ellipticEcc, 0, 'Degenerate for a circle');

            truValues  = deg2rad(1:2:359);
            meanValues = arrayfun(@(t) computeMeanFromTrueAnom(t, ellipticEcc), truValues);

            differences = diff(meanValues);

            testCase.verifyGreaterThan(min(differences), 0, sprintf( ...
                'Mean anomaly is not monotonic in true anomaly at ecc = %g (min step %g rad)', ...
                ellipticEcc, min(differences)));
        end

        function vectorizedKeplerSolverMatchesScalar(testCase, ellipticEcc)
            %vect_solveKepler must agree with the scalar solver.

            testCase.assumeGreaterThan(ellipticEcc, 0, 'Trivial for a circle');

            meanAnoms = deg2rad(5:25:355);

            scalarResult = arrayfun(@(m) solveKepler(m, ellipticEcc), meanAnoms);
            vectorResult = vect_solveKepler(meanAnoms, repmat(ellipticEcc, size(meanAnoms)));

            for(i = 1:numel(meanAnoms))
                testCase.verifyAngleEqual(vectorResult(i), scalarResult(i), 1e-8, sprintf( ...
                    'vect_solveKepler differs from solveKepler at ecc = %g, M = %g deg', ...
                    ellipticEcc, rad2deg(meanAnoms(i))));
            end
        end

        function meanMotionAndPeriodAreConsistent(testCase)
            %n = 2*pi/T, and sma round-trips through period.

            gmu = 398600.4418;

            for(sma = [6878, 26560, 42164, 1e6])
                period     = computePeriod(sma, gmu);
                meanMotion = computeMeanMotion(sma, gmu);

                testCase.verifyEqual(meanMotion, 2 * pi / period, 'RelTol', 1e-12, ...
                    sprintf('n and T inconsistent at sma = %g km', sma));

                testCase.verifyEqual(computeSMAFromPeriod(period, gmu), sma, 'RelTol', 1e-10, ...
                    sprintf('sma->T->sma failed at sma = %g km', sma));
            end
        end
    end
end
