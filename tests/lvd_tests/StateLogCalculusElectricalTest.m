classdef StateLogCalculusElectricalTest < KsptotTestCase
    %StateLogCalculusElectricalTest Covers two state-log side features that
    %are easy to break and hard to notice: the calculus (integral /
    %derivative of a dependent variable) states and the electrical power
    %storage charge rate kernel.
    %
    % PART 1 -- CALCULUS DEPENDENT VARIABLES
    % --------------------------------------
    % AbstractLaunchVehicleCalculusState.createDataFromStates() samples a
    % dependent variable task string once per state log entry, de-duplicates
    % the sample times, and builds
    %
    %     griddedInterpolant(times, values, 'makima', 'none')
    %
    % LaunchVehicleIntegralCalcState then evaluates
    %
    %     integral(@(x) gridInterp(x), initialTime, t) + constant
    %
    % (adaptive Gauss-Kronrod -- NOT a trapezoidal sum over the samples), and
    % LaunchVehicleDerivativeCalcState evaluates derivest() with a central
    % stencil, falling back to forward and then backward differences when the
    % central stencil runs off the end of the interpolant's support.
    %
    % Oracle strategy: the fixtures drive the "Altitude" dependent variable
    % along an *exactly linear* (or constant) time history.  makima
    % reproduces linear data exactly, so the interpolant equals the analytic
    % function everywhere on its support and the integral and derivative both
    % have exact closed forms that this file computes by hand.  Position
    % vectors are placed along the x axis so that norm(position) is exactly
    % (radius + altitude) with no unit-vector round off, making the sampled
    % altitudes exactly representable.  A quadratic history was tried first;
    % makima cannot reproduce it exactly, so the residual interpolation error
    % (about 0.2 absolute on an integral of order 7e4, and 0.018 on the
    % endpoint derivative) would have forced tolerances so loose that the
    % test could no longer distinguish a correct implementation from a
    % subtly wrong one.  Linear data keeps the tolerances at 1e-8/1e-9 and is
    % therefore the stronger test.
    %
    % PART 2 -- ELECTRICAL POWER
    % --------------------------
    % LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks()
    % sums the instantaneous rates of every active source and sink on every
    % active stage into a single signed cumulative rate (sinks carry negative
    % pwrRate, so there is one signed axis rather than separate charge and
    % discharge terms) and divides that rate evenly among the storage units
    % that are still able to accept it.  Units throughout are EC and EC/s,
    % and state of charge is an absolute EC quantity (not a fraction and not
    % joules or watt-hours), so a rate of r EC/s applied for D seconds is a
    % change of r*D EC.  Clamping is implemented by *excluding* a storage
    % unit from the split (its rate becomes exactly zero) rather than by
    % limiting the rate.

    properties(Constant)
        %Kerbin radius is 600 km in the stock system; the fixtures below only
        %need the value the body data actually reports, so it is read from
        %the body rather than hard coded.  Tolerances:
        INTEGRAL_ABS_TOL   = 1e-8;
        DERIVATIVE_ABS_TOL = 1e-9;
        EC_ABS_TOL         = 1e-12;
    end

    properties(TestParameter)
        caseName = { ...
            ... % Part 1: calculus dependent variables
            'IntegralOfConstantDepVar', ...
            'IntegralOfLinearDepVar', ...
            'IntegralAtInitialTimeIsZero', ...
            'IntegralWithNonZeroStartTime', ...
            'DerivativeOfConstantDepVar', ...
            'DerivativeOfLinearDepVar', ...
            'DerivativeOutsideDataRangeIsNaN', ...
            'IntegralOutsideDataRangeErrors', ...
            'DuplicateSampleTimesAreCollapsed', ...
            ... % Part 2: electrical power
            'NetPositiveChargeRate', ...
            'NetNegativeChargeRate', ...
            'ZeroNetGivesZeroRate', ...
            'FullBatteryClampsPositiveNet', ...
            'EmptyBatteryClampsNegativeNet', ...
            'NetSplitEvenlyAcrossBatteries', ...
            'FullBatteryExcludedFromSplit', ...
            'InactiveSourceExcluded', ...
            'SoCChangeOverFixedDurationUnclamped', ...
            'SoCClampsAtMaxOverFixedDuration', ...
            'SoCClampsAtZeroOverFixedDuration', ...
            'RtgHalfLifeDecayIntegratesToClosedForm', ...
        };
    end

    methods(Test)
        function stateLogCalculusAndElectricalMatchIndependentOracle(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    %% ===================================================================
    %  Part 1: calculus dependent variables
    %  ===================================================================
    methods(Access=private)
        function checkIntegralOfConstantDepVar(testCase)
            %A constant altitude c integrates to c*(t - t0) exactly.
            altConst = 350;
            t0 = 0;
            dt = 25;
            n  = 9;

            [intState, ~] = testCase.buildCalculusStates(t0, dt, n, altConst, 0);

            for(evalTime = [t0, t0+33, t0+100, t0+(n-1)*dt]) %#ok<*NO4LP>
                expected = altConst * (evalTime - t0);
                testCase.verifyEqual(intState.getValueAtTime(evalTime), expected, ...
                    'AbsTol', testCase.INTEGRAL_ABS_TOL, ...
                    sprintf('integral of a constant must be c*(t-t0) (t = %g)', evalTime));
            end
        end

        function checkIntegralOfLinearDepVar(testCase)
            %alt(s) = a0 + a1*s with s = t - t0 integrates to
            %  a0*s + a1*s^2/2
            %exactly, because makima reproduces linear data exactly.
            a0 = 200;
            a1 = 1.5;
            t0 = 0;
            dt = 10;
            n  = 21;

            [intState, ~] = testCase.buildCalculusStates(t0, dt, n, a0, a1);

            %Evaluate both on and between sample points; an implementation
            %that summed the samples trapezoidally instead of integrating the
            %interpolant would still pass on-node but drift off-node, so the
            %off-node points (77, 123.4) matter.
            for(evalTime = [t0+15, t0+77, t0+123.4, t0+(n-1)*dt])
                s = evalTime - t0;
                expected = a0*s + a1*s^2/2;

                testCase.verifyEqual(intState.getValueAtTime(evalTime), expected, ...
                    'AbsTol', testCase.INTEGRAL_ABS_TOL, ...
                    sprintf('integral of a0 + a1*s must be a0*s + a1*s^2/2 (t = %g)', evalTime));
            end
        end

        function checkIntegralAtInitialTimeIsZero(testCase)
            %The integral state records initialTime = min(sample times) and a
            %constant of integration.  The constant is evaluated as
            %  constant = getValueAtTime(initialTime)
            %*before* the constant itself has been assigned, so it always
            %works out to zero; the observable contract is therefore that the
            %integral is exactly zero at the first sample time.
            a0 = 200;
            a1 = 1.5;
            t0 = 0;
            dt = 10;
            n  = 11;

            [intState, ~] = testCase.buildCalculusStates(t0, dt, n, a0, a1);

            testCase.verifyEqual(intState.initialTime, t0, 'AbsTol', 1e-12, ...
                'initialTime must be the earliest sample time');
            testCase.verifyEqual(intState.constant, 0, 'AbsTol', 1e-12, ...
                'the constant of integration evaluates to zero by construction');
            testCase.verifyEqual(intState.getValueAtTime(t0), 0, 'AbsTol', 1e-12, ...
                'the integral must be exactly zero at its lower limit');
        end

        function checkIntegralWithNonZeroStartTime(testCase)
            %The lower limit follows the data, not the epoch: with samples
            %starting at t0 = 1000 s the integral is measured from 1000 s.
            a0 = 120;
            a1 = -0.8;
            t0 = 1000;
            dt = 10;
            n  = 11;

            [intState, ~] = testCase.buildCalculusStates(t0, dt, n, a0, a1);

            testCase.verifyEqual(intState.initialTime, t0, 'AbsTol', 1e-12, ...
                'initialTime must track the sample times, not zero');

            for(evalTime = [t0, t0+37, t0+(n-1)*dt])
                s = evalTime - t0;
                expected = a0*s + a1*s^2/2;

                testCase.verifyEqual(intState.getValueAtTime(evalTime), expected, ...
                    'AbsTol', testCase.INTEGRAL_ABS_TOL, ...
                    sprintf('integral from a non-zero start time (t = %g)', evalTime));
            end
        end

        function checkDerivativeOfConstantDepVar(testCase)
            %d/dt of a constant is zero everywhere, including at the two
            %endpoints where derivest() has to fall back from the central
            %stencil to a one sided one.
            [~, derivState] = testCase.buildCalculusStates(0, 25, 9, 350, 0);

            for(evalTime = [0, 33, 100, 200])
                testCase.verifyEqual(derivState.getValueAtTime(evalTime), 0, ...
                    'AbsTol', testCase.DERIVATIVE_ABS_TOL, ...
                    sprintf('derivative of a constant must be zero (t = %g)', evalTime));
            end
        end

        function checkDerivativeOfLinearDepVar(testCase)
            %d/dt of a0 + a1*s is a1 everywhere.  Both endpoints are included
            %deliberately: at t0 the central stencil steps off the left edge
            %of the interpolant support and returns NaN, so the forward
            %difference fallback has to fire, and symmetrically at tEnd the
            %backward fallback has to fire.  A regression that dropped either
            %fallback would return NaN here.
            a0 = 200;
            a1 = 1.5;
            t0 = 0;
            dt = 10;
            n  = 21;
            tEnd = t0 + (n-1)*dt;

            [~, derivState] = testCase.buildCalculusStates(t0, dt, n, a0, a1);

            for(evalTime = [t0, t0+15, t0+77, t0+123.4, tEnd])
                actual = derivState.getValueAtTime(evalTime);

                testCase.verifyFalse(isnan(actual), ...
                    sprintf('derivative must not be NaN inside the data range (t = %g)', evalTime));
                testCase.verifyEqual(actual, a1, 'AbsTol', testCase.DERIVATIVE_ABS_TOL, ...
                    sprintf('derivative of a0 + a1*s must be a1 (t = %g)', evalTime));
            end
        end

        function checkDerivativeOutsideDataRangeIsNaN(testCase)
            %The interpolant is built with extrapolation method 'none', so
            %every stencil point outside the sampled span is NaN and all
            %three fallbacks fail.  Returning NaN (rather than silently
            %extrapolating) is the contract.
            t0 = 1000;
            dt = 10;
            n  = 11;
            tEnd = t0 + (n-1)*dt;

            [~, derivState] = testCase.buildCalculusStates(t0, dt, n, 120, -0.8);

            testCase.verifyTrue(isnan(derivState.getValueAtTime(tEnd + 200)), ...
                'derivative past the end of the data must be NaN');
            testCase.verifyTrue(isnan(derivState.getValueAtTime(t0 - 200)), ...
                'derivative before the start of the data must be NaN');
        end

        function checkIntegralOutsideDataRangeErrors(testCase)
            %Integrating past the end of the data drives the integrand to NaN
            %and the integral state raises rather than returning garbage.
            %Note the error is raised with error('...') and therefore has an
            %EMPTY identifier, so the message is the only thing to match on.
            t0 = 1000;
            dt = 10;
            n  = 11;
            tEnd = t0 + (n-1)*dt;

            [intState, ~] = testCase.buildCalculusStates(t0, dt, n, 120, -0.8);

            caughtError = [];
            warnState = warning('off', 'MATLAB:integral:NonFiniteValue');
            cleanup = onCleanup(@() warning(warnState)); %#ok<NASGU>
            try
                intState.getValueAtTime(tEnd + 200);
            catch ME
                caughtError = ME;
            end

            testCase.verifyNotEmpty(caughtError, ...
                'integrating outside the sampled span must raise an error');
            testCase.verifySubstring(caughtError.message, 'Integral value is NaN', ...
                'the NaN integral error message must name the failure mode');
        end

        function checkDuplicateSampleTimesAreCollapsed(testCase)
            %griddedInterpolant requires strictly increasing sample points,
            %so createDataFromStates() de-duplicates the times with unique()
            %and keeps the FIRST value at each repeated time.  Repeated times
            %occur routinely in real state logs (an event boundary logs the
            %same UT twice), so this is not a synthetic concern.
            [~, template] = testCase.buildCalculusTemplate();

            sampleTimes = [0, 10, 10, 20, 30];
            entries = LaunchVehicleStateLogEntry.empty(1,0);
            for(i = 1:numel(sampleTimes))
                entries(i) = testCase.makeEntry(template, sampleTimes(i), 100 + 2*sampleTimes(i));
            end

            derivState = entries(1).calcObjStates(2);
            derivState.createDataFromStates(entries);

            testCase.verifyEqual(derivState.gridInterp.GridVectors{1}(:)', [0, 10, 20, 30], ...
                'AbsTol', 1e-12, 'duplicate sample times must collapse to a strictly increasing grid');
            testCase.verifyEqual(derivState.gridInterp.Values(:)', [100, 120, 140, 160], ...
                'AbsTol', 1e-9, 'the surviving values must be the altitudes at the unique times');

            %The de-duplicated series is still exactly linear with slope 2
            %km/s, so the derivative oracle is still exact.
            testCase.verifyEqual(derivState.getValueAtTime(15), 2, ...
                'AbsTol', testCase.DERIVATIVE_ABS_TOL, ...
                'de-duplication must not disturb the slope of the data');
        end

        %% ---------------------------------------------------------------
        %  Part 1 fixture helpers
        %  ---------------------------------------------------------------
        function [lvdData, template] = buildCalculusTemplate(testCase)
            %buildCalculusTemplate Stock vehicle carrying one integral and one
            %derivative calculus variable, both on the 'Altitude' dependent
            %variable in Kerbin's body centered inertial frame.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            frame = testCase.kerbin.getBodyCenteredInertialFrame();

            intCalc = LaunchVehicleIntegralCalc(lvdData);
            intCalc.frame = frame;
            intCalc.quantStr = 'Altitude';
            lvdData.launchVehicle.addCalculusCalcObj(intCalc);

            derivCalc = LaunchVehicleDerivativeCalc(lvdData);
            derivCalc.frame = frame;
            derivCalc.quantStr = 'Altitude';
            lvdData.launchVehicle.addCalculusCalcObj(derivCalc);

            template = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function entry = makeEntry(~, template, time, altitudeKm)
            %makeEntry One synthetic state log entry at a prescribed time and
            %altitude.
            %
            % The position is placed on the +x axis so norm(position) is
            % exactly (radius + altitude) in floating point -- an arbitrary
            % unit vector introduces about 1e-12 km of round off in the
            % sampled altitudes, which would leak straight into the oracle.
            entry = template.deepCopy();
            entry.time = time;
            entry.position = [template.centralBody.radius + altitudeKm; 0; 0];
            entry.velocity = [0; 0; 0.001];
        end

        function [intState, derivState] = buildCalculusStates(testCase, t0, dt, n, a0, a1)
            %buildCalculusStates Builds n synthetic entries whose altitude is
            %exactly a0 + a1*(t - t0) km, then populates the integral and
            %derivative calculus states from them.
            [~, template] = testCase.buildCalculusTemplate();

            entries = LaunchVehicleStateLogEntry.empty(1,0);
            for(i = 1:n)
                s = (i-1)*dt;
                entries(i) = testCase.makeEntry(template, t0 + s, a0 + a1*s);
            end

            intState   = entries(1).calcObjStates(1);
            derivState = entries(1).calcObjStates(2);

            testCase.assertClass(intState, 'LaunchVehicleIntegralCalcState', ...
                'first calculus state must be the integral');
            testCase.assertClass(derivState, 'LaunchVehicleDerivativeCalcState', ...
                'second calculus state must be the derivative');

            intState.createDataFromStates(entries);
            derivState.createDataFromStates(entries);
        end
    end

    %% ===================================================================
    %  Part 2: electrical power
    %  ===================================================================
    methods(Access=private)
        function checkNetPositiveChargeRate(testCase)
            %RTG supplying +5 EC/s against a -2 EC/s sink nets +3 EC/s into
            %the single battery.
            entry = testCase.buildEpsFixture(5, 0, -2, [100, 50]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(numel(rates), 1, 'fixture has exactly one battery');
            testCase.verifyEqual(rates(1), 3, 'AbsTol', testCase.EC_ABS_TOL, ...
                'net rate must be the signed sum of the source and sink rates');
        end

        function checkNetNegativeChargeRate(testCase)
            %RTG supplying +1 EC/s against a -4 EC/s sink nets -3 EC/s, i.e.
            %the battery drains.
            entry = testCase.buildEpsFixture(1, 0, -4, [100, 50]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), -3, 'AbsTol', testCase.EC_ABS_TOL, ...
                'a sink larger than the source must drain the battery');
        end

        function checkZeroNetGivesZeroRate(testCase)
            %Exactly balanced source and sink: the production code short
            %circuits on cumPwrRate ~= 0 and leaves the rates at zero.
            entry = testCase.buildEpsFixture(3, 0, -3, [100, 50]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), 0, ...
                'a balanced power budget must give exactly zero charge rate');
        end

        function checkFullBatteryClampsPositiveNet(testCase)
            %A battery at maximum capacity cannot accept charge, so with a
            %net positive budget and nowhere to put it the rate is zero.
            entry = testCase.buildEpsFixture(5, 0, -2, [100, 100]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), 0, ...
                'a full battery must clamp a positive net rate to exactly zero');
        end

        function checkEmptyBatteryClampsNegativeNet(testCase)
            %Symmetric case: an empty battery cannot supply any more charge.
            entry = testCase.buildEpsFixture(1, 0, -4, [100, 0]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), 0, ...
                'an empty battery must clamp a negative net rate to exactly zero');
        end

        function checkNetSplitEvenlyAcrossBatteries(testCase)
            %+8 source, -2 sink = +6 EC/s split evenly across two eligible
            %batteries regardless of their individual states of charge.
            entry = testCase.buildEpsFixture(8, 0, -2, [100, 50; 100, 20]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(numel(rates), 2, 'fixture has two batteries');
            testCase.verifyEqual(rates(1), 3, 'AbsTol', testCase.EC_ABS_TOL, ...
                'the net rate must be split evenly, not weighted by state of charge');
            testCase.verifyEqual(rates(2), 3, 'AbsTol', testCase.EC_ABS_TOL, ...
                'the net rate must be split evenly, not weighted by state of charge');
            testCase.verifyEqual(sum(rates), 6, 'AbsTol', testCase.EC_ABS_TOL, ...
                'the split must conserve the total power budget');
        end

        function checkFullBatteryExcludedFromSplit(testCase)
            %With one of the two batteries full, the whole +6 EC/s goes to the
            %battery that can still take it -- the ineligible unit is dropped
            %from the denominator, it does not merely receive zero of a half
            %share.
            entry = testCase.buildEpsFixture(8, 0, -2, [100, 100; 100, 20]);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), 0, ...
                'the full battery must receive exactly zero');
            testCase.verifyEqual(rates(2), 6, 'AbsTol', testCase.EC_ABS_TOL, ...
                'the remaining battery must absorb the entire net rate');
            testCase.verifyEqual(sum(rates), 6, 'AbsTol', testCase.EC_ABS_TOL, ...
                'clamping must not destroy power that another unit can accept');
        end

        function checkInactiveSourceExcluded(testCase)
            %Deactivating the RTG state leaves only the -2 EC/s sink.
            entry = testCase.buildEpsFixture(5, 0, -2, [100, 50]);
            entry.stageStates(1).powerSrcStates(1).setActiveState(false);

            rates = testCase.chargeRatesAt(entry, 0);

            testCase.verifyEqual(rates(1), -2, 'AbsTol', testCase.EC_ABS_TOL, ...
                'an inactive source must not contribute to the power budget');
        end

        function checkSoCChangeOverFixedDurationUnclamped(testCase)
            %State of charge is an absolute EC quantity, so a constant net
            %rate r held for D seconds changes it by exactly r*D EC.
            %
            % The rate here is independent of time (no half life) and, while
            % the battery stays strictly between empty and full, independent
            % of the state of charge as well.  This test establishes that
            % invariance across the whole traversed range and then applies the
            % closed form.
            maxCap = 100;
            soc0   = 20;
            netRate = 3;    % = (+5 source) + (-2 sink)
            duration = 20;

            entry = testCase.buildEpsFixture(5, 0, -2, [maxCap, soc0]);
            battery = entry.getAllActivePwrStorageStates();

            expectedFinalSoC = soc0 + netRate*duration;   % 80 EC, below maxCap
            testCase.assertLessThan(expectedFinalSoC, maxCap, ...
                'fixture must not clamp during the window');

            %Sample the rate across the SoC range the battery traverses.
            for(soc = linspace(soc0, expectedFinalSoC, 9))
                battery.setStateOfCharge(soc);
                rates = testCase.chargeRatesAt(entry, 0);

                testCase.verifyEqual(rates(1), netRate, 'AbsTol', testCase.EC_ABS_TOL, ...
                    sprintf('rate must stay constant while unclamped (soc = %g EC)', soc));
            end

            %With a constant rate the closed form integral is exact.
            battery.setStateOfCharge(soc0);
            testCase.verifyEqual(soc0 + testCase.chargeRatesAt(entry, 0)*duration, expectedFinalSoC, ...
                'AbsTol', testCase.EC_ABS_TOL, ...
                'SoC change over a fixed duration must equal rate * duration');
        end

        function checkSoCClampsAtMaxOverFixedDuration(testCase)
            %Charging a nearly full battery: the closed form is
            %  SoC(t) = min(soc0 + r*t, maxCapacity)
            %with the corner at tClamp = (maxCapacity - soc0)/r.  Verify the
            %rate on both sides of that corner and the resulting final SoC.
            maxCap   = 100;
            soc0     = 90;
            netRate  = 3;
            duration = 20;

            tClamp = (maxCap - soc0)/netRate;   % 10/3 s
            testCase.assertLessThan(tClamp, duration, 'the clamp must occur inside the window');

            entry = testCase.buildEpsFixture(5, 0, -2, [maxCap, soc0]);
            battery = entry.getAllActivePwrStorageStates();

            %Before the corner the battery charges at the full net rate.
            for(t = [0, tClamp/2, 0.999*tClamp])
                battery.setStateOfCharge(soc0 + netRate*t);
                testCase.verifyEqual(testCase.chargeRatesAt(entry, 0), netRate, ...
                    'AbsTol', testCase.EC_ABS_TOL, ...
                    sprintf('battery must charge at the full net rate before the clamp (t = %g s)', t));
            end

            %At and after the corner the rate is exactly zero, so the state of
            %charge holds at the capacity for the rest of the window.
            battery.setStateOfCharge(maxCap);
            testCase.verifyEqual(testCase.chargeRatesAt(entry, 0), 0, ...
                'the charge rate must be exactly zero once the battery is full');

            expectedFinalSoC = min(soc0 + netRate*duration, maxCap);
            testCase.verifyEqual(battery.getStateOfCharge(), expectedFinalSoC, ...
                'AbsTol', testCase.EC_ABS_TOL, ...
                'final SoC must be min(soc0 + r*D, maxCapacity)');
        end

        function checkSoCClampsAtZeroOverFixedDuration(testCase)
            %Mirror image: draining a nearly empty battery clamps at zero,
            %  SoC(t) = max(soc0 + r*t, 0),  r < 0
            %with the corner at tClamp = -soc0/r.
            maxCap   = 100;
            soc0     = 9;
            netRate  = -3;    % = (+1 source) + (-4 sink)
            duration = 20;

            tClamp = -soc0/netRate;   % 3 s
            testCase.assertLessThan(tClamp, duration, 'the clamp must occur inside the window');

            entry = testCase.buildEpsFixture(1, 0, -4, [maxCap, soc0]);
            battery = entry.getAllActivePwrStorageStates();

            for(t = [0, tClamp/2, 0.999*tClamp])
                battery.setStateOfCharge(soc0 + netRate*t);
                testCase.verifyEqual(testCase.chargeRatesAt(entry, 0), netRate, ...
                    'AbsTol', testCase.EC_ABS_TOL, ...
                    sprintf('battery must drain at the full net rate before the clamp (t = %g s)', t));
            end

            battery.setStateOfCharge(0);
            testCase.verifyEqual(testCase.chargeRatesAt(entry, 0), 0, ...
                'the discharge rate must be exactly zero once the battery is empty');

            expectedFinalSoC = max(soc0 + netRate*duration, 0);
            testCase.verifyEqual(battery.getStateOfCharge(), expectedFinalSoC, ...
                'AbsTol', testCase.EC_ABS_TOL, ...
                'final SoC must be max(soc0 + r*D, 0)');
        end

        function checkRtgHalfLifeDecayIntegratesToClosedForm(testCase)
            %An RTG with a half life decays as
            %  P(t) = P0 * 2^(-(t - t0)/T)
            %so the charge accumulated over [t0, t0 + D] is
            %  dSoC = P0 * T / ln(2) * (1 - 2^(-D/T))
            %
            % The battery is deliberately enormous so nothing clamps and the
            % net rate is a pure function of time; the accumulated charge is
            % then obtained by numerically integrating the production rate
            % (with MATLAB's integral(), a general purpose quadrature that is
            % not part of the code under test) and compared with the analytic
            % closed form above.
            initRate = 10;      % EC/s at t = 0
            halfLife = 600;     % s
            duration = 1800;    % s = 3 half lives

            entry = testCase.buildEpsFixture(initRate, halfLife, 0, [1e9, 5e8]);

            %Instantaneous rates first: exact powers of two at whole half
            %lives, sqrt(1/2) at half of one.
            for(t = [0, 300, 600, 1200, 1800])
                expected = initRate * 2^(-t/halfLife);
                testCase.verifyEqual(testCase.chargeRatesAt(entry, t), expected, ...
                    'AbsTol', 1e-10, ...
                    sprintf('RTG output must halve every half life (t = %g s)', t));
            end

            %Accumulated charge over the window.
            accumulated = integral(@(tt) arrayfun(@(t1) testCase.chargeRatesAt(entry, t1), tt), ...
                                   0, duration, 'ArrayValued', false);

            expectedCharge = initRate * halfLife / log(2) * (1 - 2^(-duration/halfLife));

            testCase.verifyEqual(accumulated, expectedCharge, ...
                'RelTol', 1e-9, ...
                'accumulated EC must match P0*T/ln2*(1 - 2^(-D/T))');

            %Cross check the closed form against an elementary bound that does
            %not use it: the rate is monotonically decreasing, so the total is
            %bracketed by the rectangle rules at the two endpoints.
            testCase.verifyLessThan(accumulated, initRate*duration, ...
                'a decaying source cannot deliver more than its initial rate would');
            testCase.verifyGreaterThan(accumulated, initRate*2^(-duration/halfLife)*duration, ...
                'a decaying source must deliver more than its final rate would');
        end

        %% ---------------------------------------------------------------
        %  Part 2 fixture helpers
        %  ---------------------------------------------------------------
        function entry = buildEpsFixture(testCase, rtgRate, rtgHalfLife, sinkRate, batterySpecs)
            %buildEpsFixture Stock vehicle plus one RTG, one simple sink and
            %one battery per row of batterySpecs = [maxCapacity, initialSoC].
            %
            % Sinks are stored with a NEGATIVE pwrRate, which is why the
            % production code can simply add sources and sinks together.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);

            rtg = LaunchVehicleEpsRtg(stg);
            rtg.name = 'Test RTG';
            rtg.initPwrRate = rtgRate;
            rtg.halfLife = rtgHalfLife;
            rtg.initTime = 0;
            stg.addPwrSrc(rtg);

            sink = LaunchVehicleSimplePwrSink(stg);
            sink.name = 'Test Power Sink';
            sink.pwrRate = sinkRate;
            stg.addPwrSink(sink);

            batteries = LaunchVehicleBasicElectricalBattery.empty(1,0);
            for(i = 1:size(batterySpecs, 1))
                battery = LaunchVehicleBasicElectricalBattery(stg);
                battery.name = sprintf('Test Battery %d', i);
                battery.maxCapacity = batterySpecs(i,1);
                battery.initialStateOfCharge = batterySpecs(i,2);
                stg.addPwrStorage(battery);
                batteries(end+1) = battery; %#ok<AGROW>
            end

            %Regenerate the initial state model so it carries stage states for
            %the components just added, then attach the EPS states (the
            %default initial state factory does not create them).
            bodyInfo = LvdData.getDefaultInitialBodyInfo(testCase.celBodyData);
            lvdData.initStateModel = ...
                InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, bodyInfo);

            stgState = lvdData.initStateModel.stageStates(1);
            stgState.addPowerSrcState(rtg.createDefaultInitialState(stgState));
            stgState.addPowerSinkState(sink.createDefaultInitialState(stgState));
            for(i = 1:numel(batteries))
                stgState.addPowerStorageState(batteries(i).createDefaultInitialState(stgState));
            end

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function rates = chargeRatesAt(~, entry, ut)
            %chargeRatesAt Marshals a state log entry into the static storage
            %rate kernel, the way the ODE right hand side does.
            storageStates = entry.getAllActivePwrStorageStates();

            storageSoCs = zeros(1, numel(storageStates));
            for(i = 1:numel(storageStates))
                storageSoCs(i) = storageStates(i).getStateOfCharge();
            end

            rates = LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks( ...
                storageSoCs, storageStates, entry.stageStates, ut, ...
                entry.position, entry.velocity, entry.centralBody, entry.steeringModel);
        end
    end
end
