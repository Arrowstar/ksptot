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
        
        function [newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry, integratorFH, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts)
            [t0,y0, tankStateInds] = eventInitStateLogEntry.getIntegratorStateRepresentation();
            
            %set max integration time
            maxT = tStartSimTime+obj.simMaxDur;
            if(t0 > maxT)
                maxT = t0;
            end
            
            %set integration output step size
            integrationStep = event.integrationStep;
            
            if(integrationStep <= 0)
                tspan = [t0, maxT];
            else
                tspan = [t0:integrationStep:maxT]; %#ok<NBRAK>
            end
            
            %Set up non-seq event term conditions
            nonSeqTermConds = {};
            nonSeqTermCauses = NonSeqEventTermCondIntTermCause.empty(1,0);
            for(i=1:length(activeNonSeqEvts))
                activeNonSeqEvt = activeNonSeqEvts(i);
                
                if(activeNonSeqEvt.numExecsRemaining > 0)
                    nonSeqTermConds{end+1} = activeNonSeqEvt.getTerminationCondition(); %#ok<AGROW>
                    nonSeqTermCauses(end+1) = NonSeqEventTermCondIntTermCause(activeNonSeqEvt); %#ok<AGROW>
                end
            end
            
            %Set up integrator functions
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            
            odefun = @(t,y) obj.odefun(t,y, obj, eventInitStateLogEntry, dryMass);
            odeEventsFun = @(t,y) obj.odeEvents(t,y, obj, eventInitStateLogEntry, event.termCond.getEventTermCondFuncHandle(), maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
            odeOutputFun = @(t,y,flag) obj.odeOutput(t,y,flag, tStartPropTime, obj.maxPropTime);
            options = odeset('RelTol',obj.relTol, 'AbsTol',obj.absTol,  'NonNegative',tankStateInds, 'Events',odeEventsFun, 'NormControl','on', 'OutputFcn',odeOutputFun);
            options.EventsFcn = odeEventsFun;
            
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
                    
                    for(j=1:length(activeNonSeqEvts))
                        activeNonSeqEvts(j).initEvent(newFinalStateLogEntry);
                    end
                    
                    [newStateLogEntriesRestart] = obj.integrateOneEvent(event, newFinalStateLogEntry, integratorFH, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts);
                    
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
        
        dydt = odefun(t,y, obj, eventInitStateLogEntry, dryMass);
             
        [value,isterminal,direction, causes] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
        
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