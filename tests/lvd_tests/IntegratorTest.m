classdef IntegratorTest < KsptotTestCase
    %IntegratorTest LVD integrator wrappers and their options objects.
    %
    % Every integrator is driven on an unperturbed two-body problem, whose
    % exact solution is known, and checked against refKeplerPropagate.  The
    % thresholds below are deliberately loose (roughly 20x the error each
    % method actually achieves) because their job is to catch gross
    % breakage -- a wrong Butcher tableau, a dropped term, a sign error --
    % not to certify precision.  The conservation and cross-agreement tests
    % are the ones that pin down correctness tightly.

    properties(TestParameter)
        firstOrderIntegrator = {'ODE45', 'ODE113', 'ODE78', 'ODE89', ...
                                'ODE23', 'ODE15s', 'ODE23s', 'ODE5'};
    end

    properties(Constant, Access=private)
        %Reference two-body problem: a mildly eccentric low Earth orbit.
        Gmu    = 398600.4418;
        RVect0 = [7000; 1200; 2100];
        VVect0 = [-2.2; 6.8; 2.4];
    end

    methods(Test)

        %% Accuracy against the analytic two-body solution

        function firstOrderMatchesAnalyticTwoBody(testCase, firstOrderIntegrator)
            %Propagating half a period must reproduce the Kepler solution.

            [r0, v0, gmu, period] = testCase.referenceProblem();
            dt = period / 2;

            [rExpected, vExpected] = refKeplerPropagate(r0, v0, gmu, dt);

            [~, y] = testCase.runFirstOrder(firstOrderIntegrator, [0, dt], [r0; v0]);

            tol = testCase.positionTolerance(firstOrderIntegrator);

            testCase.verifyVectorEqual(y(end, 1:3).', rExpected, tol, sprintf( ...
                '%s: position after half a period is off by more than %g km', ...
                firstOrderIntegrator, tol));

            testCase.verifyVectorEqual(y(end, 4:6).', vExpected, tol / dt * 10, sprintf( ...
                '%s: velocity after half a period disagrees with the Kepler solution', ...
                firstOrderIntegrator));
        end

        function secondOrderMatchesAnalyticTwoBody(testCase)
            %RKN1210 must reproduce the Kepler solution.

            [r0, v0, gmu, period] = testCase.referenceProblem();
            dt = period / 2;

            [rExpected, vExpected] = refKeplerPropagate(r0, v0, gmu, dt);

            [~, y, yp] = testCase.runSecondOrder([0, dt], r0, v0);

            testCase.verifyVectorEqual(y(end, :).', rExpected, 1e-9, ...
                'RKN1210: position after half a period disagrees with the Kepler solution');
            testCase.verifyVectorEqual(yp(end, :).', vExpected, 1e-11, ...
                'RKN1210: velocity after half a period disagrees with the Kepler solution');
        end

        function integratorsAgreeWithEachOther(testCase)
            %All integrators must converge on the same trajectory.
            %
            % This is stronger than any individual accuracy check: an error
            % confined to one wrapper shows up as disagreement even if the
            % analytic comparison were somehow mis-scaled.

            [r0, v0, gmu, period] = testCase.referenceProblem(); %#ok<ASGLU>
            dt = period / 3;

            names    = testCase.firstOrderIntegrator;
            endState = NaN(numel(names), 6);

            for(i = 1:numel(names)) %#ok<*NO4LP>
                [~, y] = testCase.runFirstOrder(names{i}, [0, dt], [r0; v0]);
                endState(i, :) = y(end, :);
            end

            % Compare every method against ODE89, the most accurate of them.
            referenceIdx = find(strcmp(names, 'ODE89'), 1);

            for(i = 1:numel(names))
                tol = testCase.positionTolerance(names{i});

                testCase.verifyVectorEqual(endState(i, 1:3).', ...
                    endState(referenceIdx, 1:3).', tol, sprintf( ...
                    '%s disagrees with ODE89 on the same two-body problem', names{i}));
            end
        end

        %% Conservation laws

        function firstOrderConservesEnergy(testCase, firstOrderIntegrator)
            %Specific orbital energy must be constant under point-mass gravity.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            [~, y] = testCase.runFirstOrder(firstOrderIntegrator, [0, 3 * period], [r0; v0]);

            energy0 = norm(v0)^2 / 2 - gmu / norm(r0);
            energy1 = norm(y(end, 4:6))^2 / 2 - gmu / norm(y(end, 1:3));

            drift = abs((energy1 - energy0) / energy0);
            tol   = testCase.energyTolerance(firstOrderIntegrator);

            testCase.verifyLessThan(drift, tol, sprintf( ...
                '%s: specific energy drifted by %g (relative) over three orbits', ...
                firstOrderIntegrator, drift));
        end

        function firstOrderConservesAngularMomentum(testCase, firstOrderIntegrator)
            %The angular momentum vector must be constant, in direction too.

            [r0, v0, gmu, period] = testCase.referenceProblem(); %#ok<ASGLU>

            [~, y] = testCase.runFirstOrder(firstOrderIntegrator, [0, 3 * period], [r0; v0]);

            h0 = cross(r0, v0);
            h1 = cross(y(end, 1:3).', y(end, 4:6).');

            drift = norm(h1 - h0) / norm(h0);
            tol   = testCase.energyTolerance(firstOrderIntegrator);

            testCase.verifyLessThan(drift, tol, sprintf( ...
                '%s: angular momentum drifted by %g (relative) over three orbits', ...
                firstOrderIntegrator, drift));
        end

        function secondOrderConservesEnergy(testCase)
            %RKN1210 is symplectic-ish on gravity-only problems; it should
            %conserve energy far better than the general-purpose solvers.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            [~, y, yp] = testCase.runSecondOrder([0, 3 * period], r0, v0);

            energy0 = norm(v0)^2 / 2 - gmu / norm(r0);
            energy1 = norm(yp(end, :))^2 / 2 - gmu / norm(y(end, :));

            drift = abs((energy1 - energy0) / energy0);

            testCase.verifyLessThan(drift, 1e-13, sprintf( ...
                'RKN1210: specific energy drifted by %g (relative) over three orbits', drift));
        end

        %% Time reversal

        function firstOrderPropagatesBackward(testCase, firstOrderIntegrator)
            %Forward then backward propagation must return to the start.

            [r0, v0, gmu, period] = testCase.referenceProblem(); %#ok<ASGLU>
            dt = 2 * period;

            [~, yFwd] = testCase.runFirstOrder(firstOrderIntegrator, [0, dt], [r0; v0]);
            [~, yBwd] = testCase.runFirstOrder(firstOrderIntegrator, [dt, 0], yFwd(end, :).');

            tol = testCase.reversalTolerance(firstOrderIntegrator);

            testCase.verifyVectorEqual(yBwd(end, 1:3).', r0, tol, sprintf( ...
                '%s: forward/backward propagation did not return to the initial position', ...
                firstOrderIntegrator));
        end

        function secondOrderPropagatesBackward(testCase)
            %RKN1210 must also be reversible.

            [r0, v0, gmu, period] = testCase.referenceProblem(); %#ok<ASGLU>
            dt = 2 * period;

            [~, yFwd, ypFwd] = testCase.runSecondOrder([0, dt], r0, v0);
            [~, yBwd] = testCase.runSecondOrder([dt, 0], yFwd(end, :).', ypFwd(end, :).');

            testCase.verifyVectorEqual(yBwd(end, :).', r0, 1e-7, ...
                'RKN1210: forward/backward propagation did not return to the initial position');
        end

        %% Event detection

        function firstOrderDetectsTerminalEvent(testCase, firstOrderIntegrator)
            %A terminal radius event must stop the integration on the radius.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            coe = refRv2Coe(r0, v0, gmu);
            targetRadius = coe.sma;

            evtFcn = @(t, y) refRadiusEvent(t, y, targetRadius);

            [t, y, te, ye, ie] = testCase.runFirstOrder( ...
                firstOrderIntegrator, [0, period], [r0; v0], evtFcn);

            testCase.assertNotEmpty(te, sprintf( ...
                '%s: terminal radius event was never detected', firstOrderIntegrator));

            testCase.verifyEqual(ie(1), 1, sprintf( ...
                '%s: reported the wrong event index', firstOrderIntegrator));

            testCase.verifyEqual(norm(ye(1, 1:3)), targetRadius, 'AbsTol', 1e-6, sprintf( ...
                '%s: event state is not on the target radius', firstOrderIntegrator));

            testCase.verifyEqual(t(end), te(1), 'AbsTol', 1e-6, sprintf( ...
                '%s: integration did not stop at the terminal event time', firstOrderIntegrator));

            % The event state must also be the analytically correct one.
            [rAtEvent, ~] = refKeplerPropagate(r0, v0, gmu, te(1));

            % Event states come from the solver's interpolant rather than a
            % step endpoint, so they carry a little more error than the
            % samples in y; allow an order of magnitude more room.
            testCase.verifyVectorEqual(ye(1, 1:3).', rAtEvent, ...
                10 * testCase.positionTolerance(firstOrderIntegrator), sprintf( ...
                '%s: event state disagrees with the Kepler solution at the event time', ...
                firstOrderIntegrator));
        end

        function secondOrderDetectsTerminalEventAtTheSameTime(testCase)
            %RKN1210 must find the same event time as the first-order solvers.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            coe = refRv2Coe(r0, v0, gmu);
            targetRadius = coe.sma;

            [~, ~, teFirst] = testCase.runFirstOrder('ODE89', [0, period], [r0; v0], ...
                @(t, y) refRadiusEvent(t, y, targetRadius));

            [~, ~, ~, teSecond] = testCase.runSecondOrder([0, period], r0, v0, ...
                @(t, y, yp) refRadiusEvent2ndOrder(t, y, yp, targetRadius));

            testCase.assertNotEmpty(teSecond, ...
                'RKN1210: terminal radius event was never detected');

            testCase.verifyEqual(teSecond(1), teFirst(1), 'AbsTol', 1e-4, ...
                'RKN1210 and ODE89 disagree on when the radius event occurs');
        end

        function secondOrderEventStateIsOneRowPerEvent(testCase)
            %rkn1210 must return event states row-per-event, like ode45.
            %
            % Every MATLAB ODE solver returns YE as nEvents-by-nStates, and
            % SecondOrderGravOnlyPropagator relies on that: it does
            % horzcat(ye, ype) to build a 1x6 state and, on the hold-down
            % path, indexes ye(:,1:3).

            [r0, v0, gmu, period] = testCase.referenceProblem();

            coe = refRv2Coe(r0, v0, gmu);
            targetRadius = coe.sma;

            [~, ~, ~, te, ye, ype] = testCase.runSecondOrder([0, period], r0, v0, ...
                @(t, y, yp) refRadiusEvent2ndOrder(t, y, yp, targetRadius));

            testCase.assertNotEmpty(te, 'RKN1210: radius event was never detected');

            testCase.verifySize(ye, [numel(te), 3], sprintf( ...
                ['rkn1210 returned ye as %dx%d for %d event(s); the MATLAB ', ...
                 'convention (and what SecondOrderGravOnlyPropagator assumes) ', ...
                 'is %dx3.  rkn1210.m line 1046 does ''output.YE = [output.YE; y0]'' ', ...
                 'with y0 a column vector, so states are stacked vertically.'], ...
                size(ye, 1), size(ye, 2), numel(te), numel(te)));

            testCase.verifySize(ype, [numel(te), 3], ...
                'rkn1210 returned ype with the wrong orientation (see ye above)');
        end

        function secondOrderWrapperSurvivesMultipleEvents(testCase)
            %The RKN1210 wrapper must not crash when several events fire.
            %
            % RKN1210Integrator.integrate post-processes the results with
            %
            %     bool = t == te;
            %
            % which is an element-wise comparison between the nSamples-by-1
            % time vector and the nEvents-by-1 event time vector.  As soon
            % as a non-terminal event fires more than once, and nEvents is
            % neither 1 nor nSamples, that expression throws.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            coe = refRv2Coe(r0, v0, gmu);
            targetRadius = coe.sma;

            evtFcn = @(t, y, yp) refRadiusEventNonTerminal2ndOrder(t, y, yp, targetRadius);

            caughtError = '';
            te = [];
            ye = [];

            try
                [~, ~, ~, te, ye] = testCase.runSecondOrder([0, period], r0, v0, evtFcn);
            catch ME
                caughtError = ME.message;
            end

            testCase.assertEmpty(caughtError, sprintf( ...
                ['RKN1210Integrator.integrate threw when two non-terminal events ', ...
                 'fired: "%s"  The orbit legitimately crosses its semi-major-axis ', ...
                 'radius twice per revolution.'], caughtError));

            testCase.assertEqual(numel(te), 2, ...
                'Expected the orbit to cross its semi-major-axis radius twice');

            testCase.assertSize(ye, [2, 3], sprintf( ...
                ['With 2 events rkn1210 returned ye as %dx%d instead of 2x3, so the ', ...
                 'two event states cannot be told apart.'], size(ye, 1), size(ye, 2)));

            for(k = 1:2)
                testCase.verifyEqual(norm(ye(k, :)), targetRadius, 'AbsTol', 1e-6, ...
                    sprintf('Event %d state is not on the target radius', k));
            end
        end

        function secondOrderPropagatorEventStateHasSixColumns(testCase)
            %The shape SecondOrderGravOnlyPropagator builds from ye and ype.
            %
            % The propagator does "ye = horzcat(ye, ype)" and every consumer
            % of a propagator's event output expects nEvents-by-6, matching
            % what the first-order propagators produce.

            [r0, v0, gmu, period] = testCase.referenceProblem();

            coe = refRv2Coe(r0, v0, gmu);
            targetRadius = coe.sma;

            [~, ~, ~, te, ye, ype] = testCase.runSecondOrder([0, period], r0, v0, ...
                @(t, y, yp) refRadiusEvent2ndOrder(t, y, yp, targetRadius));

            combined = horzcat(ye, ype);

            testCase.verifySize(combined, [numel(te), 6], sprintf( ...
                ['SecondOrderGravOnlyPropagator builds its event state as ', ...
                 'horzcat(ye, ype), which here is %dx%d instead of %dx6.'], ...
                size(combined, 1), size(combined, 2), numel(te)));
        end

        function fixedStepIntegratorHonorsRequestedTimes(testCase)
            %ODE5 must return the solution at exactly the requested times.

            [r0, v0, gmu, period] = testCase.referenceProblem(); %#ok<ASGLU>

            tspan = linspace(0, period / 4, 401);

            [t, y] = testCase.runFirstOrder('ODE5', tspan, [r0; v0]);

            testCase.verifyEqual(numel(t), numel(tspan), ...
                'ODE5 did not return one sample per requested time');
            testCase.verifyVectorEqual(t(:), tspan(:), 1e-9, ...
                'ODE5 returned samples at times other than those requested');
            testCase.verifyEqual(size(y, 1), numel(tspan), ...
                'ODE5 state history length does not match the requested times');
        end

        %% Integrator options

        function builtInOptionsExposeConfiguredTolerances(testCase)
            %With default MaxStep the configured tolerances must come through.

            options = BuiltInIntegratorOptions();
            options.AbsTol = 1e-9;
            options.RelTol = 1e-10;

            odeOptions = options.getIntegratorOptions();

            testCase.verifyEqual(odeget(odeOptions, 'AbsTol'), 1e-9, ...
                'AbsTol did not survive getIntegratorOptions');
            testCase.verifyEqual(odeget(odeOptions, 'RelTol'), 1e-10, ...
                'RelTol did not survive getIntegratorOptions');
        end

        function builtInOptionsRetainTolerancesWithFiniteMaxStep(testCase)
            %Setting MaxStep must not discard the other options.
            %
            % BuiltInIntegratorOptions.getIntegratorOptions does
            %
            %     options = odeset('AbsTol',..., 'RelTol',..., ...);
            %     if(isfinite(obj.MaxStep))
            %         options = odeset('MaxStep', obj.MaxStep);
            %     end
            %
            % The second call replaces the struct instead of adding to it,
            % so a finite MaxStep silently throws away AbsTol, RelTol,
            % NormControl, Refine and InitialStep.  The fix is
            % odeset(options, 'MaxStep', obj.MaxStep).

            options = BuiltInIntegratorOptions();
            options.AbsTol  = 1e-9;
            options.RelTol  = 1e-10;
            options.Refine  = 3;
            options.MaxStep = 60;

            odeOptions = options.getIntegratorOptions();

            testCase.verifyEqual(odeget(odeOptions, 'MaxStep'), 60, ...
                'MaxStep was not applied');

            testCase.verifyEqual(odeget(odeOptions, 'AbsTol'), 1e-9, ...
                ['AbsTol was discarded because MaxStep is finite.  Any user who ', ...
                 'sets a maximum step size silently falls back to the MATLAB ', ...
                 'default tolerance of 1e-6.']);

            testCase.verifyEqual(odeget(odeOptions, 'RelTol'), 1e-10, ...
                ['RelTol was discarded because MaxStep is finite.  Any user who ', ...
                 'sets a maximum step size silently falls back to the MATLAB ', ...
                 'default tolerance of 1e-3 -- seven orders of magnitude looser ', ...
                 'than the configured value.']);

            testCase.verifyEqual(odeget(odeOptions, 'Refine'), 3, ...
                'Refine was discarded because MaxStep is finite');
        end

        function finiteMaxStepDoesNotDegradeAccuracy(testCase)
            %End-to-end consequence of the option-merging bug.
            %
            % Capping the step size can only give the solver *more* work to
            % do, so the answer must not get worse.
            %
            % The cap used here is the orbital period, which is longer than
            % any step ode45 would take anyway, so it should be a no-op.
            % A small cap would mask the defect: forcing many tiny steps
            % recovers the accuracy that the dropped tolerances gave away.

            [r0, v0, gmu, period] = testCase.referenceProblem();
            dt = period / 2;

            [rExpected, ~] = refKeplerPropagate(r0, v0, gmu, dt);

            odefun = testCase.twoBodyOdeFunction();

            looseOptions = BuiltInIntegratorOptions();
            looseOptions.AbsTol = 1e-10;
            looseOptions.RelTol = 1e-10;

            cappedOptions = BuiltInIntegratorOptions();
            cappedOptions.AbsTol  = 1e-10;
            cappedOptions.RelTol  = 1e-10;
            cappedOptions.MaxStep = period;

            [~, yUncapped] = ODE45Integrator(looseOptions).integrate( ...
                odefun, [0, dt], [r0; v0], @refNeverEvent, []);
            [~, yCapped] = ODE45Integrator(cappedOptions).integrate( ...
                odefun, [0, dt], [r0; v0], @refNeverEvent, []);

            errUncapped = norm(yUncapped(end, 1:3).' - rExpected);
            errCapped   = norm(yCapped(end, 1:3).' - rExpected);

            testCase.verifyLessThan(errCapped, max(10 * errUncapped, 1e-6), sprintf( ...
                ['Setting a non-binding MaxStep made the answer %.3g times worse ', ...
                 '(%.3g km vs %.3g km after half an orbit).  Restricting the step ', ...
                 'size cannot legitimately reduce accuracy; the configured ', ...
                 'tolerances are being dropped.'], ...
                errCapped / errUncapped, errCapped, errUncapped));
        end

        function builtInOptionsNormControlIsOnOffString(testCase)
            %odeset expects NormControl as 'on'/'off', not a logical.

            options = BuiltInIntegratorOptions();
            options.NormControl = true;

            odeOptions = options.getIntegratorOptions();

            testCase.verifyTrue(strcmpi(string(odeget(odeOptions, 'NormControl')), "on"), ...
                'NormControl = true was not translated to "on"');

            options.NormControl = false;
            odeOptions = options.getIntegratorOptions();

            testCase.verifyTrue(strcmpi(string(odeget(odeOptions, 'NormControl')), "off"), ...
                'NormControl = false was not translated to "off"');
        end

        function fixedStepOptionsReportStepSize(testCase)
            %The fixed step options object must round-trip its step size.

            options = FixedStepSizeIntegratorOptions();
            options.setIntegratorStepSize(2.5);

            testCase.verifyEqual(options.getIntegratorStepSize(), 2.5, ...
                'Fixed step size was not stored');

            [~, stepFromOptions] = options.getIntegratorOptions();
            testCase.verifyEqual(stepFromOptions, 2.5, ...
                'getIntegratorOptions reported a different step size');
        end

        function fixedStepOptionsRejectNonPositiveStep(testCase)
            %A non-positive step must be refused, leaving the old value.

            options = FixedStepSizeIntegratorOptions();
            options.setIntegratorStepSize(4);

            testCase.verifyWarning(@() options.setIntegratorStepSize(0), '', ...
                'Setting a zero step size did not warn');

            testCase.verifyEqual(options.getIntegratorStepSize(), 4, ...
                'A rejected step size still overwrote the stored value');
        end

        %% Enum plumbing

        function integratorEnumBuildsMatchingObject(testCase)
            %Every enum member must build an object reporting that same enum.

            [~, allEnums] = IntegratorEnum.getListBoxStrs(true, true);

            for(i = 1:numel(allEnums))
                obj = IntegratorEnum.getIntegratorObjFromEnum(allEnums(i));

                testCase.verifyEqual(obj.integratorEnum, allEnums(i), sprintf( ...
                    'getIntegratorObjFromEnum(%s) returned an object reporting %s', ...
                    allEnums(i).nameStr, obj.integratorEnum.nameStr));

                % SecondOrderGravOnlyPropagator dispatches on this exact
                % test, so the enum flag and the class must agree.  Note
                % that ODE5Integrator descends from AbstractFixedStepIntegrator
                % rather than AbstractFirstOrderIntegrator, so the converse
                % check would not hold; nothing in the codebase relies on it.
                if(allEnums(i).isSecondOrder)
                    testCase.verifyTrue(isa(obj, 'AbstractSecondOrderIntegrator'), sprintf( ...
                        '%s is flagged second order but is not an AbstractSecondOrderIntegrator', ...
                        allEnums(i).nameStr));
                else
                    testCase.verifyFalse(isa(obj, 'AbstractSecondOrderIntegrator'), sprintf( ...
                        ['%s is flagged first order but is an AbstractSecondOrderIntegrator, ', ...
                         'so SecondOrderGravOnlyPropagator would accept it'], ...
                        allEnums(i).nameStr));
                end

                testCase.verifyTrue(isa(obj, 'AbstractIntegrator'), sprintf( ...
                    '%s is not an AbstractIntegrator', allEnums(i).nameStr));
            end
        end

        function integratorEnumLookupIsCaseInsensitive(testCase)
            %getIndOfListboxStr must find every integrator by name.

            [names, allEnums] = IntegratorEnum.getListBoxStrs(true, true);

            for(i = 1:numel(names))
                [ind, found] = IntegratorEnum.getIndOfListboxStr(lower(names{i}), true, true);

                testCase.verifyGreaterThan(ind, 0, sprintf( ...
                    'Integrator "%s" could not be found by lowercase name', names{i}));
                testCase.verifyEqual(found, allEnums(i), sprintf( ...
                    'Name lookup for "%s" returned the wrong enum', names{i}));
            end
        end

        function firstOrderFilterExcludesSecondOrderIntegrators(testCase)
            %The listbox filter must respect the order flags.

            [firstOnly, ~]  = IntegratorEnum.getListBoxStrs(true, false);
            [secondOnly, ~] = IntegratorEnum.getListBoxStrs(false, true);

            testCase.verifyFalse(any(strcmpi(firstOnly, 'RKN1210')), ...
                'RKN1210 appeared in the first-order-only integrator list');
            testCase.verifyTrue(any(strcmpi(secondOnly, 'RKN1210')), ...
                'RKN1210 is missing from the second-order integrator list');
            testCase.verifyEmpty(intersect(firstOnly, secondOnly), ...
                'An integrator is listed as both first and second order');
        end
    end

    methods(Access=private)

        function [r0, v0, gmu, period] = referenceProblem(testCase)
            %referenceProblem The common two-body test case.

            r0  = testCase.RVect0;
            v0  = testCase.VVect0;
            gmu = testCase.Gmu;

            coe    = refRv2Coe(r0, v0, gmu);
            period = 2 * pi * sqrt(coe.sma^3 / gmu);
        end

        function odefun = twoBodyOdeFunction(testCase)
            %twoBodyOdeFunction First-order point-mass gravity derivative.

            gmu = testCase.Gmu;
            odefun = @(t, y) [y(4:6); -gmu * y(1:3) / norm(y(1:3))^3];
        end

        function accfun = twoBodyAccelFunction(testCase)
            %twoBodyAccelFunction Second-order form: acceleration from position.

            gmu = testCase.Gmu;
            accfun = @(t, y) -gmu * y(1:3) / norm(y(1:3))^3;
        end

        function [t, y, te, ye, ie] = runFirstOrder(testCase, name, tspan, y0, evtFcn)
            %runFirstOrder Drives a first-order integrator by enum name.

            if(nargin < 5 || isempty(evtFcn))
                evtFcn = @refNeverEvent;
            end

            [~, enumValue] = IntegratorEnum.getIndOfListboxStr(name, true, true);
            integrator = IntegratorEnum.getIntegratorObjFromEnum(enumValue);

            % Fixed step integrators need an explicit vector of step times.
            if(enumValue == IntegratorEnum.ODE5 && numel(tspan) == 2)
                stepSize = integrator.getOptions().getIntegratorStepSize();
                nSteps   = ceil(abs(tspan(2) - tspan(1)) / stepSize) + 1;
                tspan    = linspace(tspan(1), tspan(2), nSteps);
            end

            [t, y, te, ye, ie] = integrator.integrate( ...
                testCase.twoBodyOdeFunction(), tspan, y0, evtFcn, []);
        end

        function [t, y, yp, te, ye, ype, ie] = runSecondOrder(testCase, tspan, y0, yp0, evtFcn)
            %runSecondOrder Drives RKN1210.

            if(nargin < 5 || isempty(evtFcn))
                evtFcn = @refNeverEvent2ndOrder;
            end

            integrator = RKN1210Integrator();

            [t, y, yp, te, ye, ype, ie] = integrator.integrate( ...
                testCase.twoBodyAccelFunction(), tspan, y0, yp0, evtFcn, []);
        end
    end

    methods(Static, Access=private)

        function tol = positionTolerance(name)
            %positionTolerance Per-method position bound, in km.
            %
            % Roughly 20x the error each method actually achieves on the
            % reference problem at its default 1e-7 tolerances.

            tolerances = struct('ODE45', 5e-2, 'ODE113', 2e-2, 'ODE78', 1e-4, ...
                                'ODE89', 1e-4, 'ODE23', 5e-2, 'ODE15s', 2, ...
                                'ODE23s', 5, 'ODE5', 1e-8);
            tol = tolerances.(name);
        end

        function tol = energyTolerance(name)
            %energyTolerance Per-method relative drift bound over three orbits.

            tolerances = struct('ODE45', 1e-5, 'ODE113', 1e-5, 'ODE78', 1e-6, ...
                                'ODE89', 1e-7, 'ODE23', 1e-4, 'ODE15s', 1e-4, ...
                                'ODE23s', 1e-4, 'ODE5', 1e-11);
            tol = tolerances.(name);
        end

        function tol = reversalTolerance(name)
            %reversalTolerance Per-method forward/backward closure bound, in km.

            tolerances = struct('ODE45', 1, 'ODE113', 1, 'ODE78', 5e-2, ...
                                'ODE89', 5e-2, 'ODE23', 5, 'ODE15s', 10, ...
                                'ODE23s', 5, 'ODE5', 1e-6);
            tol = tolerances.(name);
        end
    end
end
