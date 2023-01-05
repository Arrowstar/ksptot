classdef InitialStateModel < matlab.mixin.SetGet
    %InitialStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        orbitModel(1,1) = GeographicElementSet.getDefaultElements();

        lvState LaunchVehicleState
        stageStates LaunchVehicleStageState
        
        aero(1,1) LaunchVehicleAeroState
        thirdBodyGravity(1,1) LaunchVehicle3BodyGravState
        srp(1,1) LaunchVehicleSolarRadPressState
        
        steeringModels SteeringModelsSet
        throttleModels ThrottleModelsSet
        
        optVar InitialStateVariable
    end

    %deprecated
    properties(Access=private)
        steeringModel AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
    
    properties(Dependent)
        time(1,1) double
        centralBody(1,1) KSPTOT_BodyInfo
    end
    
    methods
        function obj = InitialStateModel()
            obj.steeringModels = SteeringModelsSet();
            obj.throttleModels = ThrottleModelsSet();
        end
        
        function time = get.time(obj)
            time = obj.orbitModel.time;
        end
        
        function set.time(obj, newTime)
            obj.orbitModel.time = newTime;
        end
        
        function time = get.centralBody(obj)
            time = obj.orbitModel.frame.getOriginBody();
        end
        
        function set.centralBody(obj, newCentralBody)
            if(isempty(obj.orbitModel.frame))
                obj.orbitModel.frame = newCentralBody.getBodyCenteredInertialFrame();
            end
            obj.orbitModel.frame.setOriginBody(newCentralBody);
        end
        
        function set.orbitModel(obj, newOrbitModel)
            if(isa(newOrbitModel,'AbstractOrbitStateModel'))
                if(isa(newOrbitModel,'BodyFixedOrbitStateModel'))
                    newFrame = obj.centralBody.getBodyFixedFrame(); %#ok<MCSUP> 
                    elemSet = GeographicElementSet(obj.time, newOrbitModel.lat, newOrbitModel.long, newOrbitModel.alt, ...
                                                   newOrbitModel.vVectNEZ_az, newOrbitModel.vVectNEZ_el, newOrbitModel.vVectNEZ_mag, newFrame); %#ok<MCSUP>

                elseif(isa(newOrbitModel,'KeplerianOrbitStateModel'))
                    newFrame = obj.centralBody.getBodyCenteredInertialFrame(); %#ok<MCSUP> 
                    elemSet = KeplerianElementSet(obj.time, newOrbitModel.sma, newOrbitModel.ecc, newOrbitModel.inc, ...
                                                  newOrbitModel.raan, newOrbitModel.arg, newOrbitModel.tru, newFrame); %#ok<MCSUP>
                    
                elseif(isa(newOrbitModel,'CR3BPOrbitStateModel'))
                    error('No conversion available for CR3BPOrbitStateModel to new element set models.');
                end

                obj.orbitModel = elemSet;
            else
                obj.orbitModel = newOrbitModel;
            end
        end
        
        function cb = getCentralBodyForStateLog(obj)
            cb = obj.orbitModel.frame.getOriginBody();
        end
        
        function addStageState(obj, newStageState)
            obj.stageStates(end+1) = newStageState;
        end
        
        function removeStageStateForStage(obj, stage)
            stageStateInd = find([obj.stageStates.stage] == stage,1,'first');
            
            obj.stageStates(stageStateInd) = [];
        end
        
        function stateLogEntry = getInitialStateLogEntry(obj)
            stateLogEntry = LaunchVehicleStateLogEntry();
            
            ut = obj.time;
            stateLogEntry.time = ut;
            
            iFrame = obj.centralBody.getBodyCenteredInertialFrame();
            cartElemSet = obj.orbitModel.convertToFrame(iFrame).convertToCartesianElementSet();
            stateLogEntry.position = cartElemSet.rVect;
            stateLogEntry.velocity = cartElemSet.vVect;
            
            stateLogEntry.centralBody = obj.getCentralBodyForStateLog();
            stateLogEntry.lvState = obj.lvState.deepCopy();
        
            for(i=1:length(obj.stageStates))
                stateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy(true, stateLogEntry.lvState);
            end

            tankStates = stateLogEntry.getAllTankStates();
            for(i=1:length(tankStates))
                tankState = tankStates(i);
                tankState.tankMass = tankState.tank.initialMass;
            end
            
            stateLogEntry.event = LaunchVehicleEvent.empty(0,1);
            stateLogEntry.aero = obj.aero.deepCopy();
            stateLogEntry.thirdBodyGravity = obj.thirdBodyGravity.copy();
            stateLogEntry.srp = obj.srp.deepCopy();
            
            stopwatches = stateLogEntry.launchVehicle.stopwatches;
            for(i=1:length(stopwatches))
                stateLogEntry.stopwatchStates(end+1) = stopwatches(i).createInitialState();
            end
            
            extrema = stateLogEntry.launchVehicle.extrema;
            for(i=1:length(extrema))
                stateLogEntry.extremaStates(end+1) = extrema(i).createInitialState();
            end
            
            calcObjs = stateLogEntry.launchVehicle.calcObjs;
            for(i=1:length(calcObjs))
                stateLogEntry.calcObjStates(end+1) = calcObjs(i).createInitialState();
            end
            
            obj.steeringModels.selectedModel.setT0(obj.time);
            obj.throttleModels.selectedModel.setT0(obj.time);
            
            stateLogEntry.steeringModel = obj.steeringModels.selectedModel;
            stateLogEntry.throttleModel = obj.throttleModels.selectedModel;
            
            [~,sensors] = stateLogEntry.launchVehicle.lvdData.sensors.getListboxStr();
            for(i=1:length(sensors))
                stateLogEntry.sensorStates(end+1) = sensors(i).getInitialState();
            end
        end
        
        function optVar = getNewOptVar(obj)
            optVar = InitialStateVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function vars = getAllOptVars(obj)
            vars = obj.getExistingOptVar();
            
            steeringVar = obj.steeringModels.selectedModel.getExistingOptVar();
            if(not(isempty(steeringVar)))
                vars(end+1) = obj.steeringModels.selectedModel.getExistingOptVar();
            end
            
            throttleVar = obj.throttleModels.selectedModel.getExistingOptVar();
            if(not(isempty(throttleVar)))
                vars(end+1) = throttleVar;
            end
        end
        
        function clearAllTankStatesAndRegenerate(obj)
            for(i=1:length(obj.stageStates))
                stgState = obj.stageStates(i);
                
                stgState.tankStates = LaunchVehicleTankState.empty(1,0);
                
                stage = stgState.stage;
                for(j=1:length(stage.tanks))
                    tank = stage.tanks(j);
                    
                    newTankState = LaunchVehicleTankState(stgState);
                    newTankState.tank = tank;
                    newTankState.tankMass = tank.initialMass;
                    
                    stgState.addTankState(newTankState);
                end
            end
        end
        
        function clearDuplicateEngineStates(obj)
            for(i=1:length(obj.stageStates))
                stgState = obj.stageStates(i);
                
                stage = stgState.stage;
                for(j=1:length(stage.engines))
                    engine = stage.engines(j);
                    engineStates = stgState.engineStates;
                    
                    thisEngineStates = engineStates([engineStates.engine] == engine);
                    if(length(thisEngineStates) > 1)
                        thisEngineStateToSave = thisEngineStates(1);
                        
                        engineStates(engineStates == engine) = LaunchVehicleEngineState.empty(1,0);
                        engineStates(end+1) = thisEngineStateToSave; %#ok<AGROW>
                    elseif(isempty(thisEngineStates))
                        newEngineState = LaunchVehicleEngineState(stgState);
                        newEngineState.engine = engine;
                        engineStates(end+1) = newEngineState; %#ok<AGROW>
                    end
                    
