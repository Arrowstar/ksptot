classdef GetBodyXformMatrixTest < matlab.unittest.TestCase
    %GetBodyXformMatrixTest Validates getBodyXformMatrix, the hgtransform
    %that places (and spins) a textured body sphere in the 3D views.
    %
    % getBodyXformMatrix(time, bodyInfo, viewFrame) builds M from:
    %   rotation    : R_BodyFixed_to_ViewFrame * Rz(surftexturezrotoffset)
    %   translation : body position in viewFrame, snapped to zero when the
    %                 view frame is centered on the body itself.
    %
    % Coverage:
    %   - hgtransform format (4x4, [0 0 0 1], orthonormal det +1 rotation)
    %   - own Body-Fixed view -> identity (tilt cancels, offset 0)
    %   - central-body snap-to-origin (Earth ~611 km regression from
    %     bodiesSolarSystem.ini; why the snap is load-bearing)
    %   - non-central bodies keep the computed offset (Moon/Mars in Earth frame)
    %   - own inertial view -> pure spin Rz(spin)*Rz(offset), tilt cancels
    %   - surftexturezrotoffset applied about body Z (and composes with spin)
    %   - translation matches independent convertToFrame wiring
    %   - lon0/lat0 (+X, Gulf of Guinea texel) preserved in own BF view
    %   - frame without origin body (GlobalBaseInertialFrame) keeps offset

    properties
        solarBodies % CelestialBodyData from bodiesSolarSystem.ini (tilted Earth)
        stockBodies % CelestialBodyData from bodies.ini (untilted Kerbin)
    end

    methods(TestClassSetup)
        function setupBodies(testCase)
            ksptotAddProjectPaths();
            root = ksptotTestRoot();
            [rawSolar,~,~] = inifile(fullfile(root,'bodies_other','bodiesSolarSystem.ini'), 'readall');
            testCase.solarBodies = CelestialBodyData(processINIBodyInfo(rawSolar, false, 'bodyInfo'));
            [rawStock,~,~] = inifile(fullfile(root,'bodies.ini'), 'readall');
            testCase.stockBodies = CelestialBodyData(processINIBodyInfo(rawStock, false, 'bodyInfo'));
        end
    end

    methods(Test)
        function outputIsValidHgtransform(testCase)
            % Every M must be a valid hgtransform: 4x4, bottom row
            % [0 0 0 1], rotation orthonormal with det +1.
            earth = testCase.solar('Earth');
            kerbin = testCase.stock('Kerbin');
            moon = testCase.solar('Moon');
            gi = testCase.solarBodies.globalBaseFrame;
            cases = {
                {earth,  earth.getBodyFixedFrame(),  0}, ...
                {kerbin, kerbin.getBodyFixedFrame(), 0}, ...
                {earth,  earth.getBodyCenteredInertialFrame(), 12345.678}, ...
                {moon,   earth.getBodyFixedFrame(),  0}, ...
                {earth,  gi, 0}, ...
                };
            for k = 1:numel(cases)
                b = cases{k}{1}; vf = cases{k}{2}; ut = cases{k}{3};
                M = getBodyXformMatrix(ut, b, vf);
                testCase.verifySize(M, [4 4], sprintf('case %d: M must be 4x4', k));
                testCase.verifyEqual(M(4,:), [0 0 0 1], 'AbsTol', 1e-12, sprintf('case %d: bottom row', k));
                R = M(1:3,1:3);
                testCase.verifyEqual(R*R', eye(3), 'AbsTol', 1e-9, sprintf('case %d: rotation orthonormal', k));
                testCase.verifyEqual(det(R), 1, 'AbsTol', 1e-9, sprintf('case %d: rotation det +1 (no mirror)', k));
            end
        end

        function bodyFixedViewOfOwnBodyIsIdentity(testCase)
            % In its own Body-Fixed view the sphere is unrotated and
            % untranslated (tilt cancels in R_View' * R_BF; snap zeroes t).
            % Holds across time and for tilted (Earth/Mars) and untilted (Kerbin).
            % Tolerance 1e-7: R_View' * R_BF are separately evaluated frame
            % matrices, so roundoff is ~1e-8 for Mars (2.1e-08 observed),
            % still sub-millimetre on the surface.
            bodies = {testCase.solar('Earth'), testCase.stock('Kerbin'), testCase.solar('Mars')};
            for ut = [0, 1000, 828354912]
                for i = 1:numel(bodies)
                    b = bodies{i};
                    M = getBodyXformMatrix(ut, b, b.getBodyFixedFrame());
                    testCase.verifyEqual(M, eye(4), 'AbsTol', 1e-7, ...
                        sprintf('%s own-BF ut=%.0f must be identity', b.name, ut));
                end
            end
        end

        function centralBodySnapsToOriginInOwnFrames(testCase)
            % Regression: Earth in its own BF frame used to sit ~611 km off
            % origin (M trans [239,-43,561] at ut=0), shifting 0,0 lat/long
            % off the Gulf of Guinea. Must be exactly zero now, in BF and BCI.
            bodies = {testCase.solar('Earth'), testCase.solar('Moon'), ...
                      testCase.solar('Mars'), testCase.stock('Kerbin')};
            for ut = [0, 828354912]
                for i = 1:numel(bodies)
                    b = bodies{i};
                    Mbf = getBodyXformMatrix(ut, b, b.getBodyFixedFrame());
                    testCase.verifyEqual(Mbf(1:3,4), [0;0;0], 'AbsTol', 1e-12, ...
                        sprintf('%s own-BF ut=%.0f translation', b.name, ut));
                    Mbci = getBodyXformMatrix(ut, b, b.getBodyCenteredInertialFrame());
                    testCase.verifyEqual(Mbci(1:3,4), [0;0;0], 'AbsTol', 1e-12, ...
                        sprintf('%s own-BCI ut=%.0f translation', b.name, ut));
                end
            end
        end

        function earthSnapIsLoadBearing(testCase)
            % Documents WHY the snap exists: the raw ephemeris path (before
            % snapping) still disagrees with itself for Earth by ~611 km,
            % because getStateAtTime (MEX, equatorial threshold 1E-4 rad)
            % forces Earth's 0.000418 deg osculating incl exactly equatorial
            % while getPositOfBodyWRTSun (fast chain, 1E-10 rad) keeps the
            % out-of-plane component.
            %
            % NOTE (maintenance): this test intentionally locks in that
            % current raw-offset behavior (~611 km, bounded here as
            % 100-5000 km). If the ephemeris equatorial thresholds are ever
            % unified (which requires a MEX recompile to take effect at
            % runtime), the raw offset will collapse to ~0 and THIS TEST
            % WILL FAIL. That failure is the intended signal to remove the
            % snap-to-origin block in getBodyXformMatrix.m and simplify this
            % test to assert the raw path is itself ~0 (i.e. delete this
            % load-bearing check and keep only centralBodySnapsToOriginInOwnFrames
            % as belt-and-braces).
            earth = testCase.solar('Earth');
            ut = 0;
            ce = earth.getElementSetsForTimes(ut);
            ce = ce.convertToCartesianElementSet().convertToFrame(earth.getBodyFixedFrame());
            rawOffset = ce.rVect;
            testCase.verifyGreaterThan(norm(rawOffset), 100, ...
                'raw Earth BF offset should still be ~611 km (snap is load-bearing)');
            testCase.verifyLessThan(norm(rawOffset), 5000, ...
                'raw Earth BF offset should stay small (sanity, not interplanetary scale)');
        end

        function nonCentralBodyKeepsComputedOffset(testCase)
            % The snap must NOT fire for other bodies: Moon in Earth BF view
            % sits at lunar distance with the frame-conversion position.
            earth = testCase.solar('Earth');
            moon = testCase.solar('Moon');
            ut = 0;
            M = getBodyXformMatrix(ut, moon, earth.getBodyFixedFrame());
            t = M(1:3,4);
            testCase.verifyGreaterThan(norm(t), 300000, 'Moon distance lower bound');
            testCase.verifyLessThan(norm(t), 500000, 'Moon distance upper bound');
            ce = moon.getElementSetsForTimes(ut);
            ce = ce.convertToCartesianElementSet().convertToFrame(earth.getBodyFixedFrame());
            testCase.verifyEqual(t, ce.rVect, 'AbsTol', 1e-6, ...
                'translation must come from the frame conversion');
        end

        function interplanetaryOffsetKeepsComputedPosition(testCase)
            % Same wiring check at interplanetary scale: Mars in Earth BF view.
            earth = testCase.solar('Earth');
            mars = testCase.solar('Mars');
            ut = 0;
            M = getBodyXformMatrix(ut, mars, earth.getBodyFixedFrame());
            t = M(1:3,4);
            testCase.verifyGreaterThan(norm(t), 5e7, 'Mars distance lower bound (0.3 AU)');
            testCase.verifyLessThan(norm(t), 5e8, 'Mars distance upper bound (3.3 AU)');
            ce = mars.getElementSetsForTimes(ut);
            ce = ce.convertToCartesianElementSet().convertToFrame(earth.getBodyFixedFrame());
            testCase.verifyEqual(t, ce.rVect, 'AbsTol', 1e-3, ...
                'translation must come from the frame conversion');
        end

        function inertialViewRotatesWithSpinAngle(testCase)
            % In its own BCI view the tilt cancels and the texture spins by
            % exactly Rz(spin)*Rz(offset). Covers tilted Earth and untilted Kerbin.
            bodies = {testCase.solar('Earth'), testCase.stock('Kerbin')};
            for ut = [0, 12345.678]
                for i = 1:numel(bodies)
                    b = bodies{i};
                    M = getBodyXformMatrix(ut, b, b.getBodyCenteredInertialFrame());
                    spin = mod(deg2rad(b.rotini) + 2*pi/b.rotperiod*ut, 2*pi);
                    testCase.verifyEqual(getBodySpinAngle(b, ut), spin, 'AbsTol', 1e-12, ...
                        sprintf('%s spin angle ut=%.3f', b.name, ut));
                    expected = testCase.rotZ(spin) * testCase.rotZ(deg2rad(b.surftexturezrotoffset));
                    testCase.verifyEqual(M(1:3,1:3), expected, 'AbsTol', 1e-9, ...
                        sprintf('%s own-BCI rotation ut=%.3f', b.name, ut));
                    testCase.verifyEqual(M(1:3,4), [0;0;0], 'AbsTol', 1e-12, ...
                        sprintf('%s own-BCI translation ut=%.3f', b.name, ut));
                end
            end
        end

        function surfTextureZRotOffsetAppliedAboutBodyZ(testCase)
            % A non-zero texture offset must appear as an extra Z rotation,
            % composed AFTER the frame rotation, without moving the origin.
            kerbin = testCase.stock('Kerbin');
            orig = kerbin.surftexturezrotoffset;
            restore = onCleanup(@() set(kerbin, 'surftexturezrotoffset', orig)); %#ok<NASGU>
            kerbin.surftexturezrotoffset = 90;

            Mbf = getBodyXformMatrix(0, kerbin, kerbin.getBodyFixedFrame());
            testCase.verifyEqual(Mbf(1:3,1:3), testCase.rotZ(deg2rad(90)), 'AbsTol', 1e-9, ...
                'BF rotation must equal Rz(offset)');
            testCase.verifyEqual(Mbf(1:3,4), [0;0;0], 'AbsTol', 1e-12, ...
                'snap still applies with offset');

            ut = 10000;
            Mbci = getBodyXformMatrix(ut, kerbin, kerbin.getBodyCenteredInertialFrame());
            spin = mod(deg2rad(kerbin.rotini) + 2*pi/kerbin.rotperiod*ut, 2*pi);
            testCase.verifyEqual(Mbci(1:3,1:3), testCase.rotZ(spin)*testCase.rotZ(deg2rad(90)), ...
                'AbsTol', 1e-9, 'offset must compose after spin: Rz(spin)*Rz(offset)');
        end

        function lonZeroLatZeroPreservedInOwnBodyFixedView(testCase)
            % End-to-end for the reported issue: BF lon0/lat0 (+X, Gulf of
            % Guinea texel) must map to itself in the Earth BF view, at any time.
            earth = testCase.solar('Earth');
            pBF = [earth.radius; 0; 0];
            for ut = [0, 828354912]
                M = getBodyXformMatrix(ut, earth, earth.getBodyFixedFrame());
                pView = M * [pBF; 1];
                testCase.verifyEqual(pView(1:3), pBF, 'AbsTol', 1e-6, ...
                    sprintf('0,0 lat/long must stay on +X at ut=%.0f', ut));
            end
        end

        function frameWithoutOriginBodyKeepsComputedOffset(testCase)
            % GlobalBaseInertialFrame.getOriginBody throws; the try/catch must
            % keep the computed offset instead of erroring (covers catch path).
            earth = testCase.solar('Earth');
            ut = 0;
            gi = testCase.solarBodies.globalBaseFrame;
            M = getBodyXformMatrix(ut, earth, gi); % must not throw
            t = M(1:3,4);
            testCase.verifyGreaterThan(norm(t), 1.4e8, 'heliocentric distance lower bound');
            testCase.verifyLessThan(norm(t), 1.6e8, 'heliocentric distance upper bound');
            spin = getBodySpinAngle(earth, ut);
            Rbf2gi = getBodyFixedToGlobalInertialFrame(ut, spin(:)', ...
                earth.bodyRotMatFromGlobalInertialToBodyInertial);
            expectedR = Rbf2gi * testCase.rotZ(deg2rad(earth.surftexturezrotoffset));
            testCase.verifyEqual(M(1:3,1:3), expectedR, 'AbsTol', 1e-9, ...
                'GI rotation must equal R_BF_to_GI * Rz(offset)');
        end
    end

    methods
        function b = solar(testCase, name)
            bs = testCase.solarBodies.getAllBodyInfo();
            idx = find(arrayfun(@(x) strcmpi(x.name, name), bs), 1);
            b = bs(idx);
        end

        function b = stock(testCase, name)
            bs = testCase.stockBodies.getAllBodyInfo();
            idx = find(arrayfun(@(x) strcmpi(x.name, name), bs), 1);
            b = bs(idx);
        end

        function Rz = rotZ(~, a)
            Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
        end
    end
end
