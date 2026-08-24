classdef ElementConversionTest < KsptotTestCase
    %ElementConversionTest Cartesian <-> Keplerian element conversions.
    %
    % Covers getKeplerFromState / getStatefromKepler (scalar, MEX-backed)
    % and their vectorized counterparts.
    %
    % The central assertion is convention-free: whatever set of classical
    % elements the code returns for a given state, feeding those elements
    % into an independent textbook oracle (refCoe2Rv) must reproduce the
    % original position and velocity.  This catches wrong answers without
    % taking a position on how degenerate orbits "should" be parameterized.

    properties(TestParameter)
        orbitCase = ksptotTestOrbitCatalog();
    end

    methods(Test)

        function keplerFromStateReproducesState(testCase, orbitCase)
            %Elements returned for a state must regenerate that same state.

            [sma, ecc, inc, raan, arg, tru] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            [rRebuilt, vRebuilt] = refCoe2Rv(sma, ecc, inc, raan, arg, tru, orbitCase.gmu);

            rTol = 1e-6 * max(1, norm(orbitCase.rVect));
            vTol = 1e-6 * max(1, norm(orbitCase.vVect));

            testCase.verifyVectorEqual(rRebuilt, orbitCase.rVect, rTol, ...
                sprintf('%s: getKeplerFromState elements do not reproduce position', orbitCase.desc));
            testCase.verifyVectorEqual(vRebuilt, orbitCase.vVect, vTol, ...
                sprintf('%s: getKeplerFromState elements do not reproduce velocity', orbitCase.desc));
        end

        function keplerFromStateMatchesOracleInvariants(testCase, orbitCase)
            %sma, ecc and inc are convention-free and must match the oracle.

            [sma, ecc, inc] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            expected = refRv2Coe(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            testCase.verifyEqual(sma, expected.sma, 'RelTol', 1e-9, ...
                sprintf('%s: semi-major axis mismatch', orbitCase.desc));
            testCase.verifyEqual(ecc, expected.ecc, 'AbsTol', 1e-9, ...
                sprintf('%s: eccentricity mismatch', orbitCase.desc));
            testCase.verifyEqual(inc, expected.inc, 'AbsTol', 1e-9, ...
                sprintf('%s: inclination mismatch', orbitCase.desc));
        end

        function stateFromKeplerMatchesOracle(testCase, orbitCase)
            %For non-degenerate elements, COE2RV must match the oracle.
            %
            % Degenerate inputs are skipped here because the code under test
            % deliberately reinterprets them; that behaviour is pinned down
            % separately by the equatorial/circular tests below.

            testCase.assumeGreaterThan(orbitCase.ecc, 1e-6, ...
                'Circular orbits are covered by the dedicated degenerate tests');
            testCase.assumeGreaterThan(min(orbitCase.inc, abs(pi - orbitCase.inc)), 1e-6, ...
                'Equatorial orbits are covered by the dedicated degenerate tests');

            [rActual, vActual] = getStatefromKepler(orbitCase.sma, orbitCase.ecc, ...
                orbitCase.inc, orbitCase.raan, orbitCase.arg, orbitCase.tru, orbitCase.gmu);

            testCase.verifyVectorEqual(rActual, orbitCase.rVect, 1e-6 * norm(orbitCase.rVect), ...
                sprintf('%s: getStatefromKepler position mismatch', orbitCase.desc));
            testCase.verifyVectorEqual(vActual, orbitCase.vVect, 1e-6 * norm(orbitCase.vVect), ...
                sprintf('%s: getStatefromKepler velocity mismatch', orbitCase.desc));
        end

        function cartesianRoundTripIsLossless(testCase, orbitCase)
            %r,v -> elements -> r,v must return the original state.

            [sma, ecc, inc, raan, arg, tru] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);
            [rBack, vBack] = getStatefromKepler(sma, ecc, inc, raan, arg, tru, orbitCase.gmu);

            testCase.verifyVectorEqual(rBack, orbitCase.rVect, 1e-6 * norm(orbitCase.rVect), ...
                sprintf('%s: cart->kep->cart lost position', orbitCase.desc));
            testCase.verifyVectorEqual(vBack, orbitCase.vVect, 1e-6 * norm(orbitCase.vVect), ...
                sprintf('%s: cart->kep->cart lost velocity', orbitCase.desc));
        end

        function trueAnomalyRespectsDocumentedRange(testCase, orbitCase)
            %getKeplerFromState documents tru in [0, 2*pi) for closed orbits.

            [~, ecc, ~, ~, ~, tru] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            testCase.assumeLessThan(ecc, 1, 'Range contract applies to closed orbits only');

            testCase.verifyGreaterThanOrEqual(tru, 0, ...
                sprintf('%s: true anomaly %g rad is negative for an elliptical orbit', ...
                        orbitCase.desc, tru));
            testCase.verifyLessThan(tru, 2 * pi + eps(2 * pi), ...
                sprintf('%s: true anomaly %g rad exceeds 2*pi', orbitCase.desc, tru));
        end

        function anglesRespectPrincipalRanges(testCase, orbitCase)
            %inc in [0,pi]; raan and arg in [0,2*pi).

            [~, ~, inc, raan, arg] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            testCase.verifyGreaterThanOrEqual(inc, 0, 'inclination below 0');
            testCase.verifyLessThanOrEqual(inc, pi, 'inclination above pi');

            testCase.verifyGreaterThanOrEqual(raan, 0, ...
                sprintf('%s: raan = %g rad is negative', orbitCase.desc, raan));
            testCase.verifyLessThan(raan, 2 * pi + eps(2 * pi), ...
                sprintf('%s: raan = %g rad exceeds 2*pi', orbitCase.desc, raan));

            testCase.verifyGreaterThanOrEqual(arg, 0, ...
                sprintf('%s: arg = %g rad is negative', orbitCase.desc, arg));
            testCase.verifyLessThan(arg, 2 * pi + eps(2 * pi), ...
                sprintf('%s: arg = %g rad exceeds 2*pi', orbitCase.desc, arg));
        end

        function vectorizedMatchesScalarConversion(testCase)
            %vect_getKeplerFromState must agree with the scalar MEX path.

            catalog = ksptotTestOrbitCatalog();
            names   = fieldnames(catalog);

            for(i = 1:numel(names)) %#ok<*NO4LP>
                thisCase = catalog.(names{i});

                [sScalar, eScalar, iScalar, oScalar, aScalar, tScalar] = ...
                    getKeplerFromState(thisCase.rVect, thisCase.vVect, thisCase.gmu);
                [sVec, eVec, iVec, oVec, aVec, tVec] = ...
                    vect_getKeplerFromState(thisCase.rVect, thisCase.vVect, thisCase.gmu);

                msg = sprintf('%s: vectorized/scalar disagree', thisCase.desc);

                testCase.verifyEqual(sVec, sScalar, 'RelTol', 1e-9, [msg ' (sma)']);
                testCase.verifyEqual(eVec, eScalar, 'AbsTol', 1e-9, [msg ' (ecc)']);
                testCase.verifyEqual(iVec, iScalar, 'AbsTol', 1e-9, [msg ' (inc)']);

                % Angles compared modulo 2*pi and only where well defined.
                if(eScalar > 1e-6 && min(iScalar, abs(pi - iScalar)) > 1e-6)
                    testCase.verifyAngleEqual(oVec, oScalar, 1e-8, [msg ' (raan)']);
                    testCase.verifyAngleEqual(aVec, aScalar, 1e-8, [msg ' (arg)']);
                    testCase.verifyAngleEqual(tVec, tScalar, 1e-8, [msg ' (tru)']);
                end
            end
        end

        function vectorizedStateFromKeplerMatchesOracle(testCase, orbitCase)
            %vect_getStatefromKepler must reproduce the catalog state.

            [rActual, vActual] = vect_getStatefromKepler(orbitCase.sma, orbitCase.ecc, ...
                orbitCase.inc, orbitCase.raan, orbitCase.arg, orbitCase.tru, ...
                orbitCase.gmu, false);

            testCase.verifyVectorEqual(rActual, orbitCase.rVect, 1e-6 * norm(orbitCase.rVect), ...
                sprintf('%s: vect_getStatefromKepler position mismatch', orbitCase.desc));
            testCase.verifyVectorEqual(vActual, orbitCase.vVect, 1e-6 * norm(orbitCase.vVect), ...
                sprintf('%s: vect_getStatefromKepler velocity mismatch', orbitCase.desc));
        end

        function equatorialFoldIsExactBelowBranchThreshold(testCase)
            %Below the 1E-4 inclination branch threshold in
            %vect_getStatefromKepler_Alg the conversion must return the exact
            %equatorial limit: RAAN folded into the argument of periapsis,
            %i.e. the refCoe2Rv reconstruction at inc = 0.
            %
            % This catches a regression to discarding RAAN at any inclination
            % inside the special-case region, not just at exactly inc = 0.

            gmu  = 398600.4418;
            raan = deg2rad(45);
            arg  = deg2rad(30);
            tru  = deg2rad(50);
            sma  = 700;
            ecc  = 0.1;

            [rLimit, vLimit] = refCoe2Rv(sma, ecc, 0, raan, arg, tru, gmu);

            incValues = [0, 1e-12, 1e-9, 1e-7];

            for(i = 1:numel(incValues))
                [rVect, vVect] = vect_getStatefromKepler(sma, ecc, incValues(i), ...
                    raan, arg, tru, gmu, false);

                msg = sprintf( ...
                    'at inc = %g rad (RAAN not folded into the argument of periapsis)', ...
                    incValues(i));

                testCase.verifyVectorEqual(rVect, rLimit, 1e-6 * norm(rLimit), ['position ' msg]);
                testCase.verifyVectorEqual(vVect, vLimit, 1e-6 * norm(vLimit), ['velocity ' msg]);
            end
        end

        function equatorialBranchSeamBoundedByGeometry(testCase)
            %Crossing the 1E-4 inclination branch threshold cannot be made
            %continuous: below it RAAN is folded into the argument of
            %periapsis (the inc -> 0 limit), while above it the general
            %mapping rotates the plane at rate <= |r| per radian of
            %inclination.  The seam is therefore required to be bounded by
            %geometry, not to vanish.
            %
            % Measured ratios for this configuration: position 0.985,
            % velocity 0.244 of |x| * inc; the 1.2 factor leaves margin.

            gmu  = 398600.4418;
            raan = deg2rad(45);
            arg  = deg2rad(30);
            tru  = deg2rad(50);
            sma  = 700;
            ecc  = 0.1;

            incAboveThreshold = 1.5e-4;

            [rLimit, vLimit] = refCoe2Rv(sma, ecc, 0, raan, arg, tru, gmu);
            [rAbove, vAbove] = vect_getStatefromKepler(sma, ecc, incAboveThreshold, ...
                raan, arg, tru, gmu, false);

            seamFactor = 1.2;

            rSeamBound = seamFactor * norm(rLimit) * incAboveThreshold;
            vSeamBound = seamFactor * norm(vLimit) * incAboveThreshold;

            testCase.verifyLessThan(norm(rAbove - rLimit), rSeamBound, sprintf( ...
                ['Position seam %.3g km across the equatorial branch threshold ', ...
                 '(inc = %g rad) exceeds the geometric bound %g km.'], ...
                norm(rAbove - rLimit), incAboveThreshold, rSeamBound));

            testCase.verifyLessThan(norm(vAbove - vLimit), vSeamBound, sprintf( ...
                ['Velocity seam %.3g km/s across the equatorial branch threshold ', ...
                 '(inc = %g rad) exceeds the geometric bound %g km/s.'], ...
                norm(vAbove - vLimit), incAboveThreshold, vSeamBound));
        end

        function equatorialConversionPreservesRaanInformation(testCase)
            %At inc = 0 only raan+arg is observable, but it must be preserved.

            gmu = 398600.4418;
            arg = deg2rad(30);
            tru = deg2rad(50);
            sma = 700;
            ecc = 0.1;

            [rReference, vReference] = refCoe2Rv(sma, ecc, 0, deg2rad(45), arg, tru, gmu);
            [rActual, vActual] = vect_getStatefromKepler(sma, ecc, 0, deg2rad(45), arg, tru, gmu, false);

            testCase.verifyVectorEqual(rActual, rReference, 1e-6 * norm(rReference), ...
                'Equatorial orbit ignores RAAN in position');
            testCase.verifyVectorEqual(vActual, vReference, 1e-6 * norm(vReference), ...
                'Equatorial orbit ignores RAAN in velocity');
        end

        function hyperbolicTrueAnomalyStaysWithinAsymptotes(testCase)
            %|tru| must be below the asymptotic limit acos(-1/ecc).

            catalog = ksptotTestOrbitCatalog();
            names   = fieldnames(catalog);

            for(i = 1:numel(names))
                thisCase = catalog.(names{i});

                if(thisCase.ecc <= 1)
                    continue;
                end

                [~, ecc, ~, ~, ~, tru] = ...
                    getKeplerFromState(thisCase.rVect, thisCase.vVect, thisCase.gmu);

                limit = acos(-1 / ecc);

                testCase.verifyLessThan(abs(tru), limit, sprintf( ...
                    '%s: |tru| = %g rad exceeds asymptote %g rad', ...
                    thisCase.desc, abs(tru), limit));
            end
        end

        function degenerateOrbitsReproduceStateAtAllPhases(testCase)
            %Sweep true anomaly through each degenerate geometry.
            %
            % A single sample per geometry can easily land on a phase that
            % happens to work; breakage in the quadrant logic of the special
            % cases is phase dependent.

            gmu = 398600.4418;

            geometries = { ...
                'circular equatorial prograde',    7000, 0.0,  0.0,   0.0; ...
                'circular equatorial retrograde',  7000, 0.0,  180.0, 0.0; ...
                'elliptical equatorial prograde',  8000, 0.2,  0.0,   40.0; ...
                'elliptical equatorial retrograde',8000, 0.2,  180.0, 40.0; ...
                'circular inclined',               7000, 0.0,  45.0,  0.0; ...
                'circular polar',                  7000, 0.0,  90.0,  0.0};

            for(g = 1:size(geometries, 1)) %#ok<*NO4LP>
                name = geometries{g, 1};
                sma  = geometries{g, 2};
                ecc  = geometries{g, 3};
                inc  = deg2rad(geometries{g, 4});
                arg  = deg2rad(geometries{g, 5});

                for(truDeg = 0:30:330)
                    [rVect, vVect] = refCoe2Rv(sma, ecc, inc, 0, arg, deg2rad(truDeg), gmu);

                    [smaA, eccA, incA, raanA, argA, truA] = getKeplerFromState(rVect, vVect, gmu);
                    [rBack, vBack] = refCoe2Rv(smaA, eccA, incA, raanA, argA, truA, gmu);

                    testCase.verifyLessThan(norm(rBack - rVect), 1e-3 * norm(rVect), sprintf( ...
                        '%s at tru = %d deg: elements do not reproduce position (off by %.1f km)', ...
                        name, truDeg, norm(rBack - rVect)));

                    testCase.verifyLessThan(norm(vBack - vVect), 1e-3 * norm(vVect), sprintf( ...
                        '%s at tru = %d deg: elements do not reproduce velocity', name, truDeg));

                    testCase.verifyGreaterThanOrEqual(truA, 0, sprintf( ...
                        '%s at tru = %d deg: returned true anomaly %g rad is negative', ...
                        name, truDeg, truA));
                end
            end
        end

        function vectorizedKeplerFromStateReproducesState(testCase, orbitCase)
            %The vectorized RV2COE must also produce self-consistent elements.

            [sma, ecc, inc, raan, arg, tru] = ...
                vect_getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);

            [rBack, vBack] = refCoe2Rv(sma, ecc, inc, raan, arg, tru, orbitCase.gmu);

            testCase.verifyVectorEqual(rBack, orbitCase.rVect, 1e-6 * norm(orbitCase.rVect), ...
                sprintf('%s: vect_getKeplerFromState elements do not reproduce position', orbitCase.desc));
            testCase.verifyVectorEqual(vBack, orbitCase.vVect, 1e-6 * norm(orbitCase.vVect), ...
                sprintf('%s: vect_getKeplerFromState elements do not reproduce velocity', orbitCase.desc));
        end

        function batchedVectorizedConversionMatchesElementwise(testCase)
            %Passing N states at once must equal N separate scalar calls.

            catalog = ksptotTestOrbitCatalog();
            names   = fieldnames(catalog);

            % Restrict to a single gravitational parameter so the states can
            % legitimately be batched together.
            rVects = [];
            vVects = [];
            gmu    = 398600.4418;
            kept   = {};

            for(i = 1:numel(names))
                thisCase = catalog.(names{i});
                if(thisCase.gmu ~= gmu)
                    continue;
                end
                rVects(:, end+1) = thisCase.rVect; %#ok<AGROW>
                vVects(:, end+1) = thisCase.vVect; %#ok<AGROW>
                kept{end+1} = thisCase.desc;       %#ok<AGROW>
            end

            [smaB, eccB, incB, raanB, argB, truB] = vect_getKeplerFromState(rVects, vVects, gmu);

            for(i = 1:numel(kept))
                [smaS, eccS, incS, raanS, argS, truS] = ...
                    vect_getKeplerFromState(rVects(:, i), vVects(:, i), gmu);

                msg = sprintf('%s: batched vs element-wise disagree', kept{i});

                testCase.verifyEqual(smaB(i),  smaS,  'RelTol', 1e-12, [msg ' (sma)']);
                testCase.verifyEqual(eccB(i),  eccS,  'AbsTol', 1e-12, [msg ' (ecc)']);
                testCase.verifyEqual(incB(i),  incS,  'AbsTol', 1e-12, [msg ' (inc)']);
                testCase.verifyEqual(raanB(i), raanS, 'AbsTol', 1e-12, [msg ' (raan)']);
                testCase.verifyEqual(argB(i),  argS,  'AbsTol', 1e-12, [msg ' (arg)']);
                testCase.verifyEqual(truB(i),  truS,  'AbsTol', 1e-12, [msg ' (tru)']);
            end
        end

        function specificAngularMomentumIsPreserved(testCase, orbitCase)
            %The orbit normal implied by the elements must match the state.

            [sma, ecc, inc, raan, arg, tru] = ...
                getKeplerFromState(orbitCase.rVect, orbitCase.vVect, orbitCase.gmu);
            [rBack, vBack] = refCoe2Rv(sma, ecc, inc, raan, arg, tru, orbitCase.gmu);

            hExpected = cross(orbitCase.rVect, orbitCase.vVect);
            hActual   = cross(rBack, vBack);

            testCase.verifyVectorEqual(hActual, hExpected, 1e-6 * norm(hExpected), ...
                sprintf('%s: angular momentum vector not preserved', orbitCase.desc));
        end
    end
end