%                     notThisEngineStates = engineStates([engineStates.engine] ~= engine);
%                     if(not(isempty(notThisEngineStates)))
%                         engineStates = setdiff(engineStates, notThisEngineStates);
%                     end
                    
                    stgState.engineStates = engineStates;
                end
            end
        end
        
        function tf = isVarFromInitialState(obj, var)           
            tf = obj.optVar == var;
            
            if(not(isempty(obj)) && not(isempty(obj.optVar)))
                tf = tf || obj.optVar.isVarContainedWithin(var);
            end
            
            if(not(isempty(obj.steeringModels.selectedModel.getExistingOptVar())))
                tf = tf || obj.steeringModels.selectedModel.getExistingOptVar() == var;
            end
            
            if(not(isempty(obj.throttleModels.selectedModel.getExistingOptVar())))
                tf = tf || obj.throttleModels.selectedModel.getExistingOptVar() == var;
            end
        end
        
        function setInitialStateFromStateLogEntry(obj, stateLogEntry)
            lvdData = stateLogEntry.lvdData;
            varSet = lvdData.optimizer.vars;
            
            %remove variables
            orbitVar = obj.optVar.orbitVar;
            varSet.removeVariable(orbitVar);
            
            initStateVar = obj.optVar;
            varSet.removeVariable(initStateVar);
            
            steerVar = obj.steeringModels.selectedModel.getExistingOptVar();
            varSet.removeVariable(steerVar);
            
            throttleVar = obj.throttleModels.selectedModel.getExistingOptVar();
            varSet.removeVariable(throttleVar);
            
            %set elements
            obj.orbitModel = stateLogEntry.getCartesianElementSetRepresentation();

            obj.lvState = stateLogEntry.lvState;
            obj.stageStates = stateLogEntry.stageStates;

            tankStates = stateLogEntry.getAllTankStates();
            for(i=1:length(tankStates))
                tankState = tankStates(i);
                tankState.tank.initialMass = tankState.tankMass;
            end

            obj.aero = stateLogEntry.aero;
            obj.thirdBodyGravity = stateLogEntry.thirdBodyGravity;
            obj.srp = stateLogEntry.srp;
            
            oldSteerModelT0 = stateLogEntry.steeringModel.getT0();
            newSteerModelT0 = stateLogEntry.time;
            tOffsetDelta = newSteerModelT0 - oldSteerModelT0;
            obj.steeringModels.selectedModel = stateLogEntry.steeringModel;
            obj.steeringModels.selectedModel.setInitialAttitudeFromState(stateLogEntry, tOffsetDelta);
            
            oldThrottleModelT0 = stateLogEntry.throttleModel.getT0();
            newThrottleModelT0 = stateLogEntry.time;
            tOffsetDelta = newThrottleModelT0 - oldThrottleModelT0;
            obj.throttleModels.selectedModel = stateLogEntry.throttleModel;
            obj.throttleModels.selectedModel.setInitialThrottleFromState(stateLogEntry, tOffsetDelta);
            
            %clean up
            obj.clearDuplicateEngineStates();
        end
    end

    methods(Static)
        function stateLogModel = getDefaultInitialStateLogModelForLaunchVehicle(lv, bodyInfo)
            celBodyData = lv.lvdData.celBodyData;
            stateLogModel = InitialStateModel();
            
            ut = 0;
            bfFrame = bodyInfo.getBodyFixedFrame();
            geoElemSet = GeographicElementSet(ut, 0, 0, 0, 0, 0, 0, bfFrame);
            stateLogModel.orbitModel = geoElemSet;
            
            lvsState = LaunchVehicleState(lv);
            stateLogModel.lvState = lvsState;
            lvsState.holdDownEnabled = false;
            
            for(i=1:length(lv.engineTankConns)) %#ok<*NO4LP>
                e2TConnState = EngineToTankConnState(lv.engineTankConns(i));
                e2TConnState.active = true;
                lvsState.e2TConns(end+1) = e2TConnState;
            end
            
            stageStates = LaunchVehicleStageState.empty(1,0);
            for(i=1:length(lv.stages))
                stage = lv.stages(i);
                stgState = LaunchVehicleStageState(stage);
                stgState.active = true;
                
                engines = stage.engines;
                for(j=1:length(engines))
                    engine = engines(j);
                    
                    engineState = LaunchVehicleEngineState(stgState);
                    engineState.engine = engine;
                    engineState.active = true;
                    
                    stgState.engineStates(end+1) = engineState;
                end
                 
                tanks = stage.tanks;
                for(j=1:length(tanks))
                    tank = tanks(j);
                    
                    tankState = LaunchVehicleTankState(stgState);
                    tankState.tank = tank;
                    tankState.tankMass = tank.initialMass;
                    
                    stgState.tankStates(end+1) = tankState;
                end
                
                stageStates(end+1) = stgState; %#ok<AGROW>
            end
            stateLogModel.stageStates = stageStates;
            
            aeroState = LaunchVehicleAeroState();
            stateLogModel.aero = aeroState;
            
            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.celBodyData = celBodyData;
            stateLogModel.thirdBodyGravity = grav3Body;

            stateLogModel.srp = LaunchVehicleSolarRadPressState();
            
            rpyModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            stateLogModel.steeringModel = rpyModel;
            
            throtModel = ThrottlePolyModel.getDefaultThrottleModel();
            stateLogModel.throttleModel = throtModel;
        end

        function obj = loadobj(obj)
            arguments
                obj InitialStateModel
            end

            if(isempty(obj.steeringModels))
                obj.steeringModels = SteeringModelsSet();
                obj.steeringModels.selectedModel = obj.steeringModel;
% 
%             elseif(obj.steeringModels.selectedModel ~= obj.steeringModel)
%                 obj.steeringModels.selectedModel = obj.steeringModel;
            end

            if(isempty(obj.throttleModels))
                obj.throttleModels = ThrottleModelsSet();
                obj.throttleModels.selectedModel = obj.throttleModel;

%             elseif(obj.throttleModels.selectedModel ~= obj.throttleModel)
%                 obj.throttleModels.selectedModel = obj.throttleModel;
            end
        end
    end
end