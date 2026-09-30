classdef EngineMixtureMassFlowTest < KsptotTestCase
    %EngineMixtureMassFlowTest Two-level propellant flow: engine mixture
    %across fluid species, then connection priority/weight within a species.
    %
    % Extends the VehiclePropulsionMassFlowTest oracle strategy: every
    % expected value is computed from first principles at the stock curve
    % knots (215 kN @ 0 kPa, 350 s @ 0 kPa) via mdot = -T/(g0*Isp), so the
    % curve interpolant never enters the oracle.  The per-engine GA mirror
    % (lvd_EngineTasks) delegates its flameout decision to the same
    % LaunchVehicleStateLogEntry.isEngineMixtureStarved() static the kernel
    % uses, which is covered directly in both polarities below.
    %
    % Fixture tank counts (5/6/7) are distinct from the 1-4 counts used by
    % VehiclePropulsionMassFlowTest so no memo key is ever shared, even
    % though the engine->tank memo lives per LaunchVehicleState instance.

    properties(Constant)
        VAC_THRUST_KN = 215;
        VAC_ISP_S     = 350;
        G0_MPS2 = 9.80665;
    end

    properties(TestParameter)
        caseName = { ...
            'MixtureSplitsFiveToOne', ...
            'MixtureStarvesWhenSpeciesEmpty', ...
            'MixtureNotStarvedWhenAllSpeciesPresent', ...
            'PriorityDrainsHighLevelFirst', ...
            'PriorityFallsThroughWhenLevelEmpty', ...
            'WeightsSplitTiedPriority', ...
            'BlankWeightMeansEven', ...
            'MixtureWithPriorityWithinSpecies', ...
            'TwoEnginesDifferentMixtures', ...
            'DefaultsReproduceLegacySplit', ...
        };
    end

    methods(Test)
        function tankMassFlowCases(testCase, caseName)
            testCase.(['check' caseName])();
        end

        function mixtureModelValidation(testCase)
            testCase.checkSetMixtureRejectsBadInput();
            testCase.checkSetFlowWeightRejectsBadInput();
            testCase.checkCopyPreservesMixtureAndPlumbing();
            testCase.checkLoadobjRestoresLegacyDefaults();
            testCase.checkMixtureValidatorBothPolarities();
            testCase.checkSaveLoadRoundTrip();
        end
    end

    methods(Access=private)
        %% ---------------------------------------------------------------
        %  Mixture across species
        %  ---------------------------------------------------------------
        function checkMixtureSplitsFiveToOne(testCase)
            [~, entry, fx] = testCase.buildBipropFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots, thrust] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.fuelIdx), baseMdot/6, 'AbsTol', 1e-12, ...
                'fuel tank must take 1/6 of the engine flow (5:1 ox:fuel)');
            testCase.verifyEqual(mdots(fx.oxIdx), 5*baseMdot/6, 'AbsTol', 1e-12, ...
                'ox tank must take 5/6 of the engine flow');
            testCase.verifyEqual(mdots(fx.dummyIdx), zeros(3,1), ...
                'unconnected tanks must not flow');
            testCase.verifyEqual(sum(mdots), baseMdot, 'AbsTol', 1e-12, ...
                'the species split must conserve the engine total');
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, ...
                'splitting across species must not change thrust');
        end

        function checkMixtureStarvesWhenSpeciesEmpty(testCase)
            %Ox empty, fuel full: the engine must flame out (zero thrust,
            %zero flow everywhere) rather than shifting full flow to fuel.
            [~, entry, fx] = testCase.buildBipropFixture();
            tankStates = entry.getAllActiveTankStates();
            tankStates(fx.oxIdx).tankMass = 0;

            [mdots, thrust, forceVect] = testCase.callMassFlow(entry, tankStates, 1, 0);

            testCase.verifyEqual(thrust, 0, 'exhausted ox must flame out a 5:1 engine');
            testCase.verifyEqual(mdots(fx.fuelIdx), 0, 'surviving fuel must not take over the flow');
            testCase.verifyEqual(mdots(fx.oxIdx), 0, 'the empty ox tank must not flow');
            testCase.verifyVectorEqual(forceVect, [0;0;0], 0, 'flamed-out force vector');

            engine = entry.stageStates(1).engineStates(1).engine;
            testCase.verifyTrue( ...
                LaunchVehicleStateLogEntry.isEngineMixtureStarved(engine, entry.lvState, tankStates, [tankStates.tankMass]'), ...
                'the shared starvation predicate (also used by lvd_EngineTasks) must fire');
        end

        function checkMixtureNotStarvedWhenAllSpeciesPresent(testCase)
            [~, entry, fx] = testCase.buildBipropFixture();
            tankStates = entry.getAllActiveTankStates();

            engine = entry.stageStates(1).engineStates(1).engine;
            testCase.verifyFalse( ...
                LaunchVehicleStateLogEntry.isEngineMixtureStarved(engine, entry.lvState, tankStates, [tankStates.tankMass]'), ...
                'a fully stocked biprop engine must not read as starved');
            testCase.verifyEqual(numel(fx.dummyIdx), 3, 'biprop fixture carries three dummies');
        end

        %% ---------------------------------------------------------------
        %  Priority / weight within one species (no custom mixture)
        %  ---------------------------------------------------------------
        function checkPriorityDrainsHighLevelFirst(testCase)
            %Two drop tanks at priority 1, one core at 0: the whole flow
            %comes from the drops, split evenly; the core is untouched.
            [~, entry, fx] = testCase.buildPriorityFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots, thrust] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.drop1Idx), baseMdot/2, 'AbsTol', 1e-12, 'drop 1 takes half');
            testCase.verifyEqual(mdots(fx.drop2Idx), baseMdot/2, 'AbsTol', 1e-12, 'drop 2 takes half');
            testCase.verifyEqual(mdots(fx.coreIdx), 0, 'core is untouched while drops hold propellant');
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, 'priority must not change thrust');
        end

        function checkPriorityFallsThroughWhenLevelEmpty(testCase)
            %Both drops empty: the entire flow falls through to the core.
            [~, entry, fx] = testCase.buildPriorityFixture();
            tankStates = entry.getAllActiveTankStates();
            tankStates(fx.drop1Idx).tankMass = 0;
            tankStates(fx.drop2Idx).tankMass = 0;

            [mdots, thrust] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.coreIdx), baseMdot, 'AbsTol', 1e-12, ...
                'an emptied priority level falls through to the next');
            testCase.verifyEqual(thrust, testCase.VAC_THRUST_KN, 'AbsTol', 1e-10, 'thrust survives the handover');
        end

        function checkWeightsSplitTiedPriority(testCase)
            [~, entry, fx] = testCase.buildWeightFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.tankAIdx), 2*baseMdot/3, 'AbsTol', 1e-12, 'weight 2 takes two thirds');
            testCase.verifyEqual(mdots(fx.tankBIdx), baseMdot/3, 'AbsTol', 1e-12, 'weight 1 takes one third');
            testCase.verifyEqual(sum(mdots), baseMdot, 'AbsTol', 1e-12, 'weights must conserve the total');
        end

        function checkBlankWeightMeansEven(testCase)
            %One explicit weight of 1.0 beside a blank (NaN): both resolve
            %to effective weight 1, i.e. the legacy even split.
            [lvdData, entry, fx] = testCase.buildWeightFixture();
            lv = lvdData.launchVehicle;
            conns = lv.getEngineToTankConnsForEngine(lv.stages(1).engines(1));
            allTankStates = entry.getAllActiveTankStates();
            tankA = allTankStates(fx.tankAIdx).tank;
            for(i=1:length(conns))
                if(conns(i).tank == tankA)
                    conns(i).flowWeight = 1;
                end
            end
            tankStates = entry.getAllActiveTankStates();

            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.tankAIdx), baseMdot/2, 'AbsTol', 1e-12, 'explicit 1.0 behaves as even');
            testCase.verifyEqual(mdots(fx.tankBIdx), baseMdot/2, 'AbsTol', 1e-12, 'blank behaves as even');
        end

        function checkMixtureWithPriorityWithinSpecies(testCase)
            %Biprop engine plus two ox tanks (drop prio 1, core prio 0):
            %the 5/6 ox share comes from the drop only until it empties.
            [~, entry, fx] = testCase.buildBipropPriorityFixture();
            tankStates = entry.getAllActiveTankStates();

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);
            testCase.verifyEqual(mdots(fx.fuelIdx), baseMdot/6, 'AbsTol', 1e-12, 'fuel share unaffected by ox priority');
            testCase.verifyEqual(mdots(fx.oxDropIdx), 5*baseMdot/6, 'AbsTol', 1e-12, 'ox share from the drop tank only');
            testCase.verifyEqual(mdots(fx.oxCoreIdx), 0, 'ox core untouched while drop holds propellant');

            tankStates(fx.oxDropIdx).tankMass = 0;
            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);
            testCase.verifyEqual(mdots(fx.oxCoreIdx), 5*baseMdot/6, 'AbsTol', 1e-12, 'ox share hands over to the core');
            testCase.verifyEqual(mdots(fx.fuelIdx), baseMdot/6, 'AbsTol', 1e-12, 'fuel share steady across the handover');
        end

        function checkTwoEnginesDifferentMixtures(testCase)
            %Two engines sharing one fuel and one ox tank at different O/F:
            %each engine's demand splits per its own mixture; tanks sum.
            [~, entry, fx] = testCase.buildTwoEngineFixture();
            tankStates = entry.getAllActiveTankStates();

            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            expFuel = baseMdot/6 + baseMdot/2;   % EngA 5:1 + EngB 1:1
            expOx   = 5*baseMdot/6 + baseMdot/2;
            testCase.verifyEqual(mdots(fx.fuelIdx), expFuel, 'AbsTol', 1e-12, 'fuel sums both engines'' demands');
            testCase.verifyEqual(mdots(fx.oxIdx), expOx, 'AbsTol', 1e-12, 'ox sums both engines'' demands');
            testCase.verifyEqual(sum(mdots), 2*baseMdot, 'AbsTol', 1e-12, 'conservation across engines');
        end

        function checkDefaultsReproduceLegacySplit(testCase)
            %Priorities 0 + blank weights + no mixture over two tanks must
            %equal the legacy even split bitwise (same flops, same order).
            [~, entry, fx] = testCase.buildPriorityFixture();
            lv = entry.lvState.lv;
            for(i=1:length(lv.engineTankConns))
                lv.engineTankConns(i).priority = 0;
                lv.engineTankConns(i).flowWeight = NaN;
            end
            tankStates = entry.getAllActiveTankStates();

            [mdots] = testCase.callMassFlow(entry, tankStates, 1, 0);

            baseMdot = testCase.mdotFor(testCase.VAC_THRUST_KN, testCase.VAC_ISP_S);
            testCase.verifyEqual(mdots(fx.drop1Idx) + mdots(fx.drop2Idx) + mdots(fx.coreIdx), baseMdot, 'AbsTol', 1e-12, ...
                'legacy path conserves the total over three tanks');
            testCase.verifyEqual(mdots(fx.drop1Idx), baseMdot/3, 'AbsTol', 1e-12, 'legacy even split, tank 1');
            testCase.verifyEqual(mdots(fx.drop2Idx), baseMdot/3, 'AbsTol', 1e-12, 'legacy even split, tank 2');
            testCase.verifyEqual(mdots(fx.coreIdx), baseMdot/3, 'AbsTol', 1e-12, 'legacy even split, tank 3');
        end

        %% ---------------------------------------------------------------
        %  Model, validation, persistence
        %  ---------------------------------------------------------------
        function checkSetMixtureRejectsBadInput(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            engine = lvdData.launchVehicle.stages(1).engines(1);
            lv = lvdData.launchVehicle;

            testCase.verifyFalse(engine.hasCustomMixture(), 'fresh engines use the legacy pool');
            [types, fracs] = engine.getMixtureSpec();
            testCase.verifyEqual(numel(types), 1, 'default spec is a single fluid');
            testCase.verifyEqual(fracs, 1, 'default spec is the whole flow');
            testCase.verifyEqual(engine.getMixtureFractionForFluidType(types(1)), 1, 'legacy pool answers 1');

            t1 = lv.tankTypes.getTypeForInd(1);
            t2 = lv.tankTypes.getTypeForInd(2);
            testCase.verifyError(@() engine.setMixture([t1, t2], [0.5, 0.4]), 'LaunchVehicleEngine:invalidMixture', ...
                'fractions summing to 0.9 must be rejected');
            testCase.verifyError(@() engine.setMixture([t1, t2], [0.5, -0.5]), 'LaunchVehicleEngine:invalidMixture', ...
                'non-positive fractions must be rejected');
            testCase.verifyError(@() engine.setMixture(t1, []), 'LaunchVehicleEngine:invalidMixture', ...
                'length mismatch must be rejected');
            testCase.verifyFalse(engine.hasCustomMixture(), 'rejected writes must not stick');

            engine.setMixture([t1, t2], [0.25, 0.75]);
            testCase.verifyTrue(engine.hasCustomMixture(), 'accepted write sticks');
            testCase.verifyEqual(engine.getMixtureFractionForFluidType(t2), 0.75, 'AbsTol', 1e-15, 'stored fraction reads back');
            testCase.verifyEqual(engine.getMixtureFractionForFluidType(lv.tankTypes.getTypeForInd(3)), 0, ...
                'unlisted fluids read as 0');
            engine.clearMixture();
            testCase.verifyFalse(engine.hasCustomMixture(), 'clearMixture restores the legacy pool');
        end

        function checkSetFlowWeightRejectsBadInput(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            conn = lvdData.launchVehicle.engineTankConns(1);

            testCase.verifyEqual(conn.priority, 0, 'default priority is 0');
            testCase.verifyTrue(isnan(conn.flowWeight), 'default weight is blank (even)');
            testCase.verifyEqual(conn.getEffectiveWeight(), 1, 'blank resolves to 1');

            testCase.verifyError(@() conn.setFlowWeight(0), 'EngineToTankConnection:invalidFlowWeight', ...
                'zero weight must be rejected');
            testCase.verifyError(@() conn.setFlowWeight(-2), 'EngineToTankConnection:invalidFlowWeight', ...
                'negative weight must be rejected');
            conn.setFlowWeight(2.5);
            testCase.verifyEqual(conn.flowWeight, 2.5, 'accepted weight sticks');
            testCase.verifyEqual(conn.getEffectiveWeight(), 2.5, 'explicit weight reads back');

            conn2 = conn.copy();
            testCase.verifyEqual(conn2.priority, conn.priority, 'copy preserves priority');
            testCase.verifyEqual(conn2.flowWeight, conn.flowWeight, 'copy preserves weight');
        end

        function checkCopyPreservesMixtureAndPlumbing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            engine = lvdData.launchVehicle.stages(1).engines(1);
            lv = lvdData.launchVehicle;
            t1 = lv.tankTypes.getTypeForInd(1);
            t2 = lv.tankTypes.getTypeForInd(2);
            engine.setMixture([t1, t2], [1/6, 5/6]);

            engCopy = engine.copy();
            testCase.verifyTrue(engCopy.hasCustomMixture(), 'engine copy keeps the mixture flag');
            testCase.verifyEqual(engCopy.mixtureFractions, [1/6, 5/6], 'AbsTol', 1e-15, 'engine copy keeps fractions');
            testCase.verifyEqual(numel(engCopy.mixtureFluidTypes), 2, 'engine copy keeps both fluids');
        end

        function checkLoadobjRestoresLegacyDefaults(testCase)
            %Fresh connections already carry the legacy defaults, and
            %loadobj preserves explicitly configured values (missing
            %properties on pre-mixture .mat files deserialize to these
            %same class defaults, which LaunchVehicle.loadobj also guards).
            conn = EngineToTankConnection(LaunchVehicleTank.empty(1,0), LaunchVehicleEngine.empty(1,0));
            testCase.verifyEqual(conn.priority, 0, 'fresh connections default to priority 0');
            testCase.verifyTrue(isnan(conn.flowWeight), 'fresh connections default to blank weight');

            conn.priority = 2;
            conn.flowWeight = 0.5;
            conn = EngineToTankConnection.loadobj(conn);
            testCase.verifyEqual(conn.priority, 2, 'loadobj preserves configured priority');
            testCase.verifyEqual(conn.flowWeight, 0.5, 'loadobj preserves configured weight');

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.launchVehicle = LaunchVehicle.loadobj(lvdData.launchVehicle);
            c1 = lvdData.launchVehicle.engineTankConns(1);
            testCase.verifyEqual(c1.priority, 0, 'vehicle migration keeps default priority');
            testCase.verifyTrue(isnan(c1.flowWeight), 'vehicle migration keeps blank weight');
        end

        function checkMixtureValidatorBothPolarities(testCase)
            classes = {};
            lvdData0 = LvdData.getDefaultLvdData(testCase.celBodyData);
            classes = arrayfun(@(v) class(v), lvdData0.validation.validators, 'UniformOutput', false);
            testCase.verifyTrue(any(strcmp(classes, 'EngineMixtureValidator')), 'EngineMixtureValidator must be registered.');

            %Clean stock mission: silent.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            validator = EngineMixtureValidator(lvdData);
            [errs, warns] = validator.validate();
            testCase.verifyEmpty(errs, 'mixture findings are warnings, never errors');
            testCase.verifyEmpty(warns, 'stock single-pool mission must be silent');

            %Broken mixture: bad sum + unconnected fluid + stray tank + bad weight.
            lv = lvdData.launchVehicle;
            engine = lv.stages(1).engines(1);
            t1 = lv.tankTypes.getTypeForInd(1);
            t2 = lv.tankTypes.getTypeForInd(2);
            engine.mixtureFluidTypes = [t1, t2]; %#ok<PROP> bypass setter to stage an invalid state
            engine.mixtureFractions = [0.5, 0.4];
            lv.engineTankConns(1).flowWeight = -1; %#ok<PROP> bypass setter likewise
            [~, warns] = validator.validate();
            testCase.verifyGreaterThanOrEqual(numel(warns), 3, 'bad sum, unconnected fluid and bad weight must each warn');
            testCase.verifyTrue(any(contains(string({warns.str}), 'sum to 1')), 'sum warning names the rule');
        end

        function checkSaveLoadRoundTrip(testCase)
            %A configured mixture + priority/weight must survive a .mat
            %save/load cycle (exercises LaunchVehicle.loadobj migration).
            [lvdData, ~, fx] = testCase.buildBipropFixture(); %#ok<ASGLU>
            lv = lvdData.launchVehicle;
            for(i=1:length(lv.engineTankConns))
                lv.engineTankConns(i).priority = 3;
            end

            tmpFile = [tempname() '.mat'];
            cleanup = onCleanup(@() delete(tmpFile));
            save(tmpFile, 'lvdData');
            clear lvdData;
            loaded = load(tmpFile);

            lv2 = loaded.lvdData.launchVehicle;
            eng2 = lv2.stages(1).engines(1);
            testCase.verifyTrue(eng2.hasCustomMixture(), 'mixture survives save/load');
            testCase.verifyEqual(eng2.mixtureFractions, [1/6, 5/6], 'AbsTol', 1e-15, 'fractions survive save/load');
            testCase.verifyEqual([lv2.engineTankConns.priority], 3*ones(1, length(lv2.engineTankConns)), ...
                'priorities survive save/load');
        end

        %% ---------------------------------------------------------------
        %  Oracle + fixture helpers
        %  ---------------------------------------------------------------
        function mdot = mdotFor(testCase, thrustKN, ispSec)
            mdot = -thrustKN / (testCase.G0_MPS2 * ispSec);
        end

        function [mdots, thrust, forceVect, ecRates] = callMassFlow(testCase, entry, tankStates, throttle, presskPa)
            tankMasses = [tankStates.tankMass]';

            pwrStorageStates = entry.getAllActivePwrStorageStates();
            storageSoCs = zeros(1, numel(pwrStorageStates));
            for(i = 1:numel(pwrStorageStates))
                storageSoCs(i) = pwrStorageStates(i).getStateOfCharge();
            end

            [mdots, thrust, forceVect, ecRates] = ...
                LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines( ...
                    tankStates, tankMasses, entry.stageStates, throttle, entry.lvState, ...
                    presskPa, entry.time, entry.position, entry.velocity, entry.centralBody, ...
                    entry.steeringModel, storageSoCs, pwrStorageStates, LaunchVehicleAttitudeState(eye(3)));
        end

        function idx = findTankIdx(testCase, tankStates, tank)
            idx = find([tankStates.tank] == tank, 1);
            testCase.assertNotEmpty(idx, 'fixture tank missing from active tank states');
        end

        function [lvdData, entry, fx] = buildBipropFixture(testCase)
            %5 tanks: Fuel (6 mT) + Ox (30 mT) feeding one 5:1 engine, plus
            %3 unconnected dummies.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);

            lv.tankTypes.addType(TankFluidType('Fuel'));
            lv.tankTypes.addType(TankFluidType('Ox'));
            fuelType = lv.tankTypes.types(end-1);
            oxType = lv.tankTypes.types(end);

            fuelTank = stg.tanks(1);
            fuelTank.name = 'Fuel Tank';
            fuelTank.tankType = fuelType;
            fuelTank.initialMass = 6;
            fuelTank.capacity = 6;

            oxTank = LaunchVehicleTank(stg);
            oxTank.name = 'Ox Tank';
            oxTank.tankType = oxType;
            oxTank.initialMass = 30;
            oxTank.capacity = 30;
            stg.addTank(oxTank);

            for(d=1:3)
                dummy = LaunchVehicleTank(stg);
                dummy.name = sprintf('Dummy %u', d);
                dummy.initialMass = 1;
                dummy.capacity = 1;
                stg.addTank(dummy);
            end

            lv.addEngineToTankConnection(EngineToTankConnection(oxTank, engine));
            engine.setMixture([fuelType, oxType], [1/6, 5/6]);

            entry = testCase.regenerateInitialStateEntry(lvdData);
            tankStates = entry.getAllActiveTankStates();
            fx = struct( ...
                'fuelIdx', testCase.findTankIdx(tankStates, fuelTank), ...
                'oxIdx', testCase.findTankIdx(tankStates, oxTank), ...
                'dummyIdx', [testCase.findTankIdx(tankStates, stg.tanks(3)), ...
                             testCase.findTankIdx(tankStates, stg.tanks(4)), ...
                             testCase.findTankIdx(tankStates, stg.tanks(5))]);
        end

        function [lvdData, entry, fx] = buildPriorityFixture(testCase)
            %6 tanks: Drop1/Drop2 (prio 1) + Core (prio 0) on one engine
            %(legacy single pool), plus 3 unconnected dummies.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);

            drop1 = stg.tanks(1);
            drop1.name = 'Drop Tank 1';
            drop1.initialMass = 6;
            drop1.capacity = 6;

            drop2 = LaunchVehicleTank(stg);
            drop2.name = 'Drop Tank 2';
            drop2.initialMass = 6;
            drop2.capacity = 6;
            stg.addTank(drop2);

            core = LaunchVehicleTank(stg);
            core.name = 'Core Tank';
            core.initialMass = 6;
            core.capacity = 6;
            stg.addTank(core);

            for(d=1:3)
                dummy = LaunchVehicleTank(stg);
                dummy.name = sprintf('Dummy %u', d);
                dummy.initialMass = 1;
                dummy.capacity = 1;
                stg.addTank(dummy);
            end

            c2 = EngineToTankConnection(drop2, engine);
            c2.priority = 1;
            lv.addEngineToTankConnection(c2);
            c3 = EngineToTankConnection(core, engine);
            lv.addEngineToTankConnection(c3);
            for(i=1:length(lv.engineTankConns))
                if(lv.engineTankConns(i).tank == drop1)
                    lv.engineTankConns(i).priority = 1;
                end
            end

            entry = testCase.regenerateInitialStateEntry(lvdData);
            tankStates = entry.getAllActiveTankStates();
            fx = struct( ...
                'drop1Idx', testCase.findTankIdx(tankStates, drop1), ...
                'drop2Idx', testCase.findTankIdx(tankStates, drop2), ...
                'coreIdx', testCase.findTankIdx(tankStates, core));
        end

        function [lvdData, entry, fx] = buildWeightFixture(testCase)
            %7 tanks: TankA (weight 2) + TankB (weight 1) tied at prio 0,
            %plus 5 unconnected dummies.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);

            tankA = stg.tanks(1);
            tankA.name = 'Tank A';
            tankA.initialMass = 6;
            tankA.capacity = 6;

            tankB = LaunchVehicleTank(stg);
            tankB.name = 'Tank B';
            tankB.initialMass = 6;
            tankB.capacity = 6;
            stg.addTank(tankB);

            for(d=1:5)
                dummy = LaunchVehicleTank(stg);
                dummy.name = sprintf('Dummy %u', d);
                dummy.initialMass = 1;
                dummy.capacity = 1;
                stg.addTank(dummy);
            end

            cB = EngineToTankConnection(tankB, engine);
            lv.addEngineToTankConnection(cB);
            for(i=1:length(lv.engineTankConns))
                if(lv.engineTankConns(i).tank == tankA)
                    lv.engineTankConns(i).setFlowWeight(2);
                elseif(lv.engineTankConns(i).tank == tankB)
                    lv.engineTankConns(i).setFlowWeight(1);
                end
            end

            entry = testCase.regenerateInitialStateEntry(lvdData);
            tankStates = entry.getAllActiveTankStates();
            fx = struct( ...
                'tankAIdx', testCase.findTankIdx(tankStates, tankA), ...
                'tankBIdx', testCase.findTankIdx(tankStates, tankB));
        end

        function [lvdData, entry, fx] = buildBipropPriorityFixture(testCase)
            %Biprop 5:1 engine: Fuel + OxDrop (prio 1) + OxCore (prio 0).
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engine = stg.engines(1);

            lv.tankTypes.addType(TankFluidType('Fuel'));
            lv.tankTypes.addType(TankFluidType('Ox'));
            fuelType = lv.tankTypes.types(end-1);
            oxType = lv.tankTypes.types(end);

            fuelTank = stg.tanks(1);
            fuelTank.name = 'Fuel Tank';
            fuelTank.tankType = fuelType;
            fuelTank.initialMass = 6;
            fuelTank.capacity = 6;

            oxDrop = LaunchVehicleTank(stg);
            oxDrop.name = 'Ox Drop';
            oxDrop.tankType = oxType;
            oxDrop.initialMass = 30;
            oxDrop.capacity = 30;
            stg.addTank(oxDrop);

            oxCore = LaunchVehicleTank(stg);
            oxCore.name = 'Ox Core';
            oxCore.tankType = oxType;
            oxCore.initialMass = 30;
            oxCore.capacity = 30;
            stg.addTank(oxCore);

            cDrop = EngineToTankConnection(oxDrop, engine);
            cDrop.priority = 1;
            lv.addEngineToTankConnection(cDrop);
            lv.addEngineToTankConnection(EngineToTankConnection(oxCore, engine));
            engine.setMixture([fuelType, oxType], [1/6, 5/6]);

            entry = testCase.regenerateInitialStateEntry(lvdData);
            tankStates = entry.getAllActiveTankStates();
            fx = struct( ...
                'fuelIdx', testCase.findTankIdx(tankStates, fuelTank), ...
                'oxDropIdx', testCase.findTankIdx(tankStates, oxDrop), ...
                'oxCoreIdx', testCase.findTankIdx(tankStates, oxCore));
        end

        function [lvdData, entry, fx] = buildTwoEngineFixture(testCase)
            %5 tanks: Fuel + Ox shared by EngA (5:1) and EngB (1:1), plus 3 dummies.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            engA = stg.engines(1);

            lv.tankTypes.addType(TankFluidType('Fuel'));
            lv.tankTypes.addType(TankFluidType('Ox'));
            fuelType = lv.tankTypes.types(end-1);
            oxType = lv.tankTypes.types(end);

            fuelTank = stg.tanks(1);
            fuelTank.name = 'Fuel Tank';
            fuelTank.tankType = fuelType;
            fuelTank.initialMass = 12;
            fuelTank.capacity = 12;

            oxTank = LaunchVehicleTank(stg);
            oxTank.name = 'Ox Tank';
            oxTank.tankType = oxType;
            oxTank.initialMass = 36;
            oxTank.capacity = 36;
            stg.addTank(oxTank);

            for(d=1:3)
                dummy = LaunchVehicleTank(stg);
                dummy.name = sprintf('Dummy %u', d);
                dummy.initialMass = 1;
                dummy.capacity = 1;
                stg.addTank(dummy);
            end

            engB = LaunchVehicleEngine(stg);
            engB.name = 'Engine B';
            stg.addEngine(engB);

            lv.addEngineToTankConnection(EngineToTankConnection(oxTank, engA));
            lv.addEngineToTankConnection(EngineToTankConnection(fuelTank, engB));
            lv.addEngineToTankConnection(EngineToTankConnection(oxTank, engB));
            engA.setMixture([fuelType, oxType], [1/6, 5/6]);
            engB.setMixture([fuelType, oxType], [1/2, 1/2]);

            entry = testCase.regenerateInitialStateEntry(lvdData);
            tankStates = entry.getAllActiveTankStates();
            fx = struct( ...
                'fuelIdx', testCase.findTankIdx(tankStates, fuelTank), ...
                'oxIdx', testCase.findTankIdx(tankStates, oxTank));
        end

        function entry = regenerateInitialStateEntry(testCase, lvdData)
            bodyInfo = LvdData.getDefaultInitialBodyInfo(testCase.celBodyData);
            lvdData.initStateModel = ...
                InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, bodyInfo);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end
    end
end
