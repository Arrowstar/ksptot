classdef LaunchVehicleStageState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %validators commented out to improve performance
        stage = LaunchVehicleStage.empty(1,0)% LaunchVehicleStage
        
        active = true%(1,1) logical = true;
        
        %Propulsion
        engineStates = LaunchVehicleEngineState.empty(1,0)% LaunchVehicleEngineState
        tankStates = LaunchVehicleTankState.empty(1,0);% LaunchVehicleTankState
        
        %Electrical Power
        powerSinkStates = AbstractLaunchVehicleElectricalPowerSnkState.empty(1,0);
        powerSrcStates = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0);
        powerStorageStates = AbstractLaunchVehicleEpsStorageState.empty(1,0);
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTank.empty(1,0);
    end

    methods
        function obj = LaunchVehicleStageState(stage)
            if(nargin > 0)
                obj.stage = stage;
            end
        end
        
        %% Engines 
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
        
        %% Tanks
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
        
        function [tankState, ind] = getStateForTank(obj, tank)
            ind = [];
            for(i=1:length(obj.tankStates)) %#ok<*NO4LP>
                if(tank == obj.tankStates(i).tank)
                    ind = i;
                    break;
                end
            end
            
            tankState = obj.tankStates(ind);
        end
               
        function tankMass = getStageTotalTankMass(obj)
            tankMass = sum([obj.tankStates.tankMass]);
        end
        
        function [massesByType, tankTypes] = getTotalStagePropMassesByFluidType(obj)
            tankTypes = obj.stage.launchVehicle.tankTypes.types;
            massesByType = zeros(1, length(tankTypes));
            
            if(~isempty(obj.tankStates))
                indivTankMasses = [obj.tankStates.tankMass];
                tanks = [obj.tankStates.tank];

                for(i=1:length(tankTypes))
                    type = tankTypes(i);
                    tankBool = [tanks.tankType] == type;
                    massesByType(i) = sum(indivTankMasses(tankBool));
                end
            end
        end
        
        %% EPS - Sinks
        function addPowerSinkState(obj, newPowerSinkState)
            obj.powerSinkStates(end+1) = newPowerSinkState;
        end
        
        function removePowerSinkStateForPowerState(obj, powerSink)
            ind = [];
            for(i=1:length(obj.powerSinkStates)) %#ok<*NO4LP>
                if(powerSink == obj.powerSinkStates(i).getEpsSinkComponent())
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.powerSinkStates(ind) = [];
            end
        end
        
        function powerSinkState = getStateForPowerSink(obj, powerSink)
            ind = [];
            for(i=1:length(obj.powerSinkStates)) %#ok<*NO4LP>
                if(powerSink == obj.powerSinkStates(i).getEpsSinkComponent())
                    ind = i;
                    break;
                end
            end
            
            powerSinkState = obj.powerSinkStates(ind);
        end
        
        %% EPS - Sources
        function addPowerSrcState(obj, newPowerSrcState)
            obj.powerSrcStates(end+1) = newPowerSrcState;
        end
        
        function removePowerSrcStateForPowerState(obj, powerSrc)
            ind = [];
            for(i=1:length(obj.powerSrcStates)) %#ok<*NO4LP>
                if(powerSrc == obj.powerSrcStates(i).getEpsSrcComponent())
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.powerSrcStates(ind) = [];
            end
        end
        
        function powerSrcState = getStateForPowerSrc(obj, powerSrc)
            ind = [];
            for(i=1:length(obj.powerSrcStates)) %#ok<*NO4LP>
                if(powerSrc == obj.powerSrcStates(i).getEpsSrcComponent())
                    ind = i;
                    break;
                end
            end
            
            powerSrcState = obj.powerSrcStates(ind);
        end
        
        %% EPS - Storage
        function addPowerStorageState(obj, newPowerStorageState)
            obj.powerStorageStates(end+1) = newPowerStorageState;
        end
        
        function removePowerStorageStateForPowerState(obj, powerStorage)
            ind = [];
            for(i=1:length(obj.powerStorageStates)) %#ok<*NO4LP>
                if(powerStorage == obj.powerStorageStates(i).getEpsStorageComponent())
                    ind = i;
                    break;
                end
            end
            
            if(not(isempty(ind)))
                obj.powerStorageStates(ind) = [];
            end
        end
        
        function powerSrcState = getStateForPowerStorage(obj, powerStorage)
            ind = [];
            for(i=1:length(obj.powerStorageStates)) %#ok<*NO4LP>
                if(powerStorage == obj.powerStorageStates(i).getEpsStorageComponent())
                    ind = i;
                    break;
                end
            end
            
            powerSrcState = obj.powerStorageStates(ind);
        end
        
        %% Other
        function dryMass = getStateDryMass(obj)
            dryMass = obj.stage.dryMass;
        end
        
        function stageMass = getStageTotalMass(obj)
            stageMass = obj.getStateDryMass() + obj.getStageTotalTankMass();
        end
        
        function newStageState = deepCopy(obj, deepCopyState, lvState)
            if(obj.active || deepCopyState)    
                newStageState = obj.copy();
            
                %Copy Engine States
                if(deepCopyState)
                    if(not(isempty(obj.engineStates)))
                        newEngineStates = obj.engineStates.copy();
                        [newEngineStates.stageState] = deal(newStageState);
                        newStageState.engineStates = newEngineStates;
                    end
                end

                
                if(not(isempty(obj.tankStates)))
                    newTankStates = obj.tankStates.copy();
                    [newTankStates.stageState] = deal(newStageState);
                    newStageState.tankStates = newTankStates;
                end
                
                %Copy Tank States - why is this so complicated again?
