classdef LaunchVehicleStateLogEntry < matlab.mixin.SetGet
    %LaunchVehicleStateLogEntry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        time(1,1) double = 0;
        position(3,1) double = [0;0;0];
        velocity(3,1) double = [0;0;0];
        centralBody(1,1) KSPTOT_BodyInfo
        lvState(1,:) LaunchVehicleState
        stageStates(1,:) LaunchVehicleStageState
        event(1,:) LaunchVehicleEvent
        aero(1,1) LaunchVehicleAeroState
        
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
    
    properties(Dependent)
        attitude(1,1) LaunchVehicleAttitudeState
        throttle(1,1) double
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTankState.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleStateLogEntry()
            
        end
        
        function value = get.throttle(obj)
            value = obj.throttleModel.getThrottleAtTime(obj.time);
        end
        
        function attState = get.attitude(obj)
            attState = LaunchVehicleAttitudeState();
            attState.dcm = obj.steeringModel.getBody2InertialDcmAtTime(obj.time, obj.position, obj.velocity);
        end
        
        function [t,y, tankStateInds] = getIntegratorStateRepresentation(obj)
            t = obj.time;
            
            y = [];
            y = horzcat(y, obj.position');
            y = horzcat(y, obj.velocity');
            
            tankStateInd = 7;
            tankStateInds = [];
            tankStates = obj.getAllActiveTankStates();
            for(i=1:length(tankStates))
                tankStateInds(end+1) = tankStateInd; %#ok<AGROW>
                y = [y,tankStates(i).getTankMass()]; %#ok<AGROW>
                
                tankStateInd = tankStateInd + 1;
            end
        end
        
        function stateLog = getMAFormattedStateLogMatrix(obj)
            stateLog = zeros(1,13);
            
            stateLog(1) = obj.time;
            stateLog(2:4) = obj.position';
            stateLog(5:7) = obj.velocity';
            stateLog(8) = obj.centralBody.id;
            stateLog(9) = obj.getTotalVehicleDryMass();
            stateLog(10) = obj.getTotalVehiclePropMass();
            stateLog(11) = 0;
            stateLog(12) = 0;
            stateLog(13) = obj.event.getEventNum();
        end
        
        function tankStates = getAllTankStates(obj)
%             tankStates = LaunchVehicleTankState.empty(0,1);
            tankStates = obj.emptyTankArr;
            
            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                tankStates = horzcat(tankStates, stgState.tankStates); %#ok<AGROW>
            end
        end
        
        function tankStates = getAllActiveTankStates(obj)
%             tankStates = LaunchVehicleTankState.empty(1,0);
            tankStates = obj.emptyTankArr;

            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                
                if(stgState.active)
                    tankStates = horzcat(tankStates, stgState.tankStates); %#ok<AGROW>
                end
            end
        end
        
        function dryMass = getTotalVehicleDryMass(obj)
            dryMass = 0;
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    dryMass = dryMass + obj.stageStates(i).getStateDryMass();
                end
            end
        end
        
        function propMass = getTotalVehiclePropMass(obj)
            propMass = 0;
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    propMass = propMass + obj.stageStates(i).getStageTotalTankMass();
                end
            end
        end
        
        function mass = getTotalVehicleMass(obj)
            mass = 0;
            
            for(i=1:length(obj.stageStates))
                stageState = obj.stageStates(i);
                if(stageState.active)
                    mass = mass + stageState.getStageTotalMass();
                end
            end
        end
        
        function updateTankStatesWithNewMasses(obj, newTankMasses)
            tankStates = obj.getAllActiveTankStates();
            
            [tankStates.tankMass] = disperse(newTankMasses);
        end
        
        function tankMDots = getTankMassFlowRatesDueToEngines(obj, presskPa)
            tankStates = obj.getAllActiveTankStates();
            tankMDots = zeros(size(tankStates));
            
            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                
                if(stgState.active)
                    engineStates = stgState.engineStates;

                    for(j=1:length(engineStates))
                        engineState = engineStates(j);
                        
                        if(engineState.active)
                            engine = engineState.engine;
                            [~, mdot] = engine.getThrustFlowRateForPressure(presskPa); %total mass flow through engine
                            adjustedThrottle = engine.adjustThrottleForMinMax(obj.throttle);
                            mdot = adjustedThrottle * mdot;
                            
                            tanks = obj.lvState.getTanksConnectedToEngine(engine);
                            
                            flowFromTankInds = zeros(size(tankStates));
                            for(k=1:length(tanks))
                                tank = tanks(k);
                                tankState = tankStates([tankStates.tank] == tank);
                                tankStageState = tankState.stageState;
                                
                                if(tankStageState.active && tankState.tankMass > 0)
                                    flowFromTankInds(tankStates == tankState) = 1;
                                end
                            end
                            
                            numTanksToPullFrom = sum(flowFromTankInds);
                            mDotPerTank = mdot/numTanksToPullFrom;
                            
                            flowFromTankInds = logical(flowFromTankInds);
                            tankMDots(flowFromTankInds) = tankMDots(flowFromTankInds) + mDotPerTank;
                        end
                    end
                end
            end
        end
        
        function newStateLogEntry = deepCopy(obj)
            newStateLogEntry = LaunchVehicleStateLogEntry();
            
            newStateLogEntry.time = obj.time;
            newStateLogEntry.position = obj.position;
            newStateLogEntry.velocity = obj.velocity;
            newStateLogEntry.centralBody = obj.centralBody;
            newStateLogEntry.event = obj.event;
            newStateLogEntry.steeringModel = obj.steeringModel;
            newStateLogEntry.throttleModel = obj.throttleModel;
            
            newStateLogEntry.lvState = obj.lvState.deepCopy();
            
            for(i=1:length(obj.stageStates))
                newStateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy();
            end
            
            newStateLogEntry.aero = obj.aero.deepCopy();
        end
    end
    
    methods(Static)
        function stateLogEntries = createStateLogEntryFromIntegratorOutputRow(t,y, eventInitStateLogEntry)
            y = reshape(y,length(t), numel(y)/length(t));
            
            stateLogEntries = LaunchVehicleStateLogEntry.empty(length(t),0);
            for(i=1:length(t))
                stateLogEntry = eventInitStateLogEntry.deepCopy();

                try
                stateLogEntry.time = t(i);
                stateLogEntry.position = y(i,1:3)';
                stateLogEntry.velocity = y(i,4:6)';
                stateLogEntry.updateTankStatesWithNewMasses(y(i,7:end));
                catch
                    a = 1;
                end
                
                stateLogEntries(i) = stateLogEntry;
            end
        end
    end
end