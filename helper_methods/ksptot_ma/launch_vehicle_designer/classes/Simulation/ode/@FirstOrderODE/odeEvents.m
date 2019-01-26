function [value,isterminal,direction, causes] = odeEvents(t,y, obj, eventInitStateLogEntry, evtTermCond, maxSimTime, checkForSoITrans, nonSeqTermConds, nonSeqTermCauses)
    celBodyData = obj.celBodyData;
%     causes = AbstractIntegrationTerminationCause.empty(0,1);

    sizeY = size(y);
    if(sizeY(2) > sizeY(1))
        y = y';
    end

    [ut, rVect, ~, ~] = AbstractODE.decomposeIntegratorTandY(t,y);
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
    causes(end+1) = EventTermCondIntTermCause();
end
