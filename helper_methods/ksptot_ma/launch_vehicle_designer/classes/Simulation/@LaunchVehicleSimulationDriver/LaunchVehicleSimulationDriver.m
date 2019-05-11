classdef LaunchVehicleSimulationDriver < matlab.mixin.SetGet
    %LaunchVehicleSimulationDriver Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        forceModel(1,1) TotalForceModel = TotalForceModel();
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
        
        function [newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry, integrator, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, forceModels)
            [t0,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
            
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
            [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);
            
            %Set up integrator functions
            dryMass = eventInitStateLogEntry.getTotalVehicleDryMass();
            
            [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime);
            
            [values,isterminal,~,causes] = integrator.callEventsFcn(odeEventsFun, eventInitStateLogEntry);
            tol = 1E-6;
            if(any(abs(values)<=tol))
                if(any(isterminal(abs(values)<1E-6)) == 1)
                    ie = find(abs(values)<1E-6);
                    
                    stopIntegration = false;
                    for(i=1:length(ie)) %#ok<*NO4LP>
                        if(causes(ie(i)).shouldRestartIntegration() == false)
                            stopIntegration = true;
                            break;
%                         else
%                             stopIntegration = false;
%                             eventInitStateLogEntry = causes(ie(i)).getRestartInitialState(eventInitStateLogEntry);
%                             [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime);
%                             break;
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
            
            %handle starting the script within the wrong SoI
            for(i=1:length(causes))
                if(isa(causes(i),'SoITransitionUpIntTermCause'))
                    if(values(i) < -tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime);
                    end
                elseif(isa(causes(i),'SoITransitionDownIntTermCause'))
                    if(values(i) < -tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime);
                    end
                elseif(isa(causes(i),'NonSeqEventTermCondIntTermCause'))
                    if(values(i) <= 0)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        
                        for(j=1:length(activeNonSeqEvts))
                            activeNonSeqEvts(j).initEvent(eventInitStateLogEntry);
                        end
                    
                        [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);
                        [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime);
                    end
                end
            end
            
            [t,y,~,~,ie] = integrator.callIntegrator(odefun,tspan,options,eventInitStateLogEntry); %obj.integrator
            
            if(isSparseOutput)
                t = [t(end)];
                y = [y(end,:)];
            end
                        
            newStateLogEntries = LaunchVehicleStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
            
            newStateLogEntries = obj.processIntegratorTerminationCauses(ie, newStateLogEntries, integrator, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, forceModels);
        end
        
        function [odefun, odeEventsFun, options] = getFunctionsAndOptions(obj, integrator, eventInitStateLogEntry, dryMass, forceModels, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, tStartPropTime)
            odefun = integrator.getOdeFunctionHandle(obj, eventInitStateLogEntry, dryMass, forceModels);
            odeEventsFun = integrator.getOdeEventsFunctionHandle(obj, eventInitStateLogEntry, event.termCond.getEventTermCondFuncHandle(), maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
            odeOutputFun = integrator.getOdeOutputFunctionHandle(tStartPropTime, obj.maxPropTime);
            options = odeset('RelTol',obj.relTol, 'AbsTol',obj.absTol,   'Events',odeEventsFun, 'NormControl','on', 'OutputFcn',odeOutputFun, 'InitialStep', 10, 'Refine', 1);
            options.EventsFcn = odeEventsFun;
        end
        
        function newStateLogEntries = processIntegratorTerminationCauses(obj, ie, newStateLogEntries, integrator, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, forceModels)
            if(not(isempty(ie)))
                finalStateLogEntry = newStateLogEntries(end);
                [~,~,~,causes] = integrator.callEventsFcn(odeEventsFun, finalStateLogEntry);

                cause = causes(ie(1));
                
                if(cause.shouldRestartIntegration())
                    newFinalStateLogEntry = cause.getRestartInitialState(finalStateLogEntry);
                    
                    event.initEventOnRestart(newFinalStateLogEntry);
                    
                    for(j=1:length(activeNonSeqEvts))
                        activeNonSeqEvts(j).initEvent(newFinalStateLogEntry);
                    end
                    
                    [newStateLogEntriesRestart] = obj.integrateOneEvent(event, newFinalStateLogEntry, integrator, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, forceModels);
                    
                    newStateLogEntries = horzcat(newStateLogEntries,newStateLogEntriesRestart);
                end
            end
        end        
    end
    
    methods(Static)
        function [nonSeqTermConds,nonSeqTermCauses] = getNonSeqEvtTermConds(activeNonSeqEvts)
            nonSeqTermConds = {};
            
            nonSeqTermCauses = NonSeqEventTermCondIntTermCause.empty(1,0);
            for(i=1:length(activeNonSeqEvts))
                activeNonSeqEvt = activeNonSeqEvts(i);
                
                if(activeNonSeqEvt.numExecsRemaining > 0)
                    nonSeqTermConds{end+1} = activeNonSeqEvt.getTerminationCondition(); %#ok<AGROW>
                    nonSeqTermCauses(end+1) = NonSeqEventTermCondIntTermCause(activeNonSeqEvt); %#ok<AGROW>
                end
            end
        end
    end
end