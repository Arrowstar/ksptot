function [eventLog] = ma_executeAerobrake(initialState, eventNum, maneuverEvent, celBodyData)
%ma_executeAerobrake Summary of this function goes here
%   Detailed explanation goes here

    bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    
    ut = initialState(1);
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';
    mass = sum(initialState(9:12));
    
    parentBodyInfo = bodyInfo.getParBodyInfo(celBodyData);
    [sma, ecc, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,gmu);
    [rAp, rPe] = computeApogeePerigee(sma, ecc);
    rSOI = getSOIRadius(bodyInfo, parentBodyInfo);
    tru =  AngleZero2Pi(tru);

	if(rPe > bodyInfo.radius + bodyInfo.atmohgt)
        errorStr = 'Cannot execute aerobraking maneuver: Periapse is above the atmosphere.  Skipping event.';
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
	end
    
	if((ecc >= 1.0 || rAp >= rSOI) && tru < pi)
        errorStr = 'Cannot execute aerobraking maneuver: trajectory will not intersect atmosphere.  Skipping event.';
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
	end
    
    if(norm(rVect) <= 1.015*bodyInfo.radius)
        errorStr = 'Cannot execute aerobraking maneuver: starting altitude is too low.  Skipping event.';
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    dragCoeff = maneuverEvent.dragCoeff;
    dragModel = maneuverEvent.dragModel;
    
    dragAccelModel = @(ut,rVectECI,vVectECI,mass) getDragAccel(bodyInfo, ut, rVectECI, vVectECI, dragCoeff, mass, dragModel, celBodyData);
    eventsModel = @(t,x) events(t, x, bodyInfo);
    
    rVect = reshape(rVect,1,3);
    vVect = reshape(vVect,1,3);
    
    if(ecc < 1.0)
        period = computePeriod(sma, gmu);
    else
        period = bodyInfo.rotperiod/10;
    end
    
    rhs = @(t,x) propAerobrakeRHS(t, x, gmu, dragAccelModel);
    tspan = [ut, ut + 2*period];
    x0 = [rVect, vVect, mass];
    options = odeset('Events',eventsModel,'RelTol',1E-6,'AbsTol',1E-6);
    [T,Y] = ode45(rhs,tspan,x0,options);
    
    eventLog = zeros(length(T), length(initialState));
    eventLog(:,1) = T;
    eventLog(:,2:7) = Y(:,1:6);
    eventLog(:,8) = bodyID;
    eventLog(:,9) = initialState(9);
    eventLog(:,10) = initialState(10);
    eventLog(:,11) = initialState(11);
    eventLog(:,12) = initialState(12);
    eventLog(:,13) = eventNum;
end

function xdot = propAerobrakeRHS(ut, x, gmu, dragAccelModel)
    rVect = x(1:3);
    r = norm(rVect);
    vVect = x(4:6);
    m = x(7);
    
    gAccel = -(gmu/r^3)*rVect; %km^3/s^2 / km^2 = km/s^2    
    dragAccel = dragAccelModel(ut,rVect,vVect,m);
    
    xdot(1:3) = vVect;
    xdot(4:6) = gAccel + dragAccel;
    xdot(7) = 0;
    
    xdot = xdot';    
end

function [value,isterminal,direction] = events(~, x, bodyInfo)
    rVect = x(1:3);
    r = norm(rVect);

    bodyRad2 = 1.02*bodyInfo.radius;
    bodyAtmoHgt = bodyRad2 + bodyInfo.atmohgt;
    
	value(1) = r - bodyRad2;
    value(2) = r - bodyAtmoHgt;
    
    isterminal(1) = 1;
    isterminal(2) = 1;
    
    direction(1) = 0;
    direction(2) = 1;
end