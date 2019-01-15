classdef LaunchVehicleStageState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage(1,:) LaunchVehicleStage
        
        active(1,1) logical = true;
        
        engineStates(1,:) LaunchVehicleEngineState
        tankStates(1,:) LaunchVehicleTankState
    end

    methods
        function obj = LaunchVehicleStageState(stage)
            if(nargin > 0)
                obj.stage = stage;
            end
        end
        
        function addEngineState(obj, newEngineState)
            obj.engineStates(end+1) = newEngineState;
        end
        
        function removeEngineStateForEngine(obj, engine)
            ind = [];
            for(i=1:length(obj.engineStates)) %#ok<*NO4LP>
                if(engine == obj.engineStates(i).engine)
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.engineStates(ind) = [];
            end
        end
        
        function engineState = getStateForEngine(obj, engine)
            ind = [];
            for(i=1:length(obj.engineStates)) %#ok<*NO4LP>
                if(engine == obj.engineStates(i).engine)
                    ind = i;
                    break;
                end
            end
            
            engineState = obj.engineStates(ind);
        end
        
        function addTankState(obj, newTankState)
            obj.tankStates(end+1) = newTankState;
        end
        
        function removeTankStateForTank(obj, tank)
            ind = [];
            for(i=1:length(obj.tankStates))
                if(tank == obj.tankStates(i).tank)
                    ind = i;
                end
            end
            
            if(not(isempty(ind)))
                obj.tankStates(ind) = [];
            end
        end
        
        function updateTankStateMassForTank(obj, tank)
            ind = [];
            for(i=1:length(obj.tankStates))
                if(tank == obj.tankStates(i).tank)
                    ind = i;
                    break;
                end
            end
            
            obj.tankStates(ind).tankMass = tank.initialMass;
        end
        
        function dryMass = getStateDryMass(obj)
            dryMass = obj.stage.dryMass;
        end
        
        function tankMass = getStageTotalTankMass(obj)
            tankMass = sum([obj.tankStates.tankMass]);
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.getStateDryMass() + obj.getStageTotalTankMass();
        end
        
        function newStageState = deepCopy(obj)
            newStageState = obj.copy();
%             newStageState.active = obj.active; %don't think I need to
%             copy this beacuse it's a logical and should just come with it
            
            newEngineStates = obj.engineStates.copy();
            [newEngineStates.stageState] = deal(newStageState);
            newStageState.engineStates = newEngineStates;
            
            newTankStates = obj.tankStates.copy();
            [newTankStates.stageState] = deal(newStageState);
            newStageState.tankStates = newTankStates;
        end
    end
end