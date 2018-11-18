classdef LaunchVehicleSimulationDriver < matlab.mixin.SetGet
    %LaunchVehicleSimulationDriver Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        forceModel(1,1) AbstractForceModel = TotalForceModel();
        integrator(1,1) function_handle = @ode45;
        
        lvdData LvdData
    end
    
    properties(Dependent)
        relTol(1,1) double
        absTol(1,1) double
        simMaxDur(1,1) double
        minAltitude(1,1) double
        maxPropTime(1,1) double
        celBodyData(1,1) struct
    end
    
    methods
        function obj = LaunchVehicleSimulationDriver(lvdData)
            obj.lvdData = lvdData;
        end
        
        function value = get.relTol(obj)
            value = obj.lvdData.settings.intRelTol;
        end
        
        function value = get.absTol(obj)
            value = obj.lvdData.settings.intAbsTol;
        end
        
        function value = get.simMaxDur(obj)
            value = obj.lvdData.settings.simMaxDur;
        end
        
        function value = get.minAltitude(obj)
            value = obj.lvdData.settings.minAltitude;
        end
        
        function value = get.maxPropTime(obj)
            value = obj.lvdData.settings.maxScriptPropTime;
        end
        
        function value = get.celBodyData(obj)
            value = obj.lvdData.celBodyData;
        end
        
        function [newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry, integratorFH, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans)
            [t0,y0, tankStateInds] = eventInitStateLogEntry.getIntegratorStateRepresentation();
            
            maxT = tStartSimTime+obj.simMaxDur;
            
            if(t0 > maxT)
                maxT = t0;
            end
            
            tspan = [t0, maxT];
            
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            
            odefun = @(t,y) obj.odefun(t,y, obj, eventInitStateLogEntry, dryMass);
            odeEventsFun = @(t,y) obj.odeEvents(t,y, obj, eventInitStateLogEntry, event.termCond.getEventTermCondFuncHandle(), maxT, checkForSoITrans);
            odeOutputFun = @(t,y,flag) obj.odeOutput(t,y,flag, tStartPropTime, obj.maxPropTime);
            options = odeset('RelTol',obj.relTol, 'AbsTol',obj.absTol,  'NonNegative',tankStateInds, 'Events',odeEventsFun, 'NormControl','on', 'OutputFcn',odeOutputFun);
            
            [value,isterminal,~,causes] = odeEventsFun(tspan(1), y0);
            if(any(abs(value)<=1E-6))
                if(any(isterminal(abs(value)<1E-6)) == 1)
                    ie = find(abs(value)<1E-6);
                    
                    stopIntegration = false;
                    for(i=1:length(ie)) %#ok<*NO4LP>
                        if(causes(ie(i)).shouldRestartIntegration() == false)
                            stopIntegration = true;
                        end
                    end
                    
                    if(stopIntegration)
                        t = tspan(1);
                        y = y0;
                        newStateLogEntries = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);

                        return;
                    end
                end
            end
            
            [t,y,~,~,ie] = integratorFH(odefun,tspan,y0,options); %obj.integrator
            
            if(isSparseOutput)
                t = [t(1); t(end)];
                y = [y(1,:);y(end,:)];
            end
            
            newStateLogEntries = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
            
            if(not(isempty(ie)))
                finalStateLogEntry = newStateLogEntries(end);
                [tF,yF, ~] = finalStateLogEntry.getIntegratorStateRepresentation();
                [~,~,~,causes] = odeEventsFun(tF, yF);

                cause = causes(ie(1));
                
                if(cause.shouldRestartIntegration())
                    newFinalStateLogEntry = cause.getRestartInitialState(finalStateLogEntry);
                    
                    event.initEventOnRestart(newFinalStateLogEntry);
                    
                    [newStateLogEntriesRestart] = obj.integrateOneEvent(event, newFinalStateLogEntry, integratorFH, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans);
                    
                    newStateLogEntries = horzcat(newStateLogEntries,newStateLogEntriesRestart);
                end
            end
        end
    end
   
    methods(Static, Access=private)
        function [ut, rVect, vVect, tankStates] = decomposeIntegratorTandY(t,y)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);
            tankStates = y(7:end);
        end
        
        function dydt = odefun(t,y, obj, eventInitStateLogEntry, dryMass)
            bodyInfo = eventInitStateLogEntry.centralBody;
            [ut, rVect, vVect, tankStatesMasses] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            tankStates = eventInitStateLogEntry.getAllActiveTankStates();
            stageStates = eventInitStateLogEntry.stageStates;
            throttle = eventInitStateLogEntry.throttleModel.getThrottleAtTime(ut);
            lvState = eventInitStateLogEntry.lvState;
            
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);            
            
            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();
            
            tankMassDots = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure);
                                   
            dydt = zeros(length(y),1);
            if(holdDownEnabled)
                %launch clamp is enabled, only motion is circular motion
                %(fixed to body)
                bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
                spinVect = [0;0;bodySpinRate];
                rotAccel = crossARH(spinVect,crossARH(spinVect,rVect));
                
                [rVectECEF] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo);
                vVectECEF = [0;0;0];
                [~, vVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF);
                
                dydt(1:3) = vVectECI(:); 
                dydt(4:6) = rotAccel(:);
                dydt(7:end) = tankMassDots;
            else
                %launch clamp disabled, propagate like normal
