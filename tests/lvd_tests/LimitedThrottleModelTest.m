classdef LimitedThrottleModelTest < KsptotTestCase
    %LimitedThrottleModelTest Dynamic-pressure and acceleration limited throttle.
    %
    % SUBJECT UNDER TEST
    %   LimitedThrottleModel, ThrottleModelEnum.Limited, the limitedThrottle
    %   slot of ThrottleModelsSet and promptForThrottleModelType.
    %
    % ORACLE STRATEGY
    %   The wrapper is a pure function of (base throttle, q, thrust
    %   acceleration).  Each check restates the rule independently:
    %     * pass-through: wrapper == base when limits are off or slack;
    %     * q ramp: expected value from the documented piecewise-linear law,
    %       with q computed here from density and airspeed on a NON-ROTATING
    %       body copy, so airspeed == inertial speed by construction;
    %     * acceleration: stock engine gives exactly 215 kN of vacuum thrust
    %       scaling linearly with throttle (VehiclePropulsionMassFlowTest
    %       precedent), so a(throttle) = 215*throttle/m and the limited
    %       throttle is maxAccel*m/215 in closed form.
    %   Delegation checks compare against the base model's own state.

    properties(TestParameter)
        caseName = {'PassThroughWhenLimitsOff', 'PassThroughWhenLimitsSlack', ...
                    'DynPressRampShape', 'DynPressLimitOnVehicle', 'AccelLimitOnVehicle', ...
                    'DelegationToBaseModel', 'EnumAndModelSetRoundTrip', 'ModelSetLoadobjGuard', ...
                    'RejectsNestedWrapper', 'HeterogeneousModelArraysCompareAsHandles'};
    end

    methods(Test)
        function limitedThrottleModelMatchesRule(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)
        function checkPassThroughWhenLimitsOff(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = testCase.buildFixture();
            [rVect, vVect] = testCase.atmosphericState(bodyInfo);

            base = testCase.constantPolyModel(0.7);
            model = LimitedThrottleModel.getThrottleModelWithBase(base);
            testCase.verifyFalse(model.enableDynPressLimit, 'Dynamic pressure limit must default to off.');
            testCase.verifyFalse(model.enableAccelLimit, 'Acceleration limit must default to off.');

            expected = base.getThrottleAtTime(12, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            actual = model.getThrottleAtTime(12, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actual, expected, 'With both limits disabled the wrapper must return the base throttle exactly.');
            testCase.verifyEqual(actual, 0.7, 'AbsTol', 1e-15);
        end

        function checkPassThroughWhenLimitsSlack(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = testCase.buildFixture();
            [rVect, vVect] = testCase.atmosphericState(bodyInfo);

            base = testCase.constantPolyModel(0.65);
            model = LimitedThrottleModel.getThrottleModelWithBase(base);

            q = testCase.dynPressOracle(bodyInfo, rVect, vVect);
            testCase.assertGreaterThan(q, 0, 'Fixture broken: expected a positive dynamic pressure in the atmosphere.');

            model.enableDynPressLimit = true;
            model.maxDynPress = 10 * q;      %ramp starts at 9q, far above q
            model.enableAccelLimit = true;
            model.maxAccel = 1e6;            %never binding

            actual = model.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actual, 0.65, 'AbsTol', 1e-12, 'Slack limits must not alter the base throttle.');
        end

        function checkDynPressRampShape(testCase)
            model = LimitedThrottleModel.getDefaultThrottleModel();
            model.maxDynPress = 40;
            model.dynPressRampFrac = 0.25;   %ramp from 30 kPa to 40 kPa
            model.dynPressMinThrottle = 0.2;

            ramp = @(q) model.getDynPressRampThrottle(q);
            testCase.verifyEqual(ramp(0), 1, 'AbsTol', 1e-15, 'Ramp must be 1 at zero q.');
            testCase.verifyEqual(ramp(30), 1, 'AbsTol', 1e-15, 'Ramp must be 1 exactly at the ramp start.');
            testCase.verifyEqual(ramp(35), 0.6, 'AbsTol', 1e-12, 'Ramp must be linear: midpoint gives (1 + floor)/2.');
            testCase.verifyEqual(ramp(32.5), 0.8, 'AbsTol', 1e-12, 'Ramp must be linear at the quarter point.');
            testCase.verifyEqual(ramp(40), 0.2, 'AbsTol', 1e-15, 'Ramp must reach the floor at max q.');
            testCase.verifyEqual(ramp(400), 0.2, 'AbsTol', 1e-15, 'Ramp must hold the floor above max q.');

            %Degenerate ramp fraction of zero: a step at maxDynPress.
            model.dynPressRampFrac = 0;
            testCase.verifyEqual(ramp(39.999), 1, 'AbsTol', 1e-15, 'Zero ramp width: full throttle below max q.');
            testCase.verifyEqual(ramp(40), 0.2, 'AbsTol', 1e-15, 'Zero ramp width: floor at max q.');
        end

        function checkDynPressLimitOnVehicle(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = testCase.buildFixture();
            [rVect, vVect] = testCase.atmosphericState(bodyInfo);

            q = testCase.dynPressOracle(bodyInfo, rVect, vVect);
            testCase.verifyEqual(LimitedThrottleModel.getDynamicPressure(0, rVect, vVect, bodyInfo), q, 'RelTol', 1e-12, ...
                'Model dynamic pressure must match 0.5*rho*v^2 with airspeed == inertial speed on a non-rotating body.');

            base = testCase.constantPolyModel(1.0);
            model = LimitedThrottleModel.getThrottleModelWithBase(base);
            model.enableDynPressLimit = true;
            model.dynPressRampFrac = 0.2;
            model.dynPressMinThrottle = 0;
            evalModel = @() model.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);

            %q sits exactly at the ramp start: no reduction.
            model.maxDynPress = q / (1 - model.dynPressRampFrac);
            testCase.verifyEqual(evalModel(), 1.0, 'AbsTol', 1e-9, 'At the ramp start the throttle must be untouched.');

            %q sits mid-ramp: throttle = (1 + floor)/2 = 0.5.
            model.maxDynPress = q / (1 - model.dynPressRampFrac/2);
            testCase.verifyEqual(evalModel(), 0.5, 'AbsTol', 1e-9, 'Mid-ramp q must halve a full-throttle command.');

            %q above the limit: floor.
            model.maxDynPress = q / 2;
            testCase.verifyEqual(evalModel(), 0, 'AbsTol', 1e-15, 'Above max q the throttle must drop to the floor.');

            %The limit is a cap, not a scale: a base command below the ramp
            %value passes through unchanged.
            base.setPolyTerms(0.3, 0, 0);
            model.maxDynPress = q / (1 - model.dynPressRampFrac/2); %ramp value 0.5 > 0.3
            testCase.verifyEqual(evalModel(), 0.3, 'AbsTol', 1e-12, 'A base command below the ramp cap must pass through.');

            %Outside the atmosphere q is zero, so the limit is inert.
            rVac = (bodyInfo.radius + bodyInfo.atmohgt + 50) * [0;1;0];
            model.maxDynPress = 1e-6;
            actualVac = model.getThrottleAtTime(0, rVac, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actualVac, 0.3, 'AbsTol', 1e-12, 'Above the atmosphere the dynamic pressure limit must not act.');
        end

        function checkAccelLimitOnVehicle(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = testCase.buildFixture();

            %Vacuum: stock engine gives 215 kN at full throttle, linear in
            %throttle, so a(throttle) = 215*throttle/m  [kN/mT == m/s^2].
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1;0.2;0.3]);
            vVect = [0.5; 1.6; 0.1];
            totalMassMT = dryMass + sum(tankMasses);
            aFull = 215 / totalMassMT;

            base = testCase.constantPolyModel(1.0);
            model = LimitedThrottleModel.getThrottleModelWithBase(base);
            model.enableAccelLimit = true;
            evalModel = @() model.getThrottleAtTime(0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);

            testCase.verifyEqual(model.getThrustAccelForThrottle(1.0, 0, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates), ...
                aFull, 'RelTol', 1e-12, 'Thrust acceleration at full throttle must be 215 kN over the vehicle mass.');

            model.maxAccel = 0.5 * aFull;
            testCase.verifyEqual(evalModel(), 0.5, 'AbsTol', 1e-6, 'The limited throttle must give exactly maxAccel: 0.5 for half of the full-throttle acceleration.');

            model.maxAccel = 0.25 * aFull;
            testCase.verifyEqual(evalModel(), 0.25, 'AbsTol', 1e-6, 'The limited throttle must scale with maxAccel.');

            %The limit never raises the throttle.
            base.setPolyTerms(0.3, 0, 0);
            model.maxAccel = 0.5 * aFull;
            testCase.verifyEqual(evalModel(), 0.3, 'AbsTol', 1e-12, 'A base command already under the limit must pass through.');

            %An unattainable limit (zero acceleration allowed) shuts the engine.
            base.setPolyTerms(1.0, 0, 0);
            model.maxAccel = 0;
            testCase.verifyEqual(evalModel(), 0, 'AbsTol', 1e-15, 'A zero acceleration limit must zero the throttle.');

            %Both limits together: the tighter one wins.
            [rAtm, vAtm] = testCase.atmosphericState(bodyInfo);
            q = testCase.dynPressOracle(bodyInfo, rAtm, vAtm);
            aFullAtm = model.getThrustAccelForThrottle(1.0, 0, rAtm, vAtm, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            model.enableDynPressLimit = true;
            model.dynPressRampFrac = 0.2;
            model.maxDynPress = q / (1 - model.dynPressRampFrac/2); %q cap 0.5
            model.maxAccel = 0.8 * aFullAtm;                          %accel cap 0.8
            actualBoth = model.getThrottleAtTime(0, rAtm, vAtm, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actualBoth, 0.5, 'AbsTol', 1e-6, 'With both limits active the tighter (q) cap must win.');
            model.maxAccel = 0.3 * aFullAtm;                          %accel cap 0.3 now tighter
            actualBoth = model.getThrottleAtTime(0, rAtm, vAtm, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actualBoth, 0.3, 'AbsTol', 1e-6, 'With both limits active the tighter (accel) cap must win.');
        end

        function checkDelegationToBaseModel(testCase)
            [~, entry] = testCase.buildFixture();

            base = testCase.constantPolyModel(0.4);
            model = LimitedThrottleModel.getThrottleModelWithBase(base);
            testCase.verifySameHandle(model.baseModel, base);

            model.setT0(123.5);
            testCase.verifyEqual(base.getT0(), 123.5, 'setT0 must reach the base model.');
            testCase.verifyEqual(model.getT0(), 123.5, 'getT0 must read the base model.');

            testCase.verifyEmpty(model.getExistingOptVar(), 'A fresh base model has no optimization variable.');
            optVar = model.getNewOptVar();
            testCase.verifyClass(optVar, 'SetPolyThrottleModelActionOptimVar', 'getNewOptVar must create the base model''s variable type.');
            testCase.verifySameHandle(optVar.varObj, base, 'The variable must act on the base model, not the wrapper.');
            testCase.verifySameHandle(model.getExistingOptVar(), optVar, 'getExistingOptVar must read the base model''s variable.');

            %Continuity requested on the wrapper is honoured by the base law.
            entry.throttleModel = testCase.constantPolyModel(0.9);
            model.throttleContinuity = true;
            model.initThrottleModel(entry);
            testCase.verifyTrue(base.throttleContinuity, 'Continuity on the wrapper must propagate to the base model.');
            testCase.verifyEqual(base.throttleModel.constTerm, 0.9, 'AbsTol', 1e-12, 'Continuity must seed the base constant term from the state.');
            testCase.verifyEqual(base.getT0(), entry.time, 'initThrottleModel must set the base t0 from the state.');

            %Time offsets flow through as well.
            model.setInitialThrottleFromState(entry, 2.5);
            testCase.verifyEqual(base.throttleModel.tOffset, 2.5, 'AbsTol', 1e-12, 'setInitialThrottleFromState must reach the base model.');

            %SetThrottleModelAction sees the delegated variable.
            action = SetThrottleModelAction(model);
            optVar.setUseTfForVariable(true(1,4));
            [tf, vars] = action.hasActiveOptimVar();
            testCase.verifyTrue(tf, 'The action must report the base model''s variable as active.');
            testCase.verifySameHandle(vars(1), optVar);
            testCase.verifyTrue(contains(action.getName(), 'Limited'), 'The action name must identify the limited model type.');
        end

        function checkEnumAndModelSetRoundTrip(testCase)
            [names, enums] = ThrottleModelEnum.getThrottleModelTypeNameStrs();
            testCase.verifyTrue(any(enums == ThrottleModelEnum.Limited), 'Limited must be a ThrottleModelEnum member.');
            testCase.verifyTrue(any(contains(names, 'Limited')), 'The Limited enum must have a listbox name.');
            testCase.verifyEqual(ThrottleModelEnum.Limited.classNameStr, 'LimitedThrottleModel');

            model = LimitedThrottleModel.getDefaultThrottleModel();
            testCase.verifyEqual(model.getThrottleModelTypeEnum(), ThrottleModelEnum.Limited);
            testCase.verifyEqual(ThrottleModelEnum.getIndOfListboxStrsForThrottleModel(model), find(enums == ThrottleModelEnum.Limited));
            testCase.verifyEqual(ThrottleModelEnum.getEnumForListboxStr(ThrottleModelEnum.Limited.nameStr), ThrottleModelEnum.Limited);

            set = ThrottleModelsSet();
            testCase.verifyClass(set.limitedThrottle, 'LimitedThrottleModel', 'The model set must carry a limited slot.');
            set2 = ThrottleModelsSet();
            testCase.verifyNotSameHandle(set.limitedThrottle, set2.limitedThrottle, 'Each set must own its own limited model instance.');

            set.selectedModel = model;
            testCase.verifySameHandle(set.limitedThrottle, model, 'Selecting a limited model must store it in the limited slot.');
            testCase.verifySameHandle(set.getModelForEnum(ThrottleModelEnum.Limited), model);
            testCase.verifySameHandle(set.getModelForEnum(ThrottleModelEnum.PolyModel), set.polyThrottle);
            all4 = set.getAllModels();
            testCase.verifyNumElements(all4, 4);
            testCase.verifySameHandle(all4(end), model);

            model2 = LimitedThrottleModel.getDefaultThrottleModel();
            set.setModelForEnum(ThrottleModelEnum.Limited, model2);
            testCase.verifySameHandle(set.limitedThrottle, model2);
            testCase.verifySameHandle(set.selectedModel, model2, 'Replacing the selected slot must move the selection to the new model.');
            testCase.verifyError(@() set.setModelForEnum(ThrottleModelEnum.PolyModel, model2), ?MException, ...
                'Storing a model in the wrong slot must be rejected.');

            action = SetThrottleModelAction(model2);
            testCase.verifySameHandle(action.throttleModels.selectedModel, model2);
            testCase.verifySameHandle(action.throttleModels.limitedThrottle, model2);
        end

        function checkModelSetLoadobjGuard(testCase)
            mc = ?ThrottleModelsSet;
            prop = findobj(mc.PropertyList, 'Name', 'limitedThrottle');
            testCase.assertNotEmpty(prop);
            classDefault = prop.DefaultValue;

            %A set that came back from an old file holds the shared class
            %default; loadobj must give it a private instance.
            set = ThrottleModelsSet();
            set.limitedThrottle = classDefault;
            set = ThrottleModelsSet.loadobj(set);
            testCase.verifyNotSameHandle(set.limitedThrottle, classDefault, 'loadobj must replace the shared class default.');
            testCase.verifyClass(set.limitedThrottle, 'LimitedThrottleModel');

            %A set with its own saved model keeps it.
            own = LimitedThrottleModel.getDefaultThrottleModel();
            own.maxAccel = 12.5;
            set2 = ThrottleModelsSet();
            set2.limitedThrottle = own;
            set2 = ThrottleModelsSet.loadobj(set2);
            testCase.verifySameHandle(set2.limitedThrottle, own, 'loadobj must not touch a set with its own limited model.');
        end

        function checkHeterogeneousModelArraysCompareAsHandles(testCase)
            %ThrottleModelsSet.getAllModels() is a heterogeneous array of four
            %different AbstractThrottleModel subclasses.  The throttle model
            %dialog filters it with ~= against the selected model, which only
            %works when eq/ne are sealed on the base class.
            models = ThrottleModelsSet();
            all = models.getAllModels();
            testCase.assertEqual(numel(all), 4);

            sel = models.limitedThrottle;
            others = all(all ~= sel);

            testCase.verifyEqual(numel(others), 3, 'Every model but the selected one must survive the filter.');
            testCase.verifyFalse(any(others == sel));
            testCase.verifyTrue(any(all == sel));
            testCase.verifyTrue(isa(others, 'AbstractThrottleModel'));
        end

        function checkRejectsNestedWrapper(testCase)
            outer = LimitedThrottleModel.getDefaultThrottleModel();
            inner = LimitedThrottleModel.getDefaultThrottleModel();
            testCase.verifyError(@() outer.setBaseModel(inner), ?MException, 'A limited model must not wrap another limited model.');
            testCase.verifyError(@() LimitedThrottleModel.getThrottleModelWithBase(inner), ?MException);
        end

        %% ------------------------------------------------------------ fixtures
        function [lvdData, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            %Non-rotating copy of the central body so the atmosphere-relative
            %velocity equals the inertial velocity in the oracle.
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;

            tankStates = entry.getAllActiveTankStates();
            tankMasses = [tankStates.tankMass];
            dryMass = entry.getTotalVehicleDryMass();
            pwrStates = entry.getAllActivePwrStorageStates();
            storageSoCs = zeros(1, numel(pwrStates));
            for(i = 1:numel(pwrStates)) %#ok<*NO4LP>
                storageSoCs(i) = pwrStates(i).getStateOfCharge();
            end
        end

        function [rVect, vVect] = atmosphericState(~, bodyInfo)
            %10 km up on the equator, 300 m/s eastward.
            rVect = (bodyInfo.radius + 10) * [1; 0; 0];
            vVect = [0; 0.3; 0];
        end

        function q = dynPressOracle(~, bodyInfo, rVect, vVect)
            %0.5*rho*v^2 in kPa; lat/long from geometry on the non-rotating body.
            altitude = norm(rVect) - bodyInfo.radius;
            lat = asin(rVect(3) / norm(rVect));
            long = atan2(rVect(2), rVect(1));
            rho = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, 0, long); %kg/m^3
            speedMS = norm(vVect) * 1000;
            q = 0.5 * rho * speedMS^2 / 1000;
        end

        function model = constantPolyModel(~, value)
            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.setT0(0);
            model.setPolyTerms(value, 0, 0);
        end
    end
end
