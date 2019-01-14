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
        extremaStates(1,:) LaunchVehicleExtremaState
        
        steeringModel(1,1) AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel(1,1) AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
    
    properties(Dependent)
        altitude(1,1) double
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
        
        function alt = get.altitude(obj)
            alt = norm(obj.position) - obj.centralBody.radius;
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
%                 stgState = stgStates(i);
                
                if(stgStates(i).active)
                    tankStates = [tankStates, stgStates(i).tankStates]; %#ok<AGROW>
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
        
        function extremaStates = getAllExtremaStates(obj)
            extremaStates = obj.extremaStates;
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
            
            for(i=1:length(obj.extremaStates))
                newStateLogEntry.extremaStates(i) = obj.extremaStates(i).deepCopy();
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
            
            for(i=1:length(obj.extremaStates))
                obj.extremaStates(i) = obj.extremaStates(i).deepCopy();
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
                                
                for(j=1:length(stateLogEntry.extremaStates))
                    if(i == 1)
                        newValue = stateLogEntry.extremaStates(j).value;
                    end
                    
                    [newValue] = stateLogEntry.extremaStates(j).updateExtremaStateWithStateLogEntry(stateLogEntry, newValue);
                end
                
                stateLogEntries(i) = stateLogEntry;
            end
        end
        
        function [tankMDots, totalThrust, forceVect]= getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stgStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, steeringModel)
            tankMDots = zeros(size(tankStates));
            tankMDots = tankMDots(:);
            totalThrust = 0;
            bodyThrust = [0;0;0];
            
            for(i=1:length(stgStates)) %#ok<*NO4LP>
%                 stgState = stgStates(i);
                
                if(stgStates(i).active)
                    engineStates = stgStates(i).engineStates;

                    for(j=1:length(engineStates))
                        engineState = engineStates(j);
                        
                        if(engineState.active)
                            engine = engineState.engine;
                            adjustedThrottle = engine.adjustThrottleForMinMaxFuelRemaining(throttle, []);
                            if(adjustedThrottle > 0)
                                [baseThrust, baseMdot] = engine.getThrustFlowRateForPressure(presskPa); %total mass flow through engine
                                mdot = adjustedThrottle * baseMdot;

                                flowFromTankInds = zeros(size(tankStates));
                                if(mdot < 0) %negative because we're flowing out
                                    tanks = lvState.getTanksConnectedToEngine(engine);
                                    
                                    totalConnTankCapacity = 0;
                                    totalConnTankMass = 0;
                                    for(k=1:length(tanks))
                                        if(not(isempty(tankStates)))
                                            tank = tanks(k);
                                            tankState = tankStates([tankStates.tank] == tank);
                                            tankMass = tankStatesMasses([tankStates.tank] == tank);

                                            if(not(isempty(tankState)))
                                                tankStageState = tankState.stageState;

                                                if(tankStageState.active)
                                                    totalConnTankCapacity = totalConnTankCapacity + tank.initialMass;
                                                    totalConnTankMass = totalConnTankMass + tankMass;
                                                    
                                                    if(tankMass > 0)
                                                        flowFromTankInds(tankStates == tankState) = 1;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    if(totalConnTankCapacity > 0)
                                        fuelRemainPct = 100 * totalConnTankMass / totalConnTankCapacity; %it's a percent
                                    else
                                        fuelRemainPct = 0;
                                    end
                                    
                                    %rerun the calculations for thrust and
                                    %flow rate, this time incorporating the
                                    %fuel remaining in all connected tanks
                                    adjustedThrottle = engine.adjustThrottleForMinMaxFuelRemaining(throttle, fuelRemainPct);
%                                     [thrust, mdot] = engine.getThrustFlowRateForPressure(presskPa); %total mass flow through engine
                                    mdot = adjustedThrottle * baseMdot;
                                    totalThrust = totalThrust + adjustedThrottle*baseThrust;
                                    
                                    numTanksToPullFrom = sum(flowFromTankInds);
                                    if(numTanksToPullFrom > 0)
                                        bodyThrust = bodyThrust + (baseThrust * adjustedThrottle * engine.bodyFrameThrustVect)/1000; %1/1000 to convert kN=mT*m/s^2 to mT*km/s^2 (see also ma_executeDVManeuver_finite_inertial()) 
                                    end
                                    
                                    mDotPerTank = mdot/numTanksToPullFrom;

                                    flowFromTankInds = logical(flowFromTankInds);
                                    tankMDots(flowFromTankInds) = tankMDots(flowFromTankInds) + mDotPerTank;   
                                end
                            end
                        end
                    end
                end
            end
            
            if(not(isempty(steeringModel)))
                if(norm(bodyThrust) > 0)
                    body2InertDcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);
                    forceVect = body2InertDcm * bodyThrust;
                else
                    forceVect = [0;0;0];
                end
            else
                forceVect = [NaN;NaN;NaN];
            end
        end
    end
end