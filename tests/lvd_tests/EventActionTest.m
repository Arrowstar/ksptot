classdef EventActionTest < KsptotTestCase
    %EventActionTest LVD AbstractEventAction subclasses.
    %
    % One parameterized test dispatches (by name, via dynamic method-name
    % dispatch) to a per-type check method -- the same pattern used by
    % EventTerminationConditionTest.m -- since matlab.unittest
    % TestParameter values must be simple data, not function handles bound
    % to the test instance.
    %
    % Each check builds a small fixture LaunchVehicleStateLogEntry (via
    % LvdData.getDefaultLvdData + InitialStateModel.getInitialStateLogEntry,
    % optionally augmented with an extra sensor/extremum/plugin
    % variable/tank-to-tank connection/power component), applies the
    % action under test via executeAction(), and verifies:
    %   (1) the intended field changed by the analytically/independently
    %       expected amount, and
    %   (2) unrelated fields (mass of *other* tanks, unrelated sensor
    %       properties, attitude, etc.) are unchanged -- captured into a
    %       plain-value local BEFORE calling executeAction(), since most
    %       actions mutate the state log entry in place rather than
    %       returning a deep copy (only SetKinematicStateAction and
    %       ConditionalAction deep-copy).
    %
    % Object-identity checks (e.g. "the new model was actually assigned")
    % use == directly, since every supporting class here
    % (DragCoeffModel, LiftCoeffModel, steering models, KSPTOT_BodyInfo,
    % sensors, tanks, connections, etc.) is matlab.mixin.SetGet-based,
    % i.e. a handle class, so == is safe object-identity comparison
    % throughout -- exactly the mechanism production code itself relies on
    % for state lookups (e.g. [stageStates.stage] == obj.stage).
    %
    % Two genuine production bugs were found and are pinned below as
    % documented regression tests (SetLiftAeroProperties,
    % SetRectangularSensorAzAngle) rather than fixed -- see the header
    % comments on checkSetLiftAeroProperties/checkSetRectangularSensorAzAngle
    % for the full technical description. If either bug is ever fixed,
    % those two pinned tests should be retired/rewritten.
    %
    % Skipped (documented, not silently omitted):
    %   - SetLvdPluginVarGaTaskValueAction: requires a full
    %     GraphicalAnalysisTask/state-log-matrix fixture (the same
    %     ma_getDepVarValueUnit machinery used by extrema); judged out of
    %     proportion to the value added for this pass.
    %   - AddDeltaVAction's useDeltaMass=true path (mass depletion via
    %     getTankMDotsAndTotalThrustForStateLogEntry/revRocketEqn) is not
    %     covered; only useDeltaMass=false is tested for both frames. That
    %     path pulls in the full engine/tank/throttle/steering/power
    %     force-model stack (already covered in
    %     DragThrustLiftSrpForceModelTest/PropagatorTest), and duplicating
    %     that fixture here for one more action was judged out of
    %     proportion to the value added.

    properties(TestParameter)
        actionCase = {'AddDeltaVInertial', 'AddDeltaVOrbitNtw', 'AddMassToTank', ...
            'AddValueToLvdPluginVarValue', ...
            'ConditionalActionIfBranch', 'ConditionalActionElseIfBranch', 'ConditionalActionElseBranch', ...
            'ResetExtremumValue', 'SetConicalSensorAngle', 'SetDragAeroProperties', ...
            'SetEngineActiveState', 'SetEngineTankConnActiveState', 'SetExtremumRecordingState', ...
            'SetHoldDownClampActiveStateTrue', 'SetHoldDownClampActiveStateFalse', ...
            'SetKinematicState', 'SetLiftAeroProperties', 'SetLvdPluginVarValue', 'SetNextEvent', ...
            'SetPowerSinkActiveState', 'SetPowerSrcActiveState', 'SetPowerStorageActiveState', ...
            'SetRectangularSensorAzAngle', 'SetRectangularSensorDecAngle', ...
            'SetSensorActiveState', 'SetSensorMaxRange', 'SetSensorSteeringModel', ...
            'SetSolarRadPressProperties', 'SetStageActiveState', 'SetSteeringModel', ...
            'SetStopwatchRunningState', 'SetTankTankConnActiveState', 'SetTankTankConnFlowRate', ...
            'SetThirdBodyGravitySources', 'SetThrottleModel'};
    end

    methods(Test)
        function eventActionMatchesIndependentOracle(testCase, actionCase)
            testCase.(['check' actionCase])();
        end
    end

    methods(Access=private)

        %% -------------------------------------------------- AddDeltaV

        function checkAddDeltaVInertial(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            entry.position = [7000; 0; 0];
            entry.velocity = [0; 7.5; 0.2];
            velocityBefore = entry.velocity;
            tankStates0 = entry.getAllTankStates();
            tankMassBefore = tankStates0(1).tankMass;

            dv = [0.1; -0.05; 0.02];
            action = AddDeltaVAction(dv, DeltaVFrameEnum.Inertial, false);
            newEntry = action.executeAction(entry);

            testCase.verifyVectorEqual(newEntry.velocity, velocityBefore + dv, 1e-12, ...
                'AddDeltaVAction (Inertial) did not add the delta-v vector directly to velocity');

            newTankStates = newEntry.getAllTankStates();
            testCase.verifyEqual(newTankStates(1).tankMass, tankMassBefore, 'AbsTol', 1e-12, ...
                'AddDeltaVAction (Inertial, useDeltaMass=false) unexpectedly changed tank mass');
        end

        function checkAddDeltaVOrbitNtw(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            r0 = [7000; 500; 200];
            v0 = [0.1; 7.4; 0.3];
            entry.position = r0;
            entry.velocity = v0;

            dv = [0.2; -0.03; 0.01]; %[Prograde(T); Normal(W); Radial(N)]
            action = AddDeltaVAction(dv, DeltaVFrameEnum.OrbitNtw, false);
            newEntry = action.executeAction(entry);

            %Independent T/W/N reconstruction -- deliberately NOT calling
            %getNTW2ECIdvVect.m (the function used by the production
            %code), just cross/norm from scratch.
            tHat = v0 / norm(v0);
            wHat = cross(r0, v0) / norm(cross(r0, v0));
            nHat = cross(tHat, wHat);
            dvEciExpected = dv(1)*tHat + dv(2)*wHat + dv(3)*nHat;

            testCase.verifyVectorEqual(newEntry.velocity, v0 + dvEciExpected, 1e-10, ...
                'AddDeltaVAction (OrbitNtw) does not match the independent T/W/N reconstruction');
        end

        %% -------------------------------------------------- AddMassToTank

        function checkAddMassToTank(testCase)
            [~, entry, tank1, tank2] = testCase.buildEntryWithTwoTanks();
            tankStates0 = entry.getAllTankStates();
            tank1Mass0 = tankStates0([tankStates0.tank] == tank1).tankMass;
            tank2Mass0 = tankStates0([tankStates0.tank] == tank2).tankMass;

            action = AddMassToTankAction(tank1, 1.5);
            newEntry = action.executeAction(entry);

            newTankStates = newEntry.getAllTankStates();
            newTank1State = newTankStates([newTankStates.tank] == tank1);
            newTank2State = newTankStates([newTankStates.tank] == tank2);

            testCase.verifyEqual(newTank1State.tankMass, tank1Mass0 + 1.5, 'AbsTol', 1e-12, ...
                'AddMassToTankAction did not add the requested mass to the target tank');
            testCase.verifyEqual(newTank2State.tankMass, tank2Mass0, 'AbsTol', 1e-12, ...
                'AddMassToTankAction unexpectedly changed the mass of an unrelated tank');

            %Floor-at-zero clamp
            action2 = AddMassToTankAction(tank1, -1e6);
            newEntry2 = action2.executeAction(entry);
            newTank1State2 = newEntry2.getAllTankStates();
            newTank1State2 = newTank1State2([newTank1State2.tank] == tank1);
            testCase.verifyEqual(newTank1State2.tankMass, 0, 'AbsTol', 1e-12, ...
                'AddMassToTankAction did not clamp tank mass at zero for a large negative massToAdd');
        end

        %% ------------------------------------------- Plugin variable actions

        function checkAddValueToLvdPluginVarValue(testCase)
            [~, entry, pluginVar] = testCase.buildEntryWithPluginVar();
            tankStates0 = entry.getAllTankStates();
            tankMassBefore = tankStates0(1).tankMass;

            action = AddValueToLvdPluginVarValueAction(pluginVar, 2.5);
            newEntry = action.executeAction(entry);

            testCase.verifyEqual(pluginVar.value, 7.5, 'AbsTol', 1e-12, ...
                'AddValueToLvdPluginVarValueAction did not add the offset to pluginVar.value');
            pluginVarState = newEntry.getPluginVarStateForPluginVar(pluginVar);
            testCase.verifyEqual(pluginVarState.valueAtState, 7.5, 'AbsTol', 1e-12, ...
                'AddValueToLvdPluginVarValueAction did not update the state-log plugin var state');

            newTankStates = newEntry.getAllTankStates();
            testCase.verifyEqual(newTankStates(1).tankMass, tankMassBefore, 'AbsTol', 1e-12, ...
                'AddValueToLvdPluginVarValueAction unexpectedly changed tank mass');
        end

        function checkSetLvdPluginVarValue(testCase)
            [~, entry, pluginVar] = testCase.buildEntryWithPluginVar();
            tankStates0 = entry.getAllTankStates();
            tankMassBefore = tankStates0(1).tankMass;

            action = SetLvdPluginVarValueAction(pluginVar, -3.25);
            newEntry = action.executeAction(entry);

            testCase.verifyEqual(pluginVar.value, -3.25, 'AbsTol', 1e-12, ...
                'SetLvdPluginVarValueAction did not set pluginVar.value');
            pluginVarState = newEntry.getPluginVarStateForPluginVar(pluginVar);
            testCase.verifyEqual(pluginVarState.valueAtState, -3.25, 'AbsTol', 1e-12, ...
                'SetLvdPluginVarValueAction did not update the state-log plugin var state');

            newTankStates = newEntry.getAllTankStates();
            testCase.verifyEqual(newTankStates(1).tankMass, tankMassBefore, 'AbsTol', 1e-12, ...
                'SetLvdPluginVarValueAction unexpectedly changed tank mass');
        end

        %% ------------------------------------------------ ConditionalAction

        function checkConditionalActionIfBranch(testCase)
            testCase.runConditionalActionCheck(AlwaysTrueActionCondition(), AlwaysTrueActionCondition(), 1);
        end

        function checkConditionalActionElseIfBranch(testCase)
            testCase.runConditionalActionCheck(AlwaysFalseActionCondition(), AlwaysTrueActionCondition(), 2);
        end

        function checkConditionalActionElseBranch(testCase)
            testCase.runConditionalActionCheck(AlwaysFalseActionCondition(), AlwaysFalseActionCondition(), 3);
        end

        function runConditionalActionCheck(testCase, ifCond, elseIfCond, expectedMarker)
            [~, entry, pluginVar] = testCase.buildEntryWithPluginVar();
            tankStates0 = entry.getAllTankStates();
            tankMassBefore = tankStates0(1).tankMass;

            ifAction = SetLvdPluginVarValueAction(pluginVar, 1);
            elseIfAction = SetLvdPluginVarValueAction(pluginVar, 2);
            elseAction = SetLvdPluginVarValueAction(pluginVar, 3);

            condAction = ConditionalAction();
            condAction.ifCondition = ifCond;
            condAction.addIfAction(ifAction);
            condAction.addElseIfConditional(elseIfCond);
            condAction.addElseIfAction(elseIfCond, elseIfAction);
            condAction.addElseAction(elseAction);

            newEntry = condAction.executeAction(entry);

            pluginVarState = newEntry.getPluginVarStateForPluginVar(pluginVar);
            testCase.verifyEqual(pluginVarState.valueAtState, expectedMarker, ...
                'ConditionalAction did not dispatch to the expected branch');
            testCase.verifyEqual(pluginVar.value, expectedMarker, ...
                'ConditionalAction branch action did not update the plugin variable value');

            newTankStates = newEntry.getAllTankStates();
            testCase.verifyEqual(newTankStates(1).tankMass, tankMassBefore, 'AbsTol', 1e-12, ...
                'ConditionalAction unexpectedly changed unrelated tank mass');

            testCase.verifyNotSameHandle(newEntry, entry, ...
                'ConditionalAction.executeAction must deep-copy the state log entry');
        end

        %% ------------------------------------------------------- Extrema

        function checkResetExtremumValue(testCase)
            [~, entry, ex] = testCase.buildEntryWithExtremum();
            exStateBefore = entry.extremaStates([entry.extremaStates.extrema] == ex);
            exStateBefore.value = 7.5;
            activeBefore = exStateBefore.active;

            action = ResetExtremumValueAction(ex);
            newEntry = action.executeAction(entry);

            newExState = newEntry.extremaStates([newEntry.extremaStates.extrema] == ex);
            testCase.verifyTrue(isnan(newExState.value), ...
                'ResetExtremumValueAction did not reset value to NaN');
            testCase.verifyEqual(newExState.active, activeBefore, ...
                'ResetExtremumValueAction unexpectedly changed the recording-active state');
        end

        function checkSetExtremumRecordingState(testCase)
            [~, entry, ex] = testCase.buildEntryWithExtremum();
            exStateBefore = entry.extremaStates([entry.extremaStates.extrema] == ex);
            exStateBefore.value = 3.14;

            action = SetExtremumRecordingStateAction(ex, LaunchVehicleExtremaRecordingEnum.NotRecording);
            newEntry = action.executeAction(entry);

            newExState = newEntry.extremaStates([newEntry.extremaStates.extrema] == ex);
            testCase.verifyEqual(newExState.active, LaunchVehicleExtremaRecordingEnum.NotRecording, ...
                'SetExtremumRecordingStateAction did not set the recording state');
            testCase.verifyEqual(newExState.value, 3.14, 'AbsTol', 1e-12, ...
                'SetExtremumRecordingStateAction unexpectedly changed the extremum value');
        end

        %% ------------------------------------------------------- Sensors

        function checkSetConicalSensorAngle(testCase)
            [~, entry, sensor] = testCase.buildEntryWithConicalSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            rangeBefore = sensorStateBefore.range;

            newAngle = deg2rad(25);
            action = SetConicalSensorAngleAction(sensor, newAngle);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyEqual(newSensorState.angle, newAngle, 'AbsTol', 1e-12, ...
                'SetConicalSensorAngleAction did not set sensorState.angle');
            testCase.verifyEqual(newSensorState.range, rangeBefore, 'AbsTol', 1e-12, ...
                'SetConicalSensorAngleAction unexpectedly changed sensorState.range');
        end

        function checkSetSensorActiveState(testCase)
            [~, entry, sensor] = testCase.buildEntryWithConicalSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            angleBefore = sensorStateBefore.angle;

            action = SetSensorActiveStateAction(sensor, false);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyFalse(newSensorState.getSensorActiveState(), ...
                'SetSensorActiveStateAction did not set the sensor active state to false');
            testCase.verifyEqual(newSensorState.angle, angleBefore, 'AbsTol', 1e-12, ...
                'SetSensorActiveStateAction unexpectedly changed sensorState.angle');
        end

        function checkSetSensorMaxRange(testCase)
            [~, entry, sensor] = testCase.buildEntryWithConicalSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            angleBefore = sensorStateBefore.angle;

            action = SetSensorMaxRangeAction(sensor, 750);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyEqual(newSensorState.getSensorMaxRange(), 750, 'AbsTol', 1e-10, ...
                'SetSensorMaxRangeAction did not set the sensor max range');
            testCase.verifyEqual(newSensorState.angle, angleBefore, 'AbsTol', 1e-12, ...
                'SetSensorMaxRangeAction unexpectedly changed sensorState.angle');
        end

        function checkSetSensorSteeringModel(testCase)
            [lvdData, entry, sensor] = testCase.buildEntryWithConicalSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            angleBefore = sensorStateBefore.angle;

            newSteeringModel = FixedInVehicleFrameSensorSteeringModel(0.1, 0.2, 0.3, lvdData);
            action = SetSensorSteeringModelAction(sensor, newSteeringModel);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyTrue(newSensorState.getSensorSteeringMode() == newSteeringModel, ...
                'SetSensorSteeringModelAction did not set the sensor steering model');
            testCase.verifyEqual(newSensorState.angle, angleBefore, 'AbsTol', 1e-12, ...
                'SetSensorSteeringModelAction unexpectedly changed sensorState.angle');
        end

        function checkSetRectangularSensorDecAngle(testCase)
            [~, entry, sensor] = testCase.buildEntryWithRectangularSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            azBefore = sensorStateBefore.azAngle;

            newDecAngle = deg2rad(12);
            action = SetRectangularlSensorDecAngleAction(sensor, newDecAngle);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyEqual(newSensorState.decAngle, newDecAngle, 'AbsTol', 1e-12, ...
                'SetRectangularlSensorDecAngleAction did not set sensorState.decAngle');
            testCase.verifyEqual(newSensorState.azAngle, azBefore, 'AbsTol', 1e-12, ...
                'SetRectangularlSensorDecAngleAction unexpectedly changed sensorState.azAngle');
        end

        function checkSetRectangularSensorAzAngle(testCase)
            %The constructor method inside this classdef file used to be
            %named "SetRectangularlSensorAngleAction" -- missing the "Az" --
            %so MATLAB did not recognise it as the class constructor and
            %silently fell back to the compiler-generated zero-argument one,
            %which rejects any input.  The action was therefore unusable in
            %production whenever built with a non-default value.
            [~, entry, sensor] = testCase.buildEntryWithRectangularSensor();
            sensorStateBefore = entry.getSensorStateForSensor(sensor);
            decBefore = sensorStateBefore.decAngle;

            newAzAngle = deg2rad(20);
            action = SetRectangularlSensorAzAngleAction(sensor, newAzAngle);
            newEntry = action.executeAction(entry);

            newSensorState = newEntry.getSensorStateForSensor(sensor);
            testCase.verifyEqual(newSensorState.azAngle, newAzAngle, 'AbsTol', 1e-12, ...
                'SetRectangularlSensorAzAngleAction did not set sensorState.azAngle');
            testCase.verifyEqual(newSensorState.decAngle, decBefore, 'AbsTol', 1e-12, ...
                'SetRectangularlSensorAzAngleAction unexpectedly changed sensorState.decAngle');
        end

        %% -------------------------------------------------------- Aero

        function checkSetDragAeroProperties(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            liftModelBefore = entry.aero.liftCoeffModel;

            newDragModel = DragCoeffModel();
            action = SetDragAeroPropertiesAction(newDragModel);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.aero.dragCoeffModel == newDragModel, ...
                'SetDragAeroPropertiesAction did not set aero.dragCoeffModel to the new model');
            testCase.verifyTrue(newEntry.aero.liftCoeffModel == liftModelBefore, ...
                'SetDragAeroPropertiesAction unexpectedly changed aero.liftCoeffModel');
        end

        function checkSetLiftAeroProperties(testCase)
            %The constructor method inside this classdef file used to be
            %literally named "SetDragAeroPropertiesAction", copy-pasted from
            %the sibling drag action without renaming.  MATLAB did not
            %recognise it as the class constructor and fell back to the
            %compiler-generated zero-argument one, so the action could never
            %be built with a lift model.  This mirrors
            %checkSetDragAeroProperties.
            [~, entry] = testCase.buildDefaultEntry();
            dragModelBefore = entry.aero.dragCoeffModel;

            newLiftModel = LiftCoeffModel();
            action = SetLiftAeroPropertiesAction(newLiftModel);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.aero.liftCoeffModel == newLiftModel, ...
                'SetLiftAeroPropertiesAction did not set aero.liftCoeffModel to the new model');
            testCase.verifyTrue(newEntry.aero.dragCoeffModel == dragModelBefore, ...
                'SetLiftAeroPropertiesAction unexpectedly changed aero.dragCoeffModel');
        end

        %% ------------------------------------------------------- Engines

        function checkSetEngineActiveState(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            stage = entry.launchVehicle.stages(1);
            engine = stage.engines(1);
            stgStateBefore = entry.stageStates([entry.stageStates.stage] == stage);
            stageActiveBefore = stgStateBefore.active;

            action = SetEngineActiveStateAction(engine, false);
            newEntry = action.executeAction(entry);

            newStgState = newEntry.stageStates([newEntry.stageStates.stage] == stage);
            newEngineState = newStgState.engineStates([newStgState.engineStates.engine] == engine);
            testCase.verifyFalse(newEngineState.active, ...
                'SetEngineActiveStateAction did not set the target engine''s active state to false');
            testCase.verifyEqual(newStgState.active, stageActiveBefore, ...
                'SetEngineActiveStateAction unexpectedly changed the parent stage''s own active state');
        end

        function checkSetEngineTankConnActiveState(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            conn = entry.lvState.e2TConns(1).conn;
            connStateBefore = entry.lvState.e2TConns([entry.lvState.e2TConns.conn] == conn);
            activeBefore = connStateBefore.active;

            action = SetEngineTankConnActiveStateEventAction(conn, not(activeBefore));
            newEntry = action.executeAction(entry);

            newConnState = newEntry.lvState.e2TConns([newEntry.lvState.e2TConns.conn] == conn);
            testCase.verifyEqual(newConnState.active, not(activeBefore), ...
                'SetEngineTankConnActiveStateEventAction did not toggle the connection active state');
        end

        %% ---------------------------------------------- Hold Down Clamp

        function checkSetHoldDownClampActiveStateTrue(testCase)
            %Engaging the clamp must zero the PLANET-RELATIVE velocity, or
            %the integrator carries it through the hold-down.  The body here
            %is non-rotating (rotperiod = Inf, rotini = 0), so the fixed frame
            %coincides with the inertial one and the inertial velocity must
            %come back exactly zero -- an independent statement of the same
            %thing, not a re-run of the production round trip.
            %
            %This used to throw EMLRT:runTime:WrongNumberOfInputs before doing
            %anything: executeAction calls
            %getFixedFrameVectFromInertialVect(time, position, centralBody)
            %with 3 arguments, and that wrapper forwarded only 4 into
            %getFixedFrameVectFromInertialVect_alg_mex, a codegen'd MEX whose
            %fixed entry point requires 5 (ut, rVectECI, rotperiod, rotini,
            %vVectECI).  Two other production call sites
            %(lvd_plotStateLog.m:204 and dcmPlot2.m:19) call it the same way
            %and hit the identical crash, so the fix went into the wrapper:
            %it now supplies the established NaN "no velocity" sentinel when
            %varargin is empty.
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();
            rVect = (bodyInfo.radius + 0.1) * normVector([1; 0.2; 0.1]);
            vVect = [0.05; 0.03; -0.02];
            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            action = SetHoldDownClampActiveStateAction(true);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.lvState.holdDownEnabled, ...
                'SetHoldDownClampActiveStateAction(true) did not set holdDownEnabled to true');
            testCase.verifyVectorEqual(newEntry.velocity, [0;0;0], 1e-12, ...
                ['SetHoldDownClampActiveStateAction(true) must zero the planet-relative ' ...
                 'velocity; on a non-rotating body that is the inertial velocity.']);
            testCase.verifyVectorEqual(newEntry.position, rVect, 1e-12, ...
                'SetHoldDownClampActiveStateAction(true) unexpectedly moved the vehicle');
        end

        function checkSetHoldDownClampActiveStateFalse(testCase)
            [entry, bodyInfo] = testCase.buildNonRotatingEntry();
            rVect = (bodyInfo.radius + 0.1) * normVector([1; 0.2; 0.1]);
            vVect = [0.05; 0.03; -0.02];
            entry.position = rVect; entry.velocity = vVect; entry.time = 0;

            action = SetHoldDownClampActiveStateAction(false);
            newEntry = action.executeAction(entry);

            testCase.verifyFalse(newEntry.lvState.holdDownEnabled, ...
                'SetHoldDownClampActiveStateAction(false) did not set holdDownEnabled to false');
            testCase.verifyVectorEqual(newEntry.velocity, vVect, 1e-12, ...
                'SetHoldDownClampActiveStateAction(false) unexpectedly changed velocity');
        end

        %% ------------------------------------------------ Kinematic State

        function checkSetKinematicState(testCase)
            [lvdData, entry] = testCase.buildDefaultEntry();
            bodyInfo = entry.centralBody;
            gmu = bodyInfo.gm;

            sma = bodyInfo.radius + 500; ecc = 0.1; inc = 0.3; raan = 0.6; argp = 1.1; tru = 2.0;
            frame = bodyInfo.getBodyCenteredInertialFrame();
            orbitModel = KeplerianElementSet(123.4, sma, ecc, inc, raan, argp, tru, frame);

            tankStates0 = entry.getAllTankStates();
            tankMassBefore = tankStates0(1).tankMass;

            action = SetKinematicStateAction(lvdData.stateLog, orbitModel);
            newEntry = action.executeAction(entry);

            %Independent oracle: refCoe2Rv, not the production
            %vect_getStatefromKepler path.
            [rExpected, vExpected] = refCoe2Rv(sma, ecc, inc, raan, argp, tru, gmu);

            testCase.verifyEqual(newEntry.time, 123.4, 'AbsTol', 1e-10, ...
                'SetKinematicStateAction did not set time from the orbit model');
            testCase.verifyVectorEqual(newEntry.position, rExpected, 1e-4, ...
                'SetKinematicStateAction position does not match the independent refCoe2Rv oracle');
            testCase.verifyVectorEqual(newEntry.velocity, vExpected, 1e-7, ...
                'SetKinematicStateAction velocity does not match the independent refCoe2Rv oracle');

            newTankStates = newEntry.getAllTankStates();
            testCase.verifyEqual(newTankStates(1).tankMass, tankMassBefore, 'AbsTol', 1e-12, ...
                'SetKinematicStateAction unexpectedly changed tank mass (stageStates/tankStates arrays default empty so should no-op)');

            testCase.verifyNotSameHandle(newEntry, entry, ...
                'SetKinematicStateAction.executeAction must deep-copy the state log entry');
        end

        %% ---------------------------------------------------- Next Event

        function checkSetNextEvent(testCase)
            [lvdData, entry] = testCase.buildDefaultEntry();
            script = lvdData.script;

            evt2 = LaunchVehicleEvent.getDefaultEvent(script);
            script.addEvent(evt2);

            action = SetNextEventAction(evt2);
            action.executeAction(entry);

            testCase.verifyTrue(evt2.script.nextEventToRun == evt2, ...
                'SetNextEventAction did not set script.nextEventToRun to the target event');
        end

        %% ---------------------------------------------------------- Power

        function checkSetPowerSinkActiveState(testCase)
            [~, entry, sink] = testCase.buildEntryWithPowerSink();
            sinkStateBefore = entry.stageStates(1).powerSinkStates(1).getActiveState();

            action = SetPowerSinkActiveStateAction(sink, false);
            newEntry = action.executeAction(entry);

            newSinkState = newEntry.stageStates(1).powerSinkStates(1);
            testCase.verifyNotEqual(sinkStateBefore, false, ...
                'Fixture assumption violated: power sink should default active=true so false is an observable change');
            testCase.verifyFalse(newSinkState.getActiveState(), ...
                'SetPowerSinkActiveStateAction did not set the sink active state to false');
        end

        function checkSetPowerSrcActiveState(testCase)
            [~, entry, src] = testCase.buildEntryWithPowerSrc();
            srcStateBefore = entry.stageStates(1).powerSrcStates(1).getActiveState();

            action = SetPowerSrcActiveStateAction(src, false);
            newEntry = action.executeAction(entry);

            newSrcState = newEntry.stageStates(1).powerSrcStates(1);
            testCase.verifyNotEqual(srcStateBefore, false, ...
                'Fixture assumption violated: power source should default active=true so false is an observable change');
            testCase.verifyFalse(newSrcState.getActiveState(), ...
                'SetPowerSrcActiveStateAction did not set the source active state to false');
        end

        function checkSetPowerStorageActiveState(testCase)
            [~, entry, battery] = testCase.buildEntryWithBattery();
            storageStateBefore = entry.stageStates(1).powerStorageStates(1).getActiveState();

            action = SetPowerStorageActiveStateAction(battery, false);
            newEntry = action.executeAction(entry);

            newStorageState = newEntry.stageStates(1).powerStorageStates(1);
            testCase.verifyNotEqual(storageStateBefore, false, ...
                'Fixture assumption violated: power storage should default active=true so false is an observable change');
            testCase.verifyFalse(newStorageState.getActiveState(), ...
                'SetPowerStorageActiveStateAction did not set the storage active state to false');
        end

        %% ---------------------------------------------------------- SRP

        function checkSetSolarRadPressProperties(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            aeroBefore = entry.aero;

            newSrp = LaunchVehicleSolarRadPressState();
            action = SetSolarRadPressPropertiesAction(newSrp);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.srp == newSrp, ...
                'SetSolarRadPressPropertiesAction did not set srp to the new model');
            testCase.verifyTrue(newEntry.aero == aeroBefore, ...
                'SetSolarRadPressPropertiesAction unexpectedly changed the aero state');
        end

        %% -------------------------------------------------------- Stage

        function checkSetStageActiveState(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            stage = entry.launchVehicle.stages(1);

            action = SetStageActiveStateAction(stage, false);
            newEntry = action.executeAction(entry);

            newStgState = newEntry.stageStates([newEntry.stageStates.stage] == stage);
            testCase.verifyFalse(newStgState.active, ...
                'SetStageActiveStateAction did not set the stage active state to false');
        end

        %% ------------------------------------------------- Steering/Throttle

        function checkSetSteeringModel(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            newModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();

            action = SetSteeringModelAction(newModel);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.steeringModel == newModel, ...
                'SetSteeringModelAction did not set steeringModel to the new model');
        end

        function checkSetThrottleModel(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            newModel = ThrottlePolyModel.getDefaultThrottleModel();

            action = SetThrottleModelAction(newModel);
            newEntry = action.executeAction(entry);

            testCase.verifyTrue(newEntry.throttleModel == newModel, ...
                'SetThrottleModelAction did not set throttleModel to the new model');
        end

        %% --------------------------------------------------- Stopwatch

        function checkSetStopwatchRunningState(testCase)
            [~, entry, sw] = testCase.buildEntryWithStopwatch(StopwatchRunningEnum.NotRunning, 7);
            swStateBefore = entry.stopwatchStates([entry.stopwatchStates.stopwatch] == sw);
            valueBefore = swStateBefore.value;

            action = SetStopwatchRunningStateAction(sw, StopwatchRunningEnum.Running);
            newEntry = action.executeAction(entry);

            newSwState = newEntry.stopwatchStates([newEntry.stopwatchStates.stopwatch] == sw);
            testCase.verifyEqual(newSwState.running, StopwatchRunningEnum.Running, ...
                'SetStopwatchRunningStateAction did not set the running state');
            testCase.verifyEqual(newSwState.value, valueBefore, 'AbsTol', 1e-12, ...
                'SetStopwatchRunningStateAction unexpectedly changed the stopwatch value');
        end

        %% ---------------------------------------------- Tank-to-tank conns

        function checkSetTankTankConnActiveState(testCase)
            [~, entry, conn] = testCase.buildEntryWithTankToTankConn();
            connStateBefore = entry.lvState.t2TConns([entry.lvState.t2TConns.conn] == conn);
            flowRateBefore = connStateBefore.flowRate;

            action = SetTankTankConnActiveStateEventAction(conn, false);
            newEntry = action.executeAction(entry);

            newConnState = newEntry.lvState.t2TConns([newEntry.lvState.t2TConns.conn] == conn);
            testCase.verifyFalse(newConnState.active, ...
                'SetTankTankConnActiveStateEventAction did not set active to false');
            testCase.verifyEqual(newConnState.flowRate, flowRateBefore, 'AbsTol', 1e-12, ...
                'SetTankTankConnActiveStateEventAction unexpectedly changed flowRate');
        end

        function checkSetTankTankConnFlowRate(testCase)
            [~, entry, conn] = testCase.buildEntryWithTankToTankConn();
            connStateBefore = entry.lvState.t2TConns([entry.lvState.t2TConns.conn] == conn);
            activeBefore = connStateBefore.active;

            action = SetTankTankConnFlowRateEventAction(conn, 2.5);
            newEntry = action.executeAction(entry);

            newConnState = newEntry.lvState.t2TConns([newEntry.lvState.t2TConns.conn] == conn);
            testCase.verifyEqual(newConnState.flowRate, 2.5, 'AbsTol', 1e-12, ...
                'SetTankTankConnFlowRateEventAction did not set the flow rate');
            testCase.verifyEqual(newConnState.active, activeBefore, ...
                'SetTankTankConnFlowRateEventAction unexpectedly changed the active state');
        end

        %% ---------------------------------------------- Third Body Gravity

        function checkSetThirdBodyGravitySources(testCase)
            [~, entry] = testCase.buildDefaultEntry();

            action = SetThirdBodyGravitySourcesAction();
            action.bodiesToSet = [testCase.kerbin, testCase.mun];
            newEntry = action.executeAction(entry);

            testCase.verifyEqual(newEntry.thirdBodyGravity.bodies, [testCase.kerbin, testCase.mun], ...
                'SetThirdBodyGravitySourcesAction did not set thirdBodyGravity.bodies to the requested body array');
        end

        %% ----------------------------------------------- Shared fixtures
        % (buildDefaultEntry / buildKeplerFixture / buildNonRotatingEntry /
        % buildEntryWithTwoTanks / buildEntryWithBattery /
        % buildEntryWithStopwatch copied verbatim from
        % EventTerminationConditionTest.m for self-containment.)

        function [lvdData, entry] = buildDefaultEntry(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [bodyInfo, r, v] = buildKeplerFixture(testCase) %#ok<STOUT,MANU>
            bodyInfo = testCase.kerbin;
            gmu = bodyInfo.gm;
            sma = 8000; ecc = 0.3; inc = 0.5; raan = 1.0; argp = 0.7; nu = 0.9;
            [r, v] = refCoe2Rv(sma, ecc, inc, raan, argp, nu, gmu);
        end

        function [entry, bodyInfo] = buildNonRotatingEntry(testCase)
            [~, entry] = testCase.buildDefaultEntry();
            bodyInfo = testCase.copyBodyInfo(entry.centralBody);
            bodyInfo.rotperiod = Inf;
            bodyInfo.rotini = 0;
            entry.centralBody = bodyInfo;
        end

        function [lvdData, entry, tank1, tank2] = buildEntryWithTwoTanks(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            stg.addTank(tank2);

            lvdData.initStateModel.clearAllTankStatesAndRegenerate();

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, battery] = buildEntryWithBattery(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);

            battery = LaunchVehicleBasicElectricalBattery(stg);
            battery.name = 'Test Battery';
            battery.maxCapacity = 100;
            battery.initialStateOfCharge = 37;
            stg.addPwrStorage(battery);

            stgState = lvdData.initStateModel.stageStates(1);
            newState = battery.createDefaultInitialState(stgState);
            stgState.addPowerStorageState(newState);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, sw] = buildEntryWithStopwatch(testCase, startOn, startValue)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw = LaunchVehicleStopwatch(lvdData);
            sw.startOn = startOn;
            sw.startValue = startValue;
            lvdData.launchVehicle.addStopwatch(sw);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        %% ------------------------------------------- New shared fixtures

        function [lvdData, entry, pluginVar] = buildEntryWithPluginVar(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            pluginVar = LvdPluginOptimVarWrapper();
            pluginVar.name = 'Test Plugin Var';
            pluginVar.value = 5;
            lvdData.pluginVars.addPluginVar(pluginVar);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, ex] = buildEntryWithExtremum(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            ex = LaunchVehicleExtrema(lvdData);
            ex.frame = testCase.kerbin.getBodyCenteredInertialFrame();
            ex.quantStr = 'Altitude';
            lvdData.launchVehicle.addExtremum(ex);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, sensor] = buildEntryWithConicalSensor(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            steeringModel = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('Test Conical Sensor', deg2rad(15), 500, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, sensor] = buildEntryWithRectangularSensor(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            steeringModel = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = RectangularSensor('Test Rectangular Sensor', deg2rad(8), deg2rad(6), 400, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, sink] = buildEntryWithPowerSink(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);

            sink = LaunchVehicleSimplePwrSink(stg);
            stg.addPwrSink(sink);

            stgState = lvdData.initStateModel.stageStates(1);
            newState = sink.createDefaultInitialState(stgState);
            stgState.addPowerSinkState(newState);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, src] = buildEntryWithPowerSrc(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);

            src = LaunchVehicleEpsRtg(stg);
            stg.addPwrSrc(src);

            stgState = lvdData.initStateModel.stageStates(1);
            newState = src.createDefaultInitialState(stgState);
            stgState.addPowerSrcState(newState);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, entry, conn, tank1, tank2] = buildEntryWithTankToTankConn(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            stg.addTank(tank2);

            lvdData.initStateModel.clearAllTankStatesAndRegenerate();

            conn = TankToTankConnection(tank1, tank2);
            connState = TankToTankConnState(conn);
            lvdData.initStateModel.lvState.addT2TConnState(connState);

            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end
    end
end