%                 CdA = eventInitStateLogEntry.aero.area * eventInitStateLogEntry.aero.Cd;  
                aero = eventInitStateLogEntry.aero;

                totalMass = dryMass + sum(tankStatesMasses);
                
                throttleModel = eventInitStateLogEntry.throttleModel;
                steeringModel = eventInitStateLogEntry.steeringModel;
                
                tankStates = tankStates.copy();
                tmCellArr = num2cell(tankStatesMasses);
                [tankStates.tankMass] = tmCellArr{:};
                
                if(totalMass > 0)
                    forceSum = obj.forceModel.getForce(ut, rVect, vVect, totalMass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState);
                    accelVect = forceSum/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt, but since the thrust force causes us to shed mass, we actually account for the v*dm/dt term there and therefore don't need it!  See: https://en.wikipedia.org/wiki/Variable-mass_system         
                    dydt(7:end) = tankMassDots;
                else
                    accelVect = zeros(3,1);
                    dydt(7:end) = zeros(size(tankMassDots));
                end
                
                dydt(1:3) = vVect'; 
                dydt(4:6) = accelVect;
            end
        end
        
        function [value,isterminal,direction, causes] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond, maxSimTime, checkForSoITrans)
            celBodyData = obj.celBodyData;
            causes = AbstractIntegrationTerminationCause.empty(0,1);
            
            sizeY = size(y);
            if(sizeY(2) > sizeY(1))
                y = y';
            end
            
            [ut, rVect, ~, ~] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
            
            %Max Sim Time Constraint
            simTimeRemaining = maxSimTime - ut;
            value(1) = simTimeRemaining;
            isterminal(1) = 1;
            direction(1) = 0;
            causes(1) = MaxEventSimTimeIntTermCause();
            
            %Min Altitude Constraint
            rMag = norm(rVect);
            altitude = rMag - bodyInfo.radius;
            value(end+1) = altitude - obj.minAltitude;
            isterminal(end+1) = 1;
            direction(end+1) = -1;
            causes(end+1) = MinAltitudeIntTermCause();
            
            if(checkForSoITrans)
            %SoI transitions
                [soivalue, soiisterminal, soidirection, soicauses] = getSoITransitionOdeEvents(ut, rVect, bodyInfo, celBodyData);

                value = horzcat(value, soivalue);
                isterminal = horzcat(isterminal, soiisterminal);
                direction = horzcat(direction, soidirection);
                causes = horzcat(causes, soicauses);
            end
            
            %Event Termination Condition
            [value(end+1),isterminal(end+1),direction(end+1)] = evtTermCond(t,y);
            causes(end+1) = EventTermCondIntTermCause();
        end
        
        function status = odeOutput(t,y,flag, intStartTime, maxIntegrationDuration)
            integrationDuration = toc(intStartTime);
            
            status = 0;
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
                disp('STOP!');
            end
        end
    end
end