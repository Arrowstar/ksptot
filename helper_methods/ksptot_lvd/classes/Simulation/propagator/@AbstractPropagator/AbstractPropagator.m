classdef(Abstract) AbstractPropagator < matlab.mixin.SetGet
    %AbstractPropagator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [t,y,te,ye,ie] = propagate(obj, integrator, tspan, eventInitStateLogEntry, ...
                                    eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData, ...
                                    tStartPropTime, maxPropTime)
                                
        odeFH = getOdeFunctionHandle(obj, eventInitStateLogEntry)
        
        odeEventsFH = getOdeEventsFunctionHandle(~, eventInitStateLogEntry, eventTermCondFuncHandle, termCondDir, maxT, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
        
        odeOutputFH = getOdeOutputFunctionHandle(~, tStartPropTime, maxPropTime)
        
        [value,isterminal,direction,causes] = callEventsFcn(obj, odeEventsFun, stateLogEntry);
        
        openOptionsDialog(obj);
    end
    
    methods(Static, Access = protected)
        function [value,isterminal,direction, causes] = odeEvents(t,y, eventInitStateLogEntry, evtTermCond, termCondDir, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses, minAltitude, celBodyData)
            persistent maxSimTimeCause minAltTermCause eventTermCondCause
            if(isempty(maxSimTimeCause))
                maxSimTimeCause = MaxEventSimTimeIntTermCause();
                minAltTermCause = MinAltitudeIntTermCause();
                eventTermCondCause = EventTermCondIntTermCause();
            end
            
            y = y(:);

            bodyInfo = eventInitStateLogEntry.centralBody;

            holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();
            if(holdDownEnabled)
                %Need to convert back to ECI if the hold downs are enabled because
                %we are integrating in body fixed in this case
                [rVectECI, vVectECI] = getInertialVectFromFixedFrameVect(t, y(1:3,:)', bodyInfo, y(4:6,:)');
                y = [rVectECI; vVectECI; y(7:end,:)];
            end

            [ut, rVect, ~, ~] = ForceModelPropagator.decomposeIntegratorTandY(t,y);

            %Max Sim Time Constraint
            simTimeRemaining = maxSimTime - ut;
            value(1) = simTimeRemaining;
            isterminal(1) = 1;
            direction(1) = 0;
            causes(1) = maxSimTimeCause;

            %Min Altitude Constraint
            rMag = norm(rVect);
            altitude = rMag - bodyInfo.radius;
            value(end+1) = altitude - minAltitude;
            isterminal(end+1) = 1;
            direction(end+1) = -1;
            causes(end+1) = minAltTermCause;

            %Non-Sequence Events
            for(i=1:length(nonSeqTermConds))
                nonSeqTermCond = nonSeqTermConds{i};

                [value(end+1),isterminal(end+1),direction(end+1)] = nonSeqTermCond(t,y); %#ok<AGROW>
                causes(end+1) = nonSeqTermCauses(i); %#ok<AGROW>
            end

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
            direction(end) = termCondDir.direction;
            causes(end+1) = eventTermCondCause;
        end
        
        function [ut, rVect, vVect, tankStates] = decomposeIntegratorTandY(t,y)
            ut = t;
            rVect = y(1:3);
            vVect = y(4:6);
            tankStates = y(7:end);
        end
    end
end