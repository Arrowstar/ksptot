classdef KwtAeroTest < KsptotTestCase
    %KwtAeroTest Thorough tests for the KWT-replay aero pipeline:
    %kwt_physicsGlobals, ksp_evalFloatCurve, lvd_import_cubeDB,
    %ksp_lookupCube, ksp_setDrag, kwt_inflowFromAeroAngles,
    %kwt_buildAeroSpec, kwt_aero, kwt_sweepCraft,
    %lvd_generateAeroTablesFromCraft, lvd_importAeroTableFromCraft, and
    %the lift dialog's "Generate from Craft..." button.
    %
    %All fixtures are synthetic (no KSP install required), except the
    %gated oracle tests (KSPTOT_KSP_ROOT): kOS drag bands, KWT AoA-slice
    %vector agreement, and the component-level KWT Vessel comparison
    %(kwtVesselComponentAgreement: body corr 0.999 at ratio ~1.02,
    %pod/fin/wing-drag groups bit-exact). Every sign/frame convention is
    %pinned by round-trips through LVD's own aero-angle functions plus
    %the KWT oracles instead of the absolute-|ClS| follow-up originally
    %scoped in KWT_Lift_Methodology section 7.5.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        %% ------------------------- physics globals -------------------------
        function defaultsMatchStockPhysicsCfg(testCase)
            phys = kwt_physicsGlobals();

            testCase.verifyEqual(phys.dragMultiplier, 8, 'AbsTol', 0);
            testCase.verifyEqual(phys.dragCubeMultiplier, 0.1, 'AbsTol', 0);
            testCase.verifyEqual(phys.liftMultiplier, 0.036, 'AbsTol', 0);
            testCase.verifyEqual(phys.liftDragMultiplier, 0.015, 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMultiplier, 18, 'AbsTol', 0);

            % Spot-checks transcribed from KSP 1.12.5 Physics.cfg.
            testCase.verifyEqual(phys.tipCurve(1, :), [0 1 0 0], 'AbsTol', 0);
            testCase.verifyEqual(phys.tipCurve(end, :), [5 4 0 0], 'AbsTol', 0);
            testCase.verifyEqual(size(phys.cdCurve), [8 4]);
            testCase.verifyEqual(phys.cdCurve(end, :), [1 1 1 1], 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMachCurve(1, :), [0.3 0.167 0 0], 'AbsTol', 0);
            testCase.verifyEqual(phys.wingLiftCurve(3, :), ...
                [0.5 0.9026583 0.7074468 -0.7074468], 'AbsTol', 1e-9);
            testCase.verifyEqual(phys.sourcePath, '');
        end

        function parsesMiniPhysicsCfg(testCase)
            cfgPath = testCase.writeLines('miniPhysics.cfg', { ...
                'dragMultiplier = 7', ...
                'dragCubeMultiplier = 0.2', ...
                'liftMultiplier = 0.04', ...
                'liftDragMultiplier = 0.02', ...
                'bodyLiftMultiplier = 17', ...
                'DRAG_TIP', '{', ...
                '    key = 0 2 0 0', ...
                '    key = 5 8 0 0', ...
                '}', ...
                'LIFTING_SURFACE_CURVES', '{', ...
                '    LIFTING_SURFACE', '    {', ...
                '        name = Default', ...
                '        lift', '        {', ...
                '            key = 0 0 0 0', ...
                '            key = 1 3 0 0', ...
                '        }', ...
                '        liftMach', '        {', ...
                '            key = 0 0.5 0 0', ...
                '        }', ...
                '        drag', '        {', ...
                '            key = 0 0.1 0 0', ...
                '        }', ...
                '        dragMach', '        {', ...
                '            key = 0 0.2 0 0', ...
                '        }', ...
                '    }', ...
                '    LIFTING_SURFACE', '    {', ...
                '        name = BodyLift', ...
                '        lift', '        {', ...
                '            key = 0 0 0 0', ...
                '        }', ...
                '        liftMach', '        {', ...
                '            key = 0.3 0.25 0 0', ...
                '        }', ...
                '        drag', '        {', ...
                '            key = 0 0 0 0', ...
                '        }', ...
                '        dragMach', '        {', ...
                '            key = 0 0 0 0', ...
                '        }', ...
                '    }', ...
                '}'});

            phys = kwt_physicsGlobals(cfgPath);

            testCase.verifyEqual(phys.dragMultiplier, 7, 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMultiplier, 17, 'AbsTol', 0);
            testCase.verifyEqual(phys.tipCurve, [0 2 0 0; 5 8 0 0], 'AbsTol', 0);
            testCase.verifyEqual(phys.wingLiftCurve, [0 0 0 0; 1 3 0 0], 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMachCurve, [0.3 0.25 0 0], 'AbsTol', 0);
            % Unmentioned curves keep stock defaults.
            testCase.verifyEqual(size(phys.cdCurve), [8 4]);
            testCase.verifyEqual(phys.sourcePath, cfgPath);
        end

        function missingPhysicsFileErrors(testCase)
            testCase.verifyError( ...
                @() kwt_physicsGlobals(fullfile(tempdir(), 'no-such-physics.cfg')), ...
                'kwt_physicsGlobals:fileNotFound');
        end

        function defaultsCrossCheckCommittedLiftTables(testCase)
            % The lift-curve key coordinates are independently transcribed
            % in LiftCoefficientCurves (used by CylindricalLiftModel), so a
            % typo in either copy fails here rather than silently biasing
            % every swept table.
            phys = kwt_physicsGlobals();
            curves = LiftCoefficientCurves();

            testCase.verifyEqual(phys.wingLiftCurve(:, 1), ...
                curves.defaultGiLift.GridVectors{1}(:), 'AbsTol', 0, ...
                'Default lift AoA keys diverge from LiftCoefficientCurves.');
            testCase.verifyEqual(phys.wingLiftCurve(:, 2), ...
                curves.defaultGiLift.Values(:), 'AbsTol', 0, ...
                'Default lift Cl keys diverge from LiftCoefficientCurves.');
            testCase.verifyEqual(phys.wingLiftMachCurve(:, 1), ...
                curves.defaultMachCurve.GridVectors{1}(:), 'AbsTol', 0);
            testCase.verifyEqual(phys.wingLiftMachCurve(:, 2), ...
                curves.defaultMachCurve.Values(:), 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftCurve(:, 1), ...
                curves.bodyLiftGiLift.GridVectors{1}(:), 'AbsTol', 0, ...
                'Body lift AoA keys diverge from LiftCoefficientCurves.');
            testCase.verifyEqual(phys.bodyLiftCurve(:, 2), ...
                curves.bodyLiftGiLift.Values(:), 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMachCurve(:, 1), ...
                curves.bodyLiftMachCurve.GridVectors{1}(:), 'AbsTol', 0);
            testCase.verifyEqual(phys.bodyLiftMachCurve(:, 2), ...
                curves.bodyLiftMachCurve.Values(:), 'AbsTol', 0);
        end

        %% ------------------------- FloatCurve eval -------------------------
        function floatCurveNodesExactAndClamped(testCase)
            keys = [0 10 0 0; 1 20 0 0; 2 30 0 0];

            testCase.verifyEqual(ksp_evalFloatCurve(keys, [0 1 2]), [10 20 30], 'AbsTol', 0);
            testCase.verifyEqual(ksp_evalFloatCurve(keys, -5), 10, 'AbsTol', 0, ...
                'Below-range queries must hold the edge value (KSP clamp).');
            testCase.verifyEqual(ksp_evalFloatCurve(keys, 99), 30, 'AbsTol', 0, ...
                'Above-range queries must hold the edge value (KSP clamp).');
            testCase.verifyTrue(isnan(ksp_evalFloatCurve(keys, NaN)), 'NaN must propagate.');
        end

        function floatCurveHermiteMatchesReference(testCase)
            % Hand-computed cubic Hermite (same arithmetic as Ren0k's kOS
            % hermiteInterpolator): keys [0 0 out=3] -> [1 1 in=0] at
            % t = 0.5 gives h10*3 + h01 = 0.375 + 0.5 = 0.875.
            y = ksp_evalFloatCurve([0 0 0 3; 1 1 0 0], 0.5);
            testCase.verifyEqual(y, 0.875, 'AbsTol', 1e-12, ...
                'Hermite interpolation does not match the KSP tangent semantics.');

            % Zero tangents degenerate to linear.
            yLin = ksp_evalFloatCurve([0 5 0 0; 2 9 0 0], 1);
            testCase.verifyEqual(yLin, 7, 'AbsTol', 1e-12);
        end

        function floatCurvePreservesQueryShape(testCase)
            % Unit-tangent Hermite keys reproduce y = x exactly, so the
            % query shape must pass through untouched.
            keys = [0 0 1 1; 1 1 1 1];
            q = [0 0.25; 0.5 0.75];
            y = ksp_evalFloatCurve(keys, q);
            testCase.verifyEqual(size(y), size(q));
            testCase.verifyEqual(y, q, 'AbsTol', 1e-12);
        end

        function floatCurveSortsUnsortedKeys(testCase)
            y = ksp_evalFloatCurve([1 1 1 1; 0 0 1 1], 0.25);
            testCase.verifyEqual(y, 0.25, 'AbsTol', 1e-12, ...
                'Unsorted key tables must still interpolate.');
        end

        function floatCurveZeroTangentsAreSmoothstep(testCase)
            % Zero tangents give KSP's smooth (sigmoidal) Hermite, NOT
            % piecewise linear: pins the sigmoid shape so a future
            % "linearization" cannot silently change transonic drag.
            y = ksp_evalFloatCurve([0 0 0 0; 1 1 0 0], [0.25 0.5 0.75]);
            testCase.verifyEqual(y, [0.15625 0.5 0.84375], 'AbsTol', 1e-12);
        end

        %% ------------------------- cube database -------------------------
        function parsesMinimalPartDatabase(testCase)
            facesA = repmat([1.5 0.7 0.4], 6, 1);
            facesB = repmat([0.5 0.3 0.2], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Squad/Parts/A/mk1pod', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesA), ...
                    struct('cubeName', 'Deployed', 'faces', facesB)}}), ...
                struct('url', 'Squad/Parts/B/nocube', 'cubes', {{}}) ...
                });

            [cubeDB, warnings] = lvd_import_cubeDB(dbPath);

            testCase.verifyEqual(cubeDB.numParts, 1);
            entry = cubeDB.cubes('squad/parts/a/mk1pod');
            testCase.verifyEqual(entry.cubes(1).cubeName, 'Default', ...
                'The Default cube must sort first.');
            testCase.verifyEqual(entry.cubes(1).faces, facesA, 'AbsTol', 0);
            testCase.verifyEqual(entry.cubes(2).cubeName, 'Deployed');
            testCase.verifyEqual(entry.cubes(1).center, [0 0 0], 'AbsTol', 0);
            testCase.verifyEqual(entry.cubes(1).size, [1 1 1], 'AbsTol', 0);
            testCase.verifyFalse(isempty(warnings), ...
                'Skipped PART blocks must produce a warning.');
        end

        function cubeLookupAliasesAndMiss(testCase)
            faces = repmat([2 0.5 0.3], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Squad/Parts/Engine/liquidEngine3_v2', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);

            testCase.verifyFalse(isempty(ksp_lookupCube(cubeDB, 'liquidEngine3_v2')));
            testCase.verifyFalse(isempty(ksp_lookupCube(cubeDB, 'liquidEngine3.v2')), ...
                'Craft-style dot names must resolve to underscore cfg names.');
            testCase.verifyFalse(isempty(ksp_lookupCube(cubeDB, ...
                'Squad/Parts/Engine/liquidEngine3_v2')), 'Full urls must resolve.');
            testCase.verifyTrue(isempty(ksp_lookupCube(cubeDB, 'noSuchPart')), ...
                'Misses return empty (callers raise, never substitute).');
        end

        function cubeDbBadSourceErrors(testCase)
            testCase.verifyError(@() lvd_import_cubeDB('no_such_PartDatabase.cfg'), ...
                'lvd_import_cubeDB:fileNotFound');
            testCase.verifyError(@() lvd_import_cubeDB(''), ...
                'lvd_import_cubeDB:noSource');
        end

        %% ------------------------- setDrag -------------------------
        function setDragAxisAlignedSymmetricCube(testCase)
            phys = kwt_physicsGlobals();
            A = 2; cd0 = 0.5;
            cube = testCase.boxCube([A A A], cd0);

            [areaDrag, lift] = ksp_setDrag(cube, [1; 0; 0], 0, phys);

            % Structural identity (independent of curve values): windward
            % (-X, tip) + leeward (+X, tail) axial terms plus 4 edge-on
            % surface terms, all at Mach 0 (tip = tail = 1, surf = 0.02).
            cdP = ksp_evalFloatCurve(phys.cdCurve, cd0) .^ ...
                ksp_evalFloatCurve(phys.cdPowerCurve, 0);
            expected = A * cdP * (1 + 1 + 4 * 0.02);
            testCase.verifyEqual(areaDrag, expected, 'RelTol', 1e-9, ...
                'Axis-aligned area drag must equal tip+tail+4x surface.');
            testCase.verifyEqual(norm(lift), 0, 'AbsTol', 1e-9, ...
                'Axis-aligned flow on a symmetric cube must give zero blunt-body lift.');
            testCase.verifyEqual(dot(lift, [1; 0; 0]), 0, 'AbsTol', 0, ...
                'Lift must carry no drag-aligned component by construction.');
        end

        function setDragZeroCubeGivesZero(testCase)
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([0 0 0], 0.5);
            [areaDrag, lift] = ksp_setDrag(cube, [0; 1; 0], 0.5, phys);
            testCase.verifyEqual(areaDrag, 0, 'AbsTol', 0);
            testCase.verifyEqual(norm(lift), 0, 'AbsTol', 0);
        end

        function setDragVariesWithMach(testCase)
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([2 2 2], 0.6);
            dir = [1; 1; 1] / norm([1; 1; 1]);
            [a0, ~] = ksp_setDrag(cube, dir, 0, phys);
            [a1, ~] = ksp_setDrag(cube, dir, 1, phys);
            [a5, ~] = ksp_setDrag(cube, dir, 5, phys);
            testCase.verifyGreaterThan(abs(a1 - a0), 1e-6, ...
                'Transonic Mach multipliers must move the raw area drag.');
            testCase.verifyTrue(all([a0 a1 a5] > 0), 'Area drag must stay positive.');
        end

        function setDragOcclusionReducesDrag(testCase)
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([2 2 2], 0.6);
            dir = [1; 0; 0];
            [full, ~] = ksp_setDrag(cube, dir, 0.5, phys);
            % Occlude the windward -X face (face 2 in +X,-X,... order).
            occ = ones(6, 1); occ(2) = 0;
            [occluded, ~] = ksp_setDrag(cube, dir, 0.5, phys, struct('occlusion', occ));
            testCase.verifyLessThan(occluded, full, ...
                'Zeroing the windward face area must reduce the drag.');
            testCase.verifyGreaterThan(occluded, 0, 'Leeward/side faces still drag.');
        end

        function setDragContinuousThroughEdgeOn(testCase)
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([2 1 3], 0.6);
            angs = linspace(0, pi/2, 181);
            prev = [];
            for(k = 1:numel(angs))
                dir = [cos(angs(k)); 0; sin(angs(k))];
                [a, l] = ksp_setDrag(cube, dir, 0.8, phys);
                testCase.verifyTrue(isfinite(a) && all(isfinite(l)), ...
                    'Face handoff must stay finite.');
                if(~isempty(prev))
                    testCase.verifyLessThanOrEqual(abs(a - prev(1)), 5e-2, ...
                        'Area drag must not jump at face handoffs.');
                    testCase.verifyLessThanOrEqual(norm(l - prev(2:4)), 5e-2, ...
                        'Blunt-body lift must not jump at face handoffs.');
                end
                prev = [a; l];
            end
        end

        function setDragBadInputsError(testCase)
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([1 1 1], 0.5);
            testCase.verifyError(@() ksp_setDrag(cube, [0; 0; 0], 0, phys), ...
                'ksp_setDrag:badDirection');
            testCase.verifyError(@() ksp_setDrag(struct(), [1; 0; 0], 0, phys), ...
                'ksp_setDrag:badCube');
        end

        function uniformCubeGivesZeroLiftAtAnyAttitude(testCase)
            % A face-uniform cube is aerodynamically isotropic ONLY along
            % symmetric attitudes (axis-aligned, body-diagonal: the
            % leeward face set maps onto itself parallel to the inflow).
            % Assert exact zero there -- it pins the face-sign
            % bookkeeping; oblique attitudes give small nonzero lift by
            % KSP construction (leeward faces only), bounded below.
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([1.4 1.4 1.4], 0.55);
            symDirs = [1 0 0; 0 1 0; 0 0 1; 1 1 1]';
            for(mach = [0 0.6 1.5 5])
                for(k = 1:size(symDirs, 2))
                    dir = symDirs(:, k) / norm(symDirs(:, k));
                    [areaDrag, lift] = ksp_setDrag(cube, dir, mach, phys);
                    testCase.verifyGreaterThan(areaDrag, 0);
                    testCase.verifyLessThanOrEqual(norm(lift), 1e-9 * areaDrag, ...
                        sprintf('Symmetric-attitude lift at mach=%g (face-sign bug).', mach));
                end
            end
            % Oblique attitude on the same cube: small, transverse, finite
            % (KSP's leeward-only sum is not isotropic; measured ~9%).
            dir = [1; -1; 0.5] / norm([1; -1; 0.5]);
            [areaDrag, lift] = ksp_setDrag(cube, dir, 0.6, phys);
            testCase.verifyLessThanOrEqual(norm(lift), 0.15 * areaDrag, ...
                'Uniform-cube oblique lift must stay a small fraction.');
            testCase.verifyEqual(dot(lift, dir), 0, 'AbsTol', 1e-9 * areaDrag);
        end

        function setDragLiftIgnoresMach(testCase)
            % KSP applies NO Mach transform inside the blunt-body lift
            % term (raw base Cd, AoA curve at raw dot); Mach enters lift
            % only outside via bodyLiftMach (caller side). Same direction
            % at Mach 0 and 5 must give identical liftForce.
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([0.3 2 2], 0.55);
            dir = [1; 1; 0] / norm([1; 1; 0]);
            [a0, l0] = ksp_setDrag(cube, dir, 0, phys);
            [a5, l5] = ksp_setDrag(cube, dir, 5, phys);
            testCase.verifyGreaterThan(norm(l0), 0);
            testCase.verifyEqual(l5, l0, 'AbsTol', 1e-12, ...
                'Blunt-body lift must be Mach-independent (KSP construction).');
            testCase.verifyGreaterThan(abs(a5 - a0), 1e-6, ...
                'Area drag stays Mach-dependent while lift does not.');
        end

        function nonUniformCubeGivesObliqueLift(testCase)
            % Tank-like cube (small caps, big sides): oblique flow must
            % produce transverse blunt-body lift, exactly perpendicular to
            % the inflow by construction.
            phys = kwt_physicsGlobals();
            cube = testCase.boxCube([0.3 2 2], 0.55);
            dir = [1; 1; 0] / norm([1; 1; 0]);
            [areaDrag, lift] = ksp_setDrag(cube, dir, 0.5, phys);
            testCase.verifyGreaterThan(norm(lift), 1e-6, ...
                'A non-uniform cube at oblique incidence must lift.');
            testCase.verifyLessThanOrEqual(abs(dot(lift, dir)), ...
                1e-9 * max(areaDrag, eps), 'Lift must stay transverse.');
        end

        %% ------------------------- inflow helper -------------------------
        function inflowIsUnitAndMatchesPitchSlice(testCase)
            for(aDeg = [-30 -10 0 7.5 30])
                v = kwt_inflowFromAeroAngles(deg2rad(aDeg), 0);
                testCase.verifyEqual(norm(v), 1, 'AbsTol', 1e-12);
                testCase.verifyEqual(v, [cosd(aDeg); 0; sind(aDeg)], 'AbsTol', 1e-12, ...
                    'Zero-sideslip slice must equal the pitch-plane inflow.');
            end
            V = kwt_inflowFromAeroAngles(deg2rad([0 10]), deg2rad([0 5]));
            testCase.verifyEqual(size(V), [3 2], 'Array inputs give one column each.');
        end

        function inflowRoundTripsThroughLvdAeroAngles(testCase)
            % Proves the sweep's (AoA, sideslip) axes are the same angles
            % LVD resolves live in KosDragCoeffientModel /
            % UserTabulatedLiftModel.getLiftCoeffAndDir.
            ut = 1000;
            rVect = (testCase.kerbin.radius + 10) * normVector([0.6; -0.3; 0.7]);
            vVect = [1; 1.7; 0.3];
            for(aoa = [-0.4 -0.1 0 0.25])
                for(ss = [-0.2 0 0.15])
                    [bx, by, bz, Rt] = computeBodyAxesFromAeroAngles( ...
                        ut, rVect, vVect, testCase.kerbin, aoa, ss, 0);
                    [~, vE, RE] = getFixedFrameVectFromInertialVect( ...
                        ut, rVect, testCase.kerbin, vVect);
                    windXInert = RE' * normVector(vE);
                    vHatBody = Rt' * windXInert;
                    mine = kwt_inflowFromAeroAngles(aoa, ss);
                    testCase.verifyVectorEqual(vHatBody, mine, 1e-9, ...
                        sprintf('Inflow mismatch at aoa=%g ss=%g.', aoa, ss));
                    [~, aoaBack, ssBack] = computeAeroAnglesFromBodyAxes( ...
                        ut, rVect, vVect, testCase.kerbin, bx, by, bz);
                    testCase.verifyEqual(angleNegPiToPi_mex(aoaBack - aoa), 0, ...
                        'AbsTol', 1e-9, 'AoA must round-trip.');
                    testCase.verifyEqual(angleNegPiToPi_mex(ssBack - ss), 0, ...
                        'AbsTol', 1e-9, 'Sideslip must round-trip.');
                end
            end
        end

        %% ------------------------- aero spec builder -------------------------
        function specBuilderMapsRotationsAndCubes(testCase)
            faces = repmat([1.2 0.6 0.5], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/tankA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = RotTest\n' ...
                'PART\n{\n\tpart = tankA_101\n\tpos = 0,1,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n' ...
                'PART\n{\n\tpart = tankA_102\n\tpos = 0,2,0\n\trot = 0,0,0.7071068,0.7071068\n\tmir = 1,1,1\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            testCase.verifyEqual(numel(spec.parts), 2);
            testCase.verifyEqual(spec.parts(1).cubeName, 'Default');
            for(p = 1:2)
                R = spec.parts(p).R_part2vessel;
                testCase.verifyEqual(R' * R, eye(3), 'AbsTol', 1e-9, ...
                    'Part rotations must stay orthonormal.');
                testCase.verifyGreaterThan(det(R), 0, ...
                    'Part rotations must stay proper (det +1).');
            end
            % Identity craft rotation still maps frames (rocket noseAxis).
            testCase.verifyEqual(spec.parts(1).R_part2vessel, ...
                [0 1 0; 1 0 0; 0 0 -1], 'AbsTol', 1e-9);
            testCase.verifyFalse(all(spec.parts(2).R_part2vessel == ...
                spec.parts(1).R_part2vessel, 'all'), ...
                'A 90-degree craft rotation must change the vessel DCM.');
            testCase.verifyTrue(ischar(spec.configHash) && ~isempty(spec.configHash));
        end

        function specBuilderMissingCubeNamesThePart(testCase)
            faces = repmat([1 0.5 0.3], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/known', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = MissingCube\n' ...
                'PART\n{\n\tpart = mystery.part_101\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n']);

            try
                kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());
                testCase.verifyTrue(false, 'Missing cubes must raise, never substitute.');
            catch ME
                testCase.verifyEqual(ME.identifier, 'kwt_buildAeroSpec:missingCube');
                testCase.verifyTrue(contains(ME.message, 'mystery.part'), ...
                    'The error must name the missing part.');
            end

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals(), ...
                struct('allowMissingCubes', true));
            testCase.verifyFalse(isempty(spec.warnings), ...
                'Opt-in substitution must still warn.');
            testCase.verifyEqual(sum(spec.parts(1).cube.faces(:)), 0, 'AbsTol', 0);
        end

        function specBuilderDetectsLiftModules(testCase)
            faces = repmat([3 0.4 0.1; 3 0.4 0.1; 0.2 0.4 0.1; 0.2 0.4 0.1; 1 0.4 0.1; 1 0.4 0.1], 1, 1);
            faces = reshape(faces, 6, 3);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/wingA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = WingTest\n' ...
                'PART\n{\n\tpart = wingA_201\n\tpos = 1,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleLiftingSurface\n\t\tdeflectionLiftCoeff = 2.5\n\t}\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            testCase.verifyTrue(spec.parts(1).hasLiftModule);
            testCase.verifyEqual(spec.parts(1).deflectionLiftCoeff, 2.5, 'AbsTol', 0);
            % KSP default (ModuleLiftingSurface.transformDir = Z): the
            % part-model +Z axis in part-local frame.
            testCase.verifyEqual(spec.parts(1).liftVector_local, [0; 0; 1], 'AbsTol', 0);
        end

        function specBuilderControlSurfaceFlags(testCase)
            faces = repmat([1 0.4 0.2], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/elevon', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = CtrlTest\n' ...
                'PART\n{\n\tpart = elevon_301\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleControlSurface\n\t\tdeflectionLiftCoeff = 1.2\n' ...
                '\t\tctrlSurfaceRange = 20\n\t\tauthorityLimiter = 0.5\n\t}\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            testCase.verifyTrue(spec.parts(1).isControl, 'Control modules must flag.');
            testCase.verifyEqual(spec.parts(1).ctrlRangeDeg, 20, 'AbsTol', 0);
            testCase.verifyEqual(spec.parts(1).authorityLimiter, 0.5, 'AbsTol', 0);
        end

        function gameDataHarvestsLiftingSurface(testCase)
            gameData = testCase.buildAeroGameData();
            db = lvd_import_getPartDatabase(gameData);

            wing = db.parts('testwing');
            testCase.verifyTrue(any(strcmp(wing.roles, 'liftingsurface')), ...
                'Wing modules must add the liftingSurface role.');
            testCase.verifyFalse(wing.liftingSurface.isControl);
            testCase.verifyEqual(wing.liftingSurface.deflectionLiftCoeff, 1.5, 'AbsTol', 0);

            ctrl = db.parts('testcanard');
            testCase.verifyTrue(ctrl.liftingSurface.isControl);
            testCase.verifyEqual(ctrl.liftingSurface.deflectionLiftCoeff, 0.4, 'AbsTol', 0);
            testCase.verifyEqual(ctrl.liftingSurface.ctrlSurfaceRange, 10, 'AbsTol', 0);

            plain = db.parts('testtank');
            testCase.verifyTrue(isnan(plain.liftingSurface.deflectionLiftCoeff), ...
                'Parts without the module must carry absent (NaN) coefficients.');
        end

        function bundledDbCarriesLiveLiftHarvests(testCase)
            % The bundled stock JSON was backfilled with live GameData
            % lift harvests (2026-09-26; 61 lifted parts incl. fins and
            % pods). This is what makes lvd_generateAeroTablesFromCraft's
            % bundled-partDB default produce correct lift WITHOUT a KSP
            % install: craft files omit the coefficients.
            db = lvd_import_getPartDatabase();
            testCase.verifyTrue(isKey(db.parts, 'basicfin'), 'Stock fins must exist.');
            fin = db.parts('basicfin').liftingSurface;
            testCase.verifyEqual(fin.deflectionLiftCoeff, 0.12, 'AbsTol', 1e-12, ...
                'Bundled fin harvest must read 0.12.');
            % basicFin.cfg carries no liftingSurfaceCurve and no omni
            % flag, so the record keeps absent defaults ('' -> 'Default'
            % and NaN -> true downstream, per KSP module defaults).
            testCase.verifyEqual(fin.liftingSurfaceCurve, '');
            testCase.verifyTrue(isnan(fin.omnidirectional), ...
                'Fin cfg sets no omni flag: absent (NaN) is correct.');
            pod = db.parts('mk1pod_v2').liftingSurface;
            testCase.verifyEqual(pod.deflectionLiftCoeff, 0.35, 'AbsTol', 1e-12, ...
                'Bundled pod harvest must read 0.35.');
            testCase.verifyEqual(pod.liftingSurfaceCurve, 'CapsuleBottom');
            testCase.verifyEqual(pod.transformDir, 'Y');
            testCase.verifyEqual(pod.transformSign, -1);
            % Module-less parts keep absent defaults ([] reloads absent).
            testCase.verifyTrue(isKey(db.parts, 'fueltank_long'), ...
                'Stock long tank must exist.');
            tank = db.parts('fueltank_long').liftingSurface;
            testCase.verifyTrue(isnan(tank.deflectionLiftCoeff), ...
                'Module-less parts must stay NaN.');
        end

        function builderCraftGameDataPrecedence(testCase)
            % Synthetic partDB (no file I/O): craft key -> GameData ->
            % model default, per field.
            dbMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            dbMap('winga') = struct('liftingSurface', ...
                struct('isControl', false, 'deflectionLiftCoeff', 1.5, ...
                'ctrlSurfaceRange', NaN, 'authorityLimiter', NaN, ...
                'deployAngleDeg', NaN, 'rotationAxis', []));
            partDB = struct('parts', dbMap);
            faces = repmat([3 0.4 0.1; 3 0.4 0.1; 0.2 0.4 0.1; 0.2 0.4 0.1; 1 0.4 0.1; 1 0.4 0.1], 1, 1);
            faces = reshape(faces, 6, 3);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/wingA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);

            % Craft MODULE without the key -> GameData 1.5.
            bare = sprintf([ ...
                'ship = Prec\nPART\n{\n\tpart = wingA_1\n\tpos = 0,0,0\n' ...
                '\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleLiftingSurface\n\t}\n}\n']);
            specBare = kwt_buildAeroSpec(bare, cubeDB, kwt_physicsGlobals(), ...
                struct('partDB', partDB));
            testCase.verifyEqual(specBare.parts(1).deflectionLiftCoeff, 1.5, 'AbsTol', 0, ...
                'GameData must fill craft-omitted coefficients.');

            % Explicit craft key wins, even over GameData.
            over = strrep(bare, 'name = ModuleLiftingSurface', ...
                sprintf('name = ModuleLiftingSurface\n\t\tdeflectionLiftCoeff = 0.3'));
            specOver = kwt_buildAeroSpec(over, cubeDB, kwt_physicsGlobals(), ...
                struct('partDB', partDB));
            testCase.verifyEqual(specOver.parts(1).deflectionLiftCoeff, 0.3, 'AbsTol', 0, ...
                'Explicit craft keys must win over GameData.');

            % Neither -> KSP model default 1.5 (with stale warning).
            specPlain = kwt_buildAeroSpec(bare, cubeDB, kwt_physicsGlobals());
            testCase.verifyEqual(specPlain.parts(1).deflectionLiftCoeff, 1.5, 'AbsTol', 0);
            testCase.verifyFalse(isempty(specPlain.warnings), ...
                'The 1.5 fallback must warn.');
        end

        function finLiftNonzeroWithGameData(testCase)
            % GameData refines the KSP 1.5 default: with 0.4 in the DB the
            % wing must lift at 0.4/1.5 of the default rate, and the
            % default path must warn about the stale/missing source.
            dbMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            dbMap('winga') = struct('liftingSurface', ...
                struct('isControl', false, 'deflectionLiftCoeff', 0.4, ...
                'ctrlSurfaceRange', NaN, 'authorityLimiter', NaN, ...
                'deployAngleDeg', NaN, 'rotationAxis', []));
            partDB = struct('parts', dbMap);
            faces = repmat([3 0.4 0.1; 3 0.4 0.1; 0.2 0.4 0.1; 0.2 0.4 0.1; 1 0.4 0.1; 1 0.4 0.1], 1, 1);
            faces = reshape(faces, 6, 3);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/wingA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = FinLift\nPART\n{\n\tpart = wingA_1\n\tpos = 0,0,0\n' ...
                '\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleLiftingSurface\n\t}\n}\n']);

            phys = kwt_physicsGlobals();
            vHat = kwt_inflowFromAeroAngles(deg2rad(10), 0);
            plainSpec = kwt_buildAeroSpec(craftText, cubeDB, phys);
            dbSpec = kwt_buildAeroSpec(craftText, cubeDB, phys, ...
                struct('partDB', partDB));
            testCase.verifyEqual(plainSpec.parts(1).deflectionLiftCoeff, 1.5, 'AbsTol', 0, ...
                'Missing sources must fall back to the KSP default 1.5.');
            testCase.verifyFalse(isempty(plainSpec.warnings), ...
                'The 1.5 fallback must warn (prompts a GameData refresh).');
            testCase.verifyEqual(dbSpec.parts(1).deflectionLiftCoeff, 0.4, 'AbsTol', 0);

            plain = kwt_aero(plainSpec, phys, vHat, 0.3, 1);
            with = kwt_aero(dbSpec, phys, vHat, 0.3, 1);
            testCase.verifyGreaterThan(abs(plain.ClS), 0.1, 'Default wings must lift.');
            testCase.verifyEqual(with.ClS, plain.ClS * (0.4 / 1.5), 'RelTol', 1e-9, ...
                'Lift must scale exactly with deflectionLiftCoeff.');
        end

        function wingKspDefaultsWithoutSources(testCase)
            % KSPDocs ModuleLiftingSurface defaults with no craft keys and
            % no GameData: omni true, perp false, curve Default, defl 1.5.
            faces = repmat([1 0.4 0.2], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/plainWing', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = Def\nPART\n{\n\tpart = plainWing_1\n\tpos = 0,0,0\n' ...
                '\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleLiftingSurface\n\t}\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());
            p = spec.parts(1);
            testCase.verifyTrue(p.omnidirectional, 'KSP omni default is true.');
            testCase.verifyFalse(p.perpendicularOnly, 'KSP perp default is false.');
            testCase.verifyEqual(p.liftCurveSet, 'Default');
            testCase.verifyEqual(p.deflectionLiftCoeff, 1.5, 'AbsTol', 0);
            testCase.verifyEqual(p.liftVector_local, [0; 0; 1], 'AbsTol', 0);
        end

        function podCapsuleModuleHarvest(testCase)
            % Full capsule-style MODULE (as in the Mk1 pod cfg: 0.35 /
            % CapsuleBottom / clamped / Y/-1 / bottom-node-gated /
            % dragless) must resolve entirely from GameData when the craft
            % block carries only the module name. Verified field-for-field
            % against the KWT pod group (NoBoosters Vessel export).
            dbMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            dbMap('testpod') = struct('roles', {{'tank'}}, ...
                'liftingSurface', struct('isControl', false, ...
                'deflectionLiftCoeff', 0.35, 'ctrlSurfaceRange', NaN, ...
                'authorityLimiter', NaN, 'deployAngleDeg', NaN, ...
                'rotationAxis', [], 'liftingSurfaceCurve', 'CapsuleBottom', ...
                'omnidirectional', 0, 'perpendicularOnly', 1, ...
                'transformDir', 'Y', 'transformSign', -1, ...
                'nodeEnabled', 1, 'attachNodeName', 'bottom', ...
                'useInternalDragModel', 0));
            partDB = struct('parts', dbMap);
            faces = repmat([1.1 0.7 0.5; 1.1 0.7 0.5; 1.2 0.5 0.5; 1.2 0.5 0.5; 1.1 0.7 0.5; 1.1 0.7 0.5], 1, 1);
            faces = reshape(faces, 6, 3);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/testPod', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}), ...
                struct('url', 'Test/base', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            mkPod = @(extra) sprintf([ ...
                'ship = PodRule\nPART\n{\n\tpart = testPod_1\n\tpos = 0,1,0\n' ...
                '\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tattN = bottom,base_2_0|0.4|0_0|-1|0_0|0.4|0_0|-1|0\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleLiftingSurface\n\t}\n}\n' ...
                'PART\n{\n\tpart = base_2\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n%s}\n'], extra);

            spec = kwt_buildAeroSpec(mkPod(''), cubeDB, kwt_physicsGlobals(), ...
                struct('partDB', partDB));
            p = spec.parts(1);
            testCase.verifyEqual(p.deflectionLiftCoeff, 0.35, 'AbsTol', 0);
            testCase.verifyEqual(p.liftCurveSet, 'CapsuleBottom');
            testCase.verifyFalse(p.omnidirectional, 'Pod module is clamped.');
            testCase.verifyTrue(p.perpendicularOnly);
            testCase.verifyEqual(p.liftVector_local, [0; -1; 0], 'AbsTol', 0, ...
                'transformDir Y with sign -1 gives stack-down.');
            testCase.verifyFalse(p.useInternalDragModel, 'Pod wing drag is off.');
            testCase.verifyEmpty(spec.warnings, 'Fully-sourced pod needs no warnings.');

            % Detached bottom node gates the module inert (defl 0) but
            % keeps hasLiftModule true for body exclusion.
            bare = strrep(mkPod(''), ...
                'attN = bottom,base_2_0|0.4|0_0|-1|0_0|0.4|0_0|-1|0', ...
                'attN = bottom,Null_0_0|0|0_0|-1|0_0|0|0_0|-1|0');
            specBare = kwt_buildAeroSpec(bare, cubeDB, kwt_physicsGlobals(), ...
                struct('partDB', partDB));
            testCase.verifyEqual(specBare.parts(1).deflectionLiftCoeff, 0, 'AbsTol', 0);
            testCase.verifyTrue(specBare.parts(1).hasLiftModule);
            testCase.verifyFalse(isempty(specBare.warnings), 'Gating must warn.');
        end

        %% ------------------------- occlusion -------------------------
        function parseAttachNodeFormats(testCase)
            raw = struct();
            raw.attN = { ...
                'top,engineB_2_0|0.5|0_0|1|0_0|0.5|0_0|1|0', ...
                'bottom,Null_0_0|0|0_0|-1|0_0|0|0_0|-1|0', ...
                'bottom01,solidBooster_9_0|0|0_0|-1|0_0|0|0_0|-1|0'};
            raw.srfN = 'srfAttach,fuelTank_7,,0|0|0,1|0|0,0|0|0';
            nodes = kwt_parseAttachNodes(raw);

            testCase.verifyEqual(numel(nodes.stack), 3);
            testCase.verifyEqual(nodes.stack(1).id, 'top');
            testCase.verifyEqual(nodes.stack(1).target, 'engineB_2', ...
                'One trailing _<digits> symmetry suffix must strip to the instanceID.');
            testCase.verifyEqual(nodes.stack(1).size, 0.5, 'AbsTol', 0);
            testCase.verifyEqual(nodes.stack(2).target, '', ...
                'Null targets mean unattached.');
            testCase.verifyEqual(nodes.stack(3).id, 'bottom01');

            testCase.verifyEqual(numel(nodes.srf), 1);
            testCase.verifyEqual(nodes.srf(1).target, 'fuelTank_7', ...
                'srfN targets carry no suffix and must survive verbatim.');
            testCase.verifyEqual(nodes.srf(1).orient, [1; 0; 0], 'AbsTol', 0);

            % Short Dynawing-style form.
            raw2 = struct('attN', 'top,bayParent_3_0|5|0');
            n2 = kwt_parseAttachNodes(raw2);
            testCase.verifyEqual(n2.stack(1).size, 5, 'AbsTol', 0);
            testCase.verifyEqual(n2.stack(1).target, 'bayParent_3');

            % COL-flagged surface node (KAL9000 style).
            raw3 = struct('srfN', 'srfAttach,mk1pod_1,COL,0.01|0|0,1|0|0,0.01|0|0');
            n3 = kwt_parseAttachNodes(raw3);
            testCase.verifyEqual(n3.srf(1).target, 'mk1pod_1');
            testCase.verifyEqual(n3.srf(1).orient, [1; 0; 0], 'AbsTol', 0);
        end

        function occlusionStackJointExact(testCase)
            % Two-part stack: tank caps (area 2) over engine caps (0.5).
            % Tank bottom occluded 0.5/2 -> 0.75; engine top fully capped.
            facesTank = [5 0.5 0.5; 5 0.5 0.5; 2 0.5 0.5; ...
                         2 0.5 0.5; 5 0.5 0.5; 5 0.5 0.5];
            facesEng = [3 0.5 0.5; 3 0.5 0.5; 0.5 0.5 0.5; ...
                        0.5 0.5 0.5; 3 0.5 0.5; 3 0.5 0.5];
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/tankA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesTank)}}), ...
                struct('url', 'Test/engineB', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesEng)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = OccStack\n' ...
                'PART\n{\n\tpart = tankA_1\n\tpos = 0,1,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tattN = top,Null_0_0|0|0_0|1|0_0|0|0_0|1|0\n' ...
                '\tattN = bottom,engineB_2_0|-0.5|0_0|-1|0_0|-0.5|0_0|-1|0\n}\n' ...
                'PART\n{\n\tpart = engineB_2\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tattN = top,tankA_1_0|0.5|0_0|1|0_0|0.5|0_0|1|0\n' ...
                '\tattN = bottom,Null_0_0|0|0_0|-1|0_0|0|0_0|-1|0\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            tankOcc = spec.parts(1).occlusion;
            engOcc = spec.parts(2).occlusion;
            testCase.verifyEqual(tankOcc(4), 0.75, 'AbsTol', 1e-12, ...
                'Tank bottom must keep 1 - 0.5/2.');
            testCase.verifyEqual(tankOcc([1 2 3 5 6]), ones(5, 1), 'AbsTol', 0, ...
                'Unjointed faces stay fully exposed.');
            testCase.verifyEqual(engOcc(3), 0, 'AbsTol', 0, ...
                'Engine top fully capped by the larger tank face.');
            testCase.verifyEqual(engOcc([1 2 4 5 6]), ones(5, 1), 'AbsTol', 0);

            % Occlusion must actually move setDrag output, in the right
            % direction, through the installed (not manual) path.
            phys = kwt_physicsGlobals();
            vHat = kwt_inflowFromAeroAngles(deg2rad(20), 0);
            bare = spec; bare.parts(1).occlusion = ones(6, 1);
            oBare = kwt_aero(bare, phys, vHat, 0.5, 1);
            oOcc = kwt_aero(spec, phys, vHat, 0.5, 1);
            testCase.verifyLessThan(oOcc.dragCubeCdA, oBare.dragCubeCdA, ...
                'Installed occlusion must reduce vessel drag.');
        end

        function occlusionSrfPositionBasedAndMutual(testCase)
            % Fin surface-mounted at +Z of the tank: tank +Z face takes
            % finArea/tankArea, fin -Z face fully capped in return.
            facesTank = repmat([5 0.5 0.5], 6, 1);
            facesFin = [0.2 0.4 0.1; 0.2 0.4 0.1; 1 0.4 0.1; ...
                        1 0.4 0.1; 1 0.4 0.1; 1 0.4 0.1];
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/tankC', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesTank)}}), ...
                struct('url', 'Test/finD', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesFin)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = OccSrf\n' ...
                'PART\n{\n\tpart = tankC_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n' ...
                'PART\n{\n\tpart = finD_2\n\tpos = 0,0,0.62\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tsrfN = srfAttach,tankC_1,,0|0|0,1|0|0,0|0|0\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            tankOcc = spec.parts(1).occlusion;
            finOcc = spec.parts(2).occlusion;
            testCase.verifyEqual(tankOcc(5), 1 - 1/5, 'AbsTol', 1e-12, ...
                'Tank +Z face occluded by the fin contact patch.');
            testCase.verifyEqual(tankOcc([1 2 3 4 6]), ones(5, 1), 'AbsTol', 0);
            testCase.verifyEqual(finOcc(6), 0, 'AbsTol', 0, ...
                'Fin -Z (tank-facing) face fully capped in return.');
        end

        function occlusionSrfOrientFallback(testCase)
            % Coincident positions: orient triplet decides, contact
            % opposite the node orientation (KSP outward convention).
            facesTank = repmat([5 0.5 0.5], 6, 1);
            facesFin = repmat([1 0.4 0.1], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/tankC', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesTank)}}), ...
                struct('url', 'Test/finD', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', facesFin)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = OccFallback\n' ...
                'PART\n{\n\tpart = tankC_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n' ...
                'PART\n{\n\tpart = finD_2\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tsrfN = srfAttach,tankC_1,,0|0|0,1|0|0,0|0|0\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            testCase.verifyLessThan(spec.parts(2).occlusion(2), 1, ...
                'Fallback must occlude the -X face for orient +X.');
            testCase.verifyEqual(spec.parts(2).occlusion([1 3 4 5 6]), ones(5, 1), 'AbsTol', 0);
        end

        function occlusionSkipsNullUnresolvedAndManual(testCase)
            faces = repmat([2 0.5 0.3], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/solo', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = OccSkip\n' ...
                'PART\n{\n\tpart = solo_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tattN = top,Null_0_0|0|0_0|1|0_0|0|0_0|1|0\n' ...
                '\tattN = bottom,ghost_9_0|-0.5|0_0|-1|0_0|-0.5|0_0|-1|0\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());
            testCase.verifyEqual(spec.parts(1).occlusion, ones(6, 1), 'AbsTol', 0, ...
                'Null and missing targets must leave faces exposed.');
            testCase.verifyFalse(isempty(spec.warnings), ...
                'Unresolvable non-Null targets must warn.');

            % Manual override wins; kill-switch disables automation.
            occMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            occMap('solo_1') = 0.5 * ones(6, 1);
            specMan = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals(), ...
                struct('occlusion', occMap));
            testCase.verifyEqual(specMan.parts(1).occlusion, 0.5 * ones(6, 1), 'AbsTol', 0);
            specOff = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals(), ...
                struct('autoOcclusion', false));
            testCase.verifyEqual(specOff.parts(1).occlusion, ones(6, 1), 'AbsTol', 0);
        end

        %% ------------------------- kwt_aero -------------------------
        function aeroSymmetricStackLiftAntisymmetric(testCase)
            phys = kwt_physicsGlobals();
            spec = testCase.stackSpec(3);

            aDeg = 10;
            plus = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(deg2rad(aDeg), 0), 0.5, 1);
            minus = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(deg2rad(-aDeg), 0), 0.5, 1);
            zero = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(0, 0), 0.5, 1);

            testCase.verifyEqual(zero.ClS, 0, 'AbsTol', 1e-9, ...
                'Symmetric stack at zero AoA must give zero lift.');
            testCase.verifyEqual(plus.ClS, -minus.ClS, 'RelTol', 1e-9, ...
                'Lift must be antisymmetric in AoA.');
            testCase.verifyEqual(plus.dragCubeCdA, minus.dragCubeCdA, 'RelTol', 1e-9, ...
                'Drag must be symmetric in AoA.');
            testCase.verifyGreaterThan(plus.dragCubeCdA, 0);
            testCase.verifyGreaterThan(abs(plus.ClS), 0, 'Off-axis lift must exist.');
        end

        function aeroWingScalingMatchesRenokDecomposition(testCase)
            % Ren0k Profile.ks factors: wingACD = sum(Cd*A)*15,
            % wingLiftACD = sum(Cl*A)*36 (1000*liftDragMultiplier and
            % 1000*liftMultiplier). This pins the decomposition, not just
            % the plumbing.
            phys = kwt_physicsGlobals();
            A = 2.0;
            spec = testCase.wingSpec([0; 0; 1], A, false, true);
            aoa = deg2rad(10);
            out = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(aoa, 0), 0, 1);

            a = sin(aoa);
            Cl = ksp_evalFloatCurve(phys.wingLiftCurve, a);
            Cd = ksp_evalFloatCurve(phys.wingDragCurve, a);
            % Mach 0: liftMach = 1, dragMach = 0.35 (first key).
            Wmag = Cl * 1 * A * 36;
            testCase.verifyEqual(abs(out.ClS), Wmag * cos(aoa), 'RelTol', 1e-9, ...
                'Wing |ClS| must equal the projected flat-plate lift.');
            % perpendicularOnly wings carry no induced term (KWT sets the
            % induced curve null in that case); parasitics only here.
            expectedOther = Cd * 0.35 * A * 15;
            testCase.verifyEqual(out.otherDragCdA, expectedOther, 'RelTol', 1e-9, ...
                'Other drag must equal parasitic (x15) with no induced term.');
            % Free (non-perpendicular) wings add the induced term back.
            freeSpec = testCase.wingSpec([0; 0; 1], A, false, false);
            outFree = kwt_aero(freeSpec, phys, kwt_inflowFromAeroAngles(aoa, 0), 0, 1);
            testCase.verifyEqual(outFree.otherDragCdA, expectedOther + Wmag * a, ...
                'RelTol', 1e-9, 'Free wings add induced (x36 x AoI).');
            testCase.verifyEqual(out.dragCubeCdA, 0, 'AbsTol', 0, ...
                'A pure wing vessel has no cube drag.');
            % Lift vector is exactly along the lift direction here, so the
            % force magnitude equals Q*|ClS|.
            testCase.verifyEqual(norm(out.liftForce_kN), abs(out.ClS), 'RelTol', 1e-9);
        end

        function aeroReynoldsAppliesToDragOnly(testCase)
            phys = kwt_physicsGlobals();
            spec = testCase.stackSpec(2);
            vHat = kwt_inflowFromAeroAngles(deg2rad(10), deg2rad(3));

            lo = kwt_aero(spec, phys, vHat, 0.8, 2.5, 0.01, 0);
            hi = kwt_aero(spec, phys, vHat, 0.8, 2.5, 1000, 0);

            testCase.verifyEqual(lo.dragCubeCdA, hi.dragCubeCdA, 'RelTol', 0, ...
                'Stored cube CdA excludes Reynolds (runtime applies it).');
            testCase.verifyEqual(lo.otherDragCdA, hi.otherDragCdA, 'RelTol', 1e-12, ...
                'Induced/other drag excludes Reynolds.');
            testCase.verifyVectorEqual(lo.liftForce_kN, hi.liftForce_kN, 1e-12, ...
                'Lift must be Reynolds-independent (drag-only multiplier).');

            rLo = ksp_evalFloatCurve(phys.pseudoReynoldsCurve, 0.01);
            rHi = ksp_evalFloatCurve(phys.pseudoReynoldsCurve, 1000);
            testCase.verifyEqual(lo.reynoldsMult, rLo, 'RelTol', 0);
            expectedRatio = (lo.dragCubeCdA * rLo + lo.otherDragCdA) / ...
                (hi.dragCubeCdA * rHi + hi.otherDragCdA);
            testCase.verifyEqual(norm(lo.dragForce_kN) / norm(hi.dragForce_kN), ...
                expectedRatio, 'RelTol', 1e-9, ...
                'Drag force must follow (cube*R + other)*Q exactly.');
        end

        function aeroShieldedPartsContributeNothing(testCase)
            phys = kwt_physicsGlobals();
            openSpec = testCase.stackSpec(1);
            shielded = openSpec;
            shielded.parts(1).isShielded = true;

            vHat = kwt_inflowFromAeroAngles(deg2rad(15), deg2rad(5));
            open = kwt_aero(openSpec, phys, vHat, 0.6, 1);
            shut = kwt_aero(shielded, phys, vHat, 0.6, 1);

            testCase.verifyGreaterThan(open.dragCubeCdA + open.otherDragCdA, 0);
            testCase.verifyEqual(shut.dragCubeCdA, 0, 'AbsTol', 0);
            testCase.verifyEqual(shut.otherDragCdA, 0, 'AbsTol', 0);
            testCase.verifyEqual(norm(shut.liftForce_kN), 0, 'AbsTol', 0);
        end

        function aeroControlDeflectionMovesLift(testCase)
            phys = kwt_physicsGlobals();
            spec = testCase.wingSpec([0; 0; 1], 1.5, true, true);
            spec.parts(1).rotationAxis_local = [1; 0; 0];
            spec.parts(1).ctrlRangeDeg = 20;
            spec.parts(1).authorityLimiter = 1;
            vHat = kwt_inflowFromAeroAngles(deg2rad(10), 0);

            base = kwt_aero(spec, phys, vHat, 0.3, 1, 1, 0);
            defl = kwt_aero(spec, phys, vHat, 0.3, 1, 1, 0.5);

            testCase.verifyGreaterThan(abs(defl.ClS - base.ClS), 1e-6, ...
                'Control deflection must move the lift.');
            back = kwt_aero(spec, phys, vHat, 0.3, 1, 1, 0);
            testCase.verifyEqual(back.ClS, base.ClS, 'AbsTol', 0, ...
                'Zero deflection must reproduce the untrimmed table.');
        end

        function aeroPerpendicularProjectionFlag(testCase)
            phys = kwt_physicsGlobals();
            vHat = kwt_inflowFromAeroAngles(deg2rad(25), 0);

            perpSpec = testCase.wingSpec([0; 0; 1], 2, false, true);
            freeSpec = testCase.wingSpec([0; 0; 1], 2, false, false);
            perp = kwt_aero(perpSpec, phys, vHat, 0.2, 1);
            free = kwt_aero(freeSpec, phys, vHat, 0.2, 1);

            testCase.verifyEqual(dot(perp.liftForce_kN, vHat), 0, 'AbsTol', 1e-9, ...
                'Projected wing lift must be perpendicular to inflow.');
            testCase.verifyGreaterThan(abs(dot(free.liftForce_kN, vHat)), 1e-6, ...
                'Unprojected wing lift keeps an inflow-aligned component.');
        end

        %% ------------------------- sweep + CSV -------------------------
        function sweepTensorShapeAndCsvRoundTrip(testCase)
            phys = kwt_physicsGlobals();
            spec = testCase.stackSpec(1);
            outDir = testCase.tempDir();
            [tables, files] = kwt_sweepCraft(spec, phys, struct( ...
                'machVec', [0 1], 'aoaDegVec', [-10 0 10], ...
                'sideslipDegVec', [0 5], 'outDir', outDir, 'quiet', true));

            testCase.verifyEqual(size(tables.ClS), [2 3 2]);
            testCase.verifyTrue(isfile(files.dragCsv) && isfile(files.liftCsv));

            % Row order must be sideslip-major / AoA-middle / Mach-inner,
            % the exact order the model loaders' sortrows+reshape expect.
            dragRows = readmatrix(files.dragCsv);
            testCase.verifyEqual(size(dragRows, 2), 5);
            testCase.verifyEqual(dragRows(1:2, 1)', [0 1], 'AbsTol', 0, ...
                'Mach must be the inner (fastest) axis in the CSV.');
            testCase.verifyEqual(dragRows(1, 2:3), [-10 0], 'AbsTol', 0);

            % Node-exact reload into the real LVD models.
            dragModel = KosDragCoeffientModel(files.dragCsv);
            liftModel = UserTabulatedLiftModel(files.liftCsv);
            m0 = tables.mach(1); a0 = tables.aoaDeg(2); s0 = tables.sideslipDeg(2);
            im = find(tables.mach == m0, 1); ia = find(tables.aoaDeg == a0, 1);
            is = find(tables.sideslipDeg == s0, 1);
            testCase.verifyEqual(dragModel.giDragCube(m0, deg2rad(a0), deg2rad(s0)), ...
                tables.dragCubeCdA(im, ia, is), 'AbsTol', 1e-9);
            testCase.verifyEqual(liftModel.giClS(m0, deg2rad(a0), deg2rad(s0)), ...
                tables.ClS(im, ia, is), 'AbsTol', 1e-9);
        end

        function sweepSymmetricStackSymmetries(testCase)
            phys = kwt_physicsGlobals();
            spec = testCase.stackSpec(1);
            [tables, ~] = kwt_sweepCraft(spec, phys, struct( ...
                'machVec', 0.5, 'aoaDegVec', [-10 0 10], ...
                'sideslipDegVec', [-5 0 5], 'quiet', true));

            D = tables.dragCubeCdA;
            C = tables.ClS;
            testCase.verifyEqual(D(:, :, 1), D(:, :, 3), 'RelTol', 1e-9, ...
                'Cube drag must mirror in sideslip on a symmetric stack.');
            testCase.verifyEqual(C(:, 1, 2), -C(:, 3, 2), 'RelTol', 1e-9, ...
                'Lift must antis mirror in AoA.');
            testCase.verifyEqual(C(:, 2, :), zeros(1, 1, 3), 'AbsTol', 1e-9, ...
                'Zero AoA must give zero lift across sideslip.');
        end

        %% ------------------------- end-to-end + UI -------------------------
        function generateEndToEndWritesBothCsvs(testCase)
            faces = repmat([1.4 0.65 0.45], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/tankA', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}), ...
                struct('url', 'Test/tankB', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            craftPath = testCase.writeLines('sweepCraft.craft', { ...
                'ship = SweepE2E', ...
                'PART', '{', 'part = tankA_101', 'pos = 0,0,0', ...
                'rot = 0,0,0,1', 'mir = 1,1,1', '}', ...
                'PART', '{', 'part = tankB_102', 'pos = 0,1,0', ...
                'rot = 0,0,0,1', 'mir = 1,1,1', '}'});
            outDir = testCase.tempDir();

            result = lvd_generateAeroTablesFromCraft(craftPath, struct( ...
                'cubeDB', dbPath, 'outDir', outDir, 'quiet', true, ...
                'machVec', [0 1], 'aoaDegVec', [-15 0 15], ...
                'sideslipDegVec', [-5 0 5]));

            testCase.verifyTrue(isfile(result.dragCsv) && isfile(result.liftCsv));
            testCase.verifyTrue(iscell(result.warnings));
            testCase.verifyGreaterThan(max(result.tables.dragCubeCdA(:)), 0, ...
                'Swept drag must be nonzero somewhere.');
            testCase.verifyGreaterThan(max(abs(result.tables.ClS(:))), 0, ...
                'Swept lift must be nonzero off-axis.');
            % Sibling CSVs share one folder ("both options": install one,
            % hand the other to the opposite UI).
            testCase.verifyEqual(fileparts(result.dragCsv), fileparts(result.liftCsv));
        end

        function importInstallsIntoBothModelTypes(testCase)
            faces = repmat([1.1 0.55 0.4], 6, 1);
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/probe', 'cubes', {{ ...
                    struct('cubeName', 'Default', 'faces', faces)}}) ...
                });
            craftPath = testCase.writeLines('installCraft.craft', { ...
                'ship = InstallMe', ...
                'PART', '{', 'part = probe_1', 'pos = 0,0,0', ...
                'rot = 0,0,0,1', 'mir = 1,1,1', '}'});
            outDir = testCase.tempDir();
            genOpts = struct('cubeDB', dbPath, 'outDir', outDir, 'quiet', true, ...
                'machVec', [0 1], 'aoaDegVec', [-10 0 10], ...
                'sideslipDegVec', [0 5]);

            dragModel = KosDragCoeffientModel('');
            resD = lvd_importAeroTableFromCraft(dragModel, craftPath, genOpts);
            testCase.verifyEqual(dragModel.dataFile, resD.dragCsv);
            testCase.verifyTrue(isfinite(dragModel.giDragCube(0.5, 0, 0)), ...
                'Installed drag table must interpolate.');

            liftModel = UserTabulatedLiftModel('');
            resL = lvd_importAeroTableFromCraft(liftModel, craftPath, genOpts);
            testCase.verifyEqual(liftModel.dataFile, resL.liftCsv);
            testCase.verifyTrue(isfinite(liftModel.giClS(0.5, 0, 0)), ...
                'Installed lift table must interpolate.');

            testCase.verifyError( ...
                @() lvd_importAeroTableFromCraft(ConstantDragCoeffModel(1), craftPath, genOpts), ...
                'lvd_importAeroTableFromCraft:badModel');
        end

        function liftDialogOffersGenerateFromCraft(testCase)
            model = UserTabulatedLiftModel('');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditUserTabulatedLiftPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.addTeardown(@() KwtAeroTest.deleteIfValid(app));

            testCase.verifyTrue(isprop(app, 'generateFromCraftButton'), ...
                'The lift editor must carry a Generate-from-Craft button.');
            testCase.verifyEqual(app.generateFromCraftButton.Text, 'Generate from Craft...');
        end

        %% ----------------- real craft, stubs, gated oracles -----------------
        function fullChainRealCraftWithStubCubes(testCase)
            % End-to-end over the real Kerbal 1-5_3.craft geometry (real
            % quats incl. the non-unit noseCone quaternion, radial sets,
            % real MODULE blocks) with tank-like stub cubes per part name.
            % With identical cubes per part name the vessel is exactly
            % mirror-symmetric, so this is the rotation-chaining bug
            % detector (methodology section 7.5.3): nonzero variance here
            % would mean a rotation bug, not aerodynamics. Positions are
            % ignored by the builder, so only orientations matter.
            root = ksptotTestRoot();
            craftPath = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', 'Kerbal 1-5_3.craft');
            testCase.assumeTrue(isfile(craftPath), 'Example craft missing.');

            craft = sfsParse(craftPath);
            cubeDB = testCase.stubCubeDbForNames(testCase.craftPartNames(craft));
            phys = kwt_physicsGlobals();
            spec = kwt_buildAeroSpec(craftPath, cubeDB, phys);

            testCase.verifyEqual(numel(spec.parts), numel(craft.PART), ...
                'Every craft PART must become a spec part.');
            for(p = 1:numel(spec.parts))
                R = spec.parts(p).R_part2vessel;
                testCase.verifyEqual(R' * R, eye(3), 'AbsTol', 1e-9, ...
                    'Real craft quats (incl. non-unit ones) must yield orthonormal DCMs.');
                testCase.verifyGreaterThan(det(R), 0);
            end

            a = deg2rad(12);
            oP = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(a, 0), 0.6, 1);
            oM = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(-a, 0), 0.6, 1);
            o0 = kwt_aero(spec, phys, kwt_inflowFromAeroAngles(0, 0), 0.6, 1);

            testCase.verifyGreaterThan(abs(oP.ClS), 1e-6, ...
                'The real stack at 12 deg AoA must lift (tank-like stubs).');
            % Residual (not exact) symmetry: the single KAL9000 controller
            % is mounted at a genuinely asymmetric orientation (verified by
            % per-part probe 2026-09-25: 27/28 parts antis mirror to
            % fp-level, KAL9000 maximally asymmetric). A rotation-chaining
            % bug would shatter symmetry across ALL parts, so these bounds
            % still detect it; they just don't demand geometry KSP itself
            % doesn't have. Measured 2026-09-25: lift 0.11, drag 0.030,
            % zero-AoA 0.067.
            liftResid = abs(oP.ClS + oM.ClS) / max([abs(oP.ClS), abs(oM.ClS), eps]);
            testCase.verifyLessThanOrEqual(liftResid, 0.15, ...
                'Real-geometry lift antisymmetry residual too large (rotation bug?).');
            dragResid = abs(oP.dragCubeCdA - oM.dragCubeCdA) / ...
                max([oP.dragCubeCdA, oM.dragCubeCdA, eps]);
            testCase.verifyLessThanOrEqual(dragResid, 0.05, ...
                'Real-geometry drag mirror residual too large (rotation bug?).');
            testCase.verifyLessThanOrEqual(abs(o0.ClS), 0.10 * abs(oP.ClS), ...
                'Zero-AoA residual (asymmetric singles) must stay small.');
            testCase.verifyGreaterThan(o0.dragCubeCdA, 0);
        end

        function malformedPartDatabaseHandled(testCase)
            garbage = testCase.writeLines('garbagePartDb.cfg', { ...
                'this is not {{{ a config file', 'PART { unclosed' ... 
                });
            [cubeDB, warnings] = lvd_import_cubeDB(garbage);
            testCase.verifyEqual(cubeDB.numParts, 0);
            testCase.verifyFalse(isempty(warnings), ...
                'A DB with no usable PARTs must warn, not throw.');

            badCube = testCase.writeLines('badCubePartDb.cfg', { ...
                'PART', '{', 'url = Test/broken', 'DRAG_CUBE', '{', ...
                'cube = Default, 1,2,3', '}', '}' ... 
                });
            [cubeDB2, warnings2] = lvd_import_cubeDB(badCube);
            testCase.verifyEqual(cubeDB2.numParts, 0, ...
                'A truncated cube line (< 24 numbers) must be skipped.');
            testCase.verifyFalse(isempty(warnings2));
        end

        function gatedRealPhysicsMatchesCompiledDefaults(testCase)
            % Needs a KSP install: set KSPTOT_KSP_ROOT to the install root
            % (folder containing PartDatabase.cfg + Physics.cfg). Skipped
            % otherwise. Pins the compiled Physics.cfg transcription
            % against the real 1.12.5 file (verified byte-identical once,
            % 2026-09-25; this keeps it that way).
            kspRoot = getenv('KSPTOT_KSP_ROOT');
            testCase.assumeTrue(~isempty(kspRoot) && isfolder(kspRoot), ...
                'Set KSPTOT_KSP_ROOT to a KSP install to run oracle tests.');

            filePhys = kwt_physicsGlobals(fullfile(kspRoot, 'Physics.cfg'));
            compiled = kwt_physicsGlobals();
            testCase.verifyEqual(filePhys.dragMultiplier, compiled.dragMultiplier, 'AbsTol', 0);
            testCase.verifyEqual(filePhys.dragCubeMultiplier, compiled.dragCubeMultiplier, 'AbsTol', 0);
            testCase.verifyEqual(filePhys.liftMultiplier, compiled.liftMultiplier, 'AbsTol', 0);
            testCase.verifyEqual(filePhys.liftDragMultiplier, compiled.liftDragMultiplier, 'AbsTol', 0);
            testCase.verifyEqual(filePhys.bodyLiftMultiplier, compiled.bodyLiftMultiplier, 'AbsTol', 0);
            curves = {'tipCurve','surfaceCurve','tailCurve','overallCurve','cdCurve', ...
                'cdPowerCurve','pseudoReynoldsCurve','wingLiftCurve','wingLiftMachCurve', ...
                'wingDragCurve','wingDragMachCurve','bodyLiftCurve','bodyLiftMachCurve', ...
                'capsuleLiftCurve','capsuleLiftMachCurve','capsuleDragCurve','capsuleDragMachCurve'};
            for(k = 1:numel(curves))
                testCase.verifyEqual(filePhys.(curves{k}), compiled.(curves{k}), ...
                    'AbsTol', 0, sprintf('Stock curve %s drifted.', curves{k}));
            end
        end

        function gatedRealCraftMatchesKosOracleBand(testCase)
            % Full replay on the real Kerbal 1-5_3 stack with KSP's own
            % cubes, compared against the committed kOS drag oracle for
            % the same craft. The node-area occlusion model (no fitting,
            % pure cube geometry + attN topology) lands within ~10% of
            % KSP's own drag computation across all three staging
            % configurations (medians 0.96/1.09/0.96 measured 2026-09-26,
            % previously ~4-6x without occlusion). The bands below guard
            % that calibrated state: a unit/scaling bug or a broken
            % occlusion stage fails loud; residual spread covers Mach-grid
            % sampling and the kOS profile's own approximations.
            kspRoot = getenv('KSPTOT_KSP_ROOT');
            testCase.assumeTrue(~isempty(kspRoot) && isfolder(kspRoot), ...
                'Set KSPTOT_KSP_ROOT to a KSP install to run oracle tests.');

            phys = kwt_physicsGlobals(fullfile(kspRoot, 'Physics.cfg'));
            cubeDB = lvd_import_cubeDB(fullfile(kspRoot, 'PartDatabase.cfg'));
            testCase.verifyGreaterThan(cubeDB.numParts, 100, ...
                'The real PartDatabase.cfg must yield hundreds of parts.');
            partDB = testCase.mergedGatedPartDb(kspRoot);

            root = ksptotTestRoot();
            dragDir = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData');
            variants = {'Kerbal 1-5_3', 'Kerbal 1-5_3_NoBoosters', ...
                'Kerbal 1-5_3_NoBoosters_NoFirstStage'};
            machVec = [0 0.5 1 1.5 2 5];
            aoaVec = [-15 0 15];
            for(v = 1:numel(variants))
                stem = fullfile(dragDir, variants{v});
                spec = kwt_buildAeroSpec([stem '.craft'], cubeDB, phys, ...
                    struct('partDB', partDB));
                testCase.verifyEmpty(spec.warnings, sprintf( ...
                    'Every stock part of %s must resolve cubes.', variants{v}));
                oracle = KosDragCoeffientModel([stem '_DragData.csv']);
                ratios = zeros(numel(machVec), numel(aoaVec));
                for(m = 1:numel(machVec))
                    for(a = 1:numel(aoaVec))
                        out = kwt_aero(spec, phys, kwt_inflowFromAeroAngles( ...
                            deg2rad(aoaVec(a)), 0), machVec(m), 1);
                        ref = oracle.giDragCube(machVec(m), deg2rad(aoaVec(a)), 0);
                        testCase.verifyGreaterThan(ref, 0, 'Oracle must be positive here.');
                        testCase.verifyGreaterThan(out.dragCubeCdA, 0, 'Replay must be positive here.');
                        ratios(m, a) = out.dragCubeCdA / ref;
                    end
                end
                med = median(ratios(:));
                fprintf('%s kOS-oracle drag ratio median=%g min=%g max=%g\n', ...
                    variants{v}, med, min(ratios(:)), max(ratios(:)));
                testCase.verifyGreaterThanOrEqual(med, 0.8, sprintf( ...
                    '%s median ratio %g: underprediction (broken occlusion or units).', variants{v}, med));
                testCase.verifyLessThanOrEqual(med, 1.3, sprintf( ...
                    '%s median ratio %g: overprediction (occlusion regressed?).', variants{v}, med));
                testCase.verifyGreaterThanOrEqual(min(ratios(:)), 0.7, sprintf( ...
                    '%s min ratio: point-wise underprediction too large.', variants{v}));
                testCase.verifyLessThanOrEqual(max(ratios(:)), 1.5, sprintf( ...
                    '%s max ratio: point-wise overprediction too large.', variants{v}));
            end

            % Shape invariants on the full real stack: transonic hump and
            % AoA-antisymmetric lift with a small zero-AoA residual.
            fullSpec = kwt_buildAeroSpec( ...
                fullfile(dragDir, 'Kerbal 1-5_3.craft'), cubeDB, phys, ...
                struct('partDB', partDB));
            [tables, ~] = kwt_sweepCraft(fullSpec, phys, struct('machVec', machVec, ...
                'aoaDegVec', aoaVec, 'sideslipDegVec', 0, 'quiet', true));
            D0 = squeeze(tables.dragCubeCdA(:, 2, 1));
            testCase.verifyGreaterThan(max(D0(3:4)), D0(1), ...
                'Transonic drag hump must exceed the subsonic value at AoA 0.');
            C = tables.ClS(:, :, 1);
            resid = abs(C(:, 1) + C(:, 3)) ./ max([abs(C(:)); eps]);
            testCase.verifyLessThanOrEqual(max(resid), 0.15, ...
                'Real-stack lift antisymmetry residual must stay small.');

            % Pod + fin records on the real stack: the Mk1 pod resolves its
            % full cfg module (0.35/CapsuleBottom/clamped/Y/-1/node-gated/
            % dragless) and the fins the live 0.12 coefficient.
            podIdx = find(strcmp({fullSpec.parts.baseName}, 'mk1pod.v2'), 1);
            testCase.verifyFalse(isempty(podIdx), 'Pod must be present.');
            podPart = fullSpec.parts(podIdx);
            testCase.verifyEqual(podPart.deflectionLiftCoeff, 0.35, 'AbsTol', 1e-12, ...
                'Pod harvest must read 0.35.');
            testCase.verifyEqual(podPart.liftCurveSet, 'CapsuleBottom');
            testCase.verifyFalse(podPart.omnidirectional);
            testCase.verifyEqual(podPart.liftVector_local, [0; -1; 0], 'AbsTol', 0, ...
                'Pod transformDir Y with sign -1 gives stack-down.');
            testCase.verifyFalse(podPart.useInternalDragModel, 'Pod wing drag is off.');
            testCase.verifyEqual( ...
                partDB.parts('basicfin').liftingSurface.deflectionLiftCoeff, ...
                0.12, 'AbsTol', 1e-12, 'Stock fin harvest must read 0.12.');

            % GameData refinement vs KSP defaults: identical cube drag
            % (wings never take the body path either way), different
            % other-drag (0.12/pod-rule vs blanket 1.5).
            plainSpec = kwt_buildAeroSpec( ...
                fullfile(dragDir, 'Kerbal 1-5_3.craft'), cubeDB, phys);
            v15 = kwt_inflowFromAeroAngles(deg2rad(15), 0);
            oBase = kwt_aero(plainSpec, phys, v15, 0.5, 1);
            oFin = kwt_aero(fullSpec, phys, v15, 0.5, 1);
            testCase.verifyEqual(oFin.dragCubeCdA, oBase.dragCubeCdA, 'AbsTol', 0, ...
                'Lift coefficients must not touch cube drag.');
            testCase.verifyNotEqual(oFin.otherDragCdA, oBase.otherDragCdA, ...
                'GameData coefficients must move other-drag.');
            testCase.verifyFalse(isempty(plainSpec.warnings), ...
                'Blanket 1.5 defaults must warn.');
        end

        %% ------------------------- shielding -------------------------
        function shieldFairingEnclosesInterstagePayload(testCase)
            % Closed fairing: interstage payload (+ its stack child) in,
            % top/bottom pass-through out, fairing itself out, link-only
            % hitchhiker out (conservative on missing node records).
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/fairingBase', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/payload', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/upper', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/hitch', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = ShieldFair\n' ...
                'PART\n{\n\tpart = fairingBase_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tlink = payload_2\n\tlink = upper_3\n\tlink = hitch_4\n' ...
                '\tattN = interstage01a,payload_2_0|0.5|0_0|1|0_0|0.5|0_0|1|0\n' ...
                '\tattN = top,upper_3_0|0.5|0_0|1|0_0|0.5|0_0|1|0\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleProceduralFairing\n\t}\n}\n' ...
                'PART\n{\n\tpart = payload_2\n\tpos = 0,1,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tlink = upper_3\n}\n' ...
                'PART\n{\n\tpart = upper_3\n\tpos = 0,3,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n' ...
                'PART\n{\n\tpart = hitch_4\n\tpos = 1,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());

            flags = containers.Map( ...
                {spec.parts.instanceID}, num2cell([spec.parts.isShielded]));
            testCase.verifyTrue(flags('payload_2'), 'Interstage payload must be shielded.');
            testCase.verifyFalse(flags('upper_3'), 'Top pass-through must stay exposed.');
            testCase.verifyFalse(flags('fairingBase_1'), 'The shield itself stays exposed.');
            testCase.verifyFalse(flags('hitch_4'), ...
                'Link-only child without node records stays exposed (conservative).');
            testCase.verifyEqual(sort(spec.autoShielded), {'payload_2'});

            % Shielded payload must vanish from the aero: compare against
            % the same spec with the payload deleted.
            phys = kwt_physicsGlobals();
            vHat = kwt_inflowFromAeroAngles(deg2rad(10), deg2rad(5));
            full = kwt_aero(spec, phys, vHat, 0.5, 1);
            noshield = spec;
            noshield.parts(2).isShielded = false;
            open = kwt_aero(noshield, phys, vHat, 0.5, 1);
            testCase.verifyLessThan(full.dragCubeCdA, open.dragCubeCdA, ...
                'Auto-shielding must remove payload drag.');
        end

        function shieldCargoBayDoorState(testCase)
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/bay', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/probe', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            bayCraft = @(animBlock) sprintf([ ...
                'ship = ShieldBay\n' ...
                'PART\n{\n\tpart = bay_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tlink = probe_2\n%s' ...
                '\tMODULE\n\t{\n\t\tname = ModuleCargoBay\n\t}\n}\n' ...
                'PART\n{\n\tpart = probe_2\n\tpos = 0,0,0.5\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tsrfN = srfAttach,bay_1,,0|0|0,1|0|0,0|0|0\n}\n'], animBlock);
            animOn = @(pct) sprintf([ ...
                '\tMODULE\n\t{\n\t\tname = ModuleAnimateGeneric\n' ...
                '\t\tdeployPercent = %g\n\t}\n'], pct);

            closedSpec = kwt_buildAeroSpec(bayCraft(animOn(100)), ...
                cubeDB, kwt_physicsGlobals());
            testCase.verifyTrue(closedSpec.parts(2).isShielded, ...
                'Closed bay (100%) must shield srf payload.');

            openSpec = kwt_buildAeroSpec(bayCraft(animOn(0)), ...
                cubeDB, kwt_physicsGlobals());
            testCase.verifyFalse(openSpec.parts(2).isShielded, ...
                'Open bay (0%) must not shield.');

            bareSpec = kwt_buildAeroSpec(bayCraft(''), cubeDB, kwt_physicsGlobals());
            testCase.verifyTrue(bareSpec.parts(2).isShielded, ...
                'Bay without animation state defaults to closed.');

            testCase.verifyFalse(closedSpec.parts(1).isShielded, ...
                'The bay itself stays exposed.');
        end

        function shieldNestedStackInsideFairing(testCase)
            % Engine hung under an interstage payload is still inside the
            % fairing (never crossed its top/bottom); the upper stage
            % above the fairing top is outside.
            dbPath = testCase.writePartDb({ ...
                struct('url', 'Test/fairingBase', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/tank', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/engine', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}), ...
                struct('url', 'Test/upper', 'cubes', {{ ...
                    testCase.namedCube('Default', [1 1 1])}}) ...
                });
            cubeDB = lvd_import_cubeDB(dbPath);
            craftText = sprintf([ ...
                'ship = ShieldNest\n' ...
                'PART\n{\n\tpart = fairingBase_1\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tlink = tank_2\n\tlink = upper_4\n' ...
                '\tattN = interstage01a,tank_2_0|0.5|0_0|1|0_0|0.5|0_0|1|0\n' ...
                '\tattN = top,upper_4_0|0.5|0_0|1|0_0|0.5|0_0|1|0\n' ...
                '\tMODULE\n\t{\n\t\tname = ModuleProceduralFairing\n\t}\n}\n' ...
                'PART\n{\n\tpart = tank_2\n\tpos = 0,1,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n' ...
                '\tlink = engine_3\n' ...
                '\tattN = bottom,engine_3_0|-0.5|0_0|-1|0_0|-0.5|0_0|-1|0\n}\n' ...
                'PART\n{\n\tpart = engine_3\n\tpos = 0,0,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n' ...
                'PART\n{\n\tpart = upper_4\n\tpos = 0,3,0\n\trot = 0,0,0,1\n\tmir = 1,1,1\n}\n']);

            spec = kwt_buildAeroSpec(craftText, cubeDB, kwt_physicsGlobals());
            flags = containers.Map( ...
                {spec.parts.instanceID}, num2cell([spec.parts.isShielded]));
            testCase.verifyTrue(flags('tank_2'), 'Interstage tank shielded.');
            testCase.verifyTrue(flags('engine_3'), ...
                'Stack child under enclosed tank stays enclosed.');
            testCase.verifyFalse(flags('upper_4'), 'Stage above the top node exposed.');
        end

        function shieldNoMisfireOnExampleStack(testCase)
            % The example Kerbal stack has no bays/fairings: automation
            % must stay completely quiet there (regression guard).
            root = ksptotTestRoot();
            craftPath = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', 'Kerbal 1-5_3.craft');
            testCase.assumeTrue(isfile(craftPath), 'Example craft missing.');
            craft = sfsParse(craftPath);
            cubeDB = testCase.stubCubeDbForNames(testCase.craftPartNames(craft));
            spec = kwt_buildAeroSpec(craftPath, cubeDB, kwt_physicsGlobals());
            testCase.verifyEmpty(spec.autoShielded, ...
                'No example part may auto-shield.');
            testCase.verifyFalse(any([spec.parts.isShielded]), ...
                'Manual list empty + no shields => nothing shielded.');
        end

        %% ------------------------- KWT export scaffold -------------------------
        function gatedKwtPitchSliceMatchesExport(testCase)
            % KWT-oracle pitch-plane validation (methodology section 7.5.1).
            % Needs, per craft, a KWT AoA-curve export: in KSP, open the
            % craft in the SPH/VAB with Kerbal Wind Tunnel installed,
            % WindTunnel window -> Export Data -> the SIMPLE (non
            % characterized-vessel) CSV holding drag and lift coefficient
            % vs AoA and Mach. Place it at
            %   <DragData>/KWT/<craft-stem>_KWT.csv
            % or set KSPTOT_KWT_EXPORT to a folder holding such files.
            % Without exports this skips (see the KWT author on the
            % formats: bodyDrag FloatCurve2 / MFactor x coeff pairs for
            % the characterized export; plain coeff tables otherwise).
            %
            % Comparison is by vessel-frame force vectors (direction cosine
            % plus magnitude-ratio uniformity = single reference Q), which
            % is immune to the flight-frame projection conventions that
            % made scalar lift-curve comparison meaningless near broadside.
            % Asserts direction (> 0.7 worst cosine) and magnitude
            % consistency (ratio CV < 0.3); axial tilt-response shape is
            % reported (KWT's W-shape vs our monotonic response is OPEN --
            % possibly characterized-cache ringing; a direct-mode KWT
            % export would settle it).
            kspRoot = getenv('KSPTOT_KSP_ROOT');
            testCase.assumeTrue(~isempty(kspRoot) && isfolder(kspRoot), ...
                'Set KSPTOT_KSP_ROOT to a KSP install to run oracle tests.');
            kwtFiles = testCase.findKwtExports();
            testCase.assumeTrue(~isempty(kwtFiles), ...
                ['No KWT exports found. Generate per-craft AoA-curve CSVs ' ...
                 'as described above.']);

            phys = kwt_physicsGlobals(fullfile(kspRoot, 'Physics.cfg'));
            cubeDB = lvd_import_cubeDB(fullfile(kspRoot, 'PartDatabase.cfg'));
            partDB = testCase.mergedGatedPartDb(kspRoot);
            compared = 0;
            for(f = 1:numel(kwtFiles))
                [craftStem, tbl] = testCase.loadKwtTable(kwtFiles{f});
                if(isempty(tbl))
                    continue;   % unrecognized layout: documented skip
                end
                craftPath = testCase.craftForKwtStem(craftStem);
                testCase.assumeTrue(isfile(craftPath), ...
                    sprintf('No craft found for KWT export %s.', kwtFiles{f}));
                spec = kwt_buildAeroSpec(craftPath, cubeDB, phys, ...
                    struct('partDB', partDB));
                [minCos, ratioCV, axialCorr] = testCase.kwtVectorAgreement(spec, phys, tbl);
                [~, kwtBase] = fileparts(kwtFiles{f});
                fprintf('KWT %s [%s]: minCos=%g ratioCV=%g axialCorr=%g\n', ...
                    craftStem, kwtBase, minCos, ratioCV, axialCorr);
                testCase.verifyGreaterThan(minCos, 0.7, sprintf( ...
                    'KWT vessel-force direction mismatch for %s.', craftStem));
                testCase.verifyLessThan(ratioCV, 0.3, sprintf( ...
                    'KWT force-magnitude ratio not uniform for %s (no single reference Q).', craftStem));
                compared = compared + 1;
            end
            testCase.verifyGreaterThan(compared, 0, ...
                'No KWT export had a comparable AoA-curve layout.');
        end

        function kwtVesselComponentAgreement(testCase)
            % Component-level agreement with the KWT Vessel
            % (characterized) XLSX exports, per lift group, projected on
            % the craft-frame flight direction (immune to all
            % table-projection conventions). Body lift and body drag loop
            % Mach [0.5, 2, 5] (supersonic cube/Mach-curve application has
            % no other oracle check); surfaces stay at 0.5 where they are
            % bit-exact. Validated 2026-09-26:
            % NoBoosters body corr 0.9993 at ratio 1.02, full-craft body
            % corr 0.9993 at 1.12, NoFS body corr 0.997 at 1.01;
            % pod/fin surface groups and wing drag bit-exact (corr 1.0,
            % ratio 1.0) on every craft that carries them.
            kspRoot = getenv('KSPTOT_KSP_ROOT');
            testCase.assumeTrue(~isempty(kspRoot) && isfolder(kspRoot), ...
                'Set KSPTOT_KSP_ROOT to a KSP install to run oracle tests.');
            vesselFiles = testCase.findKwtVesselExports();
            testCase.assumeTrue(~isempty(vesselFiles), ...
                ['No KWT Vessel exports found. In KSP: open the KWT window ' ...
                 'on each example craft, Update Vessel to 100%, Export, ' ...
                 'and save the workbooks as <craftStem>_KWT_Vessel.xlsx ' ...
                 'in DragData/KWT/.']);

            phys = kwt_physicsGlobals(fullfile(kspRoot, 'Physics.cfg'));
            cubeDB = lvd_import_cubeDB(fullfile(kspRoot, 'PartDatabase.cfg'));
            partDB = testCase.mergedGatedPartDb(kspRoot);
            compared = 0;
            for(f = 1:numel(vesselFiles))
                [~, name] = fileparts(vesselFiles{f});
                tok = regexpi(name, '^(.*)_kwt_vessel$', 'tokens', 'once');
                testCase.assumeTrue(~isempty(tok), ...
                    sprintf('Vessel export %s must be <craftStem>_KWT_Vessel.xlsx.', name));
                stem = tok{1};
                craftPath = testCase.craftForKwtStem(stem);
                testCase.assumeTrue(isfile(craftPath), ...
                    sprintf('No craft found for KWT Vessel export %s.', name));
                spec = kwt_buildAeroSpec(craftPath, cubeDB, phys, ...
                    struct('partDB', partDB));
                sheets = sheetnames(vesselFiles{f});
                if(strcmp(stem, 'Kerbal 1-5_3_NoBoosters'))
                    band = [0.9 1.1];
                else
                    % NoFS (smallest stack) and the SRB-heavy full stack
                    % carry larger occlusion-approximation residuals
                    % (measured body ratios 1.01 and 1.12).
                    band = [0.8 1.2];
                end

                % ---- body group (non-lifting parts) ----
                testCase.assumeTrue(any(strcmp(sheets, 'bodyLift_Coef')), ...
                    sprintf('%s: bodyLift_Coef sheet missing.', stem));
                bodySpec = testCase.zeroLiftExcept(spec, {});
                C = readmatrix(vesselFiles{f}, 'Sheet', 'bodyLift_Coef');
                MF = readmatrix(vesselFiles{f}, 'Sheet', 'bodyLift_MFactor');
                C = C(all(isfinite(C), 2), :);
                MF = MF(all(isfinite(MF), 2), :);
                testCase.assumeTrue(size(C, 1) >= 5, ...
                    sprintf('%s: too few body rows.', stem));
                % Body Mach loop: the cube/Mach-curve application above
                % Mach 1.5 has no other oracle check (kOS band stops at
                % supersonic drag; surfaces stay at 0.5 where they are
                % bit-exact). MFactor sheets evaluate at any Mach.
                for mach = [0.5 2 5]
                    mV = ksp_evalFloatCurve(MF(:, 1:4), mach);
                    [ccB, rB, nB] = testCase.vesselLiftAgreement( ...
                        bodySpec, [], phys, C(:, 1), C(:, 2) * mV, mach);
                    fprintf('KWT Vessel %s body M=%g: corr=%g ratio=%g n=%d\n', ...
                        stem, mach, ccB, rB, nB);
                    testCase.verifyGreaterThan(ccB, 0.99, sprintf('%s body M=%g shape mismatch.', stem, mach));
                    testCase.verifyGreaterThan(rB, band(1), sprintf('%s body M=%g ratio low.', stem, mach));
                    testCase.verifyLessThan(rB, band(2), sprintf('%s body M=%g ratio high.', stem, mach));
                end

                % ---- surface groups (pod + fins, best-matched by shape:
                % group indices are characterization order, not stable) ----
                surfSheets = sheets(~cellfun(@isempty, regexp(sheets, '^surfLift\d*_Coef$')));
                testCase.assumeTrue(~isempty(surfSheets), ...
                    sprintf('%s: no surface lift sheets.', stem));
                podSpec = testCase.zeroLiftExcept(spec, {'mk1pod.v2'});
                [ccP, rP, sheetP] = testCase.bestSurfMatch(podSpec, bodySpec, phys, vesselFiles{f}, surfSheets, 0.5);
                fprintf('KWT Vessel %s pod->%s: corr=%g ratio=%g\n', stem, sheetP, ccP, rP);
                testCase.verifyGreaterThan(ccP, 0.99, sprintf('%s pod shape mismatch.', stem));
                testCase.verifyGreaterThan(rP, 0.9, sprintf('%s pod ratio low.', stem));
                testCase.verifyLessThan(rP, 1.1, sprintf('%s pod ratio high.', stem));
                finSpec = testCase.zeroLiftExcept(spec, {'basicfin'});
                hasFins = any(arrayfun(@(p) p.hasLiftModule && p.deflectionLiftCoeff ~= 0, finSpec.parts));
                if(hasFins)
                    rest = setdiff(surfSheets, sheetP);
                    testCase.assumeTrue(~isempty(rest), sprintf('%s: no fin sheet left.', stem));
                    [ccF, rF, sheetF] = testCase.bestSurfMatch(finSpec, bodySpec, phys, vesselFiles{f}, rest, 0.5);
                    fprintf('KWT Vessel %s fins->%s: corr=%g ratio=%g\n', stem, sheetF, ccF, rF);
                    testCase.verifyGreaterThan(ccF, 0.99, sprintf('%s fin shape mismatch.', stem));
                    testCase.verifyGreaterThan(rF, 0.9, sprintf('%s fin ratio low.', stem));
                    testCase.verifyLessThan(rF, 1.1, sprintf('%s fin ratio high.', stem));

                    % ---- wing drag (parasitic + induced at Mach 0.5) ----
                    if(any(strcmp(sheets, 'surfDrag_Coef')) && any(strcmp(sheets, 'induDrag_Coef')))
                        testCase.wingDragAgreement(finSpec, phys, vesselFiles{f}, stem);
                    end
                else
                    % Finless craft (NoFS): every lifted part must be the pod.
                    lifted = arrayfun(@(p) p.hasLiftModule && p.deflectionLiftCoeff ~= 0, spec.parts);
                    testCase.verifyTrue(any(lifted), sprintf('%s: no lifted parts at all.', stem));
                    testCase.verifyTrue(all(strcmp({spec.parts(lifted).baseName}, 'mk1pod.v2')), ...
                        sprintf('%s: non-pod lifting parts but no fin sheets.', stem));
                end

                % ---- body drag grid (AoA rows in radians, Mach columns) ----
                if(any(strcmp(sheets, 'bodyDrag_values')))
                    testCase.bodyDragAgreement(spec, phys, vesselFiles{f}, stem);
                end
                compared = compared + 1;
            end
            testCase.verifyGreaterThan(compared, 0, ...
                'No complete KWT Vessel export compared.');
        end

        function dragEnvelopePlotsNonSquareGrid(testCase)
            % plotDragEnvelope passed the AoA vector as contour X against
            % a Z whose columns are sideslip, which only runs on square
            % grids (the kOS 13x13 tensor hid it). Craft-generated tables
            % like 13 AoA x 7 sideslip failed from the drag dialog with
            % "size of X must match ... columns of Z" (2026-09-27). The
            % transpose fix must keep square grids plotting too.
            aoa = -30:15:30;    % 5 points, DEGREES per the kOS dialect
            ssip = -15:15:15;   % 3 points (deliberately != 5)
            [A, S] = meshgrid(aoa, ssip);
            M = [zeros(numel(A), 1); ones(numel(A), 1)];
            rows = [M, repmat([A(:), S(:)], 2, 1), ...
                1 + (repmat(A(:), 2, 1)/30).^2, zeros(2*numel(A), 1)];
            csvPath = fullfile(testCase.tempDir(), 'nonsquare.csv');
            writematrix(rows, csvPath);
            model = KosDragCoeffientModel(csvPath);
            fig = figure('Visible', 'off');
            finish = onCleanup(@() close(fig));
            ax = axes(fig);
            model.plotDragEnvelope(ax, 0);
            testCase.verifyFalse(isempty(ax.Children), ...
                'Non-square grid must contour without a size error.');
            testCase.verifyEqual(ax.XLabel.String, 'Angle of Attack [deg]');
        end

        %% ------------------------- regression guards -------------------------
        function existingModelDefaultsStillConstruct(testCase)
            drag = KosDragCoeffientModel('');
            lift = UserTabulatedLiftModel('');
            testCase.verifyTrue(isa(drag, 'KosDragCoeffientModel'));
            testCase.verifyTrue(isa(lift, 'UserTabulatedLiftModel'));
            testCase.verifyTrue(isfinite(drag.giDragCube(0, 0, 0)));
            testCase.verifyEqual(lift.giClS(0, 0, 0), 0, 'AbsTol', 0);
        end

        function exampleKosDragCsvDialectLoads(testCase)
            root = ksptotTestRoot();
            f = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', ...
                'Kerbal 1-5_3_DragData.csv');
            testCase.assumeTrue(isfile(f), 'Example drag CSV missing.');
            rows = readmatrix(f);
            testCase.verifyEqual(size(rows, 2), 5, ...
                'The kOS drag dialect is 5 columns; the sweep must match it.');
            model = KosDragCoeffientModel(f);
            testCase.verifyTrue(isfinite(model.giDragCube(0.5, 0, 0)), ...
                'Example drag data must interpolate at a mid-envelope point.');
        end

        function oracleCsvGridConformanceAllVariants(testCase)
            % The DragData folder holds one kOS oracle per staging
            % configuration (full / NoBoosters / NoBoosters_NoFirstStage),
            % all generated by kos_scripts/createDragData.ks over
            % AoA/sideslip -30:5:30 deg and Mach 0:0.1:10. Every file must
            % be the same complete non-negative tensor the sweep writes.
            paths = testCase.oracleVariantPaths();
            testCase.assumeTrue(all(cellfun(@isfile, paths)), 'Oracle CSVs missing.');
            for(v = 1:numel(paths))
                M = readmatrix(paths{v});
                testCase.verifyEqual(size(M), [17069 5], ...
                    sprintf('Oracle %d must be the full 101x13x13 tensor.', v));
                testCase.verifyEqual(unique(M(:, 1))', 0:0.1:10, 'AbsTol', 1e-9, ...
                    'Oracle Mach grid must be 0:0.1:10.');
                testCase.verifyEqual(unique(M(:, 2))', -30:5:30, 'AbsTol', 1e-9, ...
                    'Oracle AoA grid must be -30:5:30 deg.');
                testCase.verifyEqual(unique(M(:, 3))', -30:5:30, 'AbsTol', 1e-9, ...
                    'Oracle sideslip grid must be -30:5:30 deg.');
                testCase.verifyEqual(size(unique(M(:, 1:3), 'rows'), 1), 17069, ...
                    'Oracle grid points must be unique (complete tensor).');
                testCase.verifyTrue(all(isfinite(M(:))), 'Oracle must be finite.');
                testCase.verifyTrue(all(M(:, 4) >= 0) && all(M(:, 5) >= 0), ...
                    'CdA columns must be non-negative.');
            end
        end

        function oracleSymmetricStackNearSymmetric(testCase)
            % The kOS oracle resolves occlusion/shielding per attitude, so
            % unlike the replay it is only APPROXIMATELY symmetric on this
            % symmetric stack (worst mirror diff 8.3% at Mach 0.5 measured
            % 2026-09-26). Pins that property: it justifies the replay's
            % exact-symmetry design target while recording the oracle's
            % own sampling noise floor.
            paths = testCase.oracleVariantPaths();
            testCase.assumeTrue(all(cellfun(@isfile, paths)), 'Oracle CSVs missing.');
            for(v = 1:numel(paths))
                M = readmatrix(paths{v});
                sub = M(M(:, 1) == 0.5, :);
                worst = 0;
                for(k = 1:size(sub, 1))
                    mirror = sub(abs(sub(:, 2) + sub(k, 2)) < 1e-9 & ...
                        abs(sub(:, 3) - sub(k, 3)) < 1e-9, :);
                    if(~isempty(mirror))
                        denom = max([abs(sub(k, 4)), abs(mirror(1, 4)), 1e-9]);
                        worst = max(worst, abs(sub(k, 4) - mirror(1, 4)) / denom);
                    end
                end
                testCase.verifyLessThanOrEqual(worst, 0.10, ...
                    sprintf('Oracle variant %d AoA-mirror spread too large.', v));
            end
        end

        function sweepRespectsStagingConfiguration(testCase)
            % Tables are per-configuration (methodology section 7.4): the
            % three example crafts model staging as separate files, so the
            % sweep must order their drag by assembly size, and every
            % configuration must hash distinctly. Stub cubes keep this
            % KSP-free; every part contributes non-negative drag, hence
            % the pointwise ordering.
            root = ksptotTestRoot();
            dragDir = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData');
            crafts = {fullfile(dragDir, 'Kerbal 1-5_3.craft'), ...
                fullfile(dragDir, 'Kerbal 1-5_3_NoBoosters.craft'), ...
                fullfile(dragDir, 'Kerbal 1-5_3_NoBoosters_NoFirstStage.craft')};
            testCase.assumeTrue(all(cellfun(@isfile, crafts)), 'Example crafts missing.');

            phys = kwt_physicsGlobals();
            grid = struct('machVec', [0 1], 'aoaDegVec', [-15 0 15], ...
                'sideslipDegVec', [0 5], 'quiet', true);
            drags = cell(1, 3);
            hashes = cell(1, 3);
            for(v = 1:3)
                craft = sfsParse(crafts{v});
                cubeDB = testCase.stubCubeDbForNames(testCase.craftPartNames(craft));
                spec = kwt_buildAeroSpec(crafts{v}, cubeDB, phys);
                [tables, ~] = kwt_sweepCraft(spec, phys, grid);
                drags{v} = tables.dragCubeCdA + tables.otherDragCdA;
                hashes{v} = tables.configHash;
                testCase.verifyGreaterThan(min(drags{v}(:)), 0, ...
                    'Every configuration must drag somewhere.');
            end
            testCase.verifyTrue(numel(unique(hashes)) == 3, ...
                'Each staging configuration must hash distinctly (regen per stage).');
            testCase.verifyTrue(all(drags{1}(:) >= drags{2}(:)) && ...
                all(drags{2}(:) >= drags{3}(:)), ...
                'Drag must order full >= NoBoosters >= NoFirstStage pointwise.');
            testCase.verifyGreaterThan(max(drags{1}(:) - drags{2}(:)), 0, ...
                'Dropping the boosters must strictly reduce drag somewhere.');
            testCase.verifyGreaterThan(max(drags{2}(:) - drags{3}(:)), 0, ...
                'Dropping the first stage must strictly reduce drag somewhere.');
        end

        function aeroVesselAssemblyIsAdditive(testCase)
            % The vessel loop has no cross-part terms in v1 (occlusion
            % maps are per-part inputs), so splitting a spec must split
            % the outputs exactly. Fails if anyone smuggles
            % configuration-level coupling into kwt_aero.
            phys = kwt_physicsGlobals();
            full = testCase.stackSpec(4);
            partA = full; partA.parts = full.parts(1:2);
            partB = full; partB.parts = full.parts(3:4);
            vHat = [kwt_inflowFromAeroAngles(deg2rad(12), deg2rad(4)), ...
                kwt_inflowFromAeroAngles(deg2rad(-7), deg2rad(9))];

            oF = kwt_aero(full, phys, vHat, 0.7, 2.0, 500, 0);
            oA = kwt_aero(partA, phys, vHat, 0.7, 2.0, 500, 0);
            oB = kwt_aero(partB, phys, vHat, 0.7, 2.0, 500, 0);

            testCase.verifyEqual(oF.ClS, oA.ClS + oB.ClS, 'AbsTol', 0);
            testCase.verifyEqual(oF.dragCubeCdA, oA.dragCubeCdA + oB.dragCubeCdA, 'AbsTol', 0);
            testCase.verifyEqual(oF.otherDragCdA, oA.otherDragCdA + oB.otherDragCdA, 'AbsTol', 0);
            testCase.verifyEqual(oF.liftForce_kN, oA.liftForce_kN + oB.liftForce_kN, 'AbsTol', 0);
            testCase.verifyEqual(oF.dragForce_kN, oA.dragForce_kN + oB.dragForce_kN, 'AbsTol', 0);
        end
    end

    methods(Access=private)
        function cube = boxCube(~, areas, cd0)
            f = [areas(1) cd0 0.5; areas(1) cd0 0.5; ...
                 areas(2) cd0 0.5; areas(2) cd0 0.5; ...
                 areas(3) cd0 0.5; areas(3) cd0 0.5];
            cube = struct('cubeName', 'Default', 'faces', f, ...
                'center', [0 0 0], 'size', [1 1 1]);
        end

        function spec = stackSpec(testCase, n)
            %stackSpec N identical tank-like body parts (identity rotation).
            % Non-uniform cubes (small caps, big sides) so body lift is
            % real; a uniform cube would (correctly) give zero lift and
            % the antisymmetry assertions below would only test fp noise.
            parts = struct.empty(0, 0);
            for(i = 1:n)
                p = struct();
                p.instanceID = sprintf('tank_%d', i);
                p.baseName = 'tank';
                p.posCraft = [0 0 0];
                p.R_part2vessel = eye(3);
                p.cube = testCase.boxCube([0.3 2 2], 0.6);
                p.cubeName = 'Default';
                p.hasLiftModule = false;
                p.liftVector_local = [0; 0; 0];
                p.deflectionLiftCoeff = 0;
                p.omnidirectional = false;
                p.perpendicularOnly = true;
                p.isControl = false;
                p.rotationAxis_local = [1; 0; 0];
                p.ctrlRangeDeg = 0;
                p.authorityLimiter = 1;
                p.deployAngleDeg = 0;
                p.bodyLiftMultiplier = 1;
                p.isShielded = false;
                p.occlusion = ones(6, 1);
                p.liftCurveSet = 'Default';
                p.useInternalDragModel = true;
                if(isempty(parts))
                    parts = p;
                else
                    parts(end+1) = p; %#ok<AGROW>
                end
            end
            spec = struct('name', 'Stack', 'parts', parts, ...
                'warnings', {{}}, 'configHash', 'test-stack');
        end

        function spec = wingSpec(testCase, liftVec, area, isControl, perpOnly)
            %wingSpec Single lifting surface with explicit geometry.
            p = struct();
            p.instanceID = 'wing_1';
            p.baseName = 'wing';
            p.posCraft = [0 0 0];
            p.R_part2vessel = eye(3);
            p.cube = testCase.boxCube([0 0 0], 0.5);
            p.cubeName = 'Zero';
            p.hasLiftModule = true;
            p.liftVector_local = liftVec(:) / norm(liftVec);
            p.deflectionLiftCoeff = area;
            p.omnidirectional = false;
            p.perpendicularOnly = perpOnly;
            p.isControl = isControl;
            p.rotationAxis_local = [1; 0; 0];
            p.ctrlRangeDeg = 0;
            p.authorityLimiter = 1;
            p.deployAngleDeg = 0;
            p.bodyLiftMultiplier = 1;
            p.isShielded = false;
            p.occlusion = ones(6, 1);
            p.liftCurveSet = 'Default';
            p.useInternalDragModel = true;
            spec = struct('name', 'Wing', 'parts', p, ...
                'warnings', {{}}, 'configHash', 'test-wing');
        end

        function path = writeLines(~, name, lines)
            path = [tempname() '_' name];
            writeLinesAtFile(path, lines);
        end

        function path = writePartDb(testCase, defs)
            lines = {};
            for(i = 1:numel(defs))
                d = defs{i};
                lines{end+1} = 'PART'; %#ok<AGROW>
                lines{end+1} = '{'; %#ok<AGROW>
                lines{end+1} = sprintf('url = %s', d.url); %#ok<AGROW>
                if(~isempty(d.cubes))
                    lines{end+1} = 'DRAG_CUBE'; %#ok<AGROW>
                    lines{end+1} = '{'; %#ok<AGROW>
                    for(c = 1:numel(d.cubes))
                        cb = d.cubes{c};
                        nums = sprintf('%g,', reshape(cb.faces', 1, []));
                        lines{end+1} = sprintf('cube = %s, %s0,0,0,1,1,1', ...
                            cb.cubeName, nums); %#ok<AGROW>
                    end
                    lines{end+1} = '}'; %#ok<AGROW>
                end
                lines{end+1} = '}'; %#ok<AGROW>
            end
            path = testCase.writeLines('testPartDb.cfg', lines);
        end

        function cube = namedCube(~, name, areas)
            %namedCube One 6-face cube struct for writePartDb fixtures.
            f = [areas(1) 0.5 0.4; areas(1) 0.5 0.4; ...
                 areas(2) 0.5 0.4; areas(2) 0.5 0.4; ...
                 areas(3) 0.5 0.4; areas(3) 0.5 0.4];
            cube = struct('cubeName', name, 'faces', f, ...
                'center', [0 0 0], 'size', [1 1 1]);
        end

        function d = tempDir(~)
            d = tempname();
            mkdir(d);
        end

        function partDB = mergedGatedPartDb(~, kspRoot)
            %mergedGatedPartDb Bundled stock DB (roles) with live fin + pod
            %records overlaid. The bundled DB carries lift harvests since
            %2026-09-26, but the gated oracles were calibrated against
            %the live GameData records, so the overlay stays to pin that
            %exact provenance (and survives a future DB regression).
            partDB = lvd_import_getPartDatabase();
            finDB = lvd_import_getPartDatabase(fullfile(kspRoot, 'GameData', ...
                'Squad', 'Parts', 'Aero', 'basicFin', 'basicFin.cfg'));
            if(isKey(finDB.parts, 'basicfin') && isKey(partDB.parts, 'basicfin'))
                partDB.parts('basicfin') = finDB.parts('basicfin');
            end
            podDB = lvd_import_getPartDatabase(fullfile(kspRoot, 'GameData', ...
                'Squad', 'Parts', 'Command', 'mk1pod_v2', 'mk1Pod_v2.cfg'));
            if(isKey(podDB.parts, 'mk1pod_v2') && isKey(partDB.parts, 'mk1pod_v2'))
                merged = partDB.parts('mk1pod_v2');
                merged.liftingSurface = podDB.parts('mk1pod_v2').liftingSurface;
                partDB.parts('mk1pod_v2') = merged;
            end
        end

        function files = findKwtExports(~)
            %findKwtExports KWT AoA-curve CSVs from DragData/KWT/ or
            %KSPTOT_KWT_EXPORT (matched '*kwt*.csv', case-insensitive;
            %condition-suffixed names like '<stem>_KWT_A100.csv' also
            %match -- each file is compared as an independent slice).
            files = {};
            root = ksptotTestRoot();
            cands = {fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', 'KWT')};
            envDir = getenv('KSPTOT_KWT_EXPORT');
            if(~isempty(envDir))
                cands{end+1} = envDir;
            end
            for(c = 1:numel(cands))
                if(~isfolder(cands{c}))
                    continue;
                end
                listing = dir(cands{c});
                for(k = 1:numel(listing))
                    if(~listing(k).isdir && ~isempty(regexpi(listing(k).name, 'kwt.*\.csv$', 'once')))
                        files{end+1} = fullfile(cands{c}, listing(k).name); %#ok<AGROW>
                    end
                end
            end
        end

        function files = findKwtVesselExports(~)
            %findKwtVesselExports KWT Vessel XLSX workbooks
            %('<stem>_KWT_Vessel.xlsx') from DragData/KWT/ or
            %KSPTOT_KWT_EXPORT.
            files = {};
            root = ksptotTestRoot();
            cands = {fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', 'KWT')};
            envDir = getenv('KSPTOT_KWT_EXPORT');
            if(~isempty(envDir))
                cands{end+1} = envDir;
            end
            for(c = 1:numel(cands))
                if(~isfolder(cands{c}))
                    continue;
                end
                listing = dir(fullfile(cands{c}, '*_KWT_Vessel.xlsx'));
                for(k = 1:numel(listing))
                    files{end+1} = fullfile(cands{c}, listing(k).name); %#ok<AGROW>
                end
            end
        end

        function sub = zeroLiftExcept(~, spec, keepNames)
            %zeroLiftExcept Spec copy with deflectionLiftCoeff zeroed for
            %every lifted part whose baseName is not in keepNames
            %(isolates one lift group for component comparison; matches
            %case-insensitively because craft files preserve part-name
            %case, e.g. 'basicFin', while part databases key lowercase).
            sub = spec;
            for(p = 1:numel(sub.parts))
                if(sub.parts(p).hasLiftModule && ~any(strcmpi(sub.parts(p).baseName, keepNames)))
                    sub.parts(p).deflectionLiftCoeff = 0;
                end
            end
        end

        function [cc, ratio, n] = vesselLiftAgreement(~, groupSpec, bodySpec, phys, aoaDeg, kwt, mach)
            %vesselLiftAgreement Craft-frame flight-direction projection:
            %replay vs KWT group force at each AoA (at Mach MACH). The group
            %contribution is measured DIFFERENTIALLY (group spec minus the
            %all-lift-zeroed body spec at the same attitude) because the
            %body baseline dominates any single surface group. An empty
            %bodySpec disables subtraction (whole-vessel body comparison).
            %Returns the
            %shape correlation and the median signed ratio (rows below 5%
            %of the KWT peak excluded: zero crossings carry no scale).
            Mfrm = groupSpec.frameM;
            aoaDeg = aoaDeg(:);
            kwt = kwt(:);
            mine = zeros(size(aoaDeg));
            for(k = 1:numel(aoaDeg))
                a = aoaDeg(k);
                ar = deg2rad(a);
                yf = [0; cos(ar); sin(ar)];
                v = Mfrm * [0; -sind(a); cosd(a)];
                outG = kwt_aero(groupSpec, phys, v, mach, 1);
                if(isempty(bodySpec))
                    dF = outG.liftForce_kN;
                else
                    outB = kwt_aero(bodySpec, phys, v, mach, 1);
                    dF = outG.liftForce_kN - outB.liftForce_kN;
                end
                mine(k) = dot(Mfrm * dF, yf);
            end
            ok = isfinite(mine) & isfinite(kwt);
            n = sum(ok);
            if(n < 5)
                cc = NaN;
                ratio = NaN;
                return;
            end
            C = corrcoef(mine(ok), kwt(ok));
            cc = C(1, 2);
            use = ok & abs(kwt) > 0.05 * max(abs(kwt(ok)));
            if(~any(use))
                ratio = NaN;
            else
                ratio = median(mine(use) ./ kwt(use));
            end
        end

        function [cc, ratio, sheet] = bestSurfMatch(testCase, groupSpec, bodySpec, phys, file, sheets, mach)
            %bestSurfMatch Compares a single-group spec against every
            %candidate surface sheet (group indices are characterization
            %order, not stable across exports) and returns the best shape
            %match with its sheet name.
            cc = -inf;
            ratio = NaN;
            sheet = '';
            allSheets = sheetnames(file);
            for(s = 1:numel(sheets))
                mSheet = [sheets{s}(1:end-5) '_MFactor'];
                if(~any(strcmp(allSheets, mSheet)))
                    continue;
                end
                C = readmatrix(file, 'Sheet', sheets{s});
                MF = readmatrix(file, 'Sheet', mSheet);
                C = C(all(isfinite(C), 2), :);
                MF = MF(all(isfinite(MF), 2), :);
                if(size(C, 1) < 5 || size(MF, 1) < 1 || size(C, 2) < 2 || size(MF, 2) < 4)
                    continue;
                end
                mV = ksp_evalFloatCurve(MF(:, 1:4), mach);
                [ccS, rS] = testCase.vesselLiftAgreement(groupSpec, bodySpec, phys, C(:, 1), C(:, 2) * mV, mach);
                if(isfinite(ccS) && ccS > cc)
                    cc = ccS;
                    ratio = rS;
                    sheet = sheets{s};
                end
            end
        end

        function wingDragAgreement(testCase, finSpec, phys, file, stem)
            %wingDragAgreement Fin-only otherDrag vs the export's
            %surfDrag (x dragMach) + induDrag (x liftMach) at Mach 0.5.
            SD = readmatrix(file, 'Sheet', 'surfDrag_Coef');
            SDM = readmatrix(file, 'Sheet', 'surfDrag_MFactor');
            ID = readmatrix(file, 'Sheet', 'induDrag_Coef');
            IDM = readmatrix(file, 'Sheet', 'induDrag_MFactor');
            SD = SD(all(isfinite(SD), 2), :);
            ID = ID(all(isfinite(ID), 2), :);
            SDM = SDM(all(isfinite(SDM), 2), :);
            IDM = IDM(all(isfinite(IDM), 2), :);
            mSD = ksp_evalFloatCurve(SDM(:, 1:4), 0.5);
            mID = ksp_evalFloatCurve(IDM(:, 1:4), 0.5);
            [common, ia, ib] = intersect(round(SD(:, 1), 6), round(ID(:, 1), 6));
            testCase.assumeTrue(numel(common) >= 5, sprintf('%s: too few wing-drag rows.', stem));
            Mfrm = finSpec.frameM;
            mine = zeros(numel(common), 1);
            kwt = zeros(numel(common), 1);
            for(k = 1:numel(common))
                a = common(k);
                out = kwt_aero(finSpec, phys, Mfrm * [0; -sind(a); cosd(a)], 0.5, 1);
                mine(k) = out.otherDragCdA;
                kwt(k) = SD(ia(k), 2) * mSD + ID(ib(k), 2) * mID;
            end
            ok = isfinite(mine) & isfinite(kwt) & mine > 0 & kwt > 0;
            testCase.assumeTrue(sum(ok) >= 5, sprintf('%s: too few positive wing-drag rows.', stem));
            C = corrcoef(mine(ok), kwt(ok));
            r = median(mine(ok) ./ kwt(ok));
            fprintf('KWT Vessel %s wingDrag: corr=%g ratio=%g n=%d\n', stem, C(1, 2), r, sum(ok));
            testCase.verifyGreaterThan(C(1, 2), 0.99, sprintf('%s wing-drag shape mismatch.', stem));
            testCase.verifyGreaterThan(r, 0.9, sprintf('%s wing-drag ratio low.', stem));
            testCase.verifyLessThan(r, 1.1, sprintf('%s wing-drag ratio high.', stem));
        end

        function bodyDragAgreement(testCase, spec, phys, file, stem)
            %bodyDragAgreement Cube-drag CdA vs the export's body-drag
            %grid (AoA rows in radians, Mach header columns), looped over
            %Mach [0.5, 2, 5]. Log-shape plus median ratio (measured
            %2026-09-26 at 0.5: NoBoosters logCorr 0.99986 at ratio 1.13, NoFS
            %logCorr 0.99854 at 0.88; residual is the known raycast-vs-
            %node-area occlusion approximation, same family as the kOS
            %oracle band).
            D = readmatrix(file, 'Sheet', 'bodyDrag_values');
            D = D(all(isfinite(D), 2), :);
            H = readcell(file, 'Sheet', 'bodyDrag_values', 'Range', 'A1:Z1');
            machs = [H{cellfun(@isnumeric, H)}];
            testCase.assumeTrue(numel(machs) == size(D, 2) - 1 && numel(machs) >= 2, ...
                sprintf('%s: body-drag Mach header mismatch.', stem));
            testCase.assumeTrue(issorted(machs), sprintf('%s: body-drag Machs unsorted.', stem));
            % Full-craft and NoFS supersonic gates are wider (shape 0.97,
            % ratio [0.7, 1.6]): above Mach 1.5 the full craft's SRB drag
            % runs ~30% hot with slight shape loss (M2/M5: 1.29/1.31 at
            % logCorr 0.993/0.991, vs 1.17/0.9998 at M0.5), and NoFS loses
            % drag shape (M2/M5 logCorr 0.981/0.977 at ratio 0.92/0.93).
            % Investigation 2026-09-26: forcing the two SRBs to their
            % Clean cube fixes the full craft at all Machs (0.98-1.15,
            % logCorr > 0.999), i.e. KSP's live VAB cube weights pick
            % Clean for bottom-exposed SRBs while the builder always takes
            % cubes(1) = Fairing. But a blanket bottom-node rule is
            % REFUTED by the LV-909 Terrier (bottom-exposed, yet KWT needs
            % Fairing: NoFS Clean-swap gives 0.78 vs 0.88 at M0.5), and a
            % 5-cube Terrier matrix (Fairing/Clean/0/1/2 x M0.5/M2/M5)
            % shows NO single cube fits all Machs (best: Fairing
            % everywhere, still 0.977 at M5) -- so KSP's weight-state rule
            % is per-part, not topological, and implementing it from 3
            % crafts would be fitting, not modeling. The wide gates guard
            % regressions (2x blowup still fails) until live weight-state
            % selection lands; M0.5 (all craft) and NoBoosters (all Machs)
            % hold the strict gates.
            for mach = [0.5 2 5]
                if(mach == 0.5 || strcmp(stem, 'Kerbal 1-5_3_NoBoosters'))
                    corrGate = 0.998;
                    lo = 0.7;
                    hi = 1.3;
                else
                    corrGate = 0.97;
                    lo = 0.7;
                    hi = 1.6;
                end
                kwt = interp1(machs, D(:, 2:end)', mach)';
                Mfrm = spec.frameM;
                mine = zeros(size(D, 1), 1);
                for(k = 1:size(D, 1))
                    v = Mfrm * [0; -sin(D(k, 1)); cos(D(k, 1))];
                    mine(k) = kwt_aero(spec, phys, v, mach, 1).dragCubeCdA;
                end
                ok = isfinite(mine) & isfinite(kwt) & mine > 0 & kwt > 0;
                testCase.assumeTrue(sum(ok) >= 5, sprintf('%s M=%g: too few body-drag rows.', stem, mach));
                C = corrcoef(log10(mine(ok)), log10(kwt(ok)));
                r = median(mine(ok) ./ kwt(ok));
                fprintf('KWT Vessel %s bodyDrag M=%g: logCorr=%g ratio=%g n=%d\n', stem, mach, C(1, 2), r, sum(ok));
                testCase.verifyGreaterThan(C(1, 2), corrGate, sprintf('%s body-drag M=%g shape mismatch.', stem, mach));
                testCase.verifyGreaterThan(r, lo, sprintf('%s body-drag M=%g ratio low.', stem, mach));
                testCase.verifyLessThan(r, hi, sprintf('%s body-drag M=%g ratio high.', stem, mach));
            end
        end

        function [stem, tbl] = loadKwtTable(~, path)
            %loadKwtTable Flexible KWT AoA-curve reader. Returns the craft
            %stem (filename before '_KWT') and a struct with .aoaDeg,
            %.lift, .drag columns plus .mach (NaN when the export carries
            %no Mach column, as the AoA Curves export does not -- it is a
            %single-condition slice). Returns ([], []) for unrecognized
            %layouts (caller skips those).
            %
            % Observed KWT AoA export header (note the degree-sign
            % mojibake; values are forces at the window's reference
            % condition, showing trim-saturated pitch inputs):
            %   Angle of Attack [A?],Lift [-],Drag [-],Pitch Input ...
            stem = '';
            tbl = [];
            [~, name] = fileparts(path);
            tok = regexpi(name, '^(.*)_kwt', 'tokens', 'once');
            if(isempty(tok))
                return;
            end
            stem = tok{1};
            fid = fopen(path, 'r');
            if(fid < 0)
                return;
            end
            header = fgetl(fid);
            fclose(fid);
            if(~ischar(header) || isempty(regexp(header, '[A-Za-z]', 'once')))
                return;   % headerless numeric dump: no safe column map
            end
            % Split on field separators ONLY (never spaces: multi-word
            % headers like 'Angle of Attack' must stay one token so header
            % indices align with data columns).
            cols = strsplit(lower(header), {',', ';', char(9)});
            cols = cols(~cellfun(@isempty, cols));
            hasTok = @(tok) contains(cols, tok);
            iMach = find(hasTok('mach'), 1);
            iAoa = find(hasTok('aoa') | hasTok('attack'), 1);
            liftHits = find(hasTok('lift') & ~hasTok('drag'));
            if(isempty(liftHits))
                liftHits = find(hasTok('lift'), 1);
            end
            iLift = [];
            if(~isempty(liftHits))
                iLift = liftHits(1);
            end
            iDrag = find(hasTok('drag'), 1);
            if(isempty(iAoa) || (isempty(iLift) && isempty(iDrag)))
                return;   % mach column optional (AoA export is one slice)
            end
            data = readmatrix(path);
            need = [iAoa, iLift, iDrag];
            if(isempty(need) || size(data, 2) < max(need))
                return;
            end
            tbl = struct('mach', NaN, 'aoaDeg', data(:, iAoa), ...
                'lift', [], 'drag', []);
            if(~isempty(iMach) && iMach <= size(data, 2))
                tbl.mach = data(:, iMach);
            end
            if(~isempty(iLift))
                tbl.lift = data(:, iLift);
            end
            if(~isempty(iDrag))
                tbl.drag = data(:, iDrag);
            end
        end

        function craftPath = craftForKwtStem(~, stem)
            %craftForKwtStem Matches '<stem>_KWT' back to '<stem>.craft' in
            %the DragData folder (stems equal the kOS variant stems).
            root = ksptotTestRoot();
            craftPath = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData', [stem '.craft']);
        end

        function [minCos, ratioCV, axialCorr] = kwtVectorAgreement(~, spec, phys, tbl)
            %kwtVectorAgreement Vessel-frame force-vector agreement with a
            %KWT AoA-curve export. KWT AoA=0 is broadside for +Y-nosed
            %rockets (pitch about X from nose-forward +Z), so each export
            %row is replayed at its own physical inflow (vessel frame =
            %craft frame for root-identity craft, mapped by spec.frameM),
            %at Mach 0.5. KWT flight-frame (lift, drag) becomes a vessel
            %vector by the inverse AoA rotation; ours comes straight from
            %kwt_aero (lift + drag vectors, Q = 1) into the craft frame.
            %This kills the projection-convention confounding that made
            %scalar lift-curve comparison meaningless near broadside
            %(both sides' "lift" there is mostly rotated drag).
            %   minCos    - worst cosine similarity over rows (direction)
            %   ratioCV   - std/mean of |KWT|/|ours| (single-reference-Q
            %               consistency of magnitude)
            %   axialCorr - stack-axis component correlation (REPORT ONLY:
            %               KWT's axial response is W-shaped/non-monotonic
            %               vs our monotonic tilt response -- open whether
            %               that is characterized-cache ringing or physics;
            %               a direct-mode (non-characterized) KWT export
            %               would settle it).
            minCos = 0; ratioCV = NaN; axialCorr = NaN;
            ok = isfinite(tbl.aoaDeg);
            aoaK = tbl.aoaDeg(ok);
            if(numel(unique(aoaK)) < 4 || isempty(tbl.lift) || isempty(tbl.drag))
                return;
            end
            liftK = tbl.lift(ok);
            dragK = tbl.drag(ok);
            if(std(liftK) <= 0 || std(dragK) <= 0)
                return;
            end
            M = spec.frameM;
            n = numel(aoaK);
            cosSim = zeros(n, 1);
            ratios = zeros(n, 1);
            axK = zeros(n, 1);
            axM = zeros(n, 1);
            for(k = 1:n)
                ar = deg2rad(aoaK(k));
                Ffl = [0; liftK(k); -dragK(k)];
                FvK = [Ffl(1); Ffl(2)*cos(ar) - Ffl(3)*sin(ar); ...
                    Ffl(2)*sin(ar) + Ffl(3)*cos(ar)];
                out = kwt_aero(spec, phys, M * [0; -sind(aoaK(k)); cosd(aoaK(k))], 0.5, 1);
                FvM = M * (out.liftForce_kN + out.dragForce_kN);
                cosSim(k) = dot(FvK, FvM) / max(norm(FvK) * norm(FvM), eps);
                ratios(k) = norm(FvK) / max(norm(FvM), eps);
                axK(k) = FvK(2);
                axM(k) = FvM(2);
            end
            minCos = min(cosSim);
            ratioCV = std(ratios) / max(mean(ratios), eps);
            if(std(axK) > 0 && std(axM) > 0)
                C = corrcoef(axK, axM);
                axialCorr = C(1, 2);
            end
        end

        function gameData = buildAeroGameData(testCase)
            %buildAeroGameData Throwaway GameData tree with lifting-surface
            %modules (wing, control canard, plain tank). Auto-removed at
            %test teardown via TemporaryFolderFixture.
            import matlab.unittest.fixtures.TemporaryFolderFixture;
            tmp = testCase.applyFixture(TemporaryFolderFixture);

            gameData = fullfile(tmp.Folder, 'GameData');
            partsDir = fullfile(gameData, 'TestMod', 'Parts');
            mkdir(partsDir);

            writeLinesAtFile(fullfile(partsDir, 'wing.cfg'), { ...
                'PART', '{', ...
                '    name = testWing', ...
                '    title = Test Wing', ...
                '    mass = 0.05', ...
                '    MODULE', '    {', ...
                '        name = ModuleLiftingSurface', ...
                '        deflectionLiftCoeff = 1.5', ...
                '    }', '}'});
            writeLinesAtFile(fullfile(partsDir, 'canard.cfg'), { ...
                'PART', '{', ...
                '    name = testCanard', ...
                '    title = Test Canard', ...
                '    mass = 0.03', ...
                '    MODULE', '    {', ...
                '        name = ModuleControlSurface', ...
                '        deflectionLiftCoeff = 0.4', ...
                '        ctrlSurfaceRange = 10', ...
                '    }', '}'});
            writeLinesAtFile(fullfile(partsDir, 'tank.cfg'), { ...
                'PART', '{', ...
                '    name = testTank', ...
                '    title = Test Tank', ...
                '    mass = 0.5', ...
                '    RESOURCE', '    {', ...
                '        name = LiquidFuel', ...
                '        amount = 180', ...
                '        maxAmount = 180', ...
                '    }', '}'});
        end

        function paths = oracleVariantPaths(~)
            %oracleVariantPaths Committed kOS oracle CSVs, one per staging
            %configuration (see kos_scripts/createDragData.ks for the
            %generation grid: AoA/sideslip -30:5:30 deg, Mach 0:0.1:10).
            root = ksptotTestRoot();
            dragDir = fullfile(root, 'examples', 'LaunchVehicleDesigner', ...
                'kOSOpenLoopControlKerbinLaunch', 'DragData');
            paths = {fullfile(dragDir, 'Kerbal 1-5_3_DragData.csv'), ...
                fullfile(dragDir, 'Kerbal 1-5_3_NoBoosters_DragData.csv'), ...
                fullfile(dragDir, 'Kerbal 1-5_3_NoBoosters_NoFirstStage_DragData.csv')};
        end

        function names = craftPartNames(~, craft)
            %craftPartNames Base part names (flight IDs stripped) in a parsed craft.
            names = {};
            for(i = 1:numel(craft.PART))
                id = craft.PART{i}.part;
                toks = strsplit(id, '_');
                if(numel(toks) >= 2 && ~isempty(regexp(toks{end}, '^\d+$', 'once')))
                    base = strjoin(toks(1:end-1), '_');
                else
                    base = id;
                end
                names{end+1} = base; %#ok<AGROW>
            end
            names = unique(names);
        end

        function cubeDB = stubCubeDbForNames(~, names)
            %stubCubeDbForNames Tank-like stub cubes (small Y caps, big
            % sides) keyed by part name. Exercises the full builder/sweep
            % chain on real craft geometry without a KSP install; the
            % cubes are symmetric per name, so vessel mirror symmetry is
            % exact and symmetry assertions stay meaningful.
            map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            faces = [1.2 0.55 0.4; 1.2 0.55 0.4; ...
                     0.3 0.55 0.4; 0.3 0.55 0.4; ...
                     1.2 0.55 0.4; 1.2 0.55 0.4];
            for(k = 1:numel(names))
                entry = struct('url', names{k}, 'name', names{k}, ...
                    'cubes', struct('cubeName', 'Default', 'faces', faces, ...
                    'center', [0 0 0], 'size', [1 1 1]));
                map(lower(names{k})) = entry;
                map(lower(strrep(names{k}, '.', '_'))) = entry;
                map(lower(strrep(names{k}, '_', '.'))) = entry;
            end
            cubeDB = struct('sourcePath', 'stub', 'cubes', map, ...
                'urls', {names}, 'numParts', double(numel(names)));
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
        end
    end
end

function writeLinesAtFile(path, lines)
%writeLinesAtFile Writes a cellstr to an explicit path (file-local helper;
%class methods cannot be called statically from other methods).

    fid = fopen(path, 'w');
    if(fid < 0)
        error('KwtAeroTest:writeFailed', 'Could not write %s', path);
    end
    closer = onCleanup(@() fclose(fid));

    for(i = 1:numel(lines))
        fprintf(fid, '%s\n', lines{i});
    end
end
