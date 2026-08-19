classdef OrbitGeometryTest < KsptotTestCase
    %OrbitGeometryTest Scalar orbit geometry helper functions.
    %
    % These are small closed-form helpers, so the tests check them against
    % first principles (vis-viva, the conic equation, the orbit's own state
    % vectors) rather than against each other.

    properties(TestParameter)
        orbitCase = ksptotTestOrbitCatalog();
    end

    methods(Test)

        function apsisRadiiMatchConicExtremes(testCase)
            %rAp and rPe must equal the conic radius at tru = pi and 0.

            for(sma = [7000, 26560])
                for(ecc = [0, 0.05, 0.4, 0.9])
                    [rAp, rPe] = computeApogeePerigee(sma, ecc);

                    testCase.verifyEqual(rPe, computeRadiusFromTrueAEcc(0, sma, ecc), ...
                        'RelTol', 1e-12, sprintf('rPe wrong at sma=%g ecc=%g', sma, ecc));
                    testCase.verifyEqual(rAp, computeRadiusFromTrueAEcc(pi, sma, ecc), ...
                        'RelTol', 1e-12, sprintf('rAp wrong at sma=%g ecc=%g', sma, ecc));
                end
            end
        end

        function smaEccFromApsisRadiiRoundTrips(testCase)
            %(rAp, rPe) -> (sma, ecc) -> (rAp, rPe) is the identity.

            for(sma = [7000, 26560, 42164])
                for(ecc = [0, 0.05, 0.4, 0.9])
                    [rAp, rPe] = computeApogeePerigee(sma, ecc);
                    [smaBack, eccBack] = computeSmaEccFromRaRp(rAp, rPe);

                    testCase.verifyEqual(smaBack, sma, 'RelTol', 1e-12, ...
                        sprintf('sma round trip failed at sma=%g ecc=%g', sma, ecc));
                    testCase.verifyEqual(eccBack, ecc, 'AbsTol', 1e-12, ...
                        sprintf('ecc round trip failed at sma=%g ecc=%g', sma, ecc));
                end
            end
        end

        function eccentricityFromPeriapsisIsConsistent(testCase)
            %getEccFromRpAndSma must invert rPe = sma*(1-ecc).

            for(sma = [7000, 26560])
                for(ecc = [0, 0.2, 0.7])
                    [~, rPe] = computeApogeePerigee(sma, ecc);

                    testCase.verifyEqual(getEccFromRpAndSma(sma, rPe), ecc, 'AbsTol', 1e-12, ...
                        sprintf('getEccFromRpAndSma wrong at sma=%g ecc=%g', sma, ecc));
                end
            end
        end

        function radiusMatchesStateVectorMagnitude(testCase, orbitCase)
            %The conic radius must equal |rVect| for the same true anomaly.

            testCase.assumeGreaterThan(orbitCase.ecc, 1e-9, 'Ill-conditioned for circles');

            radius = computeRadiusFromTrueAEcc(orbitCase.tru, orbitCase.sma, orbitCase.ecc);

            testCase.verifyEqual(radius, norm(orbitCase.rVect), 'RelTol', 1e-9, ...
                sprintf('%s: conic radius disagrees with |rVect|', orbitCase.desc));
        end

        function trueAnomalyFromRadiusRoundTrips(testCase)
            %r -> tru -> r for the ascending half of the orbit.

            sma = 12000;

            for(ecc = [0.1, 0.5, 0.85])
                for(truDeg = 10:25:170)
                    tru    = deg2rad(truDeg);
                    radius = computeRadiusFromTrueAEcc(tru, sma, ecc);
                    truBack = computeTrueAFromRadiusEcc(radius, sma, ecc);

                    testCase.verifyAngleEqual(truBack, tru, 1e-7, sprintf( ...
                        'r->tru->r failed at ecc=%g tru=%d deg', ecc, truDeg));
                end
            end
        end

        function eccentricityVectorMatchesOracle(testCase, orbitCase)
            %computeEccVector must match the textbook eccentricity vector.

            expected = refRv2Coe(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);
            actual   = computeEccVector(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            testCase.verifyVectorEqual(actual, expected.eVect, 1e-9, ...
                sprintf('%s: eccentricity vector mismatch', orbitCase.desc));

            testCase.verifyEqual(norm(actual), orbitCase.ecc, 'AbsTol', 1e-9, ...
                sprintf('%s: |eVect| does not equal eccentricity', orbitCase.desc));
        end

        function angularMomentumVectorMatchesState(testCase, orbitCase)
            %computeHVect must equal cross(rVect, vVect) for the same orbit.
            %
            % computeHVect evaluates the orbit at tru = 0, but the angular
            % momentum vector is a constant of the motion, so it must match
            % the value computed from any point on the orbit.

            testCase.assumeGreaterThan(orbitCase.ecc, 1e-9, ...
                'Degenerate: periapsis undefined for a circular orbit');
            testCase.assumeGreaterThan(min(orbitCase.inc, abs(pi - orbitCase.inc)), 1e-6, ...
                'Equatorial handling is covered by ElementConversionTest');

            actual   = computeHVect(orbitCase.sma, orbitCase.ecc, orbitCase.inc, ...
                                    orbitCase.raan, orbitCase.arg, orbitCase.gmu);
            expected = cross(orbitCase.rVect, orbitCase.vVect);

            testCase.verifyVectorEqual(actual, expected, 1e-6 * norm(expected), ...
                sprintf('%s: angular momentum vector mismatch', orbitCase.desc));
        end

        function specificEnergyMatchesVisViva(testCase, orbitCase)
            %-gmu/(2a) must equal v^2/2 - gmu/r.

            expected = norm(orbitCase.vVect)^2 / 2 - orbitCase.gmu / norm(orbitCase.rVect);
            actual   = getSpecOrbitEnergyFromSma(orbitCase.sma, orbitCase.gmu);

            testCase.verifyEqual(actual, expected, 'RelTol', 1e-9, ...
                sprintf('%s: specific orbital energy violates vis-viva', orbitCase.desc));
        end

        function radiusVelocityFpaMatchesState(testCase, orbitCase)
            %computeRVFpaFromSmaEccTru must agree with the state vectors.

            testCase.assumeLessThan(orbitCase.ecc, 1, 'Closed orbits only');

            [radius, velocity, fpa] = computeRVFpaFromSmaEccTru( ...
                orbitCase.sma, orbitCase.ecc, orbitCase.tru, orbitCase.gmu);

            expectedFpa = asin(dot(orbitCase.rVect, orbitCase.vVect) / ...
                               (norm(orbitCase.rVect) * norm(orbitCase.vVect)));

            testCase.verifyEqual(radius, norm(orbitCase.rVect), 'RelTol', 1e-9, ...
                sprintf('%s: radius mismatch', orbitCase.desc));
            testCase.verifyEqual(velocity, norm(orbitCase.vVect), 'RelTol', 1e-9, ...
                sprintf('%s: velocity mismatch', orbitCase.desc));
            testCase.verifyEqual(fpa, expectedFpa, 'AbsTol', 1e-8, ...
                sprintf('%s: flight path angle mismatch', orbitCase.desc));
        end

        function rvFpaRoundTripsToElements(testCase)
            %(sma, ecc, tru) -> (r, v, fpa) -> (sma, ecc, tru) is the identity.

            gmu = 398600.4418;
            sma = 12000;

            for(ecc = [0.05, 0.3, 0.7])
                for(truDeg = [20, 100, 190, 300])
                    tru = deg2rad(truDeg);

                    [radius, velocity, fpa] = computeRVFpaFromSmaEccTru(sma, ecc, tru, gmu);
                    [smaBack, eccBack, truBack] = computeSmaEccTruFromRVFpa(radius, velocity, fpa, gmu);

                    msg = sprintf('at ecc=%g tru=%d deg', ecc, truDeg);

                    testCase.verifyEqual(smaBack, sma, 'RelTol', 1e-8, ['sma round trip failed ' msg]);
                    testCase.verifyEqual(eccBack, ecc, 'AbsTol', 1e-8, ['ecc round trip failed ' msg]);
                    testCase.verifyAngleEqual(truBack, tru, 1e-6, ['tru round trip failed ' msg]);
                end
            end
        end

        function visVivaHoldsAlongOrbit(testCase, orbitCase)
            %The state vectors themselves must satisfy vis-viva.

            radius   = norm(orbitCase.rVect);
            velocity = norm(orbitCase.vVect);

            expectedV = sqrt(orbitCase.gmu * (2 / radius - 1 / orbitCase.sma));

            testCase.verifyEqual(velocity, expectedV, 'RelTol', 1e-9, ...
                sprintf('%s: catalog state violates vis-viva', orbitCase.desc));
        end

        function sphereOfInfluenceIsPositiveAndOrdered(testCase)
            %SOI radius must be positive and smaller than the orbit radius.

            moonSoi = getSOIRadius(testCase.mun, testCase.kerbin);

            testCase.verifyGreaterThan(moonSoi, 0, 'Mun SOI radius is not positive');
            testCase.verifyLessThan(moonSoi, testCase.mun.sma, ...
                'Mun SOI radius exceeds its orbital radius');
            testCase.verifyGreaterThan(moonSoi, testCase.mun.radius, ...
                'Mun SOI radius is inside the body itself');

            testCase.verifyEqual(getSOIRadius(testCase.sun, []), realmax, ...
                'A body with no parent must have an unbounded SOI');
        end
    end
end
