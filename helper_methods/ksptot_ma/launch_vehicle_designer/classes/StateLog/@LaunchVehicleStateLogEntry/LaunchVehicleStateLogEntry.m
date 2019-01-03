classdef LaunchVehicleStateLogEntry < matlab.mixin.SetGet & matlab.mixin.Copyable
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
        
        stopwatchStates(1,:) LaunchVehicleStopwatchState
        
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
    
    properties(Dependent)
        attitude(1,1) LaunchVehicleAttitudeState
        throttle(1,1) double
        celBodyData struct
        launchVehicle LaunchVehicle
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTankState.empty(1,0);
        emptyEngineArr = LaunchVehicleEngineState.empty(1,0);
    end
    
    methods
        function obj = LaunchVehicleStateLogEntry()
            
        end
        
        function value = get.throttle(obj)
            tankStates = obj.getAllActiveTankStates();
            
            tankMasses = zeros(size(tankStates));
            for(i=1:length(tankStates))
                tankMasses(i) = tankStates(i).tankMass;
            end
            
            value = obj.throttleModel.getThrottleAtTime(obj.time, obj.position, tankMasses, obj.getTotalVehicleDryMass(), ...
                                                        obj.stageStates, obj.lvState, tankStates, obj.centralBody);
        end
        
        function attState = get.attitude(obj)
            attState = LaunchVehicleAttitudeState();
            attState.dcm = obj.steeringModel.getBody2InertialDcmAtTime(obj.time, obj.position, obj.velocity, obj.centralBody);
        end
        
        function celBodyData = get.celBodyData(obj)
            celBodyData = obj.lvState.lv.lvdData.celBodyData;
        end
        
        function launchVehicle = get.launchVehicle(obj)
            launchVehicle = obj.lvState.lv;
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
            
            if(isempty(obj.event))
                eventNum = 1;
            else
                eventNum = obj.event.getEventNum();
            end
            
            stateLog(1) = obj.time;
            stateLog(2:4) = obj.position';
            stateLog(5:7) = obj.velocity';
            stateLog(8) = obj.centralBody.id;
            stateLog(9) = obj.getTotalVehicleDryMass();
            stateLog(10) = obj.getTotalVehiclePropMass();
            stateLog(11) = 0;
            stateLog(12) = 0;
            stateLog(13) = eventNum;
        end
        
        function tankStates = getAllTankStates(obj)
            tankStates = obj.emptyTankArr;
            
            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                tankStates = horzcat(tankStates, stgState.tankStates); %#ok<AGROW>
            end
        end
        
        function tankStates = getAllActiveTankStates(obj)
            tankStates = obj.emptyTankArr;

            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                
                if(stgState.active)
                    tankStates = horzcat(tankStates, stgState.tankStates); %#ok<AGROW>
                end
            end
        end
        
        function engineStates = getAllEngineStates(obj)
            engineStates = obj.emptyEngineArr;
            
            stgStates = obj.stageStates;
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                engineStates = horzcat(engineStates, stgState.engineStates); %#ok<AGROW>
            end
        end
        
        function stopwatchStates = getAllStopwatchStates(obj)
            stopwatchStates = obj.stopwatchStates;
        end
        
        function dryMass = getTotalVehicleDryMass(obj)
            dryMass = 0;
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    dryMass = dryMass + obj.stageStates(i).getStateDryMass();
                end
            end
        end
        
        function [propMass, tankMasses] = getTotalVehiclePropMass(obj)
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
        
        function tf = isHoldDownEnabled(obj)
            tf = obj.lvState.holdDownEnabled;
        end
        
        function updateTankStatesWithNewMasses(obj, newTankMasses)
            tankStates = obj.getAllActiveTankStates();
            
            [tankStates.tankMass] = disperse(newTankMasses);
        end
               
        function newStateLogEntry = deepCopy(obj)
            newStateLogEntry = LaunchVehicleStateLogEntry();
            
            %stuff that does not change
            newStateLogEntry.time = obj.time;
            newStateLogEntry.position = obj.position;
            newStateLogEntry.velocity = obj.velocity;
            newStateLogEntry.centralBody = obj.centralBody;
            newStateLogEntry.event = obj.event;
            newStateLogEntry.steeringModel = obj.steeringModel;
            newStateLogEntry.throttleModel = obj.throttleModel;
            
            %stuff that requires it's own copy
            newStateLogEntry.lvState = obj.lvState.deepCopy();
            
            for(i=1:length(obj.stageStates))
                newStateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy();
            end
            
            for(i=1:length(obj.stopwatchStates))
                newStateLogEntry.stopwatchStates(i) = obj.stopwatchStates(i).deepCopy();
            end
            
            newStateLogEntry.aero = obj.aero.deepCopy();
        end
        
        function obj = createCopiesOfCopyableInternals(obj)
            %stuff that requires it's own copy
            for(i=1:length(obj.stageStates))
                obj.stageStates(i) = obj.stageStates(i).deepCopy();
            end
            
            for(i=1:length(obj.stopwatchStates))
                obj.stopwatchStates(i) = obj.stopwatchStates(i).deepCopy();
            end
            
            obj.aero = obj.aero.copy();
        end
    end
    
    methods(Static)
        function stateLogEntries = createStateLogEntryFromIntegratorOutputRow(t,y, eventInitStateLogEntry)
            y = reshape(y,length(t), numel(y)/length(t));
            
            stateLogEntries = repmat(eventInitStateLogEntry,1,length(t));
            stateLogEntries = stateLogEntries.copy();
            
            stopwatchStates = eventInitStateLogEntry.stopwatchStates;
            initSwValues = [stopwatchStates.value];
            initSwRunningEnums = [stopwatchStates.running];
            initSwRunning = false(size(initSwRunningEnums));
            for(i=1:length(initSwRunningEnums))
                initSwRunning(i) = initSwRunningEnums(i).value;
            end          
            
            t0 = eventInitStateLogEntry.time;
            
            for(i=1:length(t))
                stateLogEntry = stateLogEntries(i).createCopiesOfCopyableInternals();

                stateLogEntry.time = t(i);
                stateLogEntry.position = y(i,1:3)';
                stateLogEntry.velocity = y(i,4:6)';
                stateLogEntry.updateTankStatesWithNewMasses(y(i,7:end));
                
                if(any(initSwRunning))
                    deltaT = t(i)-t0;
                    for(j=1:length(stateLogEntry.stopwatchStates))
                        if(initSwRunning(j) == true)
                            stateLogEntry.stopwatchStates(j).value = initSwValues(j) + deltaT;
                        end
                    end
                end
                
                stateLogEntries(i) = stateLogEntry;
            end
        end
        
        function [tankMDots, totalThrust]= getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stgStates, throttle, lvState, presskPa)
            tankMDots = zeros(size(tankStates));
            tankMDots = tankMDots(:);
            totalThrust = 0;
            
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                stgState = stgStates(i);
                
                if(stgState.active)
                    engineStates = stgState.engineStates;

                    for(j=1:length(engineStates))
                        engineState = engineStates(j);
                        
                        if(engineState.active)
                            engine = engineState.engine;
                            [thrust, mdot] = engine.getThrustFlowRateForPressure(presskPa); %total mass flow through engine
                            adjustedThrottle = engine.adjustThrottleForMinMax(throttle);
                            mdot = adjustedThrottle * mdot;
                            totalThrust = totalThrust + adjustedThrottle*thrust;
                            
                            flowFromTankInds = zeros(size(tankStates));
                            if(mdot < 0)
                                tanks = lvState.getTanksConnectedToEngine(engine);

                                for(k=1:length(tanks))
                                    tank = tanks(k);
                                    tankState = tankStates([tankStates.tank] == tank);
                                    tankMass = tankStatesMasses([tankStates.tank] == tank);

                                    if(not(isempty(tankState)))
                                        tankStageState = tankState.stageState;

                                        if(tankStageState.active && tankMass > 0)
                                            flowFromTankInds(tankStates == tankState) = 1;
                                        end
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
        end
    end
end