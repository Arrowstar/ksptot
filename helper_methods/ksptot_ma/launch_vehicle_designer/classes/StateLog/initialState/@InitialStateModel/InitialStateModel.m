classdef InitialStateModel < matlab.mixin.SetGet
    %InitialStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double = 0;
        centralBody(1,1) KSPTOT_BodyInfo
        
        orbitModel(1,1) AbstractOrbitStateModel = BodyFixedOrbitStateModel.getDefaultOrbitState()
        
        lvState LaunchVehicleState
        stageStates LaunchVehicleStageState
        
        aero(1,1) LaunchVehicleAeroState
        thirdBodyGravity(1,1) LaunchVehicle3BodyGravState
        
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
        
        optVar InitialStateVariable
    end
    
    methods
        function obj = InitialStateModel()
            
        end
        
        function cb = getCentralBodyForStateLog(obj)
            if(isa(obj.orbitModel,'BodyFixedOrbitStateModel'))
                cb = obj.centralBody;
            elseif(isa(obj.orbitModel,'KeplerianOrbitStateModel'))
                cb = obj.centralBody;
            elseif(isa(obj.orbitModel,'CR3BPOrbitStateModel'))
                cb = obj.centralBody.getParBodyInfo(obj.centralBody.celBodyData);
            end
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
            
            [rVectECI, vVectECI] = obj.orbitModel.getPositionAndVelocityVector(ut, obj.centralBody);
            stateLogEntry.position = rVectECI;
            stateLogEntry.velocity = vVectECI;
            
            stateLogEntry.centralBody = obj.getCentralBodyForStateLog();
            stateLogEntry.lvState = obj.lvState.deepCopy();
        
            for(i=1:length(obj.stageStates))
                stateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy();
            end
            
            stateLogEntry.event = LaunchVehicleEvent.empty(0,1);
            stateLogEntry.aero = obj.aero.deepCopy();
            stateLogEntry.thirdBodyGravity = obj.thirdBodyGravity.copy();
            
            stopwatches = stateLogEntry.launchVehicle.stopwatches;
            for(i=1:length(stopwatches))
                stateLogEntry.stopwatchStates(end+1) = stopwatches(i).createInitialState();
            end
            
            extrema = stateLogEntry.launchVehicle.extrema;
            for(i=1:length(extrema))
                stateLogEntry.extremaStates(end+1) = extrema(i).createInitialState();
            end
            
            obj.steeringModel.setT0(obj.time);
            obj.throttleModel.setT0(obj.time);
            
            stateLogEntry.steeringModel = obj.steeringModel;
            stateLogEntry.throttleModel = obj.throttleModel;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = InitialStateVariable(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
        end
        
        function vars = getAllOptVars(obj)
            vars = obj.getExistingOptVar();
            
            steeringVar = obj.steeringModel.getExistingOptVar();
            if(not(isempty(steeringVar)))
                vars(end+1) = obj.steeringModel.getExistingOptVar();
            end
            
            throttleVar = obj.throttleModel.getExistingOptVar();
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
    end

    methods(Static)
        function stateLogModel = getDefaultInitialStateLogModelForLaunchVehicle(lv, bodyInfo)
            celBodyData = lv.lvdData.celBodyData;
            stateLogModel = InitialStateModel();
            
            ut = 0;
            stateLogModel.time = ut;
            
            stateLogModel.centralBody = bodyInfo;
            
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
            aeroState.area = 1;
            aeroState.Cd = 2.2;
            stateLogModel.aero = aeroState;
            
            grav3Body = LaunchVehicle3BodyGravState();
            bNames = fieldnames(celBodyData);
            for(i=1:length(bNames))
                grav3Body.bodies(end+1) = celBodyData.(bNames{i});
            end
            grav3Body.celBodyData = celBodyData;
            stateLogModel.thirdBodyGravity = grav3Body;
            
            rpyModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            stateLogModel.steeringModel = rpyModel;
            
            throtModel = ThrottlePolyModel.getDefaultThrottleModel();
            stateLogModel.throttleModel = throtModel;
        end
    end
end