%                 if(not(isempty(obj.tankStates)))
%                     tanksToUpdateStatesFor = LaunchVehicleStageState.emptyTankArr;
%                     
%                     for(i=1:length(obj.engineStates))
%                         if(obj.engineStates(i).active)
% %                             tanksToUpdateStatesFor = [tanksToUpdateStatesFor, lvState.getTanksConnectedToEngine(obj.engineStates(i).engine)]; %#ok<AGROW>
%                             tanksToUpdateStatesFor = [tanksToUpdateStatesFor, lvState.getTanksConnectedToEngineForStage(obj.engineStates(i).engine, newStageState.stage)]; %#ok<AGROW>
%                         end
%                     end
%                     
%                     if(~isempty(lvState.t2TConns))
%                         tanksToUpdateStatesFor = [tanksToUpdateStatesFor, lvState.getTanksWithActiveTankToTankConnectionsForStage(obj)];
%                     end
%                     
% %                     stageTanks = [obj.tankStates.tank];
%                     if(not(isempty(tanksToUpdateStatesFor)))
% %                         [Lia] = ismemberClassTypesARH(tanksToUpdateStatesFor,stageTanks);
% %                         tanksToUpdateStatesFor = tanksToUpdateStatesFor(logical(Lia));
%                         
% %                         if(not(isempty(tanksToUpdateStatesFor)))
% 
%                         if(length(tanksToUpdateStatesFor) > 1)
%                             tanksToUpdateStatesFor = unique(tanksToUpdateStatesFor);
%                         end
% 
%                         for(i=1:length(tanksToUpdateStatesFor))
% %                             tankToUpdateState = tanksToUpdateStatesFor(i);
% 
%                             [tankState, ind] = obj.getStateForTank(tanksToUpdateStatesFor(i));
% %                             newTankState = LaunchVehicleTankState(newStageState);
% %                             newTankState.tank = tanksToUpdateStatesFor(i);
% %                             newTankState.tankMass = tankState.tankMass;
%                             newTankState = tankState.copy();
%                             newTankState.stageState = newStageState;
%                             newStageState.tankStates(ind) = newTankState;
%                         end
% %                         end
%                     end
%                 end
                
                %Copy Power Sink States
                if(deepCopyState && not(isempty(obj.powerSinkStates)))
                    newPwrSinkStates = obj.powerSinkStates.copy();
                    [newPwrSinkStates.stageState] = deal(newStageState);
                    newStageState.powerSinkStates = newPwrSinkStates;
                end
                
                %Copy Power Source States
                if(deepCopyState && not(isempty(obj.powerSrcStates)))
                    newPwrSrcStates = obj.powerSrcStates.copy();
                    [newPwrSrcStates.stageState] = deal(newStageState);
                    newStageState.powerSrcStates = newPwrSrcStates;
                end
                
                %Copy Power Storage States
                if(not(isempty(obj.powerStorageStates)))
                    newPwrStorageStates = obj.powerStorageStates.copy();
                    [newPwrStorageStates.stageState] = deal(newStageState);
                    newStageState.powerStorageStates = newPwrStorageStates;
                end
            else
                newStageState = obj;
            end
        end
    end
end