classdef LaunchVehicleStageState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %validators commented out to improve performance
        stage = LaunchVehicleStage.empty(1,0)% LaunchVehicleStage
        
        active = true%(1,1) logical = true;
        
        engineStates = LaunchVehicleEngineState.empty(1,0)% LaunchVehicleEngineState
        tankStates = LaunchVehicleTankState.empty(1,0);% LaunchVehicleTankState
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
        
        function [massesByType, tankTypes] = getTotalStagePropMassesByFluidType(obj)
            indivTankMasses = [obj.tankStates.tankMass];
            
            tanks = [obj.tankStates.tank];
            
            tankTypes = obj.stage.launchVehicle.tankTypes.types;
            massesByType = zeros(1, length(tankTypes));
            for(i=1:length(tankTypes))
                type = tankTypes(i);
                tankBool = [tanks.tankType] == type;
                massesByType(i) = sum(indivTankMasses(tankBool));
            end
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.getStateDryMass() + obj.getStageTotalTankMass();
        end
        
        function newStageState = deepCopy(obj)
            newStageState = obj.copy();
            
            newEngineStates = obj.engineStates.copy();
            [newEngineStates.stageState] = deal(newStageState);
            newStageState.engineStates = newEngineStates;
            
            newTankStates = obj.tankStates.copy();
            [newTankStates.stageState] = deal(newStageState);
            newStageState.tankStates = newTankStates;
        end
    end
end