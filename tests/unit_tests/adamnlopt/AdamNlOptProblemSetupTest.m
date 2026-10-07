classdef AdamNlOptProblemSetupTest < AdamNlOptTestCase
%ADAMNLOPTPROBLEMSETUPTEST  Contract tests for the adamnlopt problem front end.
%   Covers everything that happens between the caller's arguments and the
%   interior-point core: validateProblem, the defaultOptions surface,
%   mapOptions, the scaling transform (computeScaling / scaleProblem /
%   unscaleResult), the fixed-variable reduction (reduceProblem /
%   expandResult), the degeneracy family, the util_* helpers, and the
%   reporting path (diagnose, util_logger, util_logAppend).
%
%   These modules share one property that shapes every test here: they are
%   TRANSFORMS, so the strongest available oracle is almost always a round
%   trip or an algebraic identity rather than a reference value.  A scaling
%   that is applied and then inverted must return the input; a reduction
%   followed by an expansion must land on the original variable indices.  Both
%   are exact, both are independent of what the solver does in between, and
%   both catch the failure that matters most in this layer -- a transform that
%   is self-consistent but wrong.
%
%   See also ADAMNLOPTTESTCASE, VALIDATEPROBLEM, MAPOPTIONS, SCALEPROBLEM.

    methods (Test)

        %% ---------------------------------------------------------------
        %  validateProblem: rejections
        %  ---------------------------------------------------------------
        function testANonNumericX0IsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, {'a', 'b'}), 'adamnlopt:x0');
        end

        function testANonFiniteX0IsRejected(testCase)
            %   x0 reaches the user's objective before anything else runs, so
            %   a NaN here propagates into every derivative in the first
            %   iteration and surfaces far from its cause.
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; NaN]), 'adamnlopt:x0');
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; Inf]), 'adamnlopt:x0');
        end

        function testANonHandleObjectiveIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith('notAHandle', ...
                [1; 2]), 'adamnlopt:fun');
        end

        function testAHalfSuppliedLinearPairIsRejected(testCase)
            %   One half of (A,b) given alone is always a caller mistake: the
            %   missing half would otherwise be read as "no constraint" and
            %   the supplied half silently ignored.
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [1 1], []), ...
                'adamnlopt:linear');
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], 1), ...
                'adamnlopt:linear');
        end

        function testALinearMatrixWithTheWrongWidthIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [1 1 1], 1), ...
                'adamnlopt:linear');
        end

        function testALinearPairWithMismatchedHeightsIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [1 1; 2 2], 1), ...
                'adamnlopt:linear');
        end

        function testTheEqualityBlockIsCheckedTheSameWayAsTheInequalityBlock(testCase)
            %   Both pairs go through the same helper; the test exists so a
            %   future divergence between them cannot pass unnoticed.
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [1 1 1], 1), ...
                'adamnlopt:linear');
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [1 1], []), ...
                'adamnlopt:linear');
        end

        function testACrossedBoundIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [], [], ...
                [5; 0], [1; 1]), 'adamnlopt:bounds');
        end

        function testABoundOfTheWrongLengthIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [], [], ...
                [0; 0; 0], []), 'adamnlopt:bounds');
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [], [], ...
                [], [1; 1; 1]), 'adamnlopt:bounds');
        end

        function testANonHandleNonlconIsRejected(testCase)
            testCase.verifyError(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [1; 2], [], [], [], [], ...
                [], [], 'notAHandle'), 'adamnlopt:nonlcon');
        end

        %% ---------------------------------------------------------------
        %  validateProblem: normalization
        %  ---------------------------------------------------------------
        function testAnOutOfBoxX0IsClippedWithAWarning(testCase)
            %   x0 reaches fun and nonlcon here (for the constraint count), in
            %   computeScaling, and in calibrateStep -- all BEFORE
            %   initializeIterate projects it into the box.  An x0 the caller
            %   left outside therefore produced out-of-bounds evaluations on
            %   every one of those paths.  Clipping and warning is the right
            %   trade: silently moving the caller's starting point would be
            %   worse, and erroring on a common recoverable slip worse still.
            p = testCase.verifyWarning(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [5; -5], [], [], [], [], ...
                [0; 0], [1; 1]), 'adamnlopt:x0OutOfBounds');
            testCase.verifyEqual(p.x0, [1; 0], 'AbsTol', 0);
        end

        function testHonorBoundsOffLeavesAnOutOfBoxX0Alone(testCase)
            opts = adamnlopt.defaultOptions();
            opts.HonorBounds = false;
            p = adamnlopt.validateProblem(@AdamNlOptTestCase.sphere, [5; -5], ...
                [], [], [], [], [0; 0], [1; 1], [], opts);
            testCase.verifyEqual(p.x0, [5; -5], 'AbsTol', 0);
        end

        function testAnInBoxX0DoesNotWarn(testCase)
            testCase.verifyWarningFree(@() testCase.validateWith( ...
                @AdamNlOptTestCase.sphere, [0.5; 0.5], [], [], [], [], ...
                [0; 0], [1; 1]));
        end

        function testEmptyBoundsBecomeInfiniteVectors(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2; 3]);
            testCase.verifyEqual(p.lb, -Inf(3, 1));
            testCase.verifyEqual(p.ub, Inf(3, 1));
        end

        function testAScalarBoundIsReplicated(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2; 3], ...
                [], [], [], [], -2, 5);
            testCase.verifyEqual(p.lb, -2 * ones(3, 1));
            testCase.verifyEqual(p.ub, 5 * ones(3, 1));
        end

        function testAFixedVariableIsAcceptedNotRejected(testCase)
            %   lb == ub has no barrier interior, but the treatment is
            %   elimination in reduceProblem, not rejection here.  Validation
            %   must let it through or the reduction never gets the chance.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2], ...
                [], [], [], [], [1; -5], [1; 5]);
            testCase.verifyEqual(p.lb(1), p.ub(1));
        end

        function testAnEmptyLinearBlockBecomesAZeroRowMatrix(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2]);
            testCase.verifySize(p.Aineq, [0 2]);
            testCase.verifySize(p.bineq, [0 1]);
            testCase.verifySize(p.Aeqlin, [0 2]);
            testCase.verifySize(p.beqlin, [0 1]);
        end

        function testX0IsFlattenedToAColumn(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1 2 3]);
            testCase.verifySize(p.x0, [3 1]);
            testCase.verifyEqual(p.n, 3);
        end

        function testNonlconIsProbedExactlyOnceToSizeTheBlocks(testCase)
            %   The probe is a real user call before the solve starts; a second
            %   one would be charged to nobody's counter.
            calls = struct('n', 0);
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [0.3; 0.4], ...
                [], [], [], [], [], [], @countedCon);
            testCase.verifyEqual(calls.n, 1);
            testCase.verifyEqual(p.mInl, 1);
            testCase.verifyEqual(p.mEnl, 1);

            function [c, ceq] = countedCon(z)
                calls.n = calls.n + 1;
                c = z.' * z - 1;
                ceq = z(1) - z(2);
            end
        end

        function testHasConGradIsFalseWithoutANonlcon(testCase)
            %   SpecifyConstraintGradient on a problem with no nonlcon would
            %   otherwise send the Evaluator down the analytic-Jacobian path
            %   with nothing to call.
            opts = adamnlopt.defaultOptions();
            opts.SpecifyConstraintGradient = true;
            p = adamnlopt.validateProblem(@AdamNlOptTestCase.sphere, [1; 2], ...
                [], [], [], [], [], [], [], opts);
            testCase.verifyFalse(p.hasConGrad);
        end

        %% ---------------------------------------------------------------
        %  defaultOptions: the option surface pin
        %  ---------------------------------------------------------------
        function testTheOptionSurfaceIsPinnedFieldByField(testCase)
            %   The cheapest high-value test in the suite.  Every one of these
            %   names is part of the public interface -- they appear in user
            %   scripts and in the LVD options dialog -- and every value is a
            %   calibrated default somebody chose.  Renaming a field, dropping
            %   one, or re-defaulting a value is a breaking change that no
            %   behavioural test would localise, because mapOptions silently
            %   ignores an option it no longer recognises.  isequaln compares
            %   the full field SET, so an addition fails here too and forces a
            %   deliberate update to this list.
            opts = adamnlopt.defaultOptions();
            expected = testCase.expectedDefaults();
            testCase.verifyEqual(numel(fieldnames(opts)), ...
                numel(fieldnames(expected)), ...
                'the number of options changed; update expectedDefaults');
            testCase.verifyEqual(opts, expected);
        end

        function testTheSentinelDefaultsAreEmptyNotZero(testCase)
            %   compTol and muMin are deliberately [] rather than numbers: they
            %   are tied to optTol inside solve, so a literal default here
            %   would silently decouple them the moment a caller changed
            %   optTol and expected the pair to follow.
            opts = adamnlopt.defaultOptions();
            testCase.verifyEmpty(opts.compTol);
            testCase.verifyEmpty(opts.muMin);
            testCase.verifyEmpty(opts.krylovMaxIter);
        end

        %% ---------------------------------------------------------------
        %  mapOptions
        %  ---------------------------------------------------------------
        function testEveryFminconAliasMapsOntoItsNativeField(testCase)
            %   The whole point of the aliases is that an fmincon call site can
            %   be redirected to adamnlopt without rewriting its options.  An
            %   alias that quietly stopped mapping would leave the default in
            %   place and look like a solver regression.
            aliases = { ...
                'MaxIterations',            'maxIter',     11; ...
                'MaxFunctionEvaluations',   'maxFunEvals', 222; ...
                'OptimalityTolerance',      'optTol',      1e-3; ...
                'ConstraintTolerance',      'feasTol',     2e-3; ...
                'StepTolerance',            'stepTol',     3e-3};
            for k = 1:size(aliases, 1)
                in = struct(aliases{k, 1}, aliases{k, 3});
                out = adamnlopt.mapOptions(in);
                testCase.verifyEqual(out.(aliases{k, 2}), aliases{k, 3}, ...
                    sprintf('%s did not reach %s', aliases{k, 1}, aliases{k, 2}));
            end
        end

        function testTheSelfNamedFminconOptionsPassStraightThrough(testCase)
            in = struct('SpecifyObjectiveGradient', true, ...
                        'SpecifyConstraintGradient', true, ...
                        'FiniteDifferenceType', 'central', ...
                        'HonorBounds', false, ...
                        'Display', 'final', ...
                        'HessPattern', eye(2), ...
                        'JacobPattern', ones(1, 2), ...
                        'HessianFcn', @(x, l) eye(2));
            out = adamnlopt.mapOptions(in);
            testCase.verifyTrue(out.SpecifyObjectiveGradient);
            testCase.verifyTrue(out.SpecifyConstraintGradient);
            testCase.verifyEqual(out.FiniteDifferenceType, 'central');
            testCase.verifyFalse(out.HonorBounds);
            testCase.verifyEqual(out.Display, 'final');
            testCase.verifyEqual(out.HessPattern, eye(2));
            testCase.verifyClass(out.HessianFcn, 'function_handle');
        end

        function testNativeNamesOverrideTheirDefaults(testCase)
            out = adamnlopt.mapOptions(struct('mu0', 0.5, 'tau', 0.9, ...
                'linearSolver', 'krylov'));
            testCase.verifyEqual(out.mu0, 0.5);
            testCase.verifyEqual(out.tau, 0.9);
            testCase.verifyEqual(out.linearSolver, 'krylov');
        end

        function testNoArgumentsAndAnEmptyArgumentBothGiveTheDefaults(testCase)
            d = adamnlopt.defaultOptions();
            testCase.verifyEqual(adamnlopt.mapOptions(), d);
            testCase.verifyEqual(adamnlopt.mapOptions([]), d);
        end

        function testAnUnknownOptionWarnsOnceListingEveryName(testCase)
            %   One warning naming all of them, not one per name: a caller who
            %   renamed three options should see all three in a single line
            %   rather than have the first two scroll past.
            in = struct('maxIter', 5, 'notAnOption', 1, 'alsoNotAnOption', 2);
            lastwarn('');
            testCase.verifyWarning(@() adamnlopt.mapOptions(in), ...
                'adamnlopt:unknownOption');
            msg = lastwarn();
            testCase.verifyTrue(contains(msg, 'notAnOption'));
            testCase.verifyTrue(contains(msg, 'alsoNotAnOption'), ...
                'only the first unknown name was reported');
        end

        function testAnUnknownOptionDoesNotDiscardTheValidOnes(testCase)
            in = struct('maxIter', 5, 'notAnOption', 1);
            w = warning('off', 'adamnlopt:unknownOption');
            restore = onCleanup(@() warning(w));
            out = adamnlopt.mapOptions(in);
            testCase.verifyEqual(out.maxIter, 5);
        end

        function testAnEmptyValueIsSkippedRatherThanOverwritingTheDefault(testCase)
            %   An options struct assembled programmatically very often carries
            %   [] placeholders for the settings the caller did not touch.
            out = adamnlopt.mapOptions(struct('maxIter', [], 'optTol', []));
            d = adamnlopt.defaultOptions();
            testCase.verifyEqual(out.maxIter, d.maxIter);
            testCase.verifyEqual(out.optTol, d.optTol);
        end

        function testTheSymbolicFiniteDifferenceStepIsCoercedToANumber(testCase)
            %   fmincon stores this default as the CHAR 'sqrt(eps)'; left as a
            %   char it would turn every downstream step computation into
            %   character arithmetic.
            out = adamnlopt.mapOptions(struct('FiniteDifferenceStepSize', 'sqrt(eps)'));
            testCase.verifyTrue(isnumeric(out.FiniteDifferenceStepSize));
            testCase.verifyEqual(out.FiniteDifferenceStepSize, sqrt(eps));
        end

        function testAnUnparseableFiniteDifferenceStepFallsBackToTheDefault(testCase)
            out = adamnlopt.mapOptions(struct('FiniteDifferenceStepSize', 'nonsense'));
            testCase.verifyEqual(out.FiniteDifferenceStepSize, sqrt(eps));
        end

        function testANumericFiniteDifferenceStepIsLeftExactlyAsGiven(testCase)
            out = adamnlopt.mapOptions(struct('FiniteDifferenceStepSize', 1e-7));
            testCase.verifyEqual(out.FiniteDifferenceStepSize, 1e-7, 'AbsTol', 0);
        end

        function testAMisspelledHessianApproxIsAnError(testCase)
            %   It used to fall through to the finite-difference Hessian, so a
            %   typo silently changed the algorithm while every output still
            %   looked plausible.
            testCase.verifyError(@() adamnlopt.mapOptions( ...
                struct('hessianApprox', 'lbgfs')), 'adamnlopt:hessianApprox');
            testCase.verifyError(@() adamnlopt.mapOptions( ...
                struct('hessianApprox', 7)), 'adamnlopt:hessianApprox');
        end

        function testHessianApproxIsCaseInsensitiveAndNormalized(testCase)
            out = adamnlopt.mapOptions(struct('hessianApprox', 'LBFGS'));
            testCase.verifyEqual(out.hessianApprox, 'lbfgs');
        end

        function testAnUnambiguousAbbreviationIsAccepted(testCase)
            %   validatestring does prefix matching, so 'lbfg' resolves to
            %   'lbfgs' and 'ex' to 'exact'.  Recorded deliberately: the
            %   normalized value is what the rest of the package switches on,
            %   so an abbreviation must not leak through unexpanded.
            testCase.verifyEqual(adamnlopt.mapOptions( ...
                struct('hessianApprox', 'lbfg')).hessianApprox, 'lbfgs');
            testCase.verifyEqual(adamnlopt.mapOptions( ...
                struct('hessianApprox', 'ex')).hessianApprox, 'exact');
        end

        function testAMisspelledReturnIterateIsAnError(testCase)
            %   A typo here changes WHICH point comes back, which is exactly
            %   the kind of change a caller cannot see from the outputs.
            testCase.verifyError(@() adamnlopt.mapOptions( ...
                struct('returnIterate', 'bestKTT')), 'adamnlopt:returnIterate');
            testCase.verifyError(@() adamnlopt.mapOptions( ...
                struct('returnIterate', {{'last'}})), 'adamnlopt:returnIterate');
        end

        function testReturnIterateIsNormalized(testCase)
            out = adamnlopt.mapOptions(struct('returnIterate', 'BestKKT'));
            testCase.verifyEqual(out.returnIterate, 'bestKKT');
        end

        function testAStringScalarIsAcceptedForTheSelectors(testCase)
            out = adamnlopt.mapOptions(struct('hessianApprox', "exact", ...
                'returnIterate', "last"));
            testCase.verifyEqual(out.hessianApprox, 'exact');
            testCase.verifyEqual(out.returnIterate, 'last');
        end

        %% ---------------------------------------------------------------
        %  computeScaling / scaleProblem / unscaleResult
        %  ---------------------------------------------------------------
        function testNoneModeIsTheIdentityAndSaysItIsNotApplied(testCase)
            %   applied == false is what lets solve skip the wrapping entirely
            %   and stay bit-for-bit identical to the unscaled path.
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('none'));
            testCase.verifyFalse(sc.applied);
            testCase.verifyEqual(sc.Dx, ones(p.n, 1));
            testCase.verifyEqual(sc.wf, 1);
            testCase.verifyEqual(sc.Dc, ones(ev.mE, 1));
            testCase.verifyEqual(sc.Di, ones(ev.mI, 1));
        end

        function testBoundsModeScalesVariablesWithoutProbingTheJacobian(testCase)
            [p, ev] = testCase.scalingFixture();
            n0 = ev.nCon;
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('bounds'));
            testCase.verifyTrue(sc.applied);
            testCase.verifyEqual(ev.nCon, n0, ...
                'bounds mode must not spend a Jacobian probe');
            testCase.verifyEqual(sc.Dc, ones(ev.mE, 1));
        end

        function testAFinitelyBoxedVariableIsScaledByItsBoxWidth(testCase)
            %   The box width is the natural unit of a bounded variable, so the
            %   scaled box is unit width and the trust radius means the same
            %   thing in every coordinate.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [5; 0.5], ...
                [], [], [], [], [0; 0], [100; 1]);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('bounds'));
            testCase.verifyEqual(sc.Dx, [100; 1], 'RelTol', 1e-12);
        end

        function testAnUnboundedVariableFallsBackToItsOwnMagnitude(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1000; 0.001]);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('bounds'));
            testCase.verifyEqual(sc.Dx, [1000; 1], 'RelTol', 1e-12, ...
                'the floor at 1 stops a tiny component being blown up');
        end

        function testAnExtremeScaleSpreadIsCompressed(testCase)
            %   The bound range measures box WIDTH, not curvature.  Where they
            %   disagree, x = Dx.*xs maps H to Dx.*H.*Dx', multiplying cond(H)
            %   by up to spread^2 -- so an unbounded spread can turn a
            %   well-conditioned problem into a numerically singular one and
            %   stall the solve at a non-stationary point.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [0; 0], ...
                [], [], [], [], [0; 0], [1e10; 1]);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
            opts = testCase.scaleOpts('bounds');
            sc = adamnlopt.computeScaling(p, ev, opts);
            testCase.verifyLessThanOrEqual(max(sc.Dx) / min(sc.Dx), ...
                opts.autoScaleMaxSpread * (1 + 1e-9));
            testCase.verifyGreaterThan(sc.Dx(1), sc.Dx(2), ...
                'compression must preserve the ordering of the scales');
        end

        function testAModestSpreadIsLeftUntouched(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [0; 0], ...
                [], [], [], [], [0; 0], [10; 1]);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('bounds'));
            testCase.verifyEqual(sc.Dx, [10; 1], 'RelTol', 1e-12);
        end

        function testGradientModeNeverMagnifiesAConstraintRow(testCase)
            %   Row factors are capped at 1 by construction: scaling a row UP
            %   would amplify its own evaluation noise into the KKT system.
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('gradient'));
            testCase.verifyLessThanOrEqual(max([sc.Dc; sc.Di; 1]), 1);
            testCase.verifyGreaterThan(min([sc.Dc; sc.Di; 1]), 0);
            testCase.verifyEqual(sc.wf, 1, ...
                'gradient mode deliberately leaves the objective unscaled');
        end

        function testGradientModeIsInertWhenEveryRowIsAlreadyUnitScale(testCase)
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('gradient'));
            testCase.verifyEqual(sc.mElin, ev.mElin);
            testCase.verifyEqual(sc.mIlin, ev.mIlin);
            testCase.verifySize(sc.Dc, [ev.mE 1]);
            testCase.verifySize(sc.Di, [ev.mI 1]);
        end

        function testScaleProblemReproducesTheDocumentedTransform(testCase)
            %   Checked algebraically against the header's own formulas rather
            %   than against a stored result, so the test states the contract
            %   instead of recording the current behaviour.
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('gradient'));
            pS = adamnlopt.scaleProblem(p, sc);

            x  = [0.3; 0.4];
            xs = x ./ sc.Dx;
            testCase.verifyEqual(pS.x0, p.x0 ./ sc.Dx, 'RelTol', 1e-14);
            testCase.verifyEqual(pS.objFun(xs), sc.wf * p.objFun(x), ...
                'RelTol', 1e-12);

            DcLin = sc.Dc(1:sc.mElin);
            testCase.verifyEqual(pS.Aeqlin * xs - pS.beqlin, ...
                DcLin .* (p.Aeqlin * x - p.beqlin), 'AbsTol', 1e-12);

            DiNl = sc.Di(sc.mIlin+1:end);
            cs = pS.nlcon(xs);
            c  = p.nlcon(x);
            testCase.verifyEqual(cs, DiNl .* c, 'RelTol', 1e-12);
        end

        function testScaleProblemPreservesTheBoundDirections(testCase)
            %   Dx > 0, so an infinite bound stays infinite and no lb crosses
            %   its ub -- a sign slip here would invert the box.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2], ...
                [], [], [], [], [-Inf; 0], [5; Inf]);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('bounds'));
            pS = adamnlopt.scaleProblem(p, sc);
            testCase.verifyEqual(pS.lb(1), -Inf);
            testCase.verifyEqual(pS.ub(2), Inf);
            testCase.verifyTrue(all(pS.lb <= pS.ub));
        end

        function testUnscaleResultInvertsScaleProblemExactly(testCase)
            %   The round trip is the real contract: a transform that is
            %   self-consistent but not inverse to its own forward map returns
            %   a correct answer to the wrong problem.
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.computeScaling(p, ev, testCase.scaleOpts('gradient'));
            x = [0.3; 0.4];
            xs = x ./ sc.Dx;
            xBack = adamnlopt.unscaleResult(xs, [], [], [], [], sc);
            testCase.verifyEqual(xBack, x, 'RelTol', 1e-14);
        end

        function testUnscaleResultInvertsTheDerivativeTransforms(testCase)
            sc = struct('applied', true, 'mode', 'gradient', ...
                'Dx', [2; 5], 'wf', 3, 'Dc', zeros(0, 1), 'Di', zeros(0, 1), ...
                'mElin', 0, 'mIlin', 0);
            g = [6; 15];                    % = wf * (Dx .* [1;1])
            H = 3 * ([2; 5] * [2 5]);       % = wf * (Dx*Dx') .* ones(2)
            [~, fval, grad, hess] = adamnlopt.unscaleResult([1; 1], 9, g, H, [], sc);
            testCase.verifyEqual(fval, 3, 'RelTol', 1e-14);
            testCase.verifyEqual(grad, [1; 1], 'RelTol', 1e-14);
            testCase.verifyEqual(hess, ones(2), 'RelTol', 1e-14);
        end

        function testUnscaleResultPassesEverythingThroughWhenNotApplied(testCase)
            %   The output names shadow the input names, so the early return
            %   leaves every trailing output holding its input -- that IS the
            %   identity behaviour, and a caller requesting five outputs must
            %   not hit an unassigned-output error.
            sc = struct('applied', false);
            lam = struct('lower', 1, 'upper', 2, 'eqlin', 3, 'eqnonlin', 4, ...
                'ineqlin', 5, 'ineqnonlin', 6);
            [x, fval, grad, hess, lambda] = adamnlopt.unscaleResult( ...
                [1; 2], 7, [8; 9], eye(2), lam, sc);
            testCase.verifyEqual(x, [1; 2]);
            testCase.verifyEqual(fval, 7);
            testCase.verifyEqual(grad, [8; 9]);
            testCase.verifyEqual(hess, eye(2));
            testCase.verifyEqual(lambda, lam);
        end

        function testUnscaleResultSplitsTheMultipliersAtTheLinearBoundary(testCase)
            %   Dc and Di hold linear rows first; applying the nonlinear block's
            %   factors to the linear multipliers would be invisible in x and
            %   wrong in every sensitivity the caller reads off lambda.
            sc = struct('applied', true, 'mode', 'gradient', ...
                'Dx', [1; 1], 'wf', 1, 'Dc', [2; 3], 'Di', [5; 7], ...
                'mElin', 1, 'mIlin', 1);
            lam = struct('lower', [0; 0], 'upper', [0; 0], ...
                'eqlin', 1, 'eqnonlin', 1, 'ineqlin', 1, 'ineqnonlin', 1);
            [~, ~, ~, ~, out] = adamnlopt.unscaleResult([0; 0], [], [], [], lam, sc);
            testCase.verifyEqual(out.eqlin, 2);
            testCase.verifyEqual(out.eqnonlin, 3);
            testCase.verifyEqual(out.ineqlin, 5);
            testCase.verifyEqual(out.ineqnonlin, 7);
        end

        function testTheScalingRoundTripRecoversTheUnscaledOptimum(testCase)
            %   End to end: a badly scaled problem solved in the scaled space
            %   must come back to the physical optimum.
            p = testCase.catalogEntry('circleEq');
            a = testCase.solveProblem(p, struct('autoScale', 'none'));
            b = testCase.solveProblem(p, struct('autoScale', 'gradient'));
            testCase.verifyGreaterThan(a.exitflag, 0);
            testCase.verifyGreaterThan(b.exitflag, 0);
            testCase.verifyEqual(b.x, p.xStar, 'AbsTol', 1e-5);
            testCase.verifyEqual(b.fval, a.fval, 'AbsTol', 1e-5);
        end

        %% ---------------------------------------------------------------
        %  reduceProblem / expandResult
        %  ---------------------------------------------------------------
        function testNothingFixedLeavesTheProblemUntouched(testCase)
            %   Ordinary problems must be bit-for-bit unaffected: the identity
            %   case is the one this module runs on almost every solve.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2]);
            [pr, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            testCase.verifyFalse(fx.applied);
            testCase.verifyEqual(pr, p);
            testCase.verifyEqual(fx.nr, 2);
            testCase.verifyEqual(fx.nFixed, 0);
        end

        function testAFixedVariableIsEliminatedFromTheProblem(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [], [], [3; -5], [3; 5]);
            [pr, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            testCase.verifyTrue(fx.applied);
            testCase.verifyEqual(fx.nr, 1);
            testCase.verifyEqual(fx.idxFixed, 1);
            testCase.verifyEqual(fx.xF, 3);
            testCase.verifyEqual(pr.n, 1);
            testCase.verifyEqual(pr.x0, 2);
            testCase.verifyEqual(pr.lb, -5);
        end

        function testTheReducedObjectiveStillSeesTheFullVector(testCase)
            %   The user's function is never told a variable was eliminated;
            %   only the derivative ROWS it returns are sub-selected.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [], [], [3; -5], [3; 5]);
            p.hasObjGrad = true;
            [pr, ~] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            [f, g] = pr.objFun(2);
            testCase.verifyEqual(f, 3 ^ 2 + 2 ^ 2, 'AbsTol', 1e-14);
            testCase.verifySize(g, [1 1]);
            testCase.verifyEqual(g, 2 * 2, 'AbsTol', 1e-14);
        end

        function testTheLinearRightHandSideAbsorbsTheFixedValues(testCase)
            %   x1 + x2 <= 10 with x1 fixed at 3 becomes x2 <= 7.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [1 1], 10, [], [], [3; -5], [3; 5]);
            pr = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            testCase.verifyEqual(pr.Aineq, 1, 'AbsTol', 0);
            testCase.verifyEqual(pr.bineq, 7, 'AbsTol', 1e-12);
        end

        function testAVacuousButSatisfiedLinearRowIsDropped(testCase)
            %   A 0 == 0 row left in place would leave JE rank-deficient, which
            %   the Schur complement is measurably sensitive to.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [1 0], 3, [3; -5], [3; 5]);
            [pr, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            testCase.verifySize(pr.Aeqlin, [0 1]);
            testCase.verifyEqual(fx.nDropEqLin, 1);
            testCase.verifyEqual(fx.keepEqLin, false);
        end

        function testAVacuousAndViolatedEqualityRowIsAnError(testCase)
            %   No choice of the free variables can satisfy it, so grinding to
            %   a local-infeasibility exit would be a worse answer than saying
            %   exactly which row is impossible.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [1 0], 99, [3; -5], [3; 5]);
            testCase.verifyError(@() adamnlopt.reduceProblem(p, ...
                adamnlopt.defaultOptions()), 'adamnlopt:fixedInfeasible');
        end

        function testAVacuousAndViolatedInequalityRowIsAnError(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [1 0], 1, [], [], [3; -5], [3; 5]);
            testCase.verifyError(@() adamnlopt.reduceProblem(p, ...
                adamnlopt.defaultOptions()), 'adamnlopt:fixedInfeasible');
        end

        function testAX0DisagreeingWithItsOwnFixedValueWarns(testCase)
            %   Only reachable with HonorBounds off; the fixed value wins, and
            %   the caller is told their starting point was overruled.
            opts = adamnlopt.defaultOptions();
            opts.HonorBounds = false;
            p = adamnlopt.validateProblem(@AdamNlOptTestCase.sphere, [9; 2], ...
                [], [], [], [], [3; -5], [3; 5], [], opts);
            pr = testCase.verifyWarning(@() adamnlopt.reduceProblem(p, opts), ...
                'adamnlopt:fixedVariableX0');
            testCase.verifyEqual(pr.x0, 2);
        end

        function testTheFixedVariableTestIsExactNotTolerant(testCase)
            %   A narrow box is a normal bounded variable.  A tolerance here
            %   would silently convert the caller's genuine box into a fixed
            %   variable and return a different problem's answer.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [], [], [3; -5], [3 + 1e-14; 5]);
            [~, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            testCase.verifyFalse(fx.applied);
        end

        function testThePatternOptionsAreSubSelectedWithTheVariables(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2; 1], ...
                [], [], [], [], [3; -5; -5], [3; 5; 5]);
            opts = adamnlopt.defaultOptions();
            opts.HessPattern  = magic(3) > 4;
            opts.JacobPattern = [1 0 1; 0 1 1] > 0;
            [~, ~, o2] = adamnlopt.reduceProblem(p, opts);
            testCase.verifySize(o2.HessPattern, [2 2]);
            testCase.verifySize(o2.JacobPattern, [2 2]);
            testCase.verifyEqual(o2.JacobPattern, logical([0 1; 1 1]));
        end

        function testExpandResultPutsTheSolutionBackOnTheOriginalIndices(testCase)
            [p, fx] = testCase.reductionFixture();
            [x, ~, ~, ~, out] = adamnlopt.expandResult(7, [], [], [], ...
                testCase.emptyOutput(), fx, p);
            testCase.verifyEqual(x, [3; 7], 'AbsTol', 0);
            testCase.verifyEqual(out.fixedVars.idxFixed, 1);
            testCase.verifyEqual(out.fixedVars.values, 3);
            testCase.verifyEqual(out.fixedVars.nFixed, 1);
            testCase.verifyEqual(out.fixedVars.nFree, 1);
        end

        function testAnUnavailableFixedGradientRowIsNaNNotZero(testCase)
            %   A zero-width coordinate has no probe, so fdBoundedStep
            %   correctly returns hs = 0 there and an FD estimate would come
            %   back as 0.  A zero in a gradient row reads as "this direction
            %   is already stationary" -- the single most misleading value the
            %   solver could return -- so NaN is used instead and gradKnown
            %   records that it was never computed.
            [p, fx] = testCase.reductionFixture();
            p.hasObjGrad = false;
            [~, grad, ~, ~, out] = adamnlopt.expandResult(7, 14, [], [], ...
                testCase.emptyOutput(), fx, p);
            testCase.verifyEqual(grad(2), 14, 'AbsTol', 0);
            testCase.verifyTrue(isnan(grad(1)));
            testCase.verifyFalse(out.fixedVars.gradKnown);
        end

        function testAnAnalyticGradientFillsTheFixedRowAndIsCharged(testCase)
            %   The help has always said this evaluation's cost is recorded in
            %   output.funcCount; nothing recorded it, so a reduced problem
            %   under-reported the user calls it actually made.
            [p, fx] = testCase.reductionFixture();
            p.hasObjGrad = true;
            out0 = testCase.emptyOutput();
            [~, grad, ~, ~, out] = adamnlopt.expandResult(7, 14, [], [], ...
                out0, fx, p);
            testCase.verifyEqual(grad, [6; 14], 'AbsTol', 1e-12);
            testCase.verifyTrue(out.fixedVars.gradKnown);
            testCase.verifyEqual(out.objCount, out0.objCount + 1, ...
                'the gradient fill evaluation went uncounted');
        end

        function testTheFixedHessianRowsAndColumnsAreNaN(testCase)
            %   Not filled even when an exact Hessian is available: the reduced
            %   solve's model was built from steps that never moved a fixed
            %   coordinate, so grafting exact rows on would return a matrix
            %   that is part model and part truth with no way to tell which.
            [p, fx] = testCase.reductionFixture();
            [~, ~, H] = adamnlopt.expandResult(7, [], 5, [], ...
                testCase.emptyOutput(), fx, p);
            testCase.verifySize(H, [2 2]);
            testCase.verifyEqual(H(2, 2), 5, 'AbsTol', 0);
            testCase.verifyTrue(all(isnan(H([1 2 3]))));
        end

        function testExpandResultIsAPassThroughWhenNothingWasFixed(testCase)
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [1; 2]);
            [~, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
            x = adamnlopt.expandResult([1; 2], [], [], [], ...
                testCase.emptyOutput(), fx, p);
            testCase.verifyEqual(x, [1; 2]);
        end

        function testTheReductionRoundTripSolvesToTheConstrainedOptimum(testCase)
            %   End to end.  Before the elimination existed this returned
            %   x = [NaN NaN] with exitflag 1 -- a converged status on an
            %   all-NaN answer -- because the barrier has no interior at a
            %   zero-width bound.
            [x, fval, exitflag, output] = adamnlopt.solve( ...
                @AdamNlOptTestCase.sphere, [3; 2], [], [], [], [], ...
                [3; -5], [3; 5], [], testCase.quietOpts());
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [3; 0], 'AbsTol', 1e-5);
            testCase.verifyEqual(fval, 9, 'AbsTol', 1e-5);
            testCase.verifyTrue(output.fixedVars.applied);
            testCase.verifyEqual(output.fixedVars.idxFixed, 1);
        end

        %% ---------------------------------------------------------------
        %  degeneracy_*
        %  ---------------------------------------------------------------
        function testDropConstraintsKeepsOneOfADuplicatedPair(testCase)
            keep = adamnlopt.degeneracy_dropConstraints([1 2 3; 2 4 6]);
            testCase.verifyEqual(numel(keep), 1);
            testCase.verifyTrue(ismember(keep, [1 2]));
        end

        function testDropConstraintsKeepsEveryIndependentRow(testCase)
            A = [1 0 0; 0 1 0; 0 0 1];
            testCase.verifyEqual(adamnlopt.degeneracy_dropConstraints(A), ...
                (1:3).');
        end

        function testDropConstraintsHandlesASingleRow(testCase)
            %   R is n-by-1 for a single row, and diag() of a VECTOR builds a
            %   matrix instead of extracting a diagonal -- which used to make
            %   the rank a row vector and throw on the e(1:r) index.
            testCase.verifyEqual(adamnlopt.degeneracy_dropConstraints([1 2 3]), 1);
        end

        function testDropConstraintsReturnsAnEmptyColumnForAnEmptyMatrix(testCase)
            testCase.verifySize(adamnlopt.degeneracy_dropConstraints([]), [0 1]);
        end

        function testDropConstraintsReturnsSortedIndices(testCase)
            %   Callers index JE with these, so an unsorted result would
            %   permute the constraint rows relative to their multipliers.
            keep = adamnlopt.degeneracy_dropConstraints([1 0 0; 0 1 0; 2 0 0; 0 0 1]);
            testCase.verifyEqual(keep, sort(keep));
            testCase.verifyEqual(numel(keep), 3);
        end

        function testADependentEqualityJacobianIsFlagged(testCase)
            state = testCase.degenState([1 1; 2 2], [], [], []);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());
            testCase.verifyEqual(flags.rankE, 1);
            testCase.verifyTrue(flags.linDepE);
            testCase.verifyTrue(flags.degenerate);
        end

        function testAFullRankRegularIterateIsNotFlagged(testCase)
            state = testCase.degenState([1 0], [], [], []);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());
            testCase.verifyFalse(flags.linDepE);
            testCase.verifyFalse(flags.linDepActive);
            testCase.verifyFalse(flags.degenerate);
            testCase.verifyEqual(flags.n, 2);
        end

        function testWithNoActiveInequalityTheActiveRankIsJustTheEqualityRank(testCase)
            %   The active Jacobian IS JE then, so re-factorizing was deriving
            %   a rank that had just been computed -- on an inequality-free
            %   problem, once per iteration for the whole solve.
            state = testCase.degenState([1 0; 0 1], [1 1], 5, 0.2);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());
            testCase.verifyFalse(any(flags.active));
            testCase.verifyEqual(flags.rankActive, flags.rankE);
        end

        function testAnActiveInequalityBreakingLicqIsFlagged(testCase)
            state = testCase.degenState([1 0], [1 0], 0, 0.5);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());
            testCase.verifyTrue(flags.active);
            testCase.verifyTrue(flags.linDepActive);
            testCase.verifyTrue(flags.degenerate);
        end

        function testAWeaklyActiveInequalityIsReportedButDoesNotBreakLicq(testCase)
            %   Strict-complementarity failure is a diagnostic, not a routing
            %   switch: .degenerate is deliberately broader than what the
            %   degenerate-step route actually addresses.
            state = testCase.degenState([1 0], [0 1], 0, 0);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());
            testCase.verifyTrue(flags.weaklyActive);
            testCase.verifyFalse(flags.linDepE);
            testCase.verifyFalse(flags.linDepActive);
            testCase.verifyTrue(flags.degenerate);
        end

        function testElasticModeFindsTheExactStepOnAConsistentSystem(testCase)
            %   Consistent linearized constraints have a zero-penalty solution,
            %   and with a proximal term it is the minimum-norm one -- a
            %   closed-form oracle, no reference solver involved.
            JE = [1 0; 0 1];
            cE = [-0.3; 0.4];
            [dx, info] = adamnlopt.degeneracy_elasticVariables(cE, JE, ...
                zeros(0, 1), zeros(0, 2), 1e4, 1);
            testCase.verifyEqual(dx, [0.3; -0.4], 'AbsTol', 1e-4);
            testCase.verifyLessThan(info.penalty, 1e-4);
            testCase.verifyTrue(info.feasible);
        end

        function testElasticModeStaysBoundedOnConflictingConstraints(testCase)
            %   Two contradictory rows admit no feasible direction at all; the
            %   proximal term is what stops dx running away instead of the
            %   subproblem simply failing.
            JE = [1 0; 1 0];
            cE = [-1; 1];
            [dx, info] = adamnlopt.degeneracy_elasticVariables(cE, JE, ...
                zeros(0, 1), zeros(0, 2), 1e3, 1);
            testCase.verifyTrue(all(isfinite(dx)));
            testCase.verifyLessThan(norm(dx), 1e3);
            testCase.verifyFalse(info.feasible);
            testCase.verifyGreaterThan(info.penalty, 0);
        end

        function testElasticModeRejectsANonPositiveProximalWeight(testCase)
            [dx, info] = adamnlopt.degeneracy_elasticVariables([1; 1], eye(2), ...
                zeros(0, 1), zeros(0, 2), 1e3, 0);
            testCase.verifyEqual(dx, zeros(2, 1), 'AbsTol', 0);
            testCase.verifyEqual(info.penalty, inf);
            testCase.verifyFalse(info.converged);
        end

        function testElasticModeOnlyPenalizesViolatedInequalities(testCase)
            %   A satisfied inequality contributes max(cI + JI*dx, 0) = 0, so a
            %   strictly feasible one must not pull the step at all.
            [dx, info] = adamnlopt.degeneracy_elasticVariables( ...
                zeros(0, 1), zeros(0, 2), -1, [1 0], 1e3, 1);
            testCase.verifyEqual(dx, zeros(2, 1), 'AbsTol', 1e-8);
            testCase.verifyTrue(info.feasible);
        end

        function testRegularizedRecoveryFloorsTheDualRegularization(testCase)
            %   gamma > 0 makes the saddle-point matrix nonsingular with the
            %   right inertia even when JE loses rank, so the step stays
            %   bounded instead of blowing up along the null space of JE'.
            [state, res] = testCase.rankDeficientKkt();
            [d, ~, reg, info] = adamnlopt.degeneracy_regularizedRecovery( ...
                state, res, 2, 2);
            testCase.verifyGreaterThan(info.gammaMin, 0);
            testCase.verifyGreaterThanOrEqual(reg.gamma, info.gammaMin);
            testCase.verifyTrue(all(isfinite(d)));
            testCase.verifyLessThan(norm(d), 1e6, ...
                'the step ran away along the null space of JE''');
        end

        function testTheRegularizationFloorVanishesAsTheResidualDoes(testCase)
            %   Tying the floor to the residual is what preserves the
            %   asymptotic Newton rate: a fixed floor would cap the attainable
            %   accuracy at the floor itself.
            [state, res] = testCase.rankDeficientKkt();
            resSmall = res;
            resSmall.rStat  = res.rStat  * 1e-6;
            resSmall.rFeasE = res.rFeasE * 1e-6;
            [~, ~, ~, big]   = adamnlopt.degeneracy_regularizedRecovery(state, res, 2, 2);
            [~, ~, ~, small] = adamnlopt.degeneracy_regularizedRecovery(state, resSmall, 2, 2);
            testCase.verifyLessThan(small.gammaMin, big.gammaMin);
        end

        function testRestorationStrictlyReducesTheViolation(testCase)
            ev = testCase.restorationEvaluator();
            [x, info] = adamnlopt.degeneracy_restorationPhase(ev, [3; 3], ...
                [], [], adamnlopt.defaultOptions());
            testCase.verifyTrue(info.reduced);
            testCase.verifyLessThan(info.theta, info.theta0);
            testCase.verifyGreaterThan(info.iters, 0);
            testCase.verifyEqual(norm(x), 1, 'AbsTol', 1e-4, ...
                'restoration should land on the unit circle');
        end

        function testRestorationNeverLeavesTheBox(testCase)
            %   The Gauss-Newton trial points are projected before evaluation,
            %   so restoration cannot drive a throttle outside [0,1] or a
            %   time-of-flight negative on its way to feasibility.
            ev = testCase.restorationEvaluator();
            lb = [0.9; 0.9];  ub = [3; 3];
            x = adamnlopt.degeneracy_restorationPhase(ev, [3; 3], lb, ub, ...
                adamnlopt.defaultOptions());
            testCase.verifyGreaterThanOrEqual(x, lb - 1e-12);
            testCase.verifyLessThanOrEqual(x, ub + 1e-12);
        end

        function testRestorationChargesItsEvaluationsAndRespectsTheBudget(testCase)
            %   On a black-box problem this is the most expensive phase there
            %   is -- up to 50 Gauss-Newton iterations, each costing a
            %   constraint call, a Jacobian and up to 20 backtracks.  Nothing
            %   consulted maxFunEvals, so a solve that fell into restoration
            %   could blow through the budget several times over.
            ev = testCase.restorationEvaluator();
            opts = adamnlopt.defaultOptions();
            opts.maxFunEvals = 6;
            [~, info] = adamnlopt.degeneracy_restorationPhase(ev, [5; 5], ...
                [], [], opts);
            testCase.verifyTrue(info.budgetHit);
            testCase.verifyLessThan(info.evals, 4 * opts.maxFunEvals);
        end

        function testRestorationAtAFeasiblePointDoesAlmostNothing(testCase)
            ev = testCase.restorationEvaluator();
            [x, info] = adamnlopt.degeneracy_restorationPhase(ev, [1; 0], ...
                [], [], adamnlopt.defaultOptions());
            testCase.verifyLessThan(info.theta, 1e-8);
            testCase.verifyEqual(x, [1; 0], 'AbsTol', 1e-6);
        end

        %% ---------------------------------------------------------------
        %  util_*
        %  ---------------------------------------------------------------
        function testUtilNormsTakesTheMaxInfinityNormAcrossItsArguments(testCase)
            testCase.verifyEqual(adamnlopt.util_norms([1; -5], [3; 2]), 5);
            testCase.verifyEqual(adamnlopt.util_norms([-7 2; 1 3]), 7);
        end

        function testUtilNormsTreatsEmptiesAsZero(testCase)
            %   Every caller passes residual blocks that are routinely empty
            %   (no equalities, no inequalities); an empty must contribute
            %   nothing rather than making the whole norm empty.
            testCase.verifyEqual(adamnlopt.util_norms(), 0);
            testCase.verifyEqual(adamnlopt.util_norms([], []), 0);
            testCase.verifyEqual(adamnlopt.util_norms([], [2; -3], []), 3);
        end

        function testTheProjectedGradientIsIdenticalOnFreeRows(testCase)
            rd = [1; -2; 3];
            out = adamnlopt.util_projectedGradient(rd, zeros(3, 1), ...
                zeros(3, 1), false(3, 1), false(3, 1));
            testCase.verifyEqual(out, rd, 'AbsTol', 0, ...
                'a problem with no active bound must be bit-for-bit unchanged');
        end

        function testACorrectlyPinnedVariableProjectsToZero(testCase)
            %   At a lower bound, first-order optimality is rdFree >= 0, so a
            %   positive reduced gradient is no violation at all.
            out = adamnlopt.util_projectedGradient(-4, 5, 0, true, false);
            testCase.verifyEqual(out, 0, 'AbsTol', 0);
        end

        function testAWronglyPinnedVariableKeepsItsFullMagnitude(testCase)
            %   This is what masking the row out hid: a variable pinned against
            %   the gradient is a genuine first-order violation, and reporting
            %   zero there produced a converged status at a non-optimal point.
            out = adamnlopt.util_projectedGradient(-6, 5, 0, true, false);
            testCase.verifyEqual(out, -1, 'AbsTol', 1e-14);
        end

        function testAnUpperBoundProjectsWithTheOppositeSign(testCase)
            testCase.verifyEqual(adamnlopt.util_projectedGradient(4, 0, 5, ...
                false, true), 0, 'AbsTol', 0);
            testCase.verifyEqual(adamnlopt.util_projectedGradient(6, 0, 5, ...
                false, true), 1, 'AbsTol', 1e-14);
        end

        function testAVariablePinnedAtBothBoundsIsExactlyZero(testCase)
            %   It cannot move, so any sign is stationary.
            out = adamnlopt.util_projectedGradient(123, 1, 1, true, true);
            testCase.verifyEqual(out, 0, 'AbsTol', 0);
        end

        function testUtilScalingNeverScalesUp(testCase)
            %   Every factor is capped at 1: amplifying a small gradient would
            %   amplify its evaluation noise with it.
            [p, ev] = testCase.scalingFixture();
            sc = adamnlopt.util_scaling(ev, p.x0, adamnlopt.defaultOptions());
            all3 = [sc.objFactor; sc.conFactorE; sc.conFactorI];
            testCase.verifyLessThanOrEqual(max(all3), 1);
            testCase.verifyGreaterThan(min(all3), 0);
        end

        function testUtilScalingScalesDownALargeGradient(testCase)
            ev = testCase.bigGradientEvaluator();
            sc = adamnlopt.util_scaling(ev, [1; 1], adamnlopt.defaultOptions());
            %   gmax / ‖g‖inf = 100 / 1e4 exactly.
            testCase.verifyEqual(sc.objFactor, 1e-2, 'RelTol', 1e-12);
            testCase.verifySize(sc.conFactorE, [0 1]);
            testCase.verifySize(sc.conFactorI, [0 1]);
        end

        %% ---------------------------------------------------------------
        %  diagnose, util_logger, util_logAppend
        %  ---------------------------------------------------------------
        function testDiagnoseReportsAConvergedRunAndStopsThere(testCase)
            out = testCase.diagOutput(1);
            rep = testCase.quiet(@() adamnlopt.diagnose(out));
            testCase.verifyEqual(rep.exitflag, 1);
            testCase.verifyEmpty(rep.recommendations, ...
                'a converged solve has nothing to recommend');
        end

        function testDiagnoseFlagsAnExhaustedBudget(testCase)
            out = testCase.diagOutput(0);
            rep = testCase.quiet(@() adamnlopt.diagnose(out));
            testCase.verifyTrue(rep.flags.hitBudget);
            testCase.verifyNotEmpty(rep.recommendations);
        end

        function testDiagnoseFlagsLocalInfeasibility(testCase)
            out = testCase.diagOutput(-2);
            out.constrViolation = 3;
            rep = testCase.quiet(@() adamnlopt.diagnose(out));
            testCase.verifyTrue(rep.flags.infeasible);
        end

        function testDiagnoseReturnsTheDocumentedShapeOnEveryExitFlag(testCase)
            %   diagnose runs automatically on a non-converged solve, so a
            %   missing field here would turn a bad result into an error.
            for ef = [1 2 0 -1 -2 -3]
                rep = testCase.quiet(@() adamnlopt.diagnose(testCase.diagOutput(ef)));
                testCase.verifyEqual(rep.exitflag, ef);
                testCase.verifyClass(rep.messages, 'cell');
                testCase.verifyClass(rep.recommendations, 'cell');
                testCase.verifyClass(rep.flags, 'struct');
                testCase.verifyTrue(isfield(rep, 'condJE'));
                testCase.verifyTrue(isfield(rep, 'mu'));
            end
        end

        function testDiagnoseSurvivesAnOutputStrippedToNothing(testCase)
            %   A caller may hand it a struct from an older version, or one
            %   they assembled themselves.
            rep = testCase.quiet(@() adamnlopt.diagnose(struct()));
            testCase.verifyTrue(isnan(rep.exitflag));
        end

        function testDiagnoseAppendsItsReportToALogFile(testCase)
            f = [tempname '.log'];
            cleanup = onCleanup(@() testCase.removeIfPresent(f));
            testCase.quiet(@() adamnlopt.diagnose(testCase.diagOutput(0), f));
            testCase.assertTrue(isfile(f));
            testCase.verifyTrue(contains(fileread(f), 'convergence advisor'));
        end

        function testTheLoggerPrintsNothingAtTheOffLevel(testCase)
            txt = evalc("adamnlopt.util_logger('header', 'off');");
            testCase.verifyEmpty(strtrim(txt));
            txt = evalc("adamnlopt.util_logger('iter', 'off', struct('iter', 1));");
            testCase.verifyEmpty(strtrim(txt));
        end

        function testTheLoggerPrintsAHeaderOnlyAtAnIterativeLevel(testCase)
            testCase.verifyNotEmpty(strtrim(evalc( ...
                "adamnlopt.util_logger('header', 'iter');")));
            testCase.verifyEmpty(strtrim(evalc( ...
                "adamnlopt.util_logger('header', 'final');")), ...
                "the 'final' level prints a summary, not a table header");
        end

        function testTheDebugLevelAddsColumnsWithoutDisturbingTheStandardOnes(testCase)
            %   Anything parsing the leading columns has to keep working, so
            %   the debug diagnostics are appended to the RIGHT.
            plain = evalc("adamnlopt.util_logger('header', 'iter');");
            debug = evalc("adamnlopt.util_logger('header', 'iter-debug');");
            testCase.verifyGreaterThan(numel(debug), numel(plain));
            testCase.verifyTrue(startsWith(strtrim(debug), strtrim(plain)));
        end

        function testAnAbsentDebugFieldPrintsADashNotAnError(testCase)
            d = testCase.iterRow(); %#ok<NASGU> -- read inside the evalc
            txt = evalc("adamnlopt.util_logger('iter', 'iter-debug', d);");
            testCase.verifyTrue(contains(txt, '-'));
            testCase.verifyTrue(contains(txt, '1'));
        end

        function testTheFinalRecordPrintsAtBothFinalAndIterativeLevels(testCase)
            d = struct('message', 'all done', 'iterations', 4, ...
                'constrViolation', 1e-9, 'firstOrderOpt', 1e-8); %#ok<NASGU>
            for lvl = {'final', 'iter', 'iter-debug'}
                txt = evalc(sprintf( ...
                    "adamnlopt.util_logger('final', '%s', d);", lvl{1}));
                testCase.verifyTrue(contains(txt, 'all done'), ...
                    sprintf('level %s swallowed the final record', lvl{1}));
            end
        end

        function testAnUnrecognizedActionPrintsNothing(testCase)
            txt = evalc("adamnlopt.util_logger('nosuchaction', 'iter', struct());");
            testCase.verifyEmpty(strtrim(txt));
        end

        function testTheLoggerMirrorsItsOutputToTheLogFile(testCase)
            f = [tempname '.log'];
            cleanup = onCleanup(@() testCase.removeIfPresent(f));
            d = testCase.iterRow(); %#ok<NASGU>  evalc hides the use
            evalc("adamnlopt.util_logger('iter', 'iter', d, f);");
            testCase.assertTrue(isfile(f));
            testCase.verifyNotEmpty(strtrim(fileread(f)));
        end

        function testLogAppendWritesAndThenAppends(testCase)
            %   Opened and closed per call on purpose: a long solve killed or
            %   interrupted still leaves a complete log up to the last line.
            f = [tempname '.log'];
            cleanup = onCleanup(@() testCase.removeIfPresent(f));
            adamnlopt.util_logAppend(f, sprintf('one\n'));
            adamnlopt.util_logAppend(f, sprintf('two\n'));
            testCase.verifyEqual(fileread(f), sprintf('one\ntwo\n'));
        end

        function testLogAppendIsANoOpWithoutAPath(testCase)
            %   This is how every caller disables file logging.
            testCase.verifyWarningFree(@() adamnlopt.util_logAppend('', 'text'));
            testCase.verifyWarningFree(@() adamnlopt.util_logAppend([], 'text'));
        end

        function testLogAppendIgnoresEmptyText(testCase)
            f = [tempname '.log'];
            cleanup = onCleanup(@() testCase.removeIfPresent(f));
            adamnlopt.util_logAppend(f, '');
            testCase.verifyFalse(isfile(f), ...
                'an empty write must not create the file');
        end

        function testTheEchoHelpersRunWithoutError(testCase)
            %   Display-only; there is no headless assertion worth the
            %   machinery, but they are called on the 'iter-debug' path and so
            %   must not throw.
            opts = adamnlopt.defaultOptions();
            opts.maxIter = 7;
            txt = evalc('adamnlopt.util_echoOptions(opts);');
            testCase.verifyNotEmpty(strtrim(txt));
        end
    end

    %% ------------------------------------------------------------------
    %  Fixtures
    %  ------------------------------------------------------------------
    methods (Access = private)
        function p = validateWith(~, fun, x0, A, b, Aeq, beq, lb, ub, nonlcon)
            %VALIDATEWITH  validateProblem with the trailing arguments defaulted.
            if nargin < 4,  A = [];        end
            if nargin < 5,  b = [];        end
            if nargin < 6,  Aeq = [];      end
            if nargin < 7,  beq = [];      end
            if nargin < 8,  lb = [];       end
            if nargin < 9,  ub = [];       end
            if nargin < 10, nonlcon = [];  end
            p = adamnlopt.validateProblem(fun, x0, A, b, Aeq, beq, lb, ub, ...
                nonlcon, adamnlopt.defaultOptions());
        end

        function opts = scaleOpts(~, mode)
            %SCALEOPTS  Defaults with autoScale pinned to one mode.
            opts = adamnlopt.defaultOptions();
            opts.autoScale = mode;
        end

        function [p, ev] = scalingFixture(testCase)
            %SCALINGFIXTURE  A problem with one linear equality and one
            %   nonlinear inequality, so Dc and Di both have rows to scale and
            %   the linear/nonlinear split is non-trivial.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [0.3; 0.4], ...
                [], [], [1 -1], 0, [], [], @AdamNlOptTestCase.unitDiskIneq);
            ev = adamnlopt.Evaluator(p, adamnlopt.defaultOptions());
        end

        function [p, fx] = reductionFixture(testCase)
            %REDUCTIONFIXTURE  x1 fixed at 3, x2 free: the smallest reduction
            %   with something on both sides of the partition.
            p = testCase.validateWith(@AdamNlOptTestCase.sphere, [3; 2], ...
                [], [], [], [], [3; -5], [3; 5]);
            [~, fx] = adamnlopt.reduceProblem(p, adamnlopt.defaultOptions());
        end

        function out = emptyOutput(~)
            %EMPTYOUTPUT  The counter fields expandResult bumps.
            out = struct('objCount', 0, 'conCount', 0, 'funcCount', 0, ...
                'iterations', 0);
        end

        function state = degenState(~, JE, JI, cI, lamI)
            %DEGENSTATE  The five fields detectDegeneracy actually reads.
            state = struct('x', [0.5; 0.5], 'JE', JE, 'JI', JI, ...
                'cI', cI(:), 'lamI', lamI(:));
        end

        function [state, res] = rankDeficientKkt(~)
            %RANKDEFICIENTKKT  Two identical equality rows: JE has rank 1 but
            %   two multipliers, so the unregularized saddle-point matrix is
            %   singular along the null space of JE'.
            state = struct( ...
                'H',    [2 0; 0 2], ...
                'JE',   [1 1; 1 1], ...
                'JI',   [], ...
                'x',    [0.5; 0.5], ...
                'g',    [1; 1], ...
                'lamE', [0.1; 0.1], ...
                'lamI', [], ...
                'cE',   [0.2; 0.2], ...
                'cI',   [], ...
                's',    []);
            res = adamnlopt.kkt_residual(state);
        end

        function ev = restorationEvaluator(~)
            %RESTORATIONEVALUATOR  min 0 s.t. ||x||^2 = 1 -- the objective is
            %   irrelevant to restoration, which minimizes violation alone, so
            %   the only thing under test is the feasibility geometry.
            problem = struct( ...
                'objFun',     @AdamNlOptTestCase.sphere, ...
                'hasObjGrad', true, ...
                'nlcon',      @AdamNlOptTestCase.unitCircleEq, ...
                'hasConGrad', true, ...
                'Aineq',      zeros(0, 2), 'bineq', zeros(0, 1), ...
                'Aeqlin',     zeros(0, 2), 'beqlin', zeros(0, 1), ...
                'n', 2, 'mInl', 0, 'mEnl', 1);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());
        end

        function ev = bigGradientEvaluator(~)
            %BIGGRADIENTEVALUATOR  An unconstrained objective whose gradient at
            %   the probe point is far above the gmax = 100 cap.
            problem = struct( ...
                'objFun',     @AdamNlOptProblemSetupTest.steepObj, ...
                'hasObjGrad', true, ...
                'nlcon',      [], 'hasConGrad', false, ...
                'Aineq',      zeros(0, 2), 'bineq', zeros(0, 1), ...
                'Aeqlin',     zeros(0, 2), 'beqlin', zeros(0, 1), ...
                'n', 2, 'mInl', 0, 'mEnl', 0);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());
        end

        function out = diagOutput(~, exitflag)
            %DIAGOUTPUT  A plausible solve report for the advisor to read.
            out = struct( ...
                'exitflag',        exitflag, ...
                'message',         'test fixture', ...
                'iterations',      300, ...
                'funcCount',       1200, ...
                'objCount',        600, ...
                'conCount',        600, ...
                'firstOrderOpt',   1e-2, ...
                'constrViolation', 1e-8, ...
                'complementarity', 1e-7, ...
                'scaling',         struct('applied', false), ...
                'diag',            struct('rd', [1e-2; 1e-3], 'rpE', 1e-8, ...
                                          'JE', [1 2], 'lamE', 0.5, ...
                                          'zL', [0; 0], 'zU', [0; 0], ...
                                          'mu', 1e-6, 'x', [1; 2], ...
                                          'lb', [-Inf; -Inf], 'ub', [Inf; Inf]));
        end

        function d = iterRow(~)
            %ITERROW  One iteration record with the standard columns only, so
            %   the debug columns all have to fall back to a dash.
            d = struct('iter', 1, 'f', 2.5, 'rFeas', 1e-3, 'rStat', 1e-2, ...
                'rComp', 1e-4, 'mu', 0.1, 'alpha', 1, 'mode', 'ip', ...
                'nFun', 12, 'elapsed', 0.25);
        end

        function out = quiet(~, fcn)
            %QUIET  Run a printing function and keep its output off the console.
            assert(isa(fcn, 'function_handle'));
            [~, out] = evalc('fcn()');
        end

        function removeIfPresent(~, f)
            %REMOVEIFPRESENT  Tolerant temp-file cleanup.
            if isfile(f)
                delete(f);
            end
        end

        function s = expectedDefaults(~)
            %EXPECTEDDEFAULTS  The pinned option surface, name by name.
            %   Written as literals rather than generated from the module, so
            %   the test is an independent statement of the interface instead
            %   of a tautology.
            pins = { ...
                'SpecifyObjectiveGradient',   false; ...
                'SpecifyConstraintGradient',  false; ...
                'HessianFcn',                 []; ...
                'HessPattern',                []; ...
                'JacobPattern',               []; ...
                'FiniteDifferenceStepSize',   sqrt(eps); ...
                'FiniteDifferenceType',       'forward'; ...
                'HonorBounds',                true; ...
                'autoFDStep',                 true; ...
                'optTol',                     1e-6; ...
                'feasTol',                    1e-6; ...
                'constrViolTol',              1e-4; ...   % physical gate (review D3)
                'compTol',                    []; ...
                'stepTol',                    1e-12; ...
                'maxIter',                    300; ...
                'maxFunEvals',                1e5; ...
                'maxTime',                    Inf; ...
                'objPlateauWindow',           40; ...
                'objPlateauFtol',             1e-5; ...
                'objPlateauOptTol',           3e-6; ...
                'objPlateauOptWindow',        10; ...
                'hessianApprox',              'bfgs'; ...
                'bfgsGammaCurvCap',           1e4; ...
                'bfgsB0Refresh',              true; ...
                'bfgsB0RefreshWindow',        8; ...
                'bfgsB0RefreshFactor',        3; ...
                'bfgsB0RefreshRefractory',    5; ...
                'bfgsB0RefreshMaxDrop',       100; ...
                'bfgsB0RefreshMinLearned',    0.2; ...
                'bfgsResetMaxDrop',           Inf; ...
                'bfgsCondMax',                1e12; ...
                'lbfgsMemory',                10; ...
                'linearSolver',               'direct'; ...
                'krylovMethod',               'minres'; ...
                'krylovAutoDim',              500; ...
                'krylovMaxIter',              []; ...
                'forcingEtaMax',              1e-6; ...
                'forcingEtaMin',              1e-10; ...
                'forcingGamma',               1; ...
                'forcingAlpha',               1.618; ...
                'precondition',               'jacobi'; ...
                'autoScale',                  'gradient'; ...
                'autoScaleMaxSpread',         1e4; ...
                'autoScaleMaxGradient',       100; ...    % row-scale cap (review D3)
                'autoScaleCurvGate',          1e4; ...
                'autoScaleCurvProbeMaxDim',   400; ...
                'globalization',              'filter'; ...
                'kappaThetaGrow',             100; ...
                'divergeFactor',              1e3; ...
                'divergeWindow',              Inf; ...
                'returnIterate',              'last'; ...
                'mu0',                        0.1; ...
                'muMin',                      []; ...
                'muGamma',                    0.2; ...
                'muBeta',                     1.5; ...
                'kappaMu',                    10; ...
                'tau',                        0.995; ...
                'delta0',                     1; ...
                'deltaMax',                   1e6; ...
                'trEta1',                     0.1; ...
                'trEta2',                     0.75; ...
                'trShrink',                   0.25; ...
                'trExpand',                   2; ...
                'modeSwitch',                 true; ...
                'modeSwitchStagnWindow',      5; ...
                'enableRestoration',          true; ...
                'restStallWindow',            5; ...
                'parallel',                   'off'; ...
                'barrierStallFactor',         10; ...
                'feasAdmitFactor',            100; ...
                'dualStepMax',                10; ...
                'dualCondMax',                1e8; ...
                'dualCondProbeMaxDim',        400; ...
                'useNTdecomp',                false; ...
                'trMaxInner',                 20; ...
                'useSOC',                     true; ...
                'socMax',                     4; ...
                'socThreshold',               0.1; ...
                'lsMultiplierRefresh',        true; ...
                'lsRefreshDomRatio',          10; ...
                'lsRefreshFeasTol',           1e-3; ...
                'lsRefreshDeadband',          0.9; ...
                'dualFitCondMax',             1e4; ...
                'dualFitCondMinEq',           8; ...
                'dualFitGrowthMax',           10; ...
                'activeBoundGapTol',          1e-3; ...
                'excludeActiveBoundRows',     true; ...
                'enableDegeneracyDetection',  false; ...
                'modeNearBdryAugJE',          false; ...
                'enableBroyden',              false; ...
                'broydenMaxStale',            20; ...
                'broydenTol',                 0.1; ...
                'costThreshold',              Inf; ...   % Broyden opt-in (review D1)
                'traceLevel',                 1; ...
                'traceMaxRows',               20000; ...
                'warnOnSilentFailure',        false; ...
                'Plot',                       false; ...
                'PlotFcn',                    []; ...
                'IterationFcn',               []; ...
                'Display',                    'iter'; ...
                'LogFile',                    ''};
            s = struct();
            for i = 1:size(pins, 1)
                s.(pins{i, 1}) = pins{i, 2};
            end
        end
    end

    methods (Static)
        function [f, g] = steepObj(x)
            %STEEPOBJ  A gradient of order 1e4 at the unit point.
            f = 5e3 * (x(1) ^ 2 + x(2) ^ 2);
            g = 1e4 * x(:);
        end
    end
end
