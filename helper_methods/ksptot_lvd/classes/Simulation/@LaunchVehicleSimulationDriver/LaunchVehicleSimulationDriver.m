classdef LaunchVehicleSimulationDriver < matlab.mixin.SetGet
    %LaunchVehicleSimulationDriver Summary of this class goes here
    %   Detailed explanation goes here
    
    properties       
        lvdData LvdData
    end
    
    properties(Dependent)
        simMaxDur(1,1) double
        minAltitude(1,1) double
        maxPropTime(1,1) double
        celBodyData(1,1) struct
    end
    
    methods
        function obj = LaunchVehicleSimulationDriver(lvdData)
            obj.lvdData = lvdData;
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
        
        function [newStateLogEntries] = integrateOneEvent(obj, event, eventInitStateLogEntry, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts)
            [t0,y0, ~] = eventInitStateLogEntry.getFirstOrderIntegratorStateRepresentation();
                       
            %get integrator and propagator
            if(isempty(event.integratorObj))
                event.integratorObj = event.ode45Integrator;
            end
            integrator = event.integratorObj;
            
            if(isempty(event.propagatorObj))
                event.propagatorObj = event.forceModelPropagator;
            end
            propagator = event.propagatorObj;
            
            %set integration output step size
            integratorOptions = integrator.getOptions();
            integrationStep = integratorOptions.getIntegratorStepSize();
            integrationMaxFixedSteps = integratorOptions.getIntegratorMaxNumFixedSteps();
            
            %get propagation direction in time
            propagationDir = event.propDir;
            
            if(propagationDir == PropagationDirectionEnum.Forward) 
            %set max integration time
                if(not(isfinite(obj.simMaxDur)))
                    maxSimDuration = abs(1E6*integrationStep);
                else
                    maxSimDuration = obj.simMaxDur;
                end
                
                maxT = tStartSimTime + maxSimDuration;
                if(t0 > maxT)
                    maxT = t0;
                end
                
                if(integrationStep <= 0)
                    tspan = [t0, maxT];
                else
                    if(maxT - t0 < integrationStep)
                        tspan = [t0, maxT];
                    else
                        estStepsInTspan = (maxT-t0)/integrationStep + 1;
                        if(estStepsInTspan <= integrationMaxFixedSteps)
                            tspan = [t0:integrationStep:maxT]; %#ok<NBRAK>
                        else
                            maxT = integrationMaxFixedSteps*integrationStep+t0;
                            tspan = [t0:integrationStep:maxT]; %#ok<NBRAK>
                        end
                    end
                end

                if(isscalar(tspan))
                    tspan = [tspan(1), tspan(1)+integrationStep];
                end
                
            elseif(propagationDir == PropagationDirectionEnum.Backward) 
                if(not(isfinite(obj.simMaxDur)))
                    maxSimDuration = abs(1E6*integrationStep);
                else
                    maxSimDuration = obj.simMaxDur;
                end
                
                maxT = tStartSimTime - maxSimDuration;
                if(t0 < maxT)
                    maxT = t0;
                end                
                
                if(integrationStep <= 0)
                    tspan = [t0, maxT];
                else
                    if(t0 - maxT < integrationStep)
                        tspan = [t0, maxT];
                    else
                        estStepsInTspan = abs((maxT-t0)/integrationStep - 1);
                        if(estStepsInTspan <= integrationMaxFixedSteps)
                            tspan = [t0:-1*integrationStep:maxT]; %#ok<NBRAK>
                        else
                            maxT = -(integrationMaxFixedSteps*integrationStep - t0);
                            tspan = [t0:-1*integrationStep:maxT]; %#ok<NBRAK>
                        end                        
                    end
                end

                if(isscalar(tspan))
                    tspan = [tspan(1), tspan(1)-integrationStep];
                end
                
            else
                error('Invalid propagation direction selected.');
            end
            
            %Set up non-seq event term conditions
            [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);
            
            %Set up integrator functions     
            [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
            
            [values,isterminal,~,causes] = propagator.callEventsFcn(odeEventsFun, eventInitStateLogEntry);
            tol = 1E-6;
            if(any(abs(values)<=tol))
                if(any(isterminal(abs(values)<1E-6)) == 1)
                    ie = find(abs(values)<1E-6);
                    
                    stopIntegration = false;
                    for(i=1:length(ie)) %#ok<*NO4LP>
                        if(causes(ie(i)).shouldRestartIntegration() == false)
                            stopIntegration = true;
                            break;
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
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
                    end
                elseif(isa(causes(i),'SoITransitionDownIntTermCause'))
                    if(values(i) < -tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
                    end
                elseif(isa(causes(i),'NonSeqEventTermCondIntTermCause'))
                    if(abs(values(i)) <= tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        
                        for(j=1:length(activeNonSeqEvts))
                            activeNonSeqEvts(j).initEvent(eventInitStateLogEntry);
                        end
                    
                        [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses);
                    end
                end
            end
            
            eventTermCondFuncHandle = event.termCond.getEventTermCondFuncHandle();
            termCondDir = event.termCondDir;
            [t,y,~,~,ie] = propagator.propagate(integrator, tspan, eventInitStateLogEntry, ...
                                                eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, obj.minAltitude, obj.celBodyData, ...
                                                tStartPropTime, obj.maxPropTime);
                                            
            if(isempty(ie))
                str = sprintf('Event %u propagation did not return an event termination index (ie).\n\nThis generally happens when the integration is numerically unstable.  Consider loosening integration tolerances or switching to the ODE5 integrator.', event.getEventNum());
                obj.lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(str);
            end
            
            if(isSparseOutput)
                t = [t(end)];
                y = [y(end,:)];
            end
                        
            newStateLogEntries = LaunchVehicleStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
            
            newStateLogEntries = obj.processIntegratorTerminationCauses(ie, propagator, newStateLogEntries, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts);
        end
        
        function [odefun, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)
            odefun = event.propagatorObj.getOdeFunctionHandle(eventInitStateLogEntry);
            
            eventTermCondFuncHandle = event.termCond.getEventTermCondFuncHandle();
            termCondDir = event.termCondDir;
            odeEventsFun = event.propagatorObj.getOdeEventsFunctionHandle(eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, obj.minAltitude, obj.celBodyData);
        end
        
        function newStateLogEntries = processIntegratorTerminationCauses(obj, ie, propagator, newStateLogEntries, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts)
            if(not(isempty(ie)))
                finalStateLogEntry = newStateLogEntries(end);
                [~,~,~,causes] = propagator.callEventsFcn(odeEventsFun, finalStateLogEntry); 

                cause = causes(ie(1));
                
                if(cause.shouldRestartIntegration())
                    newFinalStateLogEntry = cause.getRestartInitialState(finalStateLogEntry);
                    
                    event.initEventOnRestart(newFinalStateLogEntry);
                    
                    for(j=1:length(activeNonSeqEvts))
                        activeNonSeqEvts(j).initEvent(newFinalStateLogEntry);
                    end
                    
                    [newStateLogEntriesRestart] = obj.integrateOneEvent(event, newFinalStateLogEntry, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts);
                                                                        
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