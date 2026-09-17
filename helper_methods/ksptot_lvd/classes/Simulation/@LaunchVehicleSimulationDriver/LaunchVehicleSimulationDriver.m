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

                %A10: a per-event maximum duration is measured from the start
                %of this event, not from the start of the script, and can only
                %tighten the global limit.
                if(event.useEvtMaxDur && isfinite(event.evtMaxDur))
                    maxT = min(maxT, t0 + abs(event.evtMaxDur));
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

                if(length(tspan) == 1)
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

                if(event.useEvtMaxDur && isfinite(event.evtMaxDur))
                    maxT = max(maxT, t0 - abs(event.evtMaxDur));
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

                if(length(tspan) == 1)
                    tspan = [tspan(1), tspan(1)-integrationStep];
                end
                
            else
                error('Invalid propagation direction selected.');
            end
            
            %Set up non-seq event term conditions
            [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);

            %A1: the termination conditions the integrator watches on this
            %propagation segment.  Under "All" logic the conditions that have
            %already fired are excluded; termCondInds maps what is left back
            %onto the event's full condition list.
            [termCondFHs, termCondDirs, termCondInds] = event.getActiveTermCondFuncHandles();

            %A10: the event may override the global minimum altitude floor.
            [evtMinAlt, evtMinAltIsTerrain] = obj.getEffectiveMinAltitude(event);

            %Set up integrator functions
            [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, termCondFHs, termCondDirs, evtMinAlt, evtMinAltIsTerrain);
            
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
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, termCondFHs, termCondDirs, evtMinAlt, evtMinAltIsTerrain);
                    end
                elseif(isa(causes(i),'SoITransitionDownIntTermCause'))
                    if(values(i) < -tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, termCondFHs, termCondDirs, evtMinAlt, evtMinAltIsTerrain);
                    end
                elseif(isa(causes(i),'NonSeqEventTermCondIntTermCause'))
                    if(abs(values(i)) <= tol)
                        eventInitStateLogEntry = causes(i).getRestartInitialState(eventInitStateLogEntry);
                        
                        for(j=1:length(activeNonSeqEvts))
                            activeNonSeqEvts(j).initEvent(eventInitStateLogEntry);
                        end
                    
                        [nonSeqTermConds, nonSeqTermCauses] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(activeNonSeqEvts);
                        [~, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, termCondFHs, termCondDirs, evtMinAlt, evtMinAltIsTerrain);
                    end
                end
            end
            
            [t,y,~,~,ie] = propagator.propagate(integrator, tspan, eventInitStateLogEntry, ...
                                                termCondFHs, termCondDirs, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, evtMinAlt, obj.celBodyData, ...
                                                tStartPropTime, obj.maxPropTime, evtMinAltIsTerrain);
                                            
            if(isempty(ie))
                str = sprintf('Event %u propagation did not return an event termination index (ie).\n\nThis generally happens when the integration is numerically unstable.  Consider loosening integration tolerances or switching to the ODE5 integrator.', event.getEventNum());
                obj.lvdData.validation.outputs(end+1) = LaunchVehicleDataValidationError(str);
            end
            
            if(isSparseOutput)
                t = [t(end)];
                y = [y(end,:)];
            end
                        
            newStateLogEntries = LaunchVehicleStateLogEntry.createStateLogEntryFromIntegratorOutputRow(t, y, eventInitStateLogEntry);
            
            newStateLogEntries = obj.processIntegratorTerminationCauses(ie, propagator, newStateLogEntries, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, termCondInds);
        end
        
        function [odefun, odeEventsFun] = getFunctionsAndOptions(obj, eventInitStateLogEntry, event, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, termCondFHs, termCondDirs, evtMinAlt, evtMinAltIsTerrain)
            odefun = event.propagatorObj.getOdeFunctionHandle(eventInitStateLogEntry);

            %Callers inside integrateOneEvent pass the active condition list
            %they already built; other callers get the current one.
            if(nargin < 9 || isempty(termCondFHs))
                [termCondFHs, termCondDirs] = event.getActiveTermCondFuncHandles();
            end

            if(nargin < 11)
                [evtMinAlt, evtMinAltIsTerrain] = obj.getEffectiveMinAltitude(event);
            end

            odeEventsFun = event.propagatorObj.getOdeEventsFunctionHandle(eventInitStateLogEntry, termCondFHs, termCondDirs, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, evtMinAlt, obj.celBodyData, evtMinAltIsTerrain);
        end

        function [evtMinAlt, evtMinAltIsTerrain] = getEffectiveMinAltitude(obj, event)
            %getEffectiveMinAltitude A10: an event may override the global
            %minimum altitude floor, and may ask for it to be measured
            %against the central body's terrain rather than its mean radius.
            if(event.useEvtMinAltitude)
                evtMinAlt = event.evtMinAltitude;
                evtMinAltIsTerrain = event.minAltIsTerrainRelative;
            else
                evtMinAlt = obj.minAltitude;
                evtMinAltIsTerrain = false;
            end
        end
        
        function newStateLogEntries = processIntegratorTerminationCauses(obj, ie, propagator, newStateLogEntries, odeEventsFun, event, tStartPropTime, tStartSimTime, isSparseOutput, checkForSoITrans, activeNonSeqEvts, termCondInds)
            if(nargin < 12)
                termCondInds = 1:event.getNumTermConds();
            end

            if(not(isempty(ie)))
                finalStateLogEntry = newStateLogEntries(end);
                [~,~,~,causes] = propagator.callEventsFcn(odeEventsFun, finalStateLogEntry);

                cause = causes(ie(1));

                %A1: record which of the event's termination conditions ended
                %this segment, and under "All" logic latch it and keep going
                %until every condition has fired at least once.
                restartForTermCondLogic = false;
                if(isa(cause,'EventTermCondIntTermCause'))
                    activeInd = cause.termCondInd;
                    if(activeInd >= 1 && activeInd <= numel(termCondInds))
                        firedInd = termCondInds(activeInd);
                    else
                        firedInd = 1;
                    end

                    allTermConds = event.getAllTermConds();
                    if(firedInd >= 1 && firedInd <= numel(allTermConds))
                        newStateLogEntries(end).termCondFiredInd = firedInd;
                        newStateLogEntries(end).termCondFiredName = char(allTermConds(firedInd).getName());
                    end

                    if(event.termCondLogic == EventTermCondLogicEnum.All)
                        event.latchTermCond(firedInd);
                        restartForTermCondLogic = not(event.allTermCondsLatched());
                    end
                end

                if(cause.shouldRestartIntegration() || restartForTermCondLogic)
                    newFinalStateLogEntry = cause.getRestartInitialState(finalStateLogEntry);

                    %A8: a non-sequential event that asks to be logged
                    %contributes the state log entries its actions produced,
                    %so the discontinuity is visible in the mission's log.
                    if(isa(cause,'NonSeqEventTermCondIntTermCause'))
                        loggedEntries = cause.drainLoggedStateLogEntries();

                        if(not(isempty(loggedEntries)))
                            newStateLogEntries = horzcat(newStateLogEntries, loggedEntries);
                        end
                    end

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

            %A8: highest priority first, so that when two non-sequential
            %events would fire on the same integrator step the one the user
            %marked more important appears earlier in the event vector and is
            %the one ode*'s ie(1) selects.
            activeNonSeqEvts = LaunchVehicleNonSeqEvents.sortByPriority(activeNonSeqEvts);

            nonSeqTermCauses = NonSeqEventTermCondIntTermCause.empty(1,0);
            for(i=1:length(activeNonSeqEvts))
                activeNonSeqEvt = activeNonSeqEvts(i);

                if(activeNonSeqEvt.isActive())
                    %A1: one integrator event per termination condition; they
                    %all carry the same cause, so whichever crosses first
                    %executes the non-sequential event (first-of logic).
                    evtTermConds = activeNonSeqEvt.getTerminationConditions();
                    for(j=1:numel(evtTermConds))
                        nonSeqTermConds{end+1} = evtTermConds{j}; %#ok<AGROW>
                        nonSeqTermCauses(end+1) = NonSeqEventTermCondIntTermCause(activeNonSeqEvt); %#ok<AGROW>
                    end
                end
            end
        end
    end
end