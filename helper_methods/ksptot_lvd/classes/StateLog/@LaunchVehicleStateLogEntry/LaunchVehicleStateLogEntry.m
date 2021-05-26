classdef LaunchVehicleStateLogEntry < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStateLogEntry Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %validators commented out to improve performance
        time double = 0;
        position double = [0;0;0];
        velocity double = [0;0;0];
        centralBody KSPTOT_BodyInfo
        lvState LaunchVehicleState
        stageStates = LaunchVehicleStageState.empty(1,0); %LaunchVehicleStageState
        event LaunchVehicleEvent
        
        aero LaunchVehicleAeroState
        thirdBodyGravity LaunchVehicle3BodyGravState
        
        stopwatchStates LaunchVehicleStopwatchState
        extremaStates LaunchVehicleExtremaState
        calcObjStates AbstractLaunchVehicleCalculusState
        
        steeringModel AbstractSteeringModel = RollPitchYawPolySteeringModel.getDefaultSteeringModel();
        throttleModel AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
    end
    
    properties(Dependent)
        altitude double
        attitude LaunchVehicleAttitudeState
        throttle double
        celBodyData
        launchVehicle LaunchVehicle
        lvdData LvdData
    end
    
    properties(Constant)
        emptyTankArr = LaunchVehicleTankState.empty(1,0);
        emptyEngineArr = LaunchVehicleEngineState.empty(1,0);
        emptyPwrStorageArr = AbstractLaunchVehicleEpsStorageState.empty(1,0);
        emptyPwrSrcArr = AbstractLaunchVehicleElectricalPowerSrcState.empty(1,0)
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
            
            powerStorageStates = obj.getAllActivePwrStorageStates();
            storageSoCs = NaN(size(powerStorageStates));
            for(i=1:length(powerStorageStates))
                storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
            end
            
            value = obj.throttleModel.getThrottleAtTime(obj.time, obj.position, obj.velocity, tankMasses, obj.getTotalVehicleDryMass(), ...
                obj.stageStates, obj.lvState, tankStates, obj.centralBody, storageSoCs, powerStorageStates);
        end
        
        function alt = get.altitude(obj)
            alt = norm(obj.position) - obj.centralBody.radius;
        end
        
        function attState = get.attitude(obj)
            attState = LaunchVehicleAttitudeState();
            attState.dcm = obj.steeringModel.getBody2InertialDcmAtTime(obj.time, obj.position, obj.velocity, obj.centralBody);
        end
        
        function celBodyData = get.celBodyData(obj)
            celBodyData = obj.lvdData.celBodyData;
        end
        
        function launchVehicle = get.launchVehicle(obj)
            launchVehicle = obj.lvState.lv;
        end
        
        function lvdData = get.lvdData(obj)
            lvdData = obj.lvState.lv.lvdData;
        end
        
        function [t,y, tankStateInds, pwrStorageStateInds] = getFirstOrderIntegratorStateRepresentation(obj)
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
            
            pwrStorageInd = tankStateInd; %last tank state ind + 1 is the first pwr storage ind
            pwrStorageStateInds = [];
            pwrStorageStates = obj.getAllActivePwrStorageStates();
            for(i=1:length(pwrStorageStates))
                pwrStorageStateInds(end+1) = pwrStorageInd; %#ok<AGROW>
                y = [y, pwrStorageStates(i).getStateOfCharge()]; %#ok<AGROW>
            end
        end
        
        %this probably no longer works, needs tank masses and stuff
        function [t,y,yp] = getSecondOrderIntegratorStateRepresentation(obj)
            t = obj.time;
            
            y = obj.position;
            yp = obj.velocity;
        end
        
        function stateLog = getMAFormattedStateLogMatrix(obj, needMasses)
            stateLog = zeros(1,13);
            
            if(isempty(obj.event))
                eventNum = 1;
            else
                eventNum = obj.event.getEventNum();
            end
            
            if(isempty(eventNum))
                eventNum = NaN;
            end
            
            if(needMasses)
                massesByType = obj.getTotalVehiclePropMassesByFluidType();
                if(length(massesByType) > 3)
                    otherMass = sum(massesByType(4:end));
                else
                    otherMass = 0;
                end
            else
                massesByType = [0,0,0];
                otherMass = 0;
            end
            
            stateLog(1) = obj.time;
            stateLog(2:4) = obj.position';
            stateLog(5:7) = obj.velocity';
            stateLog(8) = obj.centralBody.id;
            stateLog(9) = obj.getTotalVehicleDryMass() + otherMass;
            stateLog(10) = massesByType(1);
            stateLog(11) = massesByType(2);
            stateLog(12) = massesByType(3);
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
            stgStates = obj.stageStates;
            tankStates = [stgStates([stgStates.active]).tankStates];
            
            if(isempty(tankStates))
                tankStates = obj.emptyTankArr;
            end
        end
        
        function numTankStates = getNumActiveTankStates(obj)
            numTankStates = length(obj.getAllActiveTankStates());
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
        
        function calcObjStates = getAllCalculusObjStates(obj)
            calcObjStates = obj.calcObjStates;
        end
        
        function dryMass = getTotalVehicleDryMass(obj)
            dryMass = 0;
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    dryMass = dryMass + obj.stageStates(i).getStateDryMass();
                end
            end
        end
        
        function [propMass] = getTotalVehiclePropMass(obj)
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
        
        function massesByType = getTotalVehiclePropMassesByFluidType(obj)
            massesByType = zeros(1,length(obj.launchVehicle.tankTypes.types));
            
            for(i=1:length(obj.stageStates))
                if(obj.stageStates(i).active)
                    massesByType = massesByType + obj.stageStates(i).getTotalStagePropMassesByFluidType();
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
                newStateLogEntry.stageStates(i) = obj.stageStates(i).deepCopy(true, newStateLogEntry.lvState);
            end
            
            newStateLogEntry.stopwatchStates = obj.stopwatchStates.copy();
            
            newStateLogEntry.extremaStates = obj.extremaStates.copy();
            
            newStateLogEntry.calcObjStates = obj.calcObjStates.copy();
            
            newStateLogEntry.aero = obj.aero.deepCopy();
            newStateLogEntry.thirdBodyGravity = obj.thirdBodyGravity.copy();
        end
        
        function obj = createCopiesOfCopyableInternals(obj, deepCopyState)
            %stuff that requires it's own copy
            for(i=1:length(obj.stageStates))
                obj.stageStates(i) = obj.stageStates(i).deepCopy(deepCopyState, obj.lvState);
            end
            
            if(~isempty(obj.stopwatchStates))
                obj.stopwatchStates = obj.stopwatchStates.copy();
            end
            
            if(~isempty(obj.extremaStates))
                obj.extremaStates = obj.extremaStates.copy();
            end
            
            if(~isempty(obj.calcObjStates))
                obj.calcObjStates = obj.calcObjStates.copy();
            end
            
            if(deepCopyState)
                obj.aero = obj.aero.copy();
                obj.thirdBodyGravity = obj.thirdBodyGravity.copy();
            end
        end
        
        function cartElemSet = getCartesianElementSetRepresentation(obj, createObjOfArray)
            arguments
                obj
                createObjOfArray(1,1) logical = false;
            end
            
            obj = obj(:)';
            
            for(i=1:length(obj))
                frame(i) = obj(i).centralBody.getBodyCenteredInertialFrame(); %#ok<AGROW>
            end
            cartElemSet = CartesianElementSet([obj.time], [obj.position], [obj.velocity], frame, createObjOfArray);
        end
        
        function setCartesianElementSet(obj, elemSet)
            obj = obj(:)';
            
            for(i=1:length(obj))
                cartElem = elemSet(i).convertToCartesianElementSet();
                bodyInfo = cartElem.frame.getOriginBody();
                cartElem = cartElem.convertToFrame(bodyInfo.getBodyCenteredInertialFrame());
                
                obj(i).position = cartElem.rVect;
                obj(i).velocity = cartElem.vVect;
                obj(i).centralBody = bodyInfo;
            end
        end

        function pwrStorageStates = getAllActivePwrStorageStates(obj)
            stgStates = obj.stageStates;
            pwrStorageStates = [stgStates([stgStates.active]).powerStorageStates];
              
            if(isempty(pwrStorageStates))
                pwrStorageStates = obj.emptyPwrStorageArr;
                
            else
                pwrStorageStates = pwrStorageStates(getActiveState(pwrStorageStates));
            end
        end
        
        function pwrSinksStates = getAllActivePwrSinksStates(obj)
            stgStates = obj.stageStates;
            pwrSinksStates = [stgStates([stgStates.active]).powerSinkStates];
              
            if(isempty(pwrSinksStates))
                pwrSinksStates = obj.emptyPwrSrcArr;
                
            else
                pwrSinksStates = pwrSinksStates(getActiveState(pwrSinksStates));
            end
        end
        
        function pwrSrcsStates = getAllActivePwrSrcsStates(obj)
            stgStates = obj.stageStates;
            pwrSrcsStates = [stgStates([stgStates.active]).powerSrcStates];
              
            if(isempty(pwrSrcsStates))
                pwrSrcsStates = obj.emptyPwrSrcArr;
                
            else
                for(i=1:length(pwrSrcsStates))
                    activeInds(i) = pwrSrcsStates(i).getActiveState(); %#ok<AGROW>
                end
                
                pwrSrcsStates = pwrSrcsStates(activeInds);
            end
        end
        
        function numPwrStorageStates = getNumActivePwrStorageStates(obj)
            numPwrStorageStates = length(obj.getAllActivePwrStorageStates());
        end
        
        function updatePwrStorageStatesWithNewCharges(obj, newStorageSoCs)
            pwrStorageStates = obj.getAllActivePwrStorageStates();
            
            for(i=1:length(pwrStorageStates))
                pwrStorageStates(i).setStateOfCharge(newStorageSoCs(i));
            end
        end
    end
    
    methods(Access=protected)
        function cpObj = copyElement(obj, deepCopyStageState)
            if(nargin <= 1)
                deepCopyStageState = true;
            end
            
            cpObj = copyElement@matlab.mixin.Copyable(obj);
            cpObj = cpObj.createCopiesOfCopyableInternals(deepCopyStageState);
        end
    end
    
    methods(Static)
        function stateLogEntries = createStateLogEntryFromIntegratorOutputRow(t,y, eventInitStateLogEntry)
            y = reshape(y,length(t), numel(y)/length(t));
            
            stateLogEntries = repmat(eventInitStateLogEntry,1,length(t));
            
            if(length(t) > 1)
                for(i=1:length(stateLogEntries)-1)
                    stateLogEntries(i) = stateLogEntries(i).copyElement(false);
                end
                
                stateLogEntries(end) = stateLogEntries(end).copyElement(true);
            else
                stateLogEntries = stateLogEntries.copy();
            end
            
            stopwatchStates = eventInitStateLogEntry.stopwatchStates;
            initSwValues = [stopwatchStates.value];
            initSwRunningEnums = [stopwatchStates.running];
            initSwRunning = false(size(initSwRunningEnums));
            for(i=1:length(initSwRunningEnums))
                initSwRunning(i) = initSwRunningEnums(i).value;
            end
            
            t0 = eventInitStateLogEntry.time;
            
            numTankStates = eventInitStateLogEntry.getNumActiveTankStates();
            numPwrStorageStates = eventInitStateLogEntry.getNumActivePwrStorageStates();
            
            for(i=1:length(t))
                stateLogEntry = stateLogEntries(i);
                
                [ut, rVect, vVect, tankStates, pwrStorageStates] = AbstractPropagator.decomposeIntegratorTandY(t(i),y(i,:), numTankStates, numPwrStorageStates);
                
                stateLogEntry.time = ut;
                stateLogEntry.position = rVect(:);
                stateLogEntry.velocity = vVect(:);
                stateLogEntry.updateTankStatesWithNewMasses(tankStates);
                stateLogEntry.updatePwrStorageStatesWithNewCharges(pwrStorageStates);
                
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
            
            calcObjStates = stateLogEntries(1).calcObjStates;
            for(i=1:length(calcObjStates))
                calcObjStates(i).createDataFromStates(stateLogEntries);
                
                
                if(calcObjStates(i).calcObj.type == CalculusCalculationEnum.Integral)
                    calcObjStates(i).constant = eventInitStateLogEntry.calcObjStates(i).getValueAtTime(eventInitStateLogEntry.time);
                end
            end
            
            for(i=2:length(stateLogEntries))
                stateLogEntries(i).calcObjStates = calcObjStates;
            end
        end
        
        function [tankMDots, totalThrust, forceVect, ecStorageRates] = getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stgStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates)
            tankMDots = zeros(size(tankStates));
            tankMDots = tankMDots(:);
            totalThrust = 0;
            bodyThrust = [0;0;0];
            
            storageSoCs = storageSoCs(:);
            ecStorageRates = zeros(size(storageSoCs));
            
            maxEcCapacities = NaN(size(powerStorageStates));
            for(i=1:length(powerStorageStates))
                pwrStorage = powerStorageStates(i).getEpsStorageComponent();
                maxEcCapacities(i) = pwrStorage.getMaximumCapacity();
            end
            maxEcCapacities = maxEcCapacities(:);
            
            for(i=1:length(stgStates)) %#ok<*NO4LP>
                %                 stgState = stgStates(i);
                
                if(stgStates(i).active)
                    engineStates = stgStates(i).engineStates;
                    
                    for(j=1:length(engineStates))
                        engineState = engineStates(j);
                        
                        if(engineState.active)
                            engine = engineState.engine;
                            adjustedThrottle = engine.adjustThrottle(throttle, []);
                            if(adjustedThrottle > 0)
                                [baseThrust, baseMdot] = engine.getThrustFlowRateForPressure(presskPa); %total mass flow through engine
                                mdot = adjustedThrottle * baseMdot;
                                
                                flowFromTankInds = zeros(size(tankStates));
                                if(mdot < 0 && ... %negative because we're flowing out
                                   (engine.reqsElecCharge == false || (engine.reqsElecCharge == true && numel(storageSoCs)>0 && sum(storageSoCs)>0))) %handle engines that require EC to function 
                                    tanks = lvState.getTanksConnectedToEngine(engine);
                                    
                                    totalConnTankCapacity = 0;
                                    totalConnTankMass = 0;
                                    for(k=1:length(tanks))
                                        if(not(isempty(tankStates)))
                                            tank = tanks(k);
                                            tankBool = [tankStates.tank] == tank;
                                            tankState = tankStates(tankBool);
                                            
                                            if(not(isempty(tankState)))
                                                tankStageState = tankState.stageState;
                                                
                                                if(tankStageState.active)
                                                    tankMass = tankStatesMasses(tankBool);
                                                    
                                                    totalConnTankCapacity = totalConnTankCapacity + tank.initialMass;
                                                    totalConnTankMass = totalConnTankMass + tankMass;
                                                    
                                                    if(tankMass > 0)
                                                        flowFromTankInds(tankStates == tankState) = 1;
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    if(totalConnTankCapacity > 0 && totalConnTankMass > 0)
                                        fuelRemainPct = 100 * totalConnTankMass / totalConnTankCapacity; %it's a percent
                                    else
                                        fuelRemainPct = 0;
                                    end
                                    
                                    %rerun the calculations for thrust and
                                    %flow rate, this time incorporating the
                                    %fuel remaining in all connected tanks
                                    adjustedThrottle = engine.adjustThrottle(throttle, fuelRemainPct);
                                    if(totalConnTankMass <= 0)
                                        adjustedThrottle = 0;
                                    end
                                    
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

                                    if(numel(storageSoCs) > 0)
                                        pwrRate = engine.getPowerRate(throttle);
                                        if(pwrRate > 0)
                                            bool = storageSoCs < maxEcCapacities;
                                            numStorage = sum(bool);
                                            eachStgRate = pwrRate/numStorage;
                                            ecStorageRates(bool) = ecStorageRates(bool) + eachStgRate;

                                        elseif(pwrRate < 0)
                                            bool = storageSoCs > 0;
                                            numStorage = sum(bool);
                                            eachStgRate = pwrRate/numStorage;
                                            ecStorageRates(bool) = ecStorageRates(bool) + eachStgRate;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if(nargout >= 3 && not(isempty(steeringModel)))
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
        
        function storageRates = getStorageChargeRatesDueToSourcesSinks(storageSoCs, powerStorageStates, stgStates, ut, rVect, vVect, bodyInfo, steeringModel)
            if(length(storageSoCs) >= 1)
                elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
                
                hasPanels = false;
                for(i=1:length(stgStates))
                    for(j=1:length([stgStates(i).powerSrcStates]))
                        if(isa(stgStates(i).powerSrcStates(j).getEpsSrcComponent(), 'AbstractLaunchVehicleSolarPanel'))
                            hasPanels = true;
                            break;
                        end
                    end
                    
                    if(hasPanels)
                        break;
                    end
                end
                
                if(hasPanels)
                    [hasSunLoS, body2InertDcm, elemSetSun] = AbstractLaunchVehicleSolarPanel.getExpensiveSolarPanelInputs(elemSet, bodyInfo, steeringModel);
