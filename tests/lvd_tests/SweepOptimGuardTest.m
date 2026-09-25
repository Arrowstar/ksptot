classdef SweepOptimGuardTest < KsptotTestCase
    %SweepOptimGuardTest The Optimize-mode pre-run guard in
    %LvdSweepSetup.validate.
    %
    % Every case pins its dispersed quantities off the optimizer so the
    % solver cannot move them back off the sampled values.  When the
    % dispersed set covers everything the mission has enabled, every case
    % would fail with "no optimization variables enabled" -- while the
    % untouched template still optimizes fine, which is exactly the
    % confusion this guard exists to prevent.  validate must refuse such a
    % setup with a message that names the conflict, before anything runs.

    methods(Test)
        function optimizeRefusesWhenDispersionsCoverEveryEnabledVariable(testCase)
            [lvdData, fx] = testCase.twoVarMission();

            fx.steerVar.setUseTfForVariable(false(1,10));

            setup = testCase.guardSetup(...
                {LvdSweepOptimVarParameter(fx.initStateVar, 1, 'Sweep A', 'none'), ...
                 LvdSweepOptimVarParameter(fx.initStateVar, 2, 'Sweep B', 'none')}, ...
                LvdCaseMatrixRunModeEnum.Optimize);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyFalse(tf, 'Dispersing every enabled element must not validate');
            testCase.verifyTrue(contains(msg, 'Sweep A') && contains(msg, 'Sweep B'), ...
                sprintf('The message must name the offending dispersions, got: %s', msg));
            testCase.verifyTrue(contains(msg, 'Propagate Only'), ...
                'The message must point at the way out');
        end

        function optimizePassesWhenOneEnabledElementSurvives(testCase)
            [lvdData, fx] = testCase.twoVarMission();

            setup = testCase.guardSetup(...
                {LvdSweepOptimVarParameter(fx.initStateVar, 2, 'Sweep B', 'none')}, ...
                LvdCaseMatrixRunModeEnum.Optimize);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyTrue(tf, sprintf('One surviving element must validate, got: %s', msg));
        end

        function duplicateDispersionsOfTheSameElementCountOnce(testCase)
            %Two parameters pinning the same element must not doom it
            %twice: with only elements 4 and 5 enabled and both parameters
            %on element 4, element 5 survives and the setup is fine.
            [lvdData, fx] = testCase.twoVarMission();

            fx.initStateVar.setUseTfForVariable(false(1,7));

            setup = testCase.guardSetup(...
                {LvdSweepOptimVarParameter(fx.steerVar, 4, 'Sweep A', 'none'), ...
                 LvdSweepOptimVarParameter(fx.steerVar, 4, 'Sweep B', 'none')}, ...
                LvdCaseMatrixRunModeEnum.Optimize);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyTrue(tf, sprintf('A twice-pinned element must count once, got: %s', msg));
        end

        function propagateOnlyDoesNotCareAboutPinning(testCase)
            %Propagation never consults the optimizer, so pinning everything
            %is harmless there.
            [lvdData, fx] = testCase.twoVarMission();

            setup = testCase.guardSetup(...
                {LvdSweepOptimVarParameter(fx.initStateVar, 1, 'Sweep A', 'none'), ...
                 LvdSweepOptimVarParameter(fx.initStateVar, 2, 'Sweep B', 'none')}, ...
                LvdCaseMatrixRunModeEnum.PropagateOnly);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyTrue(tf, sprintf('Propagate-only must validate, got: %s', msg));
        end

        function optimizeRefusesAMissionWithNothingEnabled(testCase)
            [lvdData, fx] = testCase.twoVarMission();

            fx.initStateVar.setUseTfForVariable(false(1,7));
            fx.steerVar.setUseTfForVariable(false(1,10));

            setup = testCase.guardSetup(...
                {LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankCapacity, fx.tank)}, ...
                LvdCaseMatrixRunModeEnum.Optimize);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyFalse(tf, 'Optimize mode with no enabled variables must not validate');
            testCase.verifyTrue(contains(msg, 'no optimization variables enabled'), ...
                sprintf('The message must say what is missing, got: %s', msg));
        end

        function knobMassDispersionCountsAgainstTheLiveVariable(testCase)
            %The guard must see through the same redirect the apply uses: a
            %stage dry-mass knob pins the optimizer's set member, so
            %dispersing the only enabled variable refuses even though the
            %stage handle itself is untouched by the accounting.
            [lvdData, fx] = testCase.twoVarMission();

            fx.initStateVar.setUseTfForVariable(false(1,7));
            fx.steerVar.setUseTfForVariable(false(1,10));

            live = StageDryMassOptimizationVariable(fx.stage);
            live.setUseTfForVariable(true);
            lvdData.optimizer.vars.addVariable(live);

            setup = testCase.guardSetup(...
                {LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, fx.stage)}, ...
                LvdCaseMatrixRunModeEnum.Optimize);

            [tf, msg] = setup.validate(lvdData);

            testCase.verifyFalse(tf, 'Pinning the only enabled variable via a knob must not validate');
            testCase.verifyTrue(contains(msg, 'Stage Dry Mass'), ...
                sprintf('The message must name the knob, got: %s', msg));
        end
    end

    methods(Access=private)
        function [lvdData, fx] = twoVarMission(testCase)
            %twoVarMission Default mission, Cartesian orbit, two variables:
            %elements 1-2 of the initial state and elements 4-5 of a
            %steering variable.  Small enough to count by hand.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = ...
                CartesianElementSet(0, [testCase.kerbin.radius + 300; 0; 0], [0; 2.2; 0], testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(60);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            initStateVar = InitialStateVariable(lvdData.initStateModel);
            initStateVar.setUseTfForVariable([true true false false false false false]);
            lvdData.optimizer.vars.addVariable(initStateVar);

            steerModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            steerVar = SetRPYSteeringModelActionOptimVar(steerModel);
            steerVar.setUseTfForVariable([false false false true true false false false false false]);
            lvdData.optimizer.vars.addVariable(steerVar);

            steerEvt = LaunchVehicleEvent(lvdData.script);
            steerEvt.termCond = EventDurationTermCondition(60);
            steerEvt.propagatorObj = steerEvt.twoBodyPropagator;
            lvdData.script.addEvent(steerEvt);

            steerAction = SetSteeringModelAction();
            steerAction.steeringModels.selectedModel = steerModel;
            steerEvt.addAction(steerAction);

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();

            fx = struct('initStateVar', initStateVar, ...
                        'steerVar', steerVar, ...
                        'stage', lvdData.launchVehicle.stages(1), ...
                        'tank', tanks(1));

            testCase.assertNotEmpty(fx.tank, 'Fixture broken: the default vehicle has no tank');
        end

        function setup = guardSetup(testCase, params, runMode)
            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            setup = LvdSweepSetup();
            for(k=1:numel(params))
                setup.addParameter(params{k}, LvdSweepGridVariation(0, 1, 1));
            end
            setup.samplingMode = LvdSweepSamplingEnum.FullFactorial;
            setup.runMode = runMode;
            setup.persistCaseFiles = false;
            setup.writeGaTimeSeries = false;
            setup.writeXlsx = false;
            setup.writeMat = false;
            setup.writeCsv = false;
            setup.outputLocation = outDir;

            setup.addResponse(LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), ...
                                               LvdSweepResponseNodeEnum.InitialState, 0));
        end
    end
end
