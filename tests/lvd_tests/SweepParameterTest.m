classdef SweepParameterTest < KsptotTestCase
    %SweepParameterTest The four kinds of thing a G1/G2 run can vary.
    %
    % The original case matrix could only sweep plugin variables because its
    % parameter class was hard typed to LvdPluginOptimVarWrapper.  The
    % generalization rests on three mechanisms, and every one of them fails
    % silently rather than loudly if it is wrong, which is why they are
    % pinned here:
    %
    %   * Rebinding by id.  A case runs against a byte-stream clone of the
    %     mission in which every handle is new, so a parameter that held a
    %     handle would write into an orphan and the case would run with the
    %     baseline value while reporting the swept one.
    %
    %   * The one-hot use mask.  updateObjWithVarValue consumes its input
    %     positionally over the ACTIVE elements only, so setting one element
    %     of an arbitrary AbstractOptimizationVariable means masking all the
    %     others off first.  Get the mask wrong and the value lands in a
    %     neighbouring element.
    %
    %   * Pinning.  A swept quantity that is still an active optimization
    %     variable is just an initial guess the optimizer throws away.
    %
    % The engine multipliers add a fourth: they must apply against a captured
    % baseline, not against the curve's present value, because an Optimize
    % mode case starts from a clone of the nearest completed case whose curve
    % has already been scaled once.

    methods(Test)

        function pluginVarParameterSetsTheValueAndDeactivatesItsBackingVariable(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            param = LvdSweepPluginVarParameter(ctx.pluginVars(2));

            testCase.verifyEqual(param.getName(), 'Beta');
            testCase.verifyEqual(param.getGroupName(), 'Plugin Variables');
            testCase.verifyEqual(param.getUnit(), '');
            testCase.verifyEqual(param.getCurrentValue(), 40, 'The parameter must read the plugin variable''s value');
            testCase.verifyTrue(param.isPinnable());

            ctx.pluginVars(2).setIfVariableIsActive(true);
            testCase.assertTrue(ctx.pluginVars(2).isVariableActive(), 'Fixture broken: the plugin variable is not active');

            testCase.verifyTrue(param.resolve(lvdData), 'A plugin variable present in the mission must resolve');
            param.applyValue(999);

            testCase.verifyEqual(ctx.pluginVars(2).value, 999, 'applyValue did not write the plugin variable''s value');
            testCase.verifyFalse(ctx.pluginVars(2).isVariableActive(), ...
                'A swept plugin variable must be deactivated, or the optimizer moves it straight back off the swept value');
            testCase.verifyEqual(param.getCurrentValue(), 999);

            %The other plugin variables must be untouched.
            testCase.verifyEqual([ctx.pluginVars([1 3]).value], [3 500], ...
                'Applying one plugin variable disturbed the others');
        end

        function optimVarParameterWritesExactlyOneElementAndRestoresTheMaskWithItPinned(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            %Element 3 of the initial state variable is Ry, which is readable
            %straight off the orbit model, so the one-hot write can be
            %checked against the property rather than against another call
            %into the same machinery.
            param = LvdSweepOptimVarParameter(ctx.initStateVar, 3, 'Initial State Ry', 'none');

            maskBefore = ctx.initStateVar.getUseTfForVariable();
            testCase.assertTrue(maskBefore(3), 'Fixture broken: element 3 should start active');
            testCase.assertTrue(maskBefore(2), 'Fixture broken: element 2 should start active');

            rBefore = lvdData.initStateModel.orbitModel.rVect;
            vBefore = lvdData.initStateModel.orbitModel.vVect;

            testCase.verifyTrue(param.resolve(lvdData));
            testCase.verifyEqual(param.getCurrentValue(), rBefore(2), 'RelTol', 1e-14, ...
                'getCurrentValue must read the element it targets');

            param.applyValue(123.5);

            rAfter = lvdData.initStateModel.orbitModel.rVect;
            vAfter = lvdData.initStateModel.orbitModel.vVect;

            testCase.verifyEqual(rAfter(2), 123.5, 'RelTol', 1e-12, ...
                'The one-hot write did not land on the element it was aimed at');
            testCase.verifyEqual(rAfter([1 3]), rBefore([1 3]), 'RelTol', 1e-14, ...
                'Writing one position element disturbed the others');
            testCase.verifyEqual(vAfter, vBefore, 'RelTol', 1e-14, ...
                'Writing a position element disturbed the velocity');

            %The mask must come back as it was, except that the swept element
            %is now pinned off.
            maskAfter = ctx.initStateVar.getUseTfForVariable();
            expectedMask = maskBefore;
            expectedMask(3) = false;

            testCase.verifyEqual(maskAfter, expectedMask, ...
                'The use mask was not restored with the swept element pinned off');
        end

        function optimVarParameterWorksOnAnUnrelatedVariableClassAndConvertsDisplayUnits(testCase)
            %"Any optimization variable" has to mean any: the steering model
            %variable shares no code with the initial state variable, and its
            %angle elements are stored in radians but shown in degrees.  A
            %user who asks to sweep a pitch rate from 0 to 90 means degrees.
            [lvdData, ctx] = testCase.sweepMission();

            param = LvdSweepOptimVarParameter(ctx.steerVar, 5, 'Event 2 Pitch Rate', 'rad');

            testCase.verifyEqual(param.getUnit(), 'deg', 'A radians element must be presented in degrees');
            testCase.verifyTrue(param.resolve(lvdData));

            pitchBefore = ctx.steerVar.varObj.pitchModel.constTerm;

            param.applyValue(30);

            testCase.verifyEqual(ctx.steerVar.varObj.pitchModel.linearTerm, deg2rad(30), 'RelTol', 1e-12, ...
                'A degrees value must be stored in radians');
            testCase.verifyEqual(ctx.steerVar.varObj.pitchModel.constTerm, pitchBefore, 'AbsTol', 1e-15, ...
                'Writing the pitch rate disturbed the pitch constant');
            testCase.verifyEqual(param.getCurrentValue(), 30, 'RelTol', 1e-12, ...
                'getCurrentValue must convert back to display units');

            mask = ctx.steerVar.getUseTfForVariable();
            testCase.verifyFalse(mask(5), 'The swept steering element must be pinned off');
            testCase.verifyTrue(mask(4), 'Pinning the swept element must not pin its neighbours');
        end

        function applyingAnOptimVarParameterClearsTheActiveVariableCaches(testCase)
            %LaunchVehicleEvent memoizes "do I have any active optimization
            %variables".  Pinning the last active element of an event's
            %variable without dropping that memo leaves the optimizer
            %believing the event still has a free variable, which is exactly
            %the state that produces a sweep whose cases all come back
            %identical.
            [lvdData, ctx] = testCase.sweepMission();

            ctx.steerVar.setUseTfForVariable([false false false, false true false, false false false, false]);

            %Warm the memo.
            testCase.assertTrue(ctx.steerEvt.hasActiveOptVars(), ...
                'Fixture broken: the steering event should start with an active variable');

            param = LvdSweepOptimVarParameter(ctx.steerVar, 5, 'Event 2 Pitch Rate', 'rad');
            testCase.verifyTrue(param.resolve(lvdData));
            param.applyValue(15);

            testCase.verifyFalse(ctx.steerEvt.hasActiveOptVars(), ...
                'The active-variable memo survived the pin: LvdOptimTableModel.clearOptimCaches was not called');
        end

        function constraintBoundParameterWritesTheRequestedBound(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            lower = LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Lower);
            upper = LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Upper);
            both  = LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Both);

            testCase.verifyEqual(lower.getGroupName(), 'Constraint Bounds');
            testCase.verifyFalse(lower.isPinnable(), ...
                'A constraint bound is not an optimization variable, so there is nothing to pin');
            testCase.verifyEqual(lower.getUnit(), 'km', 'The bound must carry the constraint''s own unit');

            testCase.verifyTrue(lower.resolve(lvdData));
            testCase.verifyTrue(upper.resolve(lvdData));
            testCase.verifyTrue(both.resolve(lvdData));

            testCase.verifyEqual(lower.getCurrentValue(), 10, 'RelTol', 1e-14);
            testCase.verifyEqual(upper.getCurrentValue(), 200, 'RelTol', 1e-14);
            testCase.verifyEqual(both.getCurrentValue(), 105, 'RelTol', 1e-14, ...
                'A two sided bound reports its midpoint as its single value');

            lower.applyValue(50);
            testCase.verifyEqual(ctx.const.lb, 50, 'RelTol', 1e-14);
            testCase.verifyEqual(ctx.const.ub, 200, 'RelTol', 1e-14, 'Setting the lower bound moved the upper one');

            upper.applyValue(400);
            testCase.verifyEqual(ctx.const.lb, 50, 'RelTol', 1e-14, 'Setting the upper bound moved the lower one');
            testCase.verifyEqual(ctx.const.ub, 400, 'RelTol', 1e-14);

            both.applyValue(75);
            testCase.verifyEqual([ctx.const.lb, ctx.const.ub], [75 75], 'RelTol', 1e-14, ...
                'Sweeping "both" must turn the constraint into an equality at the swept value');

            %The names must distinguish the three, or the results columns are
            %indistinguishable.
            testCase.verifyNotEqual(lower.getName(), upper.getName());
            testCase.verifyNotEqual(lower.getName(), both.getName());
        end

        function vehicleKnobsReadAndWriteMassAndDragTargets(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            dryMass = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, ctx.stage);
            tankMass = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankInitialMass, ctx.tank);
            tankCap = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankCapacity, ctx.tank);
            initDrag = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.InitStateDragMultiplier, ...
                                                    lvdData.initStateModel.aero.dragCoeffModel);
            evtDrag = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EventDragMultiplier, ctx.dragAction);

            params = [dryMass, tankMass, tankCap, initDrag, evtDrag];
            for(i = 1:numel(params))
                testCase.verifyEqual(params(i).getGroupName(), 'Vehicle Knobs');
                testCase.verifyTrue(params(i).resolve(lvdData), ...
                    sprintf('Knob "%s" did not resolve against the mission it came from', params(i).getName()));
            end

            testCase.verifyEqual(dryMass.getCurrentValue(), ctx.stage.dryMass, 'RelTol', 1e-14);
            dryMass.applyValue(12.5);
            testCase.verifyEqual(ctx.stage.dryMass, 12.5, 'RelTol', 1e-14, 'Stage dry mass was not written');

            tankMass.applyValue(3.25);
            testCase.verifyEqual(ctx.tank.initialMass, 3.25, 'RelTol', 1e-14, 'Tank initial mass was not written');

            tankCap.applyValue(9.75);
            testCase.verifyEqual(ctx.tank.capacity, 9.75, 'RelTol', 1e-14, 'Tank capacity was not written');

            %A negative capacity is a sampler overshoot, not a user request:
            %clamp it rather than handing the propagator a negative tank.
            tankCap.applyValue(-1);
            testCase.verifyEqual(ctx.tank.capacity, 0, 'A sampled negative tank capacity must clamp to zero');

            initDrag.applyValue(1.4);
            testCase.verifyEqual(lvdData.initStateModel.aero.dragCoeffModel.globalDragMultiplier, 1.4, 'RelTol', 1e-14, ...
                'The initial state drag multiplier was not written');
            testCase.verifyEqual(initDrag.getCurrentValue(), 1.4, 'RelTol', 1e-14);

            evtDrag.applyValue(0.6);
            testCase.verifyEqual(ctx.dragAction.dragCoeffModel.globalDragMultiplier, 0.6, 'RelTol', 1e-14, ...
                'The event drag multiplier was not written');
            testCase.verifyEqual(lvdData.initStateModel.aero.dragCoeffModel.globalDragMultiplier, 1.4, 'RelTol', 1e-14, ...
                'The event drag action and the initial state drag model must be separate targets');

            %Only the two mass knobs hang off something that could also be an
            %optimization variable, so only those two pin.
            testCase.verifyTrue(dryMass.isPinnable());
            testCase.verifyTrue(tankMass.isPinnable());
            testCase.verifyFalse(tankCap.isPinnable());
            testCase.verifyFalse(initDrag.isPinnable());
            testCase.verifyFalse(evtDrag.isPinnable());
        end

        function engineMultiplierScalesTheCurveAbsolutelyAndIsIdempotent(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            thrust = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ctx.engine);
            isp = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineIspMultiplier, ctx.engine);

            testCase.verifyTrue(thrust.knob.isMultiplier());
            testCase.verifyTrue(isp.knob.isMultiplier());
            testCase.verifyEqual(thrust.getUnit(), '', 'A multiplier is dimensionless');

            thrust.captureBaseline(lvdData);
            isp.captureBaseline(lvdData);

            baselineThrust = [ctx.engine.thrustPressCurve.elems.depVar];
            baselineIsp = [ctx.engine.ispPressCurve.elems.depVar];
            testCase.assertNotEmpty(baselineThrust, 'Fixture broken: the engine has no thrust curve');
            testCase.verifyEqual(thrust.baseline, baselineThrust, 'RelTol', 1e-14, ...
                'captureBaseline did not record the template curve');
            testCase.verifyEqual(thrust.getCurrentValue(), 1, 'RelTol', 1e-14, ...
                'An unscaled curve must report a multiplier of exactly one');

            [t0, i0] = ctx.engine.getThrustIspForPressure(0);

            thrust.applyValue(1.1);
            once = [ctx.engine.thrustPressCurve.elems.depVar];
            testCase.verifyEqual(once, 1.1*baselineThrust, 'RelTol', 1e-12, ...
                'The thrust multiplier did not scale every curve element');

            %The whole point: applying the same multiplier again must not
            %compound.  An Optimize mode case starts from a clone of the
            %nearest completed case, whose curve has already been scaled.
            thrust.applyValue(1.1);
            twice = [ctx.engine.thrustPressCurve.elems.depVar];
            testCase.verifyEqual(twice, once, 'RelTol', 1e-14, ...
                'Applying 1.1 twice compounded to 1.21: the multiplier is relative, not absolute');
            testCase.verifyEqual(thrust.getCurrentValue(), 1.1, 'RelTol', 1e-12);

            %And the scaling must actually reach the propagation chokepoint,
            %not just the stored curve elements.
            [t1, i1] = ctx.engine.getThrustIspForPressure(0);
            testCase.verifyEqual(t1, 1.1*t0, 'RelTol', 1e-12, ...
                'The scaled curve was not regenerated: getThrustIspForPressure still returns the baseline thrust');
            testCase.verifyEqual(i1, i0, 'RelTol', 1e-14, 'The thrust multiplier must not move Isp');

            %A multiplier of one must restore the baseline exactly, which is
            %what makes an unswept case identical to the template.
            thrust.applyValue(1.0);
            testCase.verifyEqual([ctx.engine.thrustPressCurve.elems.depVar], baselineThrust, 'RelTol', 1e-14, ...
                'A multiplier of one did not restore the baseline curve');

            isp.applyValue(0.9);
            [t2, i2] = ctx.engine.getThrustIspForPressure(0);
            testCase.verifyEqual(i2, 0.9*i0, 'RelTol', 1e-12, 'The Isp multiplier did not scale the Isp curve');
            testCase.verifyEqual(t2, t0, 'RelTol', 1e-12, 'The Isp multiplier must not move thrust');
            testCase.verifyEqual([ctx.engine.ispPressCurve.elems.depVar], 0.9*baselineIsp, 'RelTol', 1e-12);
        end

        function captureBaselineIsRetakenSoAnEditedCurveCannotLeaveAStaleBaseline(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            thrust = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ctx.engine);
            thrust.captureBaseline(lvdData);
            original = thrust.baseline;

            %The user edits the engine between runs.
            for(k = 1:numel(ctx.engine.thrustPressCurve.elems))
                ctx.engine.thrustPressCurve.elems(k).depVar = 2*ctx.engine.thrustPressCurve.elems(k).depVar;
            end
            ctx.engine.thrustPressCurve.generateCurve();

            thrust.captureBaseline(lvdData);
            testCase.verifyEqual(thrust.baseline, 2*original, 'RelTol', 1e-14, ...
                'A second run must re-take the baseline off the edited curve');

            thrust.applyValue(1.5);
            testCase.verifyEqual([ctx.engine.thrustPressCurve.elems.depVar], 3*original, 'RelTol', 1e-12, ...
                'The multiplier must scale the re-taken baseline, not the original one');
        end

        function everyParameterRebindsByIdAfterAByteStreamClone(testCase)
            %This is the one that matters most: a case never runs against the
            %mission the user configured.  Clone the mission the way the
            %sweep engine does, resolve the parameters into the clone, and
            %check that the writes land in the CLONE and not in the original.
            [lvdData, ctx] = testCase.sweepMission();

            params = [LvdSweepPluginVarParameter(ctx.pluginVars(1)), ...
                      LvdSweepOptimVarParameter(ctx.initStateVar, 3, 'Initial State Ry', 'none'), ...
                      LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Upper), ...
                      LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, ctx.stage), ...
                      LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ctx.engine)];

            for(i = 1:numel(params))
                params(i).captureBaseline(lvdData);
            end

            originals = struct('pluginVal',  ctx.pluginVars(1).value, ...
                               'ry',         lvdData.initStateModel.orbitModel.rVect(2), ...
                               'ub',         ctx.const.ub, ...
                               'dryMass',    ctx.stage.dryMass, ...
                               'thrust',     [ctx.engine.thrustPressCurve.elems.depVar]);

            clone = getArrayFromByteStream(getByteStreamFromArray(lvdData));
            testCase.assertNotSameHandle(clone, lvdData, 'Fixture broken: the clone is the same handle');

            values = [77, 456.5, 1234, 22.5, 1.2];
            for(i = 1:numel(params))
                testCase.verifyTrue(params(i).resolve(clone), ...
                    sprintf('"%s" did not rebind onto the cloned mission', params(i).getName()));
                params(i).applyValue(values(i));
            end

            %The clone got every value.
            [~, cloneEngines] = clone.launchVehicle.getEnginesListBoxStr();
            clonePluginVars = clone.pluginVars.getPluginVarsArray();
            testCase.verifyEqual(clonePluginVars(1).value, 77, 'RelTol', 1e-14);
            testCase.verifyEqual(clone.initStateModel.orbitModel.rVect(2), 456.5, 'RelTol', 1e-12);
            testCase.verifyEqual(clone.optimizer.constraints.consts(1).ub, 1234, 'RelTol', 1e-14);
            testCase.verifyEqual(clone.launchVehicle.stages(1).dryMass, 22.5, 'RelTol', 1e-14);
            testCase.verifyEqual([cloneEngines(1).thrustPressCurve.elems.depVar], 1.2*originals.thrust, 'RelTol', 1e-12);

            %The original got none of them.  A parameter that kept its
            %original handle would have written here instead, and the case
            %would have propagated the baseline while reporting the swept
            %value.
            testCase.verifyEqual(ctx.pluginVars(1).value, originals.pluginVal, 'RelTol', 1e-14, ...
                'Applying to the clone leaked back into the original mission');
            testCase.verifyEqual(lvdData.initStateModel.orbitModel.rVect(2), originals.ry, 'RelTol', 1e-14, ...
                'Applying to the clone leaked back into the original mission');
            testCase.verifyEqual(ctx.const.ub, originals.ub, 'RelTol', 1e-14, ...
                'Applying to the clone leaked back into the original mission');
            testCase.verifyEqual(ctx.stage.dryMass, originals.dryMass, 'RelTol', 1e-14, ...
                'Applying to the clone leaked back into the original mission');
            testCase.verifyEqual([ctx.engine.thrustPressCurve.elems.depVar], originals.thrust, 'RelTol', 1e-14, ...
                'Applying to the clone leaked back into the original mission');
        end

        function resolveReportsFalseWhenTheTargetIsGoneRatherThanErroringInAWorker(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            optimParam = LvdSweepOptimVarParameter(ctx.steerVar, 5, 'Event 2 Pitch Rate', 'rad');
            pluginParam = LvdSweepPluginVarParameter(ctx.pluginVars(3));
            constParam = LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Lower);
            knobParam = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, ctx.stage);

            testCase.assertTrue(optimParam.resolve(lvdData), 'Fixture broken: the parameter should resolve first');

            %The user deletes the variable, the plugin variable and the
            %constraint between configuring the sweep and running it.
            lvdData.optimizer.vars.removeVariable(ctx.steerVar);
            lvdData.pluginVars.removePluginVar(ctx.pluginVars(3));
            lvdData.optimizer.constraints.removeConstraint(ctx.const);

            testCase.verifyFalse(optimParam.resolve(lvdData), 'A deleted optimization variable must resolve to false');
            testCase.verifyFalse(optimParam.isResolved);
            testCase.verifyFalse(pluginParam.resolve(lvdData), 'A deleted plugin variable must resolve to false');
            testCase.verifyFalse(constParam.resolve(lvdData), 'A deleted constraint must resolve to false');

            %A parameter that lost its target reports NaN rather than the
            %stale value it used to have.
            testCase.verifyTrue(isnan(optimParam.getCurrentValue()));
            testCase.verifyTrue(isnan(pluginParam.getCurrentValue()));
            testCase.verifyTrue(isnan(constParam.getCurrentValue()));

            %And applying it errors with an identifier the run loop can catch
            %and turn into a per-case message.
            testCase.verifyError(@() optimParam.applyValue(1), 'LvdSweepParameter:unresolved');
            testCase.verifyError(@() pluginParam.applyValue(1), 'LvdSweepParameter:unresolved');
            testCase.verifyError(@() constParam.applyValue(1), 'LvdSweepParameter:unresolved');

            %A knob whose target lives in a different mission must also miss.
            other = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.verifyFalse(knobParam.resolve(other), ...
                'A stage id from another mission must not resolve');
            testCase.verifyError(@() knobParam.applyValue(1), 'LvdSweepParameter:unresolved');
        end

        function suggestedBoundsComeFromTheTargetAndFallBackToTenPercent(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            %An optimization variable already carries bounds the user set in
            %the variable table; a sweep should start from those rather than
            %inventing a window.
            ctx.steerVar.lb = -pi*ones(1,10);
            ctx.steerVar.ub =  pi*ones(1,10);

            optimParam = LvdSweepOptimVarParameter(ctx.steerVar, 5, 'Event 2 Pitch Rate', 'rad');
            testCase.verifyTrue(optimParam.resolve(lvdData));

            [lb, ub] = optimParam.getSuggestedBounds();
            testCase.verifyEqual([lb, ub], [-180, 180], 'RelTol', 1e-12, ...
                'Suggested bounds must come from the variable''s own bounds, in display units');

            %A multiplier's natural window is around one, not around a
            %fraction of itself.
            thrust = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ctx.engine);
            [lb, ub] = thrust.getSuggestedBounds();
            testCase.verifyEqual([lb, ub], [0.95, 1.05], 'RelTol', 1e-14, ...
                'An engine multiplier should be suggested as a small window around one');

            %Everything else falls back on +/- 10% of the current value.
            dryMass = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, ctx.stage);
            testCase.verifyTrue(dryMass.resolve(lvdData));
            v = dryMass.getCurrentValue();
            [lb, ub] = dryMass.getSuggestedBounds();
            testCase.verifyEqual([lb, ub], [v - 0.1*abs(v), v + 0.1*abs(v)], 'RelTol', 1e-12);

            %A current value of zero has no percentage to take, so the
            %fallback must still be a usable non-degenerate window.
            ctx.stage.dryMass = 0;
            [lb, ub] = dryMass.getSuggestedBounds();
            testCase.verifyGreaterThan(ub, lb, 'A zero valued parameter must still get a non-degenerate window');
        end

        function labelsAndUnitsAreUsableAsResultsColumnHeaders(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            withUnit = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, ctx.stage);
            testCase.verifyEqual(withUnit.getUnit(), 'mT');
            testCase.verifyEqual(withUnit.getFullLabel(), sprintf('%s (mT)', withUnit.getName()), ...
                'A parameter with a unit must show it in the column header');

            withoutUnit = LvdSweepPluginVarParameter(ctx.pluginVars(1));
            testCase.verifyEqual(withoutUnit.getFullLabel(), withoutUnit.getName(), ...
                'A dimensionless parameter must not get an empty parenthesis');

            %Every enumerated parameter must produce a non-empty, distinct
            %label, or the results spreadsheet has two columns called the
            %same thing.
            params = LvdSweepParameterFactory.enumerate(lvdData);
            labels = arrayfun(@(p) string(p.getFullLabel()), params);

            testCase.verifyTrue(all(strlength(labels) > 0), 'Every parameter must have a non-empty label');
            testCase.verifyEqual(numel(unique(labels)), numel(labels), ...
                'Two enumerated parameters share a label, so their results columns would be indistinguishable');
        end

        function factoryEnumeratesEveryGroupAndTheDispersionSubsetOmitsConstraintBounds(testCase)
            [lvdData, ctx] = testCase.sweepMission();

            params = LvdSweepParameterFactory.enumerate(lvdData);
            [groupNames, indsByGroup] = LvdSweepParameterFactory.groupParameters(params);

            testCase.verifyEqual(sort(groupNames), ...
                sort({'Plugin Variables', 'Optimization Variables', 'Vehicle Knobs', 'Constraint Bounds'}), ...
                'The factory did not offer all four parameter groups');
            testCase.verifyEqual(sum(cellfun(@numel, indsByGroup)), numel(params), ...
                'Grouping lost or duplicated a parameter');

            %Every enumerated parameter must resolve against the mission it
            %was enumerated from -- this is the cheapest way to catch a
            %target kind whose id lookup does not match where the factory
            %found it.
            for(i = 1:numel(params))
                testCase.verifyTrue(params(i).resolve(lvdData), ...
                    sprintf('Enumerated parameter "%s" could not resolve against its own mission', params(i).getName()));
            end

            %A Monte Carlo run disperses vehicle knobs, plugin variables and
            %optimization variables.  A constraint bound is meaningless in a
            %propagate-only case, and offering it would produce a dispersion
            %that provably changes nothing.
            dispersion = LvdSweepParameterFactory.enumerate(lvdData, LvdSweepParameterFactory.getDispersionGroups());
            dispersionGroups = unique(arrayfun(@(p) string(p.getGroupName()), dispersion));

            testCase.verifyFalse(ismember("Constraint Bounds", dispersionGroups), ...
                'Constraint bounds must not be offered as a dispersion source');
            testCase.verifyTrue(ismember("Vehicle Knobs", dispersionGroups));
            testCase.verifyTrue(ismember("Optimization Variables", dispersionGroups));
            testCase.verifyLessThan(numel(dispersion), numel(params), ...
                'The dispersion subset should be strictly smaller than the full list');

            %Three bound choices per bounded constraint.
            constParams = params(arrayfun(@(p) isa(p, 'LvdSweepConstraintBoundParameter'), params));
            testCase.verifyEqual(numel(constParams), 3*numel(lvdData.optimizer.constraints.consts), ...
                'Each bounded constraint should offer a lower, an upper and a both parameter');
            testCase.verifyEqual(constParams(1).constId, ctx.const.id);
        end

        function factoryDoesNotOfferAPluginVariableUnderTwoDifferentGroups(testCase)
            %A plugin variable is backed by an optimization variable.  Listing
            %it under both headings would let a user sweep the same number
            %two different ways in one run, with the second apply silently
            %overwriting the first.
            [lvdData, ctx] = testCase.sweepMission();

            optimParams = LvdSweepParameterFactory.enumerateOptimVars(lvdData);
            pluginBackingIds = arrayfun(@(pv) pv.optVar.id, ctx.pluginVars);

            offeredIds = arrayfun(@(p) p.varId, optimParams);
            testCase.verifyFalse(any(ismember(pluginBackingIds, offeredIds)), ...
                'A plugin variable''s backing optimization variable was offered under Optimization Variables as well');

            %The plugin variables themselves are still offered, once each.
            pluginParams = LvdSweepParameterFactory.enumeratePluginVars(lvdData);
            testCase.verifyEqual(numel(pluginParams), numel(ctx.pluginVars));
            testCase.verifyEqual(sort(arrayfun(@(p) p.pluginVarId, pluginParams)), ...
                sort(arrayfun(@(pv) pv.id, ctx.pluginVars)));
        end

        function parametersCarryDistinctIdentitiesAndAreHeterogeneousTogether(testCase)
            %The setup holds one mixed array of parameters, so the four kinds
            %have to live in one heterogeneous array and be distinguishable
            %by id inside it.
            [lvdData, ctx] = testCase.sweepMission();

            mixed = [LvdSweepPluginVarParameter(ctx.pluginVars(1)), ...
                     LvdSweepOptimVarParameter(ctx.initStateVar, 2, 'Rx', 'none'), ...
                     LvdSweepConstraintBoundParameter(ctx.const, LvdSweepBoundEnum.Lower), ...
                     LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankCapacity, ctx.tank)];

            testCase.verifyClass(mixed, 'AbstractLvdSweepParameter', ...
                'The four parameter kinds must form one heterogeneous array');
            testCase.verifyNumElements(mixed, 4);
            testCase.verifyEqual(numel(unique([mixed.id])), 4, 'Parameters must have distinct ids');

            groups = arrayfun(@(p) string(p.getGroupName()), mixed);
            testCase.verifyEqual(numel(unique(groups)), 4, 'Each kind must report its own group');

            for(i = 1:numel(mixed))
                testCase.verifyTrue(mixed(i).resolve(lvdData));
            end

            %A byte-stream round trip of the parameter array itself (which is
            %what dispatching a task does) must keep the ids and drop the
            %transient resolved handles, since a handle into one mission is
            %meaningless in another.
            clonedParams = getArrayFromByteStream(getByteStreamFromArray(mixed));
            testCase.verifyEqual([clonedParams.id], [mixed.id], ...
                'Serializing the parameter array must preserve the ids it rebinds by');
            testCase.verifyFalse(any([clonedParams.isResolved]), ...
                'A deserialized parameter must start unresolved so it re-finds its target in the case''s own mission');
        end

        function nonSequentialEventActionsAreEnumerableAsKnobs(testCase)
            %Regression: getAllEvents double-unwrapped the non-sequential
            %container's evts getter (which already returns
            %LaunchVehicleEvents), so any mission with a non-sequential
            %event errored out of the parameter enumeration instead of
            %offering its drag actions as knobs.
            [lvdData, ~] = testCase.sweepMission();

            innerEvt = LaunchVehicleEvent(lvdData.script);
            innerEvt.name = 'Non-seq drag';
            innerEvt.termCond = EventDurationTermCondition(60);
            innerEvt.propagatorObj = innerEvt.twoBodyPropagator;
            nonSeqDrag = SetDragAeroPropertiesAction();
            innerEvt.addAction(nonSeqDrag);
            lvdData.script.nonSeqEvts.addEvent(LaunchVehicleNonSeqEvent(innerEvt));

            evts = LvdSweepVehicleKnobParameter.getAllEvents(lvdData);
            testCase.verifyEqual(numel(evts), 3, ...
                'Two sequential events plus the unwrapped non-sequential one');
            testCase.verifyTrue(any(evts == innerEvt), ...
                'The non-sequential event must come back unwrapped');

            knobs = LvdSweepParameterFactory.enumerateVehicleKnobs(lvdData);
            isDragKnob = arrayfun(@(p) isa(p, 'LvdSweepVehicleKnobParameter') && ...
                p.knob == LvdSweepVehicleKnobEnum.EventDragMultiplier, knobs);
            testCase.verifyEqual(nnz(isDragKnob), 2, ...
                'One event-drag knob per SetDragAeroPropertiesAction, sequential and non-sequential');

            testCase.verifyEqual(LvdSweepVehicleKnobParameter.findActionById(lvdData, nonSeqDrag.id), nonSeqDrag, ...
                'Rebinding by id must find the non-sequential action too');
        end
    end

    methods(Access=private)

        function [lvdData, ctx] = sweepMission(testCase)
            %sweepMission A mission that has one of everything a sweep can
            %vary: three plugin variables, two structurally unrelated
            %optimization variables, a bounded constraint, a stage, a tank,
            %an engine, and two independent drag models.

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = ...
                CartesianElementSet(0, [testCase.kerbin.radius + 300; 0; 0], [0; 2.2; 0], testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(60);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            %The initial state variable: 7 elements (epoch, position,
            %velocity), the first three of them active.
            initStateVar = InitialStateVariable(lvdData.initStateModel);
            initStateVar.setUseTfForVariable([true true true false false false false]);
            lvdData.optimizer.vars.addVariable(initStateVar);

            %A steering model variable, which shares no code at all with the
            %initial state variable and stores its angles in radians.
            steerModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            steerVar = SetRPYSteeringModelActionOptimVar(steerModel);
            steerVar.lb = -pi*ones(1,10);
            steerVar.ub =  pi*ones(1,10);
            steerVar.setUseTfForVariable([false false false, true true false, false false false, false]);
            lvdData.optimizer.vars.addVariable(steerVar);

            steerEvt = LaunchVehicleEvent(lvdData.script);
            steerEvt.termCond = EventDurationTermCondition(60);
            steerEvt.propagatorObj = steerEvt.twoBodyPropagator;
            lvdData.script.addEvent(steerEvt);

            steerAction = SetSteeringModelAction();
            steerAction.steeringModels.selectedModel = steerModel;
            steerEvt.addAction(steerAction);

            dragAction = SetDragAeroPropertiesAction();
            steerEvt.addAction(dragAction);

            const = GenericMAConstraint('Altitude', steerEvt, 10, 200, ...
                                        struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            lvdData.optimizer.constraints.addConstraint(const);

            names = {'Alpha', 'Beta', 'Gamma'};
            currentValues = [3, 40, 500];
            pluginVars = LvdPluginOptimVarWrapper.empty(1,0);
            for(i = 1:3) %#ok<*NO4LP>
                pluginVars(i) = LvdPluginOptimVarWrapper();
                pluginVars(i).name = names{i};
                pluginVars(i).value = currentValues(i);
                pluginVars(i).optVar = pluginVars(i).getNewOptVar();
                lvdData.pluginVars.addPluginVar(pluginVars(i));
            end

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();

            ctx = struct('evt1', evt1, ...
                         'steerEvt', steerEvt, ...
                         'initStateVar', initStateVar, ...
                         'steerVar', steerVar, ...
                         'const', const, ...
                         'pluginVars', pluginVars, ...
                         'stage', lvdData.launchVehicle.stages(1), ...
                         'tank', tanks(1), ...
                         'engine', engines(1), ...
                         'dragAction', dragAction);

            testCase.assertNotEmpty(ctx.tank, 'Fixture broken: the default vehicle has no tank');
            testCase.assertNotEmpty(ctx.engine, 'Fixture broken: the default vehicle has no engine');
        end
    end
end
