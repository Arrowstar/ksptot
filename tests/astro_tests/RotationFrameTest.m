classdef RotationFrameTest < KsptotTestCase
    %RotationFrameTest Vector rotations and local orbital frames.
    %
    % Covers Rodrigues rotation, the RSW (radial/along-track/cross-track)
    % and NTW (normal/tangential/cross-track) frames, the 3-1-3 Euler
    % transformation, and the NTW spherical parameterization.

    properties(TestParameter)
        orbitCase = ksptotTestOrbitCatalog();
    end

    methods(Test)

        function rodriguesMatchesAxisAngleMatrix(testCase)
            %Rodrigues rotation must equal the equivalent rotation matrix.

            rng(7);

            for(trial = 1:25) %#ok<*NO4LP>
                v     = randn(3, 1) * 10;
                axis  = randn(3, 1);
                theta = (rand() - 0.5) * 4 * pi;

                kHat = axis / norm(axis);

                % Closed-form axis-angle matrix (independent of the code).
                skew = [        0, -kHat(3),  kHat(2); ...
                          kHat(3),        0, -kHat(1); ...
                         -kHat(2),  kHat(1),        0];
                rotMat = eye(3) + sin(theta) * skew + (1 - cos(theta)) * (skew * skew);

                expected = rotMat * v;
                actual   = rodrigues_rot(v, kHat, theta);

                testCase.verifyVectorEqual(actual, expected, 1e-10, ...
                    sprintf('Rodrigues rotation mismatch on trial %d', trial));
            end
        end

        function rodriguesPreservesNormAndAxis(testCase)
            %Rotation is an isometry and leaves the axis invariant.

            rng(11);

            for(trial = 1:20)
                v     = randn(3, 1) * 5;
                kHat  = randn(3, 1);
                kHat  = kHat / norm(kHat);
                theta = rand() * 2 * pi;

                rotated = rodrigues_rot(v, kHat, theta);

                testCase.verifyEqual(norm(rotated), norm(v), 'RelTol', 1e-12, ...
                    'Rodrigues rotation changed the vector magnitude');

                axisRotated = rodrigues_rot(kHat, kHat, theta);
                testCase.verifyVectorEqual(axisRotated, kHat, 1e-12, ...
                    'Rodrigues rotation moved its own rotation axis');
            end
        end

        function rodriguesFullTurnIsIdentity(testCase)
            %Rotating by 2*pi returns the original vector.

            v    = [3; -4; 12];
            kHat = [1; 1; 1] / sqrt(3);

            testCase.verifyVectorEqual(rodrigues_rot(v, kHat, 2 * pi), v, 1e-12, ...
                'Rotation by 2*pi is not the identity');
        end

        function rswRoundTripsAndHasCorrectBasis(testCase, orbitCase)
            %ECI -> RSW -> ECI is the identity, and R points along position.

            rVect = orbitCase.rVect;
            vVect = orbitCase.vVect;

            sample = [1.5; -2.25; 0.75];

            rsw  = rotateVectorFromEciToRsw(sample, rVect, vVect);
            back = rotateVectorFromRsw2Eci(rsw, rVect, vVect);

            testCase.verifyVectorEqual(back, sample, 1e-10, ...
                sprintf('%s: ECI->RSW->ECI round trip failed', orbitCase.desc));

            % The position vector must lie purely along the R axis.
            rInRsw = rotateVectorFromEciToRsw(rVect, rVect, vVect);

            testCase.verifyEqual(rInRsw(1), norm(rVect), 'RelTol', 1e-9, ...
                sprintf('%s: R component of position is wrong', orbitCase.desc));
            testCase.verifyLessThan(abs(rInRsw(2)), 1e-6 * norm(rVect), ...
                sprintf('%s: position has along-track component in RSW', orbitCase.desc));
            testCase.verifyLessThan(abs(rInRsw(3)), 1e-6 * norm(rVect), ...
                sprintf('%s: position has cross-track component in RSW', orbitCase.desc));
        end

        function rswPreservesVectorMagnitude(testCase, orbitCase)
            %A frame rotation must not change lengths.

            sample = [10; -3; 7];
            rsw    = rotateVectorFromEciToRsw(sample, orbitCase.rVect, orbitCase.vVect);

            testCase.verifyEqual(norm(rsw), norm(sample), 'RelTol', 1e-10, ...
                sprintf('%s: RSW rotation changed vector magnitude', orbitCase.desc));
        end

        function ntwRoundTripsAndHasCorrectBasis(testCase, orbitCase)
            %ECI -> NTW -> ECI is the identity, and velocity is along T.

            rVect = orbitCase.rVect;
            vVect = orbitCase.vVect;

            sample = [0.4; 1.1; -0.6];

            ntw  = getECI2NTWdvVect(sample, rVect, vVect);
            back = getNTW2ECIdvVect(ntw, rVect, vVect);

            testCase.verifyVectorEqual(back, sample, 1e-10, ...
                sprintf('%s: ECI->NTW->ECI round trip failed', orbitCase.desc));

            testCase.verifyEqual(norm(ntw), norm(sample), 'RelTol', 1e-10, ...
                sprintf('%s: NTW rotation changed vector magnitude', orbitCase.desc));

            % Velocity must be purely tangential (first component of this basis).
            vInNtw = getECI2NTWdvVect(vVect, rVect, vVect);

            testCase.verifyEqual(vInNtw(1), norm(vVect), 'RelTol', 1e-9, ...
                sprintf('%s: tangential component of velocity is wrong', orbitCase.desc));
            testCase.verifyLessThan(norm(vInNtw(2:3)), 1e-6 * norm(vVect), ...
                sprintf('%s: velocity has non-tangential NTW components', orbitCase.desc));
        end

        function legacyNtwHelperAgreesWithCurrentOne(testCase, orbitCase)
            %getNTWdvVect and getECI2NTWdvVect must produce the same result.

            sample = [2; -1; 3];

            legacy  = getNTWdvVect(sample, orbitCase.rVect, orbitCase.vVect);
            current = getECI2NTWdvVect(sample, orbitCase.rVect, orbitCase.vVect);

            testCase.verifyVectorEqual(legacy, current, 1e-10, ...
                sprintf('%s: getNTWdvVect disagrees with getECI2NTWdvVect', orbitCase.desc));
        end

        function ntwAzElMagRoundTrips(testCase)
            %NTW vector -> (az, el, mag) -> NTW vector is the identity.

            rng(3);

            for(trial = 1:30)
                ntwVector = randn(1, 3) * 2;

                [az, el, mag] = getAzElMagFromNTW(ntwVector);
                back = getNTWFromAzElMag(az, el, mag);

                testCase.verifyVectorEqual(back, ntwVector, 1e-10, ...
                    sprintf('NTW az/el/mag round trip failed on trial %d', trial));

                testCase.verifyEqual(mag, norm(ntwVector), 'RelTol', 1e-12, ...
                    'Magnitude from getAzElMagFromNTW is wrong');
            end
        end

        function euler313IsOrthonormalRotation(testCase)
            %The 3-1-3 transform must be orthonormal with determinant +1.

            rng(5);

            for(trial = 1:20)
                raan = rand() * 2 * pi;
                inc  = rand() * pi;
                arg  = rand() * 2 * pi;

                transMat = Euler313(raan, inc, arg);

                testCase.verifyVectorEqual(reshape(transMat' * transMat, 9, 1), ...
                    reshape(eye(3), 9, 1), 1e-12, ...
                    sprintf('Euler313 is not orthonormal on trial %d', trial));

                testCase.verifyEqual(det(transMat), 1, 'AbsTol', 1e-12, ...
                    sprintf('Euler313 determinant is not +1 on trial %d', trial));
            end
        end

        function euler313MatchesPerifocalTransform(testCase)
            %Euler313(raan, inc, arg) is the perifocal-to-inertial matrix.

            rng(13);

            for(trial = 1:15)
                raan = rand() * 2 * pi;
                inc  = rand() * pi;
                arg  = rand() * 2 * pi;

                transMat = Euler313(raan, inc, arg);

                % Compare by action on the perifocal unit vectors, using the
                % oracle to generate the expected inertial directions.
                sma = 8000;
                ecc = 0.1;
                gmu = 398600.4418;

                [rVect, ~] = refCoe2Rv(sma, ecc, inc, raan, arg, 0, gmu);

                periapsisDirection = transMat * [1; 0; 0];

                testCase.verifyVectorEqual(periapsisDirection, rVect / norm(rVect), 1e-10, ...
                    sprintf('Euler313 periapsis direction mismatch on trial %d', trial));
            end
        end

        function settingSpinRateInvalidatesFixedFrameMemo(testCase)
            %KSPTOT_BodyInfo memoizes {rotperiod, rotini} into
            %fixedFrameFromInertialFrameCache, and that memo -- not the
            %properties -- is what the ECI<->ECEF conversion actually reads.
            %Assigning either property must therefore invalidate it.
            %
            %Regressing this is close to invisible: the spin *angle* at
            %ut = 0 is unchanged, so position still converts correctly and
            %only the ECEF velocity is wrong. That silently corrupts the
            %wind frame (angle of attack / sideslip / bank) and dynamic
            %pressure, and it corrupts them only once some earlier caller in
            %the same session has warmed the memo -- which made four
            %EventTerminationConditionTest cases fail purely as a function of
            %test execution order.

            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);

            rVect = [800; 0; 0];
            vVect = [0; 2; 0];

            % Warm the memo against the real spin rate.
            bodyInfo.rotperiod = 21549.425;
            bodyInfo.rotini = 0;
            [~, vEcefSpinning] = getFixedFrameVectFromInertialVect(0, rVect, bodyInfo, vVect);

            testCase.verifyGreaterThan(norm(vEcefSpinning - vVect), 1e-6, ...
                'Fixture is not exercising the test: a spinning body must give vEcef ~= vEci');

            % Now stop the body.  With the memo invalidated, ECEF must
            % collapse onto ECI exactly (spin angle 0, spin rate 0).
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;
            [rEcef, vEcef] = getFixedFrameVectFromInertialVect(0, rVect, bodyInfo, vVect);

            testCase.verifyVectorEqual(rEcef(:), rVect(:), 1e-12, ...
                'Setting rotperiod=Inf did not take effect on the ECEF position');
            testCase.verifyVectorEqual(vEcef(:), vVect(:), 1e-12, ...
                ['Setting rotperiod=Inf did not take effect on the ECEF velocity: ' ...
                 'fixedFrameFromInertialFrameCache was not invalidated by set.rotperiod']);
        end
    end
end
