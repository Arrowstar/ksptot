classdef FixedFrameTiltTest < matlab.unittest.TestCase
    %FixedFrameTiltTest Verifies tilt-aware fixed-frame conversions.
    %
    % Legacy fixed-frame code historically assumed body-centered inertial
    % (BCI, equatorial, standard ECI) == Global Inertial (GI, ecliptic
    % J2000) translated to the body center, i.e. spin-only ECI<->ECEF with
    % no tilt term. That holds for untilted bodies (Kerbin stock,
    % bodyRotMat==eye(3)) but fails for tilted bodies in
    % bodiesSolarSystem.ini (Earth obliquity 23.44 deg about X).
    %
    % New helpers make the distinction explicit:
    %   BCI<->BF (spin-only, legacy, unchanged):
    %     getFixedFrameVectFromInertialVect (BCI->BF)
    %     getInertialVectFromFixedFrameVect (BF->BCI)
    %     getLatLongAltFromInertialVect (BCI->geographic)
    %     getInertialVectFromLatLongAlt (geographic->BCI)
    %   GI<->BCI (tilt-only, new):
    %     getBodyInertialVectFromGlobalInertialVect
    %     getGlobalInertialVectFromBodyInertialVect
    %   GI<->BF (tilt + spin, new):
    %     getFixedFrameVectFromGlobalInertialVect
    %     getGlobalInertialVectFromFixedFrameVect
    %     getLatLongAltFromGlobalInertialVect
    %     getGlobalInertialVectFromLatLongAlt
    % plus computeHourAngle now uses GI->BF (tilt-aware) for the Sun vector
    % from getPositOfBodyWRTSun (ecliptic), fixing day/night by up to 23.4 deg.

    properties
        solarBodies % struct from bodiesSolarSystem.ini (tilted Earth)
        stockBodies % struct from bodies.ini (untilted Kerbin)
    end

    methods(TestClassSetup)
        function setupBodies(testCase)
            ksptotAddProjectPaths();
            root = ksptotTestRoot();
            [rawSolar,~,~] = inifile(fullfile(root,'bodies_other','bodiesSolarSystem.ini'), 'readall');
            testCase.solarBodies = processINIBodyInfo(rawSolar, false, 'bodyInfo');
            [rawStock,~,~] = inifile(fullfile(root,'bodies.ini'), 'readall');
            testCase.stockBodies = processINIBodyInfo(rawStock, false, 'bodyInfo');
        end
    end

    methods(Test)
        function untiltedGiEqualsBci(testCase)
            % For untilted Kerbin (tilt == identity), GI->BF must equal BCI->BF.
            kerbin = testCase.stockBodies.kerbin;
            testCase.verifyEqual(kerbin.bodyRotMatFromGlobalInertialToBodyInertial, eye(3), 'AbsTol', 1e-12, 'Kerbin must be untilted for this test');

            uts = [0, 1000, 828354912, -1e6];
            for ut = uts
                r = [1000; -2000; 500];
                v = [1.5; -0.5; 0.2];
                [rBF_gi, vBF_gi] = getFixedFrameVectFromGlobalInertialVect(ut, r, kerbin, v);
                [rBF_bci, vBF_bci] = getFixedFrameVectFromInertialVect(ut, r, kerbin, v);
                testCase.verifyEqual(rBF_gi, rBF_bci, 'AbsTol', 1e-9, sprintf('Kerbin GI==BCI position ut=%.0f',ut));
                testCase.verifyEqual(vBF_gi, vBF_bci, 'AbsTol', 1e-9, sprintf('Kerbin GI==BCI velocity ut=%.0f',ut));

                [rGI, vGI] = getGlobalInertialVectFromFixedFrameVect(ut, rBF_bci, kerbin, vBF_bci);
                [rBCI, vBCI] = getInertialVectFromFixedFrameVect(ut, rBF_bci, kerbin, vBF_bci);
                testCase.verifyEqual(rGI, rBCI, 'AbsTol', 1e-9);
                testCase.verifyEqual(vGI, vBCI, 'AbsTol', 1e-9);
            end
        end

        function kscPadRoundTripBciPreserved(testCase)
            % KSC pad in BF must round-trip through BCI (spin-only) exactly.
            % This is the liftoff case from the issue: 28.62716N, 279.3791E.
            earth = testCase.solarBodies.earth;
            lat0 = deg2rad(28.62716);
            lon0 = deg2rad(279.3791); % == -80.6209 after wrapTo180
            for ut = [0, 828354912]
                [rBCI, ~] = getInertialVectFromLatLongAlt(ut, lat0, lon0, 0, earth, [NaN;NaN;NaN]);
                [lat1, long1, alt1] = getLatLongAltFromInertialVect(ut, rBCI, earth);
                testCase.verifyEqual(rad2deg(lat1), rad2deg(lat0), 'AbsTol', 1e-9, sprintf('KSC lat BCI round-trip ut=%.0f',ut));
                testCase.verifyEqual(wrapTo180(rad2deg(long1)), wrapTo180(rad2deg(lon0)), 'AbsTol', 1e-9);
                testCase.verifyEqual(alt1, 0, 'AbsTol', 1e-6);
            end
        end

        function giVsBciDifferByTiltForEarth(testCase)
            % Same physical pad expressed in GI vs BCI must differ by tilt,
            % and misusing a GI vector as BCI (legacy spin-only) must give
            % the ~23 deg wrong latitude seen in the issue. New GI helpers fix it.
            earth = testCase.solarBodies.earth;
            tilt = earth.bodyRotMatFromGlobalInertialToBodyInertial; % R_GI_to_BI
            testCase.verifyGreaterThan(norm(tilt - eye(3)), 0.1, 'Earth must be tilted for this test');

            lat0 = deg2rad(28.62716);
            lon0 = deg2rad(279.3791);
            ut = 828354912; % Year 27 Day 98 10:35:12, from issue

            % Pad -> BCI (correct, spin-only) and pad -> GI (tilt + spin).
            [rBCI, ~] = getInertialVectFromLatLongAlt(ut, lat0, lon0, 0, earth, [NaN;NaN;NaN]);
            [rGI, ~] = getGlobalInertialVectFromLatLongAlt(ut, lat0, lon0, 0, earth, [NaN;NaN;NaN]);

            % BCI and GI (both body-centered, same physical point) differ by tilt.
            [rBCI_fromGI, ~] = getBodyInertialVectFromGlobalInertialVect(rGI, earth);
            testCase.verifyEqual(rBCI_fromGI, rBCI, 'AbsTol', 1e-6, 'GI->BCI tilt must map pad GI to pad BCI');
            [rGI_fromBCI, ~] = getGlobalInertialVectFromBodyInertialVect(rBCI, earth);
            testCase.verifyEqual(rGI_fromBCI, rGI, 'AbsTol', 1e-6);

            % Correct paths preserve pad.
            [latBCI, ~] = getLatLongAltFromInertialVect(ut, rBCI, earth);
            testCase.verifyEqual(rad2deg(latBCI), 28.62716, 'AbsTol', 1e-6);
            [latGI, lonGI] = getLatLongAltFromGlobalInertialVect(ut, rGI, earth);
            testCase.verifyEqual(rad2deg(latGI), 28.62716, 'AbsTol', 1e-6);
            testCase.verifyEqual(wrapTo180(rad2deg(lonGI)), wrapTo180(rad2deg(lon0)), 'AbsTol', 1e-6);

            % BUG DEMO: feeding GI (ecliptic Sun-style vector) to legacy
            % BCI-only routine ignores tilt. At this UT the error is huge
            % (5.2N vs 28.6N; at UT=0 it is 33.8N, inland NW like screenshot).
            [latWrong, ~] = getLatLongAltFromInertialVect(ut, rGI, earth);
            testCase.verifyGreaterThan(abs(rad2deg(latWrong) - 28.62716), 10, 'GI-as-BCI must be >10 deg off at this UT (tilt ignored)');
            testCase.verifyEqual(rad2deg(latWrong), 5.2029, 'AbsTol', 0.05, 'GI-as-BCI latitude at UT 828354912');
        end

        function roundTripsPreserve(testCase)
            % GI->BF->GI, BF->GI->BF, BCI->BF->BCI must all preserve vectors.
            earth = testCase.solarBodies.earth;
            kerbin = testCase.stockBodies.kerbin;
            rBF = [6378.14*cosd(28.6)*cosd(-80.6); 6378.14*cosd(28.6)*sind(-80.6); 6378.14*sind(28.6)];
            vBF = [0.1; -0.2; 0.05];
            rBCI = [5000; -3000; 2000];
            vBCI = [1; 2; -0.5];
            rGI = [1e8; -2e7; 1e7];
            vGI = [10; -5; 2];
            for ut = [0, 123456.789, 828354912]
                % BCI round-trip (legacy, spin-only, unchanged behavior).
                [r1, v1] = getFixedFrameVectFromInertialVect(ut, rBCI, earth, vBCI);
                [r2, v2] = getInertialVectFromFixedFrameVect(ut, r1, earth, v1);
                testCase.verifyEqual(r2, rBCI, 'AbsTol', 1e-6);
                testCase.verifyEqual(v2, vBCI, 'AbsTol', 1e-6);

                % GI round-trips (new, tilt + spin).
                [rb1, vb1] = getFixedFrameVectFromGlobalInertialVect(ut, rGI, earth, vGI);
                [rg2, vg2] = getGlobalInertialVectFromFixedFrameVect(ut, rb1, earth, vb1);
                testCase.verifyEqual(rg2, rGI, 'RelTol', 1e-9);
                testCase.verifyEqual(vg2, vGI, 'RelTol', 1e-9);

                [rg1, vg1] = getGlobalInertialVectFromFixedFrameVect(ut, rBF, earth, vBF);
                [rb2, vb2] = getFixedFrameVectFromGlobalInertialVect(ut, rg1, earth, vg1);
                testCase.verifyEqual(rb2, rBF, 'RelTol', 1e-9);
                testCase.verifyEqual(vb2, vBF, 'RelTol', 1e-9);

                % Same for untilted Kerbin (sanity, backward compat).
                [rk1, vk1] = getFixedFrameVectFromGlobalInertialVect(ut, rBCI, kerbin, vBCI);
                [rk2, vk2] = getGlobalInertialVectFromFixedFrameVect(ut, rk1, kerbin, vk1);
                testCase.verifyEqual(rk2, rBCI, 'AbsTol', 1e-6);
                testCase.verifyEqual(vk2, vBCI, 'AbsTol', 1e-6);
            end
        end

        function matchesNewFrameRotation(testCase)
            % New GI<->BF rotation must match gold-standard
            % getBodyFixedToGlobalInertialFrame (used by BodyFixedFrame,
            % independent code path via axang2rotm). Position-only check
            % isolates rotation from omega handling.
            earth = testCase.solarBodies.earth;
            tilt = earth.bodyRotMatFromGlobalInertialToBodyInertial;
            for ut = [0, 828354912, 12345.678]
                spinAngle = mod(deg2rad(earth.rotini) + 2*pi/earth.rotperiod*ut, 2*pi);
                R_BF_to_GI = getBodyFixedToGlobalInertialFrame(ut, spinAngle, tilt);
                R_GI_to_BF_expected = R_BF_to_GI';
                [~, ~, R_GI_to_BF] = getFixedFrameVectFromGlobalInertialVect(ut, [1e8;0;0], earth);
                testCase.verifyEqual(R_GI_to_BF, R_GI_to_BF_expected, 'AbsTol', 1e-9, sprintf('GI->BF rotation ut=%.0f',ut));

                % BCI->BF (legacy spin-only) must match new-frames BCI->BF:
                % R_BCI_to_BF = Rz(spin)' . Build CartesianElementSets in
                % BCI/BF and convert via convertToFrame.
                rBCI = [5000; -3000; 2000];
                bciFrame = earth.getBodyCenteredInertialFrame();
                ceBCI = CartesianElementSet(ut, rBCI, [0;0;0], bciFrame);
                ceBF = ceBCI.convertToFrame(earth.getBodyFixedFrame());
                [rBF_legacy, ~] = getFixedFrameVectFromInertialVect(ut, rBCI, earth);
                testCase.verifyEqual(ceBF.rVect, rBF_legacy, 'AbsTol', 1e-6, 'legacy BCI->BF must match new frames');
            end
        end

        function hourAngleUsesTilt(testCase)
            % Sun ECEF via new GI->BF must equal Sun BCI->BF only when tilt==I.
            % For tilted Earth they must differ (old code ignored tilt).
            earth = testCase.solarBodies.earth;
            kerbin = testCase.stockBodies.kerbin;
            ut = 828354912;
            [rSunGI, ~] = getPositOfBodyWRTSun(ut, earth, testCase.solarBodies);
            rSunGI = -rSunGI; % Sun w.r.t. Earth, GI (ecliptic), body-centered
            [rSunBF_new, ~] = getFixedFrameVectFromGlobalInertialVect(ut, rSunGI, earth);
            % Legacy misuse (GI as if BCI, spin-only) - old computeHourAngle path:
            [rSunBF_old, ~] = getFixedFrameVectFromInertialVect(ut, rSunGI, earth);
            testCase.verifyGreaterThan(norm(rSunBF_new - rSunBF_old), 1e6, 'Earth Sun ECEF must differ with/without tilt (1e6 km scale)');
            % Untilted Kerbin: no difference.
            [rKerSunGI, ~] = getPositOfBodyWRTSun(0, kerbin, testCase.stockBodies);
            if(norm(rKerSunGI) > 0)
                rKerSunGI = -rKerSunGI;
                [rkNew, ~] = getFixedFrameVectFromGlobalInertialVect(0, rKerSunGI, kerbin);
                [rkOld, ~] = getFixedFrameVectFromInertialVect(0, rKerSunGI, kerbin);
                testCase.verifyEqual(rkNew, rkOld, 'AbsTol', 1e-6);
            end
            % Hour angle itself runs without error and is finite for KSC lon.
            hra = computeHourAngle(ut, deg2rad(279.3791), earth);
            testCase.verifyTrue(isfinite(hra) && abs(hra) <= pi);
        end

        function vectorizedUtAndNanVelocity(testCase)
            % New GI helpers must handle vector UT (1xN, 3xN) like the legacy
            % MEX path, return R as 3x3xN, and preserve the NaN "no velocity"
            % sentinel used by computeHourAngle for position-only calls.
            earth = testCase.solarBodies.earth;
            uts = [0 1000 2000];
            rGI = repmat([1e8;-2e7;1e7], 1, 3);
            vGI = repmat([10;-5;2], 1, 3);

            [rBF, vBF, R] = getFixedFrameVectFromGlobalInertialVect(uts, rGI, earth, vGI);
            testCase.verifySize(rBF, [3 3]);
            testCase.verifySize(vBF, [3 3]);
            testCase.verifySize(R, [3 3 3]);

            % Scalar call must match the corresponding column of vector call.
            [rBFs, vBFs] = getFixedFrameVectFromGlobalInertialVect(uts(1), rGI(:,1), earth, vGI(:,1));
            testCase.verifyEqual(rBFs, rBF(:,1), 'AbsTol', 1e-6);
            testCase.verifyEqual(vBFs, vBF(:,1), 'AbsTol', 1e-6);

            % Omitted velocity -> all-NaN velocity, correct position.
            [rBFp, vBFp] = getFixedFrameVectFromGlobalInertialVect(uts, rGI, earth);
            testCase.verifyEqual(rBFp, rBF, 'AbsTol', 1e-6);
            testCase.verifyTrue(all(isnan(vBFp), 'all'), 'omitted velocity must stay NaN');

            % Lat/long without velocity must not crash and must yield NaN rates.
            [~, ~, ~, ~, h, vv] = getLatLongAltFromGlobalInertialVect(uts(1), rGI(:,1), earth);
            testCase.verifyTrue(isnan(h) && isnan(vv));

            % Reverse direction is vectorized too.
            [rg, vg] = getGlobalInertialVectFromFixedFrameVect(uts, rBF, earth, vBF);
            testCase.verifySize(rg, [3 3]);
            testCase.verifyEqual(rg, rGI, 'RelTol', 1e-9);
            testCase.verifyEqual(vg, vGI, 'RelTol', 1e-9);
        end

        function samePhysicalVectorVelocityConsistent(testCase)
            % Same physical state in BCI vs GI coordinates must yield identical
            % BF position AND velocity (incl. SEZ/horz/vert). Round-trips alone
            % cannot catch a wrong tilt because forward/inverse cancel; this
            % cross-checks the omega handling through the tilt step.
            earth = testCase.solarBodies.earth;
            Rbi2gi = earth.bodyRotMatFromGlobalInertialToBodyInertial';
            ut = 828354912;
            rBCI = [5000; -3000; 2000];
            vBCI = [1; 2; -0.5];
            rGI = Rbi2gi * rBCI; % same physical vectors, GI coords
            vGI = Rbi2gi * vBCI;

            [rBFa, vBFa] = getFixedFrameVectFromInertialVect(ut, rBCI, earth, vBCI);
            [rBFb, vBFb] = getFixedFrameVectFromGlobalInertialVect(ut, rGI, earth, vGI);
            testCase.verifyEqual(rBFb, rBFa, 'AbsTol', 1e-9);
            testCase.verifyEqual(vBFb, vBFa, 'AbsTol', 1e-9);

            [latA, lonA, ~, ~, hA, vertA] = getLatLongAltFromInertialVect(ut, rBCI, earth, vBCI);
            [latB, lonB, ~, ~, hB, vertB] = getLatLongAltFromGlobalInertialVect(ut, rGI, earth, vGI);
            testCase.verifyEqual(latB, latA, 'AbsTol', 1e-12);
            testCase.verifyEqual(wrapTo180(rad2deg(lonB - lonA)), 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(hB, hA, 'AbsTol', 1e-9);
            testCase.verifyEqual(vertB, vertA, 'AbsTol', 1e-9);
        end

        function retrogradeTiltedBody(testCase)
            % Venus: retrograde spin (rotperiod < 0) plus large tilt.
            % Round-trips and new-frame agreement must hold with the sign flip.
            venus = testCase.solarBodies.venus;
            testCase.verifyLessThan(venus.rotperiod, 0, 'Venus must be retrograde for this test');
            testCase.verifyGreaterThan(norm(venus.bodyRotMatFromGlobalInertialToBodyInertial - eye(3)), 0.1, 'Venus must be tilted for this test');

            ut = 1e7;
            rBCI = [8000; 1000; -3000];
            vBCI = [-0.5; 1.5; 0.8];
            [rBF, vBF] = getFixedFrameVectFromInertialVect(ut, rBCI, venus, vBCI);
            [rBack, vBack] = getInertialVectFromFixedFrameVect(ut, rBF, venus, vBF);
            testCase.verifyEqual(rBack, rBCI, 'AbsTol', 1e-6);
            testCase.verifyEqual(vBack, vBCI, 'AbsTol', 1e-6);

            rGI = [5e7; 1e7; -2e6];
            vGI = [8; -3; 1];
            [rb1, vb1] = getFixedFrameVectFromGlobalInertialVect(ut, rGI, venus, vGI);
            [rg2, vg2] = getGlobalInertialVectFromFixedFrameVect(ut, rb1, venus, vb1);
            testCase.verifyEqual(rg2, rGI, 'RelTol', 1e-9);
            testCase.verifyEqual(vg2, vGI, 'RelTol', 1e-9);

            % Legacy BCI->BF must still match new-frames conversion for retrograde.
            bciFrame = venus.getBodyCenteredInertialFrame();
            ceBCI = CartesianElementSet(ut, rBCI, [0;0;0], bciFrame);
            ceBF = ceBCI.convertToFrame(venus.getBodyFixedFrame());
            [rBFlegacy, ~] = getFixedFrameVectFromInertialVect(ut, rBCI, venus);
            testCase.verifyEqual(ceBF.rVect, rBFlegacy, 'AbsTol', 1e-6);
        end

        function subSolarHourAngleZero(testCase)
            % End-to-end check of the computeHourAngle fix: hour angle at the
            % sub-solar longitude (from tilt-aware Sun ECEF) must be ~0 and
            % at the antipode ~pi. Legacy spin-only misuse is off by ~degrees.
            earth = testCase.solarBodies.earth;
            for ut = [1e7, 828354912]
                [rB2S, ~] = getPositOfBodyWRTSun(ut, earth, testCase.solarBodies);
                rSunGI = -rB2S;
                [rSunBF, ~] = getFixedFrameVectFromGlobalInertialVect(ut, rSunGI, earth);
                subLon = AngleZero2Pi(atan2(rSunBF(2), rSunBF(1)));

                hraSub = computeHourAngle(ut, subLon, earth);
                testCase.verifyEqual(hraSub, 0, 'AbsTol', 1e-9, sprintf('sub-solar HRA ut=%.0f', ut));
                hraAnti = computeHourAngle(ut, subLon + pi, earth);
                testCase.verifyEqual(abs(hraAnti), pi, 'AbsTol', 1e-9, sprintf('antipode HRA ut=%.0f', ut));

                % Old path (GI vector through spin-only BCI routine) gets the
                % sub-solar meridian wrong -- at ut=1e7 by >2 deg.
                [rSunBFold, ~] = getFixedFrameVectFromInertialVect(ut, rSunGI, earth);
                subOld = AngleZero2Pi(atan2(rSunBFold(2), rSunBFold(1)));
                if(ut == 1e7)
                    testCase.verifyGreaterThan(abs(wrapTo180(rad2deg(subOld - subLon))), 2.0, 'legacy sub-solar lon off by >2 deg at ut=1e7');
                end
            end
        end
    end
end