%                     celBodyData = bodyInfo.celBodyData;
%                     sunBodyInfo = celBodyData.getTopLevelBody();
%                     
%                     hasSunLoS = true;
%                     eclipseBodies = [bodyInfo, bodyInfo.getParBodyInfo(), bodyInfo.getChildrenBodyInfo()];
%                     for(i=1:length(eclipseBodies))
%                         eclipseBodyInfo = eclipseBodies(i);
% 
%                         if(eclipseBodyInfo == sunBodyInfo)
%                             continue;
%                         end
% 
%                         stateLogEntry = [elemSet.time, elemSet.rVect(:)'];
%                         LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, sunBodyInfo, celBodyData, []);
%                         if(LoS == 0)
%                             hasSunLoS = false;
%                             break;
%                         end
%                     end
%                     
%                     body2InertDcm = steeringModel.getBody2InertialDcmAtTime(elemSet.time, elemSet.rVect(:), elemSet.vVect(:), bodyInfo);
                else
                    hasSunLoS = false; %doesn't matter
                    body2InertDcm = eye(3); %doesn't matter
                    elemSetSun = elemSet; %doesn't matter
                end
                
                storageRates = zeros(size(storageSoCs));
                cumPwrRate = 0;
                for(i=1:length(stgStates)) %#ok<*NO4LP>
                    if(stgStates(i).active)
                        powerSinkStates = stgStates(i).powerSinkStates;
                        powerSrcStates = stgStates(i).powerSrcStates;
                        
                        for(j=1:length(powerSinkStates))
                            powerSinkState = powerSinkStates(j);
                            
                            if(powerSinkState.getActiveState())
                                cumPwrRate = cumPwrRate + powerSinkState.getElectricalPwrRate(elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun);
                            end
                        end
                        
                        for(j=1:length(powerSrcStates))
                            powerSrcState = powerSrcStates(j);
                            
                            if(powerSrcState.getActiveState())
                                cumPwrRate = cumPwrRate + powerSrcState.getElectricalPwrRate(elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun);
                            end
                        end
                    end
                end
                
                numActiveStorage = 0;
                activeStorageInds = [];
                if(cumPwrRate ~= 0)
                    for(i=1:length(powerStorageStates))
                        pwrStorage = powerStorageStates(i).getEpsStorageComponent();
                        
                        if((storageSoCs(i) > 0 && cumPwrRate <= 0) || ...
                                (storageSoCs(i) < pwrStorage.getMaximumCapacity() && cumPwrRate >= 0))
                            numActiveStorage = numActiveStorage + 1;
                            activeStorageInds(end+1) = i; %#ok<AGROW>
                        end
                    end
                    
                    if(numActiveStorage >= 1)
                        storageRates(activeStorageInds) = cumPwrRate / numActiveStorage;
                    end
                end
            else
                storageRates = [];
            end
        end
    end
end