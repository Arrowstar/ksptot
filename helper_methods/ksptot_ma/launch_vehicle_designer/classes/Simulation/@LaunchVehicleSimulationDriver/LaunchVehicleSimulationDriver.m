classdef LaunchVehicleSimulationDriver < matlab.mixin.SetGet
    %LaunchVehicleSimulationDrive Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        forceModel(1,1) AbstractForceModel = TotalForceModel();
        integrator(1,1) function_handle = @ode45;
        
        simMaxDur(1,1) double = 600; %sec
        minAltitude = -1; %km
        
        celBodyData(1,1) struct
    end
    
    methods
        function obj = LaunchVehicleSimulationDriver(simMaxDur, minAltitude, celBodyData)
            obj.simMaxDur = simMaxDur;
            obj.minAltitude = minAltitude;
            obj.celBodyData = celBodyData;
        end
        
        function [t,y,newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry)
            [t0,y0, tankStateInds] = eventInitStateLogEntry.getIntegratorStateRepresentation();
            
            maxT = t0+obj.simMaxDur;
            tspan = [t0, maxT];
            
            odefun = @(t,y) obj.odefun(t,y, obj, eventInitStateLogEntry);
            odeEventsFun = @(t,y) obj.odeEvents(t,y, obj, eventInitStateLogEntry, event.termCond.getEventTermCondFuncHandle());
            odeOutputFun = @(t,y,flag) obj.odeOutput(t,y,flag, now()*86400);
            options = odeset('RelTol',1E-4, 'AbsTol',1E-6,  'NonNegative',tankStateInds, 'Events',odeEventsFun, 'NormControl','on', 'OutputFcn',odeOutputFun);
            
            [value,isterminal,~] = odeEventsFun(tspan(1), y0);
            if(any(abs(value)<=1E-6))
                if(any(isterminal(abs(value)<1E-6)) == 1)
                    t = tspan(1);
                    y = y0;
                    newStateLogEntries = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
                    
                    return;
                end
            end
            
            [t,y] = obj.integrator(odefun,tspan,y0,options);
            
%             newStateLogEntries = LaunchVehicleStateLogEntry.empty(length(t),0);
            newStateLogEntries = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
        end
    end
   
    methods(Static, Access=private)
        function [ut, rVect, vVect, tankStates] = decomposeIntegratorTandY(t,y)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);
            tankStates = y(7:end);
        end
        
        function dydt = odefun(t,y, obj, eventInitStateLogEntry)
            if(any(isnan(y)))
                a = 1;
            end
            [ut, rVect, vVect, tankStates] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
                       
            tempStateLogEntry = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t,y, eventInitStateLogEntry);
            totalMass = tempStateLogEntry.getTotalVehicleMass();
            
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            
            dydt = zeros(length(y),1);
                       
            if(totalMass > 0)
                accelVect = obj.forceModel.getForce(tempStateLogEntry)/totalMass;
            else
                accelVect = zeros(3,1);
            end
            
            dydt(1:3) = vVect'; 
            dydt(4:6) = accelVect;
            dydt(7:end) = tempStateLogEntry.getTankMassFlowRatesDueToEngines(pressure);
            
            if(any(isnan(dydt)))
                a = 1;
            end
        end
        
        function [value,isterminal,direction] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond)
            celBodyData = obj.celBodyData;
            
            sizeY = size(y);
            if(sizeY(2) > sizeY(1))
                y = y';
            end
            
            [ut, rVect, vVect, tankStates] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
            
            %Min Altitude Constraint
            altitude = norm(rVect) - bodyInfo.radius;
            value(1) = altitude - obj.minAltitude;
            isterminal(1) = 1;
            direction(1) = -1;
            
            %Max Radius (SoI Radius) Constraint
            parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
            rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
            radius = norm(rVect);
            
            value(2) = rSOI - radius;
            isterminal(2) = 1;
            direction(2) = 1;
                        
            %Event Termination Condition
            [value(3),isterminal(3),direction(3)] = evtTermCond(t,y);
            
            %Temp Condition to see if all tanks are empty
%             value(3) = sum(tankStates);
%             isterminal(3) = 1;
%             direction(3) = 0;
        end
        
        function status = odeOutput(t,y,flag, intStartTime)
            integrationDuration = now()*86400 - intStartTime;
            maxIntegrationDuration = 5;
            
            status = 0; %TODO FIX ME!
            if(integrationDuration > maxIntegrationDuration)
                status = 1;
            end

%             odeprint(t,y,flag);
        end
    end
end