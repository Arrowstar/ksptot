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
        
        function value = get.celBodyData(obj)
            value = obj.lvdData.celBodyData;
        end
        
        function [t,y,newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry)
            [t0,y0, tankStateInds] = eventInitStateLogEntry.getIntegratorStateRepresentation();
            
            maxT = t0+obj.simMaxDur;
            tspan = [t0, maxT];
            
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            
            odefun = @(t,y) obj.odefun(t,y, obj, eventInitStateLogEntry, dryMass);
            odeEventsFun = @(t,y) obj.odeEvents(t,y, obj, eventInitStateLogEntry, event.termCond.getEventTermCondFuncHandle());
            odeOutputFun = @(t,y,flag) obj.odeOutput(t,y,flag, now()*86400);
            options = odeset('RelTol',obj.relTol, 'AbsTol',obj.absTol,  'NonNegative',tankStateInds, 'Events',odeEventsFun, 'NormControl','on', 'OutputFcn',odeOutputFun);
            
            [value,isterminal,~,causes] = odeEventsFun(tspan(1), y0);
            if(any(abs(value)<=1E-6))
                if(any(isterminal(abs(value)<1E-6)) == 1)
                    ie = find(abs(value)<1E-6);
                    
                    stopIntegration = false;
                    for(i=1:length(ie))
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
            
            [t,y,~,~,ie] = obj.integrator(odefun,tspan,y0,options);
            newStateLogEntries = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
            
            if(not(isempty(ie)))
                finalStateLogEntry = newStateLogEntries(end);
                [tF,yF, ~] = finalStateLogEntry.getIntegratorStateRepresentation();
                [~,~,~,causes] = odeEventsFun(tF, yF);

                cause = causes(ie(1));
                
                if(cause.shouldRestartIntegration())
                    newFinalStateLogEntry = cause.getRestartInitialState(finalStateLogEntry);
                    
                    [tRestart,yRestart,newStateLogEntriesRestart] = obj.integrateOneEvent(event, newFinalStateLogEntry);
                    
                    t = vertcat(t,tRestart);
                    y = vertcat(y,yRestart);
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
            
            tankMassDots = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, stageStates, throttle, lvState, pressure);
            
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
            else
                %launch clamp disabled, propagate like normal
                CdA = eventInitStateLogEntry.aero.area * eventInitStateLogEntry.aero.Cd;            

                totalMass = dryMass + sum(tankStatesMasses);

                throttleModel = eventInitStateLogEntry.throttleModel;
                steeringModel = eventInitStateLogEntry.steeringModel;
                
                for(i=1:length(tankStates)) %#ok<*NO4LP>
                    tankStates(i) = tankStates(i).deepCopy();
                    tankStates(i).setTankMass(tankStatesMasses(i));
                end

                totalMDot = sum(tankMassDots);
                
                if(totalMass > 0)
                    forceSum = obj.forceModel.getForce(ut, rVect, vVect, totalMass, bodyInfo, CdA, throttleModel, steeringModel, tankStates, stageStates, lvState);
                    accelVect = (forceSum - vVect*totalMDot)/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt
                else
                    accelVect = zeros(3,1);
                end

                dydt(1:3) = vVect'; 
                dydt(4:6) = accelVect;
            end
            
            dydt(7:end) = tankMassDots;
        end
        
        function [value,isterminal,direction, causes] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond)
            celBodyData = obj.celBodyData;
            causes = AbstractIntegrationTerminationCause.empty(0,1);
            
            sizeY = size(y);
            if(sizeY(2) > sizeY(1))
                y = y';
            end
            
            [ut, rVect, vVect, tankStates] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
            
            %Min Altitude Constraint
            rMag = norm(rVect);
            altitude = rMag - bodyInfo.radius;
            value(1) = altitude - obj.minAltitude;
            isterminal(1) = 1;
            direction(1) = -1;
            causes(1) = MinAltitudeIntTermCause();
            
            %Max Radius (SoI Radius) Constraint (Leave SOI Upwards)
            parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
            rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
            radius = norm(rVect);
            
            if(isempty(parentBodyInfo))
                parentBodyInfo = KSPTOT_BodyInfo.empty(0,1);
            end
            
            value(2) = rSOI - radius;
            isterminal(2) = 1;
            direction(2) = -1;
            causes(2) = SoITransitionUpIntTermCause(bodyInfo, parentBodyInfo, celBodyData);    
            
            %Leave SoI Downwards
            children = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
            for(i=1:length(children))
                childBodyInfo = children{i};
                
                dVect = getAbsPositBetweenSpacecraftAndBody(ut, rVect, bodyInfo, childBodyInfo, celBodyData);
                distToChild = norm(dVect);
                
                rSOI = getSOIRadius(childBodyInfo, bodyInfo);
                
                value(end+1) = distToChild - rSOI; %#ok<AGROW>
                isterminal(end+1) = 1; %#ok<AGROW>
                direction(end+1) = -1; %#ok<AGROW>
                causes(end+1) = SoITransitionDownIntTermCause(bodyInfo, childBodyInfo, celBodyData); %#ok<AGROW>
            end
            
            %Event Termination Condition
            [value(end+1),isterminal(end+1),direction(end+1)] = evtTermCond(t,y);
            causes(end+1) = EventTermCondIntTermCause();
        end
        
        function status = odeOutput(t,y,flag, intStartTime)
            integrationDuration = now()*86400 - intStartTime;
            maxIntegrationDuration = 5;
%             disp(integrationDuration);
            
            status = 0; %TODO FIX ME!
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end

%             odeprint(t,y,flag);
        end
    end
end