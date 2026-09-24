classdef H6ValidatorTest < KsptotTestCase
    properties(Constant, Access=private)
        Smi = 700;
        EvtDur = 600;
    end

    methods(Test)
        function engineWithoutTank(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            connection = lvdData.launchVehicle.engineTankConns(1);
            lvdData.launchVehicle.removeEngineToTankConnection(connection);

            validator = EngineWithoutTankValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'no connected tank'));

            lvdData.launchVehicle.addEngineToTankConnection(connection);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyEmpty(warnings);
        end

        function tankWithoutConsumer(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stage = lv.stages(1);
            tank = LaunchVehicleTank(stage);
            tank.name = 'Unconsumed Tank';
            stage.addTank(tank);

            validator = TankWithoutConsumerValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'Unconsumed Tank'));

            lv.addEngineToTankConnection(EngineToTankConnection(tank, stage.engines(1)));
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyEmpty(warnings);

            sourceTank = LaunchVehicleTank(stage);
            sourceTank.name = 'Source Tank';
            targetTank = LaunchVehicleTank(stage);
            targetTank.name = 'Destination Only Tank';
            stage.addTank(sourceTank);
            stage.addTank(targetTank);
            lv.addTankToTankConnection(TankToTankConnection(sourceTank, targetTank));
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'Destination Only Tank'));
        end

        function nonPositiveDryMass(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stage = lvdData.launchVehicle.stages(1);
            validator = NonPositiveStageDryMassValidator(lvdData);

            stage.dryMass = 1;
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyEmpty(warnings);

            stage.dryMass = 0;
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'invalid dry mass'));

            stage.dryMass = -1;
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
        end

        function zeroAreaLift(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.propagatorObj = evt.forceModelPropagator;
            evt.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Lift];
            lvdData.stateLog.clearStateLog();
            lvdData.initStateModel.aero.liftCoeffModel.liftCoeffObj.cylinderLength = 0;
            lvdData.initStateModel.aero.liftCoeffModel.liftCoeffObj.cylinderRadius = 0;

            validator = ZeroAreaLiftModelValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'zero-area'));

            lvdData.initStateModel.aero.liftCoeffModel.liftCoeffObj.cylinderRadius = 1;
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);

            evt.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Thrust];
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);
        end

        function throttleBelowMinimum(testCase)
            lvdData = testCase.makeRunMission();
            evt = lvdData.script.getEventForInd(1);
            evt.propagatorObj = evt.forceModelPropagator;
            engine = lvdData.launchVehicle.stages(1).engines(1);
            engine.minThrottle = 0.4;
            testCase.setThrottleOnEvent(lvdData, evt, 0.4);

            validator = ThrottleBelowMinimumValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyEmpty(warnings);

            testCase.setThrottleOnEvent(lvdData, evt, 0.4 - 1e-6);
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'below the minimum'));
        end

        function electricEngineWithoutCharge(testCase)
            lvdData = testCase.makeRunMission();
            evt = lvdData.script.getEventForInd(1);
            evt.propagatorObj = evt.forceModelPropagator;
            engine = lvdData.launchVehicle.stages(1).engines(1);
            engine.reqsElecCharge = true;
            engine.pwrUsageRate = 1;
            testCase.setThrottleOnEvent(lvdData, evt, 0.5);

            validator = ElectricEngineWithoutChargeValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'no active positive state of charge'));

            stage = lvdData.launchVehicle.stages(1);
            battery = LaunchVehicleBasicElectricalBattery(stage);
            battery.maxCapacity = 10;
            battery.initialStateOfCharge = 0;
            entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
            for(i=1:numel(entries))
                batteryState = battery.createDefaultInitialState(entries(i).stageStates(1));
                entries(i).stageStates(1).addPowerStorageState(batteryState);
            end
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);

            entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
            for(i=1:numel(entries))
                entries(i).stageStates(1).powerStorageStates(1).setStateOfCharge(5);
            end
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);

            testCase.setThrottleOnEvent(lvdData, evt, 0);
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);
        end

        function engineActivatedOnInactiveStage(testCase)
            lvdData = testCase.makeRunMission();
            initialStageState = lvdData.initStateModel.stageStates(1);
            initialStageState.active = false;
            validator = EngineActiveOnInactiveStageValidator(lvdData);

            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'Initial state'));

            initialStageState.active = true;
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);

            lvdData = testCase.makeRunMission();
            evt = lvdData.script.getEventForInd(1);
            entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
            entries(1).stageStates(1).active = false;
            entries(2).stageStates(1).active = false;
            entries(1).stageStates(1).engineStates(1).active = false;
            entries(2).stageStates(1).engineStates(1).active = true;
            allEntries = lvdData.stateLog.getAllEntries();
            allEntries(1:numel(entries)) = entries;
            lvdData.stateLog.entries = allEntries;
            validator = EngineActiveOnInactiveStageValidator(lvdData);
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'activated while the stage is inactive'));
        end

        function graphicalAnalysisFailure(testCase)
            lvdData = testCase.makeRunMission();
            validator = GraphicalAnalysisTaskFailureValidator(lvdData);
            [errors, warnings] = validator.validate();
            testCase.verifyEmpty(errors);
            testCase.verifyEmpty(warnings);

            timeTask = GraphicalAnalysisTask('Universal Time', testCase.kerbinFrame);
            lvdData.graphAnalysis.addTask(timeTask);
            entry = lvdData.stateLog.getFirstStateLogForEvent(lvdData.script.getEventForInd(1));
            entry.time = -1;
            [~, warnings] = validator.validate();
            testCase.verifyEmpty(warnings);
            lvdData.graphAnalysis.removeTask(timeTask);

            lvdData.graphAnalysis.addTask(GraphicalAnalysisTask('Not A Real Quantity', testCase.kerbinFrame));
            [~, warnings] = validator.validate();
            testCase.verifyNumElements(warnings, 1);
            testCase.verifyTrue(contains(warnings(1).str, 'Graphical analysis task evaluation failed'));
            testCase.verifyTrue(contains(warnings(1).str, 'Not A Real Quantity'));
        end
    end

    methods(Access=private)
        function lvdData = makeRunMission(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, testCase.Smi, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(testCase.EvtDur);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(testCase.EvtDur);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            lvdData.script.executeScript(false, evt1, false, false, false, false, false);
        end

        function setThrottleOnEvent(~, lvdData, evt, value)
            entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
            for(i=1:numel(entries))
                model = ThrottlePolyModel.getDefaultThrottleModel();
                model.setT0(0);
                model.setPolyTerms(value, 0, 0);
                entries(i).throttleModel = model;
            end
        end
    end
end
