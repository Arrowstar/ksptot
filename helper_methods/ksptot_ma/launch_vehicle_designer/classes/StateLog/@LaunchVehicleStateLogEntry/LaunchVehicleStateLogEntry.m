classdef LaunchVehicleStateLogEntry < matlab.mixin.SetGet
    %LaunchVehicleStateLogEntry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double = 0;
        position(3,1) double = [0;0;0];
        velocity(3,1) double = [0;0;0];
        centralBody(1,1) KSPTOT_BodyInfo
        stageStates(1,:) LaunchVehicleStageState
        event(1,1)
        attitude(1,1) LaunchVehicleAttitudeState 
        throttle(1,1) double = 0;
        aero(1,1) LaunchVehicleAeroState
        
        steeringModel(1,1) AbstractSteeringModel
        throttleModel(1,1) AbstractThrottleModel
    end
    
    methods
        function obj = LaunchVehicleStateLogEntry()
            
        end
        
        function [t,y, tankStateInds] = getIntegratorStateRepresentation(obj)
            t = obj.time;
            
            y = [];
            y = horzcat(y, obj.position');
            y = horzcat(y, obj.velocity');
            
            tankStateInd = 7;
            tankStateInds = [];
            tankStates = obj.getAllTankStates();
            for(i=1:length(tankStates))
                tankStateInds(end+1) = tankStateInd; %#ok<AGROW>
                y = [y,tankStates(i).getTankMass()]; %#ok<AGROW>
                
                tankStateInd = tankStateInd + 1;
            end
        end
        
        function tankStates = getAllTankStates(obj)
            tankStates = LaunchVehicleTankState.empty(0,1);
            
            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                
                if(stgState.active)
                    tankStates = horzcat(tankStates, stgState.tankStates); %#ok<AGROW>
                end
            end
        end
        
        function mass = getTotalVehicleMass(obj)
            mass = 0;
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    mass = mass + obj.stageStates(i).getStageTotalMass();
                end
            end
        end
    end
    
    methods(Static)
        function stateLogEntry = createStateLogEntryFromIntegratorOutputRow(t,y, lv, centralBody, event)
            stateLogEntry = LaunchVehicleStateLogEntry();
            
            stateLogEntry.time = t;
            stateLogEntry.position = y(1:3)';
            stateLogEntry.velocity = y(4:6)';
            stateLogEntry.centralBody = centralBody;
            stateLogEntry.event = event;
            
            curTankYInd = 7;
            
            stages = lv.stages;
            stateStates = LaunchVehicleStage.empty(0,1);
            for(i=1:length(stages))
                stage = stages(i);
                tanks = stage.tanks;
                engines = state.engines;
                
                stageState = LaunchVehicleStageState();
                stageState.stage = stage;
                stageState.active = true; %TODO: Handle this appropriately, probably with something that tracks activeness for stages and engines through time
                
                stateStates(end+1) = stageState; %#ok<AGROW>
                for(j=1:length(tanks))
                    tank = tanks(j);
                    tankState = LaunchVehicleTankState();
                    
                    tankState.tank = tank;
                    tankState.tankMass = y(curTankYInd);
                    curTankYInd = curTankYInd + 1;
                    
                    stageState.tankStates(end+1) = tankState;
                end
                
                for(j=1:length(engines))
                    engine = engines(j);
                    engineState = LaunchVehicleEngineState();
                    
                    engineState.engine = engine;
                    engineState.active = true; %TODO: Handle this appropriately, probably with something that tracks activeness for stages and engines through time
                end
            end
            
            stateLogEntry.stageStates = stateStates;
        end
    end
end