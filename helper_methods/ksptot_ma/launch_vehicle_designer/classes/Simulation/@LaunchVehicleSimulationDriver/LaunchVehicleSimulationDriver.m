classdef LaunchVehicleSimulationDriver < matlab.mixin.SetGet
    %LaunchVehicleSimulationDrive Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lv(1,1) LaunchVehicle
        forceModel(1,1) AbstractForceModel = TotalForceModel();
        integrator(1,1) function_handle = @ode45;
        
        simT0(1,1) double = 0; %sec
        simMaxDur(1,1) double = 600; %sec
        minAltitude = -1; %km
    end
    
    methods
        function obj = LaunchVehicleSimulationDriver(lv, simT0, simMaxDur, minAltitude)
            obj.lv = lv;
            obj.simT0 = simT0;
            obj.simMaxDur = simMaxDur;
        end
        
        function [t,y,newStateLogEntries] = integrateOneEvent(obj, eventInitStateLogEntry)
            [t0,y0, tankStateInds] = eventInitStateLogEntry.getIntegratorStateRepresentation();
            
            maxT = obj.simT0+obj.simMaxDur;
            tspan = [t0, maxT];
            
            odefun = @(t,y) obj.odefun(t,y, obj, eventInitStateLogEntry);
            odeEventsFun = @(t,y) obj.odeEvents(t,y, obj, eventInitStateLogEntry);
            options = odeset('NonNegative',tankStateInds, 'Events',odeEventsFun);
            
            [t,y] = obj.integrator(odefun,tspan,y0,options);
            
            newStateLogEntries = LaunchVehicleStateLogEntry.empty(length(t),0);
            for(i=1:length(t)) %#ok<*NO4LP>
                newStateLogEntries(i) = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t(i), y(i,:), eventInitStateLogEntry);
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
        
        function dydt = odefun(t,y, obj, eventInitStateLogEntry)
            [ut, rVect, vVect, tankStates] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
                       
            tempStateLogEntry = eventInitStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t,y, eventInitStateLogEntry);
            totalMass = tempStateLogEntry.getTotalVehicleMass();
            
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            
            dydt = zeros(length(y),1);
                       
            dydt(1:3) = vVect'; 
            dydt(4:6) = obj.forceModel.getForce(tempStateLogEntry)/totalMass;
            dydt(7:end) = tempStateLogEntry.getTankMassFlowRatesDueToEngines(pressure);
        end
        
        function [value,isterminal,direction] = odeEvents(t,y, obj, eventInitStateLogEntry)
            [ut, rVect, vVect, tankStates] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
            bodyInfo = eventInitStateLogEntry.centralBody;
            
            %Min Altitude Constraint
            altitude = norm(rVect) - bodyInfo.radius;
            value(1) = altitude - obj.minAltitude;
            isterminal(1) = 1;
            direction(1) = 0;
            
            %Temp Condition to see if all tanks are empty
%             value(2) = sum(tankStates);
%             isterminal(2) = 1;
%             direction(2) = 0;
        end
    end
end