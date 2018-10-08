classdef InitialStateModel < matlab.mixin.SetGet
    %InitialStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double = 0;
        centralBody(1,1) KSPTOT_BodyInfo
        
        orbitModel(1,1) AbstractOrbitStateModel = BodyFixedOrbitStateModel.getDefaultOrbitState()
        
        lvState(1,:) LaunchVehicleState
        stageStates(1,:) LaunchVehicleStageState
        
        aero(1,1) LaunchVehicleAeroState
        
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
        
        optVar InitialStateVariable
    end
    
    methods
        function obj = InitialStateModel()
            
        end
        
        function addStageState(obj, newStageState)
            obj.stageStates(end+1) = newStageState;
        end
        
        function removeStageStateForStage(obj, stage)
            stageStateInd = find([obj.stageStates.stage] == stage,1,'first');
%             stageState = obj.stageStates(stageStateInd);
            
%             stage = stageState.stage;
            
%             for(i=1:length(stage.engines))
%                 stageState.removeEngineStateForEngine(stage.engines(i));
%             end
%             
%             for(i=1:length(stage.tanks))
%                 stageState.removeTankStateForTank(stage.tanks(i));
%             end
            
            obj.stageStates(stageStateInd) = [];
        end
        
        function stateLogEntry = getInitialStateLogEntry(obj)
            stateLogEntry = LaunchVehicleStateLogEntry();
            
            ut = obj.time;
            stateLogEntry.time = ut;
            
            [rVectECI, vVectECI] = obj.orbitModel.getPositionAndVelocityVector(ut, obj.centralBody);
            stateLogEntry.position = rVectECI;
            stateLogEntry.velocity = vVectECI;
            
            stateLogEntry.centralBody = obj.centralBody;
            stateLogEntry.lvState = obj.lvState.deepCopy();
        
            for(i=1:length(obj.stageStates))
                stateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy();
            end
            
            stateLogEntry.event = LaunchVehicleEvent.empty(0,1);
            stateLogEntry.aero = obj.aero.deepCopy();

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
            
            vars(end+1) = obj.steeringModel.getExistingOptVar();
            vars(end+1) = obj.throttleModel.getExistingOptVar();
        end
    end

    methods(Static)
        function stateLogModel = getDefaultInitialStateLogModelForLaunchVehicle(lv, bodyInfo)
            stateLogModel = InitialStateModel();
            
            ut = 0;
            stateLogModel.time = ut;
            
            stateLogModel.centralBody = bodyInfo;
            
            lvsState = LaunchVehicleState(lv);
            stateLogModel.lvState = lvsState;
            
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
            
            rpyModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
            stateLogModel.steeringModel = rpyModel;
            
            throtModel = ThrottlePolyModel.getDefaultThrottleModel();
            stateLogModel.throttleModel = throtModel;
        end
    end
end

