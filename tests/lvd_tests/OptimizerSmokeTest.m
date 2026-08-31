classdef OptimizerSmokeTest < KsptotTestCase
    %OptimizerSmokeTest Wiring smoke tests for the 7 AbstractOptimizer subclasses.
    %
    % SUBJECT UNDER TEST
    %   helper_methods/ksptot_lvd/classes/Optimization/optimizers/*
    %   helper_methods/ksptot_lvd/optimization/lvd_executeOptimProblem.m
    %
    % WHY THIS FILE IS NOT INDEPENDENT-ORACLE TESTING
    %   The other files in tests/lvd_tests re-derive the quantity under test
    %   from first principles and compare.  That is the wrong shape here: the
    %   thing being tested is fmincon, IPOPT, NOMAD, pattern search, Adam,
    %   surrogate optimization and SQP, and reimplementing any of them in a
    %   test file would be absurd.  What CAN break, and what these tests are
    %   for, is the wiring around them:
    %     * does each LvdOptimizerAlgoEnum reach the right wrapper class,
    %     * does each wrapper assemble a problem struct that its solver
    %       actually accepts,
    %     * does lvd_executeOptimProblem dispatch on problem.solver correctly,
    %     * and does the answer get merged back into the mission script?
    %   None of that is numerical, and all of it is the sort of thing that
    %   rots when a solver's interface changes underneath it.  (One of the
    %   seven has in fact already rotted; see the SQP pin below.)
    %
    % THE TOY PROBLEM
    %   A one-variable bowl with an exactly known analytic minimum, expressed
    %   in real LVD terms so the whole production path runs:
    %
    %     initial state:  Kepler orbit about Kerbin, a = 1000 km, e = 0.2,
    %                     true anomaly 0 -- i.e. starting AT periapsis
    %     one event:      pure two-body coast of duration T
    %     variable:       T, bounded to [0.6 P, 1.4 P], initial guess 0.85 P
    %     objective:      minimize the altitude at the end of the event
    %
    %   Under two-body motion the radius after coasting T from periapsis is
    %   r(T) = a(1 - e*cos(E(T))), which over one period has a single interior
    %   minimum at T = P, the orbital period.  So:
    %
    %     analytic argmin   T* = P = 2*pi*sqrt(a^3/mu)
    %     analytic minimum  alt* = a(1 - e) - R = 1000*0.8 - 600 = 200 km
    %
    %   Both are computed in the test from a, e, mu and R -- never read back
    %   out of the solver.  r(T) is smooth and locally quadratic around T = P,
    %   which is what makes it a fair target for gradient and derivative-free
    %   solvers alike.  The initial guess of 0.85 P is deliberately off the
    %   answer by 15% of a period so that "the variable was merged back into
    %   the script" is distinguishable from "the variable was never touched".
    %
    % TOLERANCES
    %   Each solver is checked against T* with a tolerance chosen for its
    %   class, not tuned until it passed: the gradient solvers get 0.1% of a
    %   period, the derivative-free ones 2%.  These are smoke tolerances.  A
    %   test here failing means the wiring broke, not that the solver got
    %   slightly worse.
    %
    % SKIPPED (documented)
    %   * openOptionsDialog on all 7 wrappers -- each launches an App Designer
    %     dialog and blocks.
    %   * The static getOutputFunction / writeOptimStatus / generatePlots
    %     methods on FminconOptimizer, PatternSearchOptimizer,
    %     SurrogateOptimizer, NomadOptimizer and IpOptOptimizer.  They are
    %     reachable only with callOutputFcn = true, which opens
    %     ma_ObserveOptimGUI_App and reads uicontrol values; generatePlots also
    %     touches the GLOBAL_AppThemer global.  Every test here therefore runs
    %     with callOutputFcn = false.
    %   * The callOutputFcn = true branch at the bottom of
    %     lvd_executeOptimProblem, which asks the user through
    %     ma_OptimResultsScorecardGUI_App whether to keep the solution.  The
    %     "discard" arm of that branch (x empty -> restore initX) is
    %     unreachable without the dialog.
    %   * Parallel execution.  Every wrapper's useParallel option defaults to
    %     off and turning it on would need a pool; the parfevalOnAll block at
    %     the top of lvd_executeOptimProblem is not exercised.
    %   * The FiniteDifferences and DerivEst gradient arms of the four
    %     AbstractGradientOptimizer subclasses, and
    %     FminconOptions.computeOptimalStepSizes.  Those select between
    %     CustomFiniteDiffsCalculationMethod and
    %     DERIVEstFiniteDiffsCalculationMethod, which are a separate subsystem
    %     with their own sparsity machinery, and the sparsity progress dialog
    %     wants a live hLvdMainGUI.  All tests here run on the default BuiltIn
    %     gradient algorithm.
    %   * NomadOptimizer.nomadObjConstrWrapper's parallel/blackbox marshalling
    %     details, and IpOptOptimizer's Jacobian-structure helpers.  Both are
    %     exercised end to end by the bowl tests but not probed individually.
    %
    % REGRESSION GUARDS
    %   The last two checks guard defects found while building this file and
    %   since fixed (a dead Optimization Toolbox private call that made SQP
    %   unusable, and two static objective-function factories calling stale
    %   constructor signatures).  Their comments name the original fault so a
    %   regression is recognisable.

    properties(TestParameter)
        caseName = { ...
            'AlgoEnumToOptimizerMapping', ...
            'NoVariablesEarlyReturn', ...
            'OptionsAccessors', ...
            'FminconBowl', ...
            'PatternSearchBowl', ...
            'SurrogateBowl', ...
            'NomadBowl', ...
            'IpoptBowl', ...
            'AdamNlOptBowl', ...
            'UnknownSolverDispatchError', ...
            'SqpBowl', ...
            'StaticDefaultObjFcnFactoriesBuildUsableObjects', ...
        };
    end

    properties(Constant, Access=private)
        Sma      = 1000;    %km
        Ecc      = 0.2;
        InitFrac = 0.85;    %initial guess, in periods
        LbFrac   = 0.6;     %lower bound, in periods
        UbFrac   = 1.4;     %upper bound, in periods
    end

    methods(Test)
        function optimizerWiringIsIntact(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ------------------------------------------------------------------
        %  Interface / dispatch
        %  ------------------------------------------------------------------

        function checkAlgoEnumToOptimizerMapping(testCase)
            %Every member of LvdOptimizerAlgoEnum must resolve to exactly one
            %wrapper class, and getSelectedOptimizer must honour optAlgo.  The
            %expected mapping is written out longhand rather than derived from
            %the enum, so that adding an eighth solver to the enum without
            %wiring it up fails here instead of passing vacuously.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            optimizer = lvdData.optimizer;

            expected = { ...
                LvdOptimizerAlgoEnum.Fmincon,       'FminconOptimizer'; ...
                LvdOptimizerAlgoEnum.SQP,           'SQPOptimizer'; ...
                LvdOptimizerAlgoEnum.PatternSearch, 'PatternSearchOptimizer'; ...
                LvdOptimizerAlgoEnum.Nomad,         'NomadOptimizer'; ...
                LvdOptimizerAlgoEnum.Ipopt,         'IpOptOptimizer'; ...
                LvdOptimizerAlgoEnum.Surrogate,     'SurrogateOptimizer'; ...
                LvdOptimizerAlgoEnum.AdamNlOpt,     'AdamNlOptOptimizer'};

            allAlgos = enumeration('LvdOptimizerAlgoEnum');
            testCase.verifyNumElements(allAlgos, size(expected,1), ...
                'LvdOptimizerAlgoEnum has gained or lost a member; update this mapping.');

            for(i = 1:size(expected,1))
                algo = expected{i,1};
                wanted = expected{i,2};

                opt = optimizer.getOptimizerForEnum(algo);
                testCase.verifyClass(opt, wanted, ...
                    sprintf('getOptimizerForEnum(%s) must return a %s.', algo.name, wanted));

                optimizer.optAlgo = algo;
                sel = optimizer.getSelectedOptimizer();
                testCase.verifyTrue(sel == opt, ...
                    sprintf('getSelectedOptimizer must return the same handle as getOptimizerForEnum for %s.', algo.name));

                testCase.verifyTrue(isa(opt, 'AbstractOptimizer'), ...
                    sprintf('%s must derive from AbstractOptimizer.', wanted));
            end

            %The four solvers the enum marks as gradient-based must actually be
            %AbstractGradientOptimizer subclasses.  reqGrad drives the GUI's
            %gradient-algorithm selector, so a mismatch would offer gradient
            %options for a solver that cannot use them.
            for(i = 1:size(expected,1))
                algo = expected{i,1};
                opt = optimizer.getOptimizerForEnum(algo);
                testCase.verifyEqual(isa(opt, 'AbstractGradientOptimizer'), algo.reqGrad, ...
                    sprintf(['%s declares reqGrad = %d, which disagrees with whether ' ...
                             'its wrapper %s derives from AbstractGradientOptimizer.'], ...
                            algo.name, algo.reqGrad, class(opt)));
            end
        end

        function checkNoVariablesEarlyReturn(testCase)
            %All 7 wrappers open with the same guard: if the script has no
            %enabled optimization variables, return exitflag 0 and a fixed
            %message WITHOUT touching the solver.  This is the one check that
            %covers every wrapper unconditionally, because it returns before
            %any external binary or toolbox function is reached.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            optimizer = lvdData.optimizer;
            writeOutput = @(varargin) [];

            [x0All, actVars] = optimizer.vars.getTotalScaledXVector();
            testCase.assertEmpty(x0All, 'Fixture broken: the default script should have no variables.');
            testCase.assertEmpty(actVars, 'Fixture broken: the default script should have no variables.');

            allAlgos = enumeration('LvdOptimizerAlgoEnum');
            for(i = 1:numel(allAlgos))
                algo = allAlgos(i);
                opt = optimizer.getOptimizerForEnum(algo);

                %optimize() is called on the wrapper directly rather than
                %through LvdOptimization.optimize, which puts up a uialert on
                %this same condition and needs a live figure handle.
                [exitflag, message] = opt.optimize(optimizer, writeOutput, false, []);

                testCase.verifyEqual(exitflag, 0, ...
                    sprintf('%s must return exitflag 0 when there are no variables.', algo.name));
                testCase.verifyEqual(message, 'No variables enabled on script.  Aborting optimization.', ...
                    sprintf('%s returned the wrong no-variables message.', algo.name));
            end
        end

        function checkOptionsAccessors(testCase)
            %Each wrapper owns an options object of a specific class and
            %exposes it through getOptions().  Most of the options properties
            %are private, so getOptions is the only handle the GUI has on
            %them; if it returns the wrong type the options dialog silently
            %edits nothing.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            optimizer = lvdData.optimizer;

            expected = { ...
                LvdOptimizerAlgoEnum.Fmincon,       'FminconOptions'; ...
                LvdOptimizerAlgoEnum.SQP,           'SqpOptions'; ...
                LvdOptimizerAlgoEnum.PatternSearch, 'PatternSearchOptions'; ...
                LvdOptimizerAlgoEnum.Nomad,         'NomadOptions'; ...
                LvdOptimizerAlgoEnum.Ipopt,         'IpoptOptions'; ...
                LvdOptimizerAlgoEnum.Surrogate,     'SurrogateOptimizerOptions'; ...
                LvdOptimizerAlgoEnum.AdamNlOpt,     'AdamNlOptOptions'};

            for(i = 1:size(expected,1))
                algo = expected{i,1};
                opt = optimizer.getOptimizerForEnum(algo);

                testCase.verifyClass(opt.getOptions(), expected{i,2}, ...
                    sprintf('%s.getOptions() must return a %s.', class(opt), expected{i,2}));

                %The options objects are handles, so getOptions must hand back
                %the SAME object every time -- otherwise edits made through
                %the options dialog would be thrown away.
                testCase.verifyTrue(opt.getOptions() == opt.getOptions(), ...
                    sprintf('%s.getOptions() must return the same handle on every call.', class(opt)));

                %usesParallel and getNumParaWorkers are called by
                %LvdOptimization before a run and must be plain scalars.
                tf = opt.usesParallel();
                testCase.verifyClass(tf, 'logical', ...
                    sprintf('%s.usesParallel() must return a logical.', class(opt)));
                testCase.verifyFalse(tf, ...
                    sprintf('%s must default to serial execution.', class(opt)));

                numWorkers = opt.getNumParaWorkers();
                testCase.verifyTrue(isnumeric(numWorkers) && isscalar(numWorkers), ...
                    sprintf('%s.getNumParaWorkers() must return a numeric scalar.', class(opt)));
                testCase.verifyGreaterThanOrEqual(numWorkers, 1, ...
                    sprintf('%s.getNumParaWorkers() must return at least one worker.', class(opt)));
            end
        end

        function checkUnknownSolverDispatchError(testCase)
            %lvd_executeOptimProblem's final else must reject an unrecognised
            %solver name rather than silently returning garbage.  This is the
            %guard that catches a wrapper whose problem.solver string has
            %drifted from the dispatch table.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            problem = struct();
            problem.solver = 'notasolver';
            problem.options.UseParallel = false;
            problem.lvdData = lvdData;

            %The error is raised without an identifier, so the message is the
            %only thing available to assert on.
            caughtMsg = '';
            try
                lvd_executeOptimProblem(testCase.celBodyData, @(varargin) [], problem, ma_OptimRecorder(), false);
            catch ME
                caughtMsg = ME.message;
            end
            testCase.verifyEqual(caughtMsg, 'Unknown optimizer function: notasolver', ...
                'An unrecognised problem.solver must be rejected with a naming error.');
        end

        %% ------------------------------------------------------------------
        %  Quadratic bowl, one solver per check
        %  ------------------------------------------------------------------

        function checkFminconBowl(testCase)
            testCase.runBowl(LvdOptimizerAlgoEnum.Fmincon, 1e-3, ...
                @() testCase.assumeNotEmpty(which('fmincon'), 'fmincon is unavailable.'));
        end

        function checkPatternSearchBowl(testCase)
            testCase.runBowl(LvdOptimizerAlgoEnum.PatternSearch, 2e-2, ...
                @() testCase.assumeNotEmpty(which('patternsearch'), ...
                    'patternsearch (Global Optimization Toolbox) is unavailable.'));
        end

        function checkSurrogateBowl(testCase)
            %surrogateopt samples pseudo-randomly, so the run is seeded to keep
            %the check reproducible, and its evaluation budget is cut right
            %down -- this is a wiring test, not a convergence study.
            testCase.assumeNotEmpty(which('surrogateopt'), ...
                'surrogateopt (Global Optimization Toolbox) is unavailable.');

            rng(42, 'twister');
            testCase.runBowl(LvdOptimizerAlgoEnum.Surrogate, 2e-2, [], ...
                @(optimizer) set(optimizer.surragateOpt.getOptions(), 'maxFuncEvals', 60));
        end

        function checkNomadBowl(testCase)
            %NOMAD is an external mex binary and is not always present; skip
            %cleanly rather than failing the suite when it is not.
            testCase.runBowl(LvdOptimizerAlgoEnum.Nomad, 2e-2, ...
                @() testCase.assumeNotEmpty(which('nomadOpt'), ...
                    'The NOMAD mex binary (nomadOpt) is not on the path.'));
        end

        function checkIpoptBowl(testCase)
            %IPOPT is an external mex binary and is not always present.
            testCase.runBowl(LvdOptimizerAlgoEnum.Ipopt, 1e-3, ...
                @() testCase.assumeNotEmpty(which('ipopt'), ...
                    'The IPOPT mex binary is not on the path.'));
        end

        function checkAdamNlOptBowl(testCase)
            %adamnlopt is a separate package and is not always present.
            testCase.runBowl(LvdOptimizerAlgoEnum.AdamNlOpt, 1e-3, ...
                @() testCase.assumeNotEmpty(which('adamnlopt.solve'), ...
                    'The adamnlopt package is not on the path.'));
        end

        %% ------------------------------------------------------------------
        %  Regression guards for previously-fixed defects
        %  ------------------------------------------------------------------

        function checkSqpBowl(testCase)
            %SQPOptimizer must solve the bowl like the other six wrappers.  It
            %is offered in the GUI's solver list (LvdOptimizerAlgoEnum.SQP)
            %with no caveat, so a user selecting it must get a real solve.
            %
            %It used to throw MATLAB:UndefinedFunction before a single
            %objective evaluation, via a two-step chain inside the vendored
            %slp_sqp library:
            %  (1) sqp.m:380 read PlotFcn = isfield(Opts,'PlotFcns'), testing
            %      whether the options struct HAS the field rather than whether
            %      a plot function was actually requested.  SqpOptions.m:34
            %      builds its options with optimset, which always emits the
            %      full field list including an empty PlotFcns, so the plotting
            %      path ran unconditionally.
            %  (2) private/plotFcns.m:40 then called createCellArrayOfFunctions,
            %      a PRIVATE Optimization Toolbox function that no longer ships
            %      with current MATLAB.  (The same dead call still sits in
            %      private/saocrkargin.m:115, on a path this does not reach.)
            %The fix was (1): gate on a non-empty PlotFcns.
            %
            %With SQP reachable again, a second gap surfaced behind it: sqp.m
            %only populates out.status on a NON-converged exit, so
            %lvd_executeOptimProblem.m returned an empty status message on
            %every successful SQP solve.  That call site now supplies one.
            testCase.runBowl(LvdOptimizerAlgoEnum.SQP, 1e-3, ...
                @() testCase.assumeNotEmpty(which('fmincon'), ...
                    'The SQP wrapper needs the Optimization Toolbox on the path.'));
        end

        function checkStaticDefaultObjFcnFactoriesBuildUsableObjects(testCase)
            %AbstractObjectiveFcn.m:46 declares the abstract static factory
            %  objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
            %and advertises it as the supported way to make a default objective
            %function.  Both concrete implementations must return a usable,
            %fully wired object.
            %
            %Both used to call their own constructor with a stale signature:
            %GenericObjectiveFcn.getDefaultObjFcn passed 5 arguments to the
            %6-argument constructor (the scaleFactor parameter had been
            %inserted in the middle), so lvdOptim landed in scaleFactor and
            %lvdData was left unassigned -- MATLAB:minrhs.  CompositeObjectiveFcn
            %passed 3 arguments to its 5-argument constructor, so an
            %LvdOptimization landed in the ObjFcnDirectionTypeEnum-typed
            %dirType property.  Neither factory could be called at all.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            noBody = KSPTOT_BodyInfo.empty(1,0);

            genericObjFcn = GenericObjectiveFcn.getDefaultObjFcn(evt1, noBody, lvdData.optimizer, lvdData);
            testCase.verifyClass(genericObjFcn, 'GenericObjectiveFcn', ...
                'GenericObjectiveFcn.getDefaultObjFcn must return a GenericObjectiveFcn.');
            testCase.verifyTrue(genericObjFcn.lvdData == lvdData, ...
                'The factory must wire the real lvdData through, not shift it into another slot.');
            testCase.verifyTrue(genericObjFcn.event == evt1, ...
                'The factory must wire the event through.');

            compObjFcn = CompositeObjectiveFcn.getDefaultObjFcn(evt1, noBody, lvdData.optimizer, lvdData);
            testCase.verifyClass(compObjFcn, 'CompositeObjectiveFcn', ...
                'CompositeObjectiveFcn.getDefaultObjFcn must return a CompositeObjectiveFcn.');
            testCase.verifyTrue(compObjFcn.lvdData == lvdData, ...
                'The composite factory must wire the real lvdData through.');
            testCase.verifyClass(compObjFcn.dirType, 'ObjFcnDirectionTypeEnum', ...
                ['dirType must hold a direction enum.  An LvdOptimization here means ' ...
                 'the factory has regressed to the 3-argument constructor call.']);

            %Control: the six-argument form the live code actually uses builds
            %a working object.  This is what proves the factories are wrong
            %rather than the constructors.
            %The explicit constructor form the live code paths use (see
            %CompositeObjectiveFcn.upgradeExistingObjFuncs) must keep agreeing
            %with the factory above -- it is the signature the factory was out
            %of step with.
            frame = testCase.kerbinFrame;
            fcn = GenericMAConstraint('Altitude', evt1, 0, 0, [], [], noBody);
            objFcn = GenericObjectiveFcn(evt1, frame, fcn, 1, lvdData.optimizer, lvdData);
            testCase.verifyClass(objFcn, 'GenericObjectiveFcn', ...
                'The 6-argument GenericObjectiveFcn constructor must work.');
            testCase.verifyTrue(objFcn.lvdData == lvdData, ...
                'The 6-argument form must wire lvdData through.');
            testCase.verifyEqual(objFcn.scaleFactor, 1, ...
                'The 6-argument form must wire the scale factor through.');
        end

        %% ------------------------------------------------------------------
        %  Fixtures and shared drivers
        %  ------------------------------------------------------------------

        function runBowl(testCase, algo, relTol, assumeFcn, configureFcn)
            %Solves the toy bowl with one solver and checks the answer against
            %the analytic optimum.
            if(nargin >= 4 && not(isempty(assumeFcn)))
                assumeFcn();
            end

            [lvdData, evt1, P, minAltKm] = testCase.makeBowlMission();
            optimizer = lvdData.optimizer;
            optimizer.optAlgo = algo;

            if(nargin >= 5 && not(isempty(configureFcn)))
                configureFcn(optimizer);
            end

            durInit = evt1.termCond.duration;
            testCase.assertEqual(durInit, testCase.InitFrac*P, 'AbsTol', 1e-9, ...
                'Fixture broken: the initial guess is not where it should be.');

            [exitflag, message] = optimizer.consoleOptimize();

            %Interface contract first: two outputs, of the right shapes.
            testCase.verifyTrue(isnumeric(exitflag) && isscalar(exitflag), ...
                sprintf('%s must return a numeric scalar exit flag.', algo.name));
            testCase.verifyNotEmpty(message, ...
                sprintf('%s must return a non-empty status message.', algo.name));
            testCase.verifyTrue(ischar(message) || isstring(message), ...
                sprintf('%s must return its status message as text.', algo.name));

            %Then the wiring that matters most: the answer has to come back
            %out of the solver and into the mission script.  lvd_executeOptimProblem
            %does this with vars.updateObjsWithScaledVarValues(x).
            durFinal = evt1.termCond.duration;
            testCase.verifyNotEqual(durFinal, durInit, ...
                sprintf(['%s left the event duration at its initial guess -- the ' ...
                         'solution was never merged back into the script.'], algo.name));

            %And finally the answer itself, against the analytic optimum
            %derived from a, e, mu and R at the top of makeBowlMission.
            testCase.verifyLessThan(abs(durFinal/P - 1), relTol, ...
                sprintf(['%s converged to T/P = %.6f; the analytic argmin is ' ...
                         'T/P = 1 (one full orbital period back to periapsis).'], ...
                        algo.name, durFinal/P));

            %Re-run the script at the solution and confirm the objective really
            %is the periapsis altitude.  This is an independent read of the
            %result: it goes through the propagator, not through anything the
            %optimizer reported.
            stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);
            finalEntry = stateLog.getLastStateLogForEvent(evt1);
            altFinal = norm(finalEntry.position) - finalEntry.centralBody.radius;
            testCase.verifyLessThan(abs(altFinal - minAltKm), max(1, relTol*minAltKm), ...
                sprintf(['%s left the vehicle at %.4f km altitude; the analytic ' ...
                         'minimum is a(1-e) - R = %.4f km.'], algo.name, altFinal, minAltKm));

            %Sanity: the optimizer improved on the initial guess.  A solver
            %that returned x0 unchanged would already have been caught above,
            %but this also catches one that wandered uphill.
            evtCopyDur = evt1.termCond.duration;
            evt1.termCond.duration = durInit;
            stateLog0 = lvdData.script.executeScript(false, evt1, false, false, false, false, false);
            entry0 = stateLog0.getLastStateLogForEvent(evt1);
            alt0 = norm(entry0.position) - entry0.centralBody.radius;
            evt1.termCond.duration = evtCopyDur;

            testCase.verifyLessThan(altFinal, alt0, ...
                sprintf('%s must improve on the initial guess (%.4f km).', algo.name, alt0));
        end

        function [lvdData, evt1, P, minAltKm] = makeBowlMission(testCase)
            %The toy bowl described in the class header.
            ksptotAddProjectPaths();

            bodyInfo = testCase.kerbin;
            frame = testCase.kerbinFrame;

            a = testCase.Sma;
            e = testCase.Ecc;

            %Orbital period and periapsis altitude, straight from the
            %definitions.  Nothing here consults the optimizer or the
            %propagator, which is what makes them a usable target.
            P = 2*pi*sqrt(a^3 / bodyInfo.gm);
            minAltKm = a*(1 - e) - bodyInfo.radius;
            testCase.assertGreaterThan(minAltKm, bodyInfo.atmohgt, ...
                'Fixture broken: periapsis must stay above the atmosphere so drag cannot matter.');

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            %True anomaly 0 puts the vehicle at periapsis at t = 0, which is
            %what makes the argmin land exactly on one period.
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, a, e, 0.1, 0, 0, 0, frame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(testCase.InitFrac * P);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            %Objective: minimise the altitude at the end of the event.
            fcn = GenericMAConstraint('Altitude', evt1, 0, 0, [], [], KSPTOT_BodyInfo.empty(1,0));
            objFcn = GenericObjectiveFcn(evt1, frame, fcn, 1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.addObjFunc(objFcn);
            testCase.assertEqual(lvdData.optimizer.objFcn.dirType, ObjFcnDirectionTypeEnum.Minimize, ...
                'Fixture broken: the composite objective must be set to minimise.');

            %Variable: the event duration, bracketing exactly one period.
            var = EventDurationOptimizationVariable(evt1.termCond);
            var.useTf = true;
            var.lb = testCase.LbFrac * P;
            var.ub = testCase.UbFrac * P;
            lvdData.optimizer.vars.addVariable(var);

            [x0All, actVars] = lvdData.optimizer.vars.getTotalScaledXVector();
            testCase.assertNumElements(x0All, 1, 'Fixture broken: expected exactly one scaled variable.');
            testCase.assertNumElements(actVars, 1, 'Fixture broken: expected exactly one active variable.');
        end
    end
end
