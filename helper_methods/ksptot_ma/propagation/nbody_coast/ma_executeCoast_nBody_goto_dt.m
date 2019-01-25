function [eventLog] = ma_executeCoast_nBody_goto_dt(dt, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime, events, contOnSoITrans, celBodyData)
%ma_executeCoast_nBody_goto_dt Summary of this function goes here
%   Detailed explanation goes here
    if(dt < 0)
        errorStr = ['Cannot coast ', num2str(dt), ' seconds.  Reverse time error, skipping event (any revs prior to this event may still be executed).'];
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    elseif(dt == 0)
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    if(dt > maxPropTime)
        dt = maxPropTime;
    end
    
    ut = initialState(1);
	rVect = initialState(2:4);
    vVect = initialState(5:7);
    dryMass = initialState(9);
    fuelOxMass = initialState(10);
    monoMass = initialState(11);
    xenonMass = initialState(12);
    
	bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    bodyInfoSun = celBodyData.sun;
    forceModel.gravModelBodyIds(end+1) = bodyInfoSun.id;
    forceModel.gravModelBodyIds = unique(forceModel.gravModelBodyIds);
    
    [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody(ut, rVect', bodyInfo, bodyInfoSun, celBodyData, vVect');
       
    rhs = @(t,x) propRHS(t, x, bodyInfoSun, forceModel, massLoss, celBodyData);
    tspan = [ut, ut + dt]; %linspace(ut, ut + dt, numPts); %[ut, ut + dt];
    x0 = [-rVect', -vVect', dryMass, fuelOxMass, monoMass, xenonMass];
    eventFun = @(T,Y) ma_runNBodyEvents(T,Y, events);
    options = odeset('RelTol',1E-8, 'AbsTol',1E-8, 'Events',eventFun);
    [T,Y,TE,YE,IE] = ode113(rhs,tspan,x0,options);
   
    deltaT = T(end) - T(1);
    
    [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody(T', Y(:,1:3)', bodyInfoSun, bodyInfo, celBodyData, Y(:,4:6)');
    
    eventLog = zeros(length(T), length(initialState));
    eventLog(:,1) = T;
    eventLog(:,2:4) = -rVect';
    eventLog(:,5:7) = -vVect';
    eventLog(:,8) = bodyID;
    eventLog(:,9) = Y(:,7);   %Dry Mass
    eventLog(:,10) = Y(:,8);  %Fuel/Ox Mass
    eventLog(:,11) = Y(:,9);  %Monoprop Mass
    eventLog(:,12) = Y(:,10); %Xenon Mass
    eventLog(:,13) = eventNum;
    
    if(~isempty(IE))
        [~,~,~,eventDescs] = eventFun(TE, YE');
        eDesc = eventDescs{IE};
        
        if(contains(eDesc, 'SoI Transition'))
            ut =  TE;
            rVect = YE(1:3);
            vVect = YE(4:6);
            
            if(contains(eDesc,'Up'))
                parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
                [rVectNew, vVectNew] = convertRVVectOnUpwardsSoITransition(bodyInfo, celBodyData, ut, rVect, vVect);
                newBodyId = parentBodyInfo.id;
            elseif(contains(eDesc,'Down'))
                tokens = regexpi(eDesc,'- (\d+)\)','tokens');
                bodyId = str2double(tokens{1});
                childBodyInfo = getBodyInfoByNumber(bodyId, celBodyData);
                
                [rVectNew, vVectNew] = convertRVVectOnDownwardsSoITransition(childBodyInfo, celBodyData, ut, rVect, vVect);
                newBodyId = childBodyInfo.id;
            end
            
            soiTransInitState = [ut, rVectNew', vVectNew', newBodyId, eventLog(end,9:13)];
            eventLog(end+1,:) = soiTransInitState;
            
            if(contOnSoITrans == true)
                events = ma_updateEventFcnWithNewBodyInfo(events, getBodyInfoByNumber(newBodyId, celBodyData), celBodyData);

                soiTranseventLog = ma_executeCoast_nBody_goto_dt(dt-deltaT, soiTransInitState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime-deltaT, events, contOnSoITrans, celBodyData);
                eventLog = [eventLog;soiTranseventLog];
            end
        end
    end
end

function xdot = propRHS(ut, x, cBodyInfo, forceModel, massLoss, celBodyData)
    gBodyIds = forceModel.gravModelBodyIds;

    rVectSC = x(1:3);
    vVectSC = x(4:6);
    
    gAccel = [0;0;0];
    for(i=1:length(gBodyIds)) %#ok<*NO4LP>
        gBodyId = gBodyIds(i);
        bodyOther = getBodyInfoByNumber(gBodyId, celBodyData);
        
        [rVect,~] = getAbsPositBetweenSpacecraftAndBody(ut, rVectSC, cBodyInfo, bodyOther, celBodyData);
        r = norm(rVect);
        
        gAccel = gAccel + (bodyOther.gm/r^3)*rVect; %the negative sign that is normally here is taken care of in the rVect already by virtue of how getAbsPositBetweenSpacecraftAndBody() works
    end
    
	xdot(1:3) = vVectSC;
    xdot(4:6) = gAccel;
    xdot(7) = 0;
    xdot(8) = 0;
    xdot(9) = 0;
    xdot(10) = 0;

	if(massLoss.use == 1 && ~isempty(massLoss.lossConvert))
        resRates = ma_getResRates(massLoss);
        
        xdot(8) = resRates(1);
        xdot(9) = resRates(2);
        xdot(10) = resRates(3);
	end
    
    xdot = xdot';  
end